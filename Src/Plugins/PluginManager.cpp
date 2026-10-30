#include "PluginManager.h"
#include "IRepositoryAwarePlugin.h"
#include "PluginContext.h"
#include "../Git/Models/Repository.h"
#include <git2.h>
#include "IPlugin.h"
#include "IDockPlugin.h"
#include "ICommandPlugin.h"
#include "IAuthPlugin.h"
#include "IDiffPlugin.h"
#include "IServicePlugin.h"
#include "IPagePlugin.h"
#include "IContextMenuPlugin.h"
#include "IWorkflowPlugin.h"
#include "IToolbarPlugin.h"
#include "IRulePlugin.h"

#include <QJSEngine>
#include <QJSValueList>

#include <archive.h>
#include <archive_entry.h>

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QPluginLoader>
#include <QLibrary>
#include <QStringList>
#include <QQmlEngine>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDateTime>
#include <QElapsedTimer>
#include <QThread>
#include <QEventLoop>
#include <QEvent>
#include <QMetaObject>
#include <QPointer>
#include <QSet>
#include <QTimer>

#include <atomic>
#include <thread>
#include <algorithm>

// ── GEP helpers ───────────────────────────────────────────────────────────────
namespace {
    QString slugify(const QString& name)
    {
        QString slug;
        slug.reserve(name.size());
        bool prevDash = false;
        for (const QChar c : name) {
            if (c.isLetterOrNumber()) {
                slug += c.toLower();
                prevDash = false;
            } else if (!slug.isEmpty() && !prevDash) {
                slug += QLatin1Char('-');
                prevDash = true;
            }
        }
        while (slug.endsWith(QLatin1Char('-')))
            slug.chop(1);
        return slug;
    }

    QString manifestIdOfDir(const QString& dir)
    {
        QFile f(dir + QStringLiteral("/plugin.json"));
        if (!f.open(QIODevice::ReadOnly))
            return {};
        const auto doc = QJsonDocument::fromJson(f.readAll());
        return doc.isObject() ? doc.object().value(QStringLiteral("id")).toString()
                              : QString();
    }

    int compareVersions(const QString& a, const QString& b)
    {
        const QStringList pa = a.split(QLatin1Char('.'));
        const QStringList pb = b.split(QLatin1Char('.'));
        const int n = qMax(pa.size(), pb.size());
        for (int i = 0; i < n; ++i) {
            const int x = i < pa.size() ? pa.at(i).toInt() : 0;
            const int y = i < pb.size() ? pb.at(i).toInt() : 0;
            if (x != y)
                return x < y ? -1 : 1;
        }
        return 0;
    }

    IContextMenuPlugin::MenuTarget menuTargetFor(const QString& target)
    {
        using T = IContextMenuPlugin::MenuTarget;
        if      (target == QStringLiteral("branch")) return T::Branch;
        else if (target == QStringLiteral("file"))   return T::File;
        return T::CommitGraph;
    }

    PluginInfo readGepManifest(const QString& gepPath)
    {
        PluginInfo info;

        struct archive* reader = archive_read_new();
        if (!reader)
            return info;
        archive_read_support_format_all(reader);
        archive_read_support_filter_all(reader);
        if (archive_read_open_filename(reader, gepPath.toUtf8().constData(), 10240) != ARCHIVE_OK) {
            archive_read_free(reader);
            return info;
        }

        struct archive_entry* entry = nullptr;
        QByteArray data;
        while (archive_read_next_header(reader, &entry) == ARCHIVE_OK) {
            const QString name = QString::fromUtf8(archive_entry_pathname(entry));
            if (QFileInfo(name).fileName() != QStringLiteral("plugin.json"))
                continue;

            data.clear();
            const void* buf = nullptr;
            size_t size = 0;
            la_int64_t offset = 0;
            int r;
            while ((r = archive_read_data_block(reader, &buf, &size, &offset)) == ARCHIVE_OK)
                data.append(static_cast<const char*>(buf), int(size));
            if (r != ARCHIVE_EOF)
                data.clear(); // incomplete read — keep scanning for another plugin.json
            else
                break;
        }
        archive_read_free(reader);

        if (data.isEmpty())
            return info;
        const auto doc = QJsonDocument::fromJson(data);
        if (doc.isObject())
            info = PluginInfo::fromJson(doc.object(), QString());
        return info;
    }

    bool removeDirectoryPatiently(const QString& path, int timeoutMs)
    {
        QElapsedTimer timer;
        timer.start();
        while (QDir(path).exists()) {
            QDir(path).removeRecursively();
            if (!QDir(path).exists())
                return true;
            if (timer.elapsed() >= timeoutMs)
                return false;
            QThread::msleep(50);
        }
        return true;
    }

    bool waitUntilReadable(const QString& dir, int timeoutMs)
    {
        QElapsedTimer timer;
        timer.start();
        while (true) {
            bool allReadable = true;
            QDirIterator it(dir, QDir::Files, QDirIterator::Subdirectories);
            while (it.hasNext()) {
                it.next();
                QFile f(it.filePath());
                if (!f.open(QIODevice::ReadOnly)) {
                    allReadable = false;
                    break;
                }
                f.close();
            }
            if (allReadable)
                return true;
            if (timer.elapsed() >= timeoutMs)
                return false;
            QThread::msleep(50);
        }
    }

    constexpr int kUiSettleMs        = 60;
    constexpr int kUnloadRetryMs     = 40;
    constexpr int kMaxUnloadAttempts = 25;
    constexpr int kScanIdleRetryMs   = 40;

    bool extractPackage(const QString& gepPath, const QString& targetDir);

    GepPlaceResult placeGepPayload(const QString& gepPath, const QString& payloadSource,
                                const QString& targetDir, const QString& pluginId,
                                bool hasBinary)
    {
        // Unique install dirs are created empty; skip a hard replace of a locked folder.
        if (QDir(targetDir).exists() && !removeDirectoryPatiently(targetDir, 1500)) {
            if (!payloadSource.isEmpty())
                QDir(payloadSource).removeRecursively();
            return GepPlaceResult::PlaceFailed;
        }

        if (payloadSource.isEmpty()) {
            // Nothing staged yet: write each file once, in place.
            if (!extractPackage(gepPath, targetDir))
                return GepPlaceResult::ExtractFailed;
        } else {
            bool moved = false;
            for (int attempt = 0; attempt < 15 && !moved; ++attempt) {
                if (QDir().rename(payloadSource, targetDir) || !QDir(payloadSource).exists())
                    moved = true;
                else
                    QThread::msleep(qMin(300, 100 + 100 * attempt));
            }
            if (!moved)
                moved = extractPackage(gepPath, targetDir);
            QDir(payloadSource).removeRecursively();
            if (!moved)
                return GepPlaceResult::PlaceFailed;
        }

        if (hasBinary)
            waitUntilReadable(targetDir, 2500);

        if (!pluginId.isEmpty()) {
            const QDir root(QFileInfo(targetDir).absolutePath());
            const auto entries = root.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
            for (const QString& entry : entries) {
                const QString p = root.absoluteFilePath(entry);
                if (p != targetDir && manifestIdOfDir(p) == pluginId) {
                    if (!QDir(p).removeRecursively() && QDir(p).exists()) {
                        QFile marker(p + QStringLiteral("/.gitease-uninstalled"));
                        if (marker.open(QIODevice::WriteOnly)) {
                            marker.write("1");
                            marker.close();
                        }
                    }
                }
            }
        }
        return GepPlaceResult::Ok;
    }

    bool extractPackage(const QString& gepPath, const QString& targetDir)
    {
        if (!QDir().mkpath(targetDir))
            return false;

        struct archive *reader = archive_read_new();
        struct archive *writer = archive_write_disk_new();
        struct archive_entry *entry = nullptr;

        if (!reader || !writer) {
            if (reader) archive_read_free(reader);
            if (writer) archive_write_free(writer);
            return false;
        }

        archive_read_support_format_all(reader);
        archive_read_support_filter_all(reader);
        archive_write_disk_set_options(writer,
            ARCHIVE_EXTRACT_TIME |
            ARCHIVE_EXTRACT_PERM |
            ARCHIVE_EXTRACT_SECURE_NODOTDOT);

        int r = archive_read_open_filename(reader, gepPath.toUtf8().constData(), 10240);
        if (r != ARCHIVE_OK) {
            const QString err = QString::fromUtf8(archive_error_string(reader));
            qWarning() << "[GEP] Cannot open archive:" << err;
            archive_read_free(reader);
            archive_write_free(writer);
            return false;
        }

        bool extractOk = true;

        while ((r = archive_read_next_header(reader, &entry)) == ARCHIVE_OK) {
            const QString entryName = QString::fromUtf8(archive_entry_pathname(entry));

            // Normalize and reject unsafe paths (absolute, .. traversal)
            const QString cleanRel = QDir::cleanPath(entryName);
            if (cleanRel.isEmpty() || cleanRel.startsWith(QLatin1Char('/')) ||
                cleanRel == QStringLiteral("..") || cleanRel.startsWith(QStringLiteral("../")))
            {
                qWarning() << "[GEP] Skipping unsafe path:" << entryName;
                continue;
            }

            const QString absolutePath = targetDir + QLatin1Char('/') + cleanRel;
            archive_entry_set_pathname(entry, absolutePath.toUtf8().constData());

            int hr = archive_write_header(writer, entry);
            if (hr == ARCHIVE_FATAL) {
                qWarning() << "[GEP] Fatal writing header for:" << entryName
                           << QString::fromUtf8(archive_error_string(writer));
                extractOk = false;
                break;
            }

            if (archive_entry_size(entry) > 0) {
                const void* buf = nullptr;
                size_t bufSize = 0;
                la_int64_t offset = 0;
                int dataResult = 0;

                while ((dataResult = archive_read_data_block(reader, &buf, &bufSize, &offset)) == ARCHIVE_OK) {
                    if (archive_write_data_block(writer, buf, bufSize, offset) != ARCHIVE_OK) {
                        qWarning() << "[GEP] Failed writing data for:" << entryName
                                   << QString::fromUtf8(archive_error_string(writer));
                        extractOk = false;
                        break;
                    }
                }

                if (!extractOk)
                    break;

                if (dataResult != ARCHIVE_EOF) {
                    qWarning() << "[GEP] Unexpected end of data for:" << entryName;
                    extractOk = false;
                    break;
                }
            }

            archive_write_finish_entry(writer);
        }

        if (r != ARCHIVE_EOF)
            extractOk = false;

        archive_read_free(reader);
        archive_write_free(writer);
        return extractOk;
    }

    QString resolveLibraryPath(const QString& pluginDir, const QString& entry)
    {
        if(entry.endsWith(QStringLiteral(".dll"), Qt::CaseInsensitive) ||
           entry.endsWith(QStringLiteral(".so"),  Qt::CaseInsensitive) ||
           entry.endsWith(QStringLiteral(".dylib"), Qt::CaseInsensitive))
        {
            return QDir(pluginDir).filePath(entry);
        }

#if defined(Q_OS_WIN)
        return QDir(pluginDir).filePath(entry + QStringLiteral(".dll"));
#elif defined(Q_OS_MACOS)
        const QFileInfo fi(entry);
        const QString dir  = fi.path();
        const QString base = fi.fileName();
        return QDir(pluginDir).filePath(dir + QStringLiteral("/lib") + base + QStringLiteral(".dylib"));
#else
        const QFileInfo fi(entry);
        const QString dir  = fi.path();
        const QString base = fi.fileName();
        return QDir(pluginDir).filePath(dir + QStringLiteral("/lib") + base + QStringLiteral(".so"));
#endif
    }

    PluginInfo readManifestFile(const QString& pluginDir)
    {
        QJsonObject obj;
        QFile f(QDir(pluginDir).filePath(QStringLiteral("plugin.json")));
        if(!f.open(QIODevice::ReadOnly)) {
            return {};
        }

        const auto doc = QJsonDocument::fromJson(f.readAll());
        if(!doc.isNull() && doc.isObject()) {
            obj = doc.object();
        }

        return PluginInfo::fromJson(obj, pluginDir);
    }

    // Deletes the copies an earlier load left in a .hot folder. A copy that is still mapped by a
    // running process cannot be deleted on Windows; it stays and is tried again next time.
    void removeHotCopies(const QString& hotDir)
    {
        const QDir hot(hotDir);
        const auto copies = hot.entryList(QDir::Files);
        for(const QString& copy : copies) {
            QFile::remove(hot.filePath(copy));
        }
    }

    bool isHotCopy(const QString& path)
    {
        return QDir::fromNativeSeparators(path).contains(QStringLiteral("/.hot/"));
    }

    QString prepareHotLibrary(const QString& pluginDir, const QString& entry)
    {
        static std::atomic<int> counter { 0 };

        const QString original = resolveLibraryPath(pluginDir, entry);
        if(!QFileInfo::exists(original)) {
            return original;
        }

        const QFileInfo fi(original);
        const QString hotDir = fi.dir().filePath(QStringLiteral(".hot"));
        QDir().mkpath(hotDir);
        removeHotCopies(hotDir);
        const QString hotPath = QDir(hotDir).filePath(
            QString::number(QDateTime::currentMSecsSinceEpoch()) + QLatin1Char('-')
            + QString::number(counter.fetch_add(1)) + QLatin1Char('-') + fi.fileName());
        if(QFile::copy(original, hotPath)) {
            return hotPath;
        }

        return original;
    }

    template<typename Work, typename Done>
    void runInBackground(PluginManager* self, Work work, Done done)
    {
        QPointer<PluginManager> guard(self);
        QMetaObject::invokeMethod(self->backgroundContext(),
                                  [guard, work = std::move(work), done = std::move(done)]() mutable {
            auto result = work();
            if(!guard) {
                return;
            }

            QMetaObject::invokeMethod(guard.data(), [done, result]() mutable {
                done(result);
            }, Qt::QueuedConnection);
        }, Qt::QueuedConnection);
    }

    PluginScanResult scanPluginDirectory(const QString& path, const QSet<QString>& skipIds)
    {
        struct Candidate
        {
            QString    dir;
            PluginInfo info;
        };

        PluginScanResult result;
        QDir dir(path);
        if(!dir.exists()) {
            return result;
        }

        QList<Candidate> candidates;
        const auto entries = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        for(const QString& entry : entries) {
            if(entry.startsWith(QLatin1Char('.'))) {
                continue; // staging dirs / markers
            }

            const QString dirPath = dir.absoluteFilePath(entry);
            if(QFile::exists(dirPath + QStringLiteral("/.gitease-uninstalled"))) {
                QDir(dirPath).removeRecursively(); // marked for removal on a previous run
                continue;
            }

            const PluginInfo info = readManifestFile(dirPath);
            if(!info.isValid() || info.id.isEmpty() || info.version.isEmpty()) {
                continue;
            }

            if(skipIds.contains(info.id)) {
                continue; // a loaded plugin's files may be in use; never touch or reload them here
            }

            candidates.append(Candidate { dirPath, info });
        }

        QMap<QString, int> best;
        for(int i = 0; i < candidates.size(); ++i) {
            const Candidate& candidate = candidates.at(i);
            auto it = best.find(candidate.info.id);
            if(it == best.end()) {
                best.insert(candidate.info.id, i);
                continue;
            }

            const Candidate& current = candidates.at(it.value());
            const int order = compareVersions(candidate.info.version, current.info.version);
            if(order > 0
               || (order == 0 && QFileInfo(candidate.dir).lastModified() > QFileInfo(current.dir).lastModified())) {
                it.value() = i;
            }
        }

        for(int i = 0; i < candidates.size(); ++i) {
            const Candidate& candidate = candidates.at(i);
            if(best.value(candidate.info.id) != i) {
                result.staleDirs.append(qMakePair(candidate.dir, candidate.info.id));
            }
        }

        for(auto it = best.cbegin(); it != best.cend(); ++it) {
            const Candidate& candidate = candidates.at(it.value());
            PreparedPlugin prepared;
            prepared.info = candidate.info;
            if(candidate.info.enabled && candidate.info.hasCppEntry()) {
                prepared.libraryPath = prepareHotLibrary(candidate.dir, candidate.info.cppEntry);
            }
            result.plugins.append(prepared);
        }

        return result;
    }

    // Reads the manifest of a .gep without touching the plugin folders and keeps a copy of the
    // package in the downloads folder.
    GepInspection inspectGepPackage(const GepRequest& request)
    {
        GepInspection inspection;
        QDir().mkpath(request.pluginRoot);

        inspection.manifest = readGepManifest(request.gepPath);
        if(!inspection.manifest.isValid() || inspection.manifest.id.isEmpty()) {
            const QString staging = request.pluginRoot + QStringLiteral("/.stage_")
                                    + QString::number(QDateTime::currentMSecsSinceEpoch());
            inspection.staging = staging;
            if(extractPackage(request.gepPath, staging)) {
                QString actualStagingDir = staging;
                if(!QFile::exists(staging + QStringLiteral("/plugin.json"))) {
                    QDirIterator it(staging, {QStringLiteral("plugin.json")},
                                    QDir::Files, QDirIterator::Subdirectories);
                    if(it.hasNext()) {
                        it.next();
                        actualStagingDir = QFileInfo(it.filePath()).absolutePath();
                    }
                }

                inspection.manifest = readManifestFile(actualStagingDir);
                if(inspection.manifest.isValid() && !inspection.manifest.id.isEmpty()) {
                    inspection.payloadSource = staging; // already extracted — reuse it
                }
            }
        }

        if(inspection.manifest.isValid() && !inspection.manifest.id.isEmpty()
           && QDir().mkpath(request.downloadsDir)) {
            const QString slug = slugify(inspection.manifest.name);
            const QString savedName = slug.isEmpty() ? inspection.manifest.id : slug;
            const QString savedPath = request.downloadsDir + QLatin1Char('/')
                                      + savedName + QLatin1Char('-') + inspection.manifest.version
                                      + QStringLiteral(".gep");
            // A package picked from the downloads folder already is its own saved copy; touching
            // it would delete the file that is about to be installed.
            const QString sourcePath = QFileInfo(request.gepPath).canonicalFilePath();
            const QString savedCanonical = QFileInfo(savedPath).canonicalFilePath();
            if(sourcePath.isEmpty() || sourcePath != savedCanonical) {
                const QString partialPath = savedPath + QStringLiteral(".part");
                QFile::remove(partialPath);
                if(QFile::copy(request.gepPath, partialPath)) {
                    QFile::remove(savedPath);
                    QFile::rename(partialPath, savedPath);
                } else {
                    QFile::remove(partialPath);
                }
            }
        }

        return inspection;
    }

    GepPlacement placeAndPrepare(const GepRequest& request, const QString& payloadSource,
                                 const QString& targetDir, const PluginInfo& manifest)
    {
        GepPlacement placement;
        placement.id        = manifest.id;
        placement.name      = manifest.name;
        placement.targetDir = targetDir;
        placement.result    = placeGepPayload(request.gepPath, payloadSource, targetDir,
                                              manifest.id, !manifest.cppEntry.isEmpty());

        if(placement.result == GepPlaceResult::Ok) {
            placement.prepared.info = readManifestFile(targetDir);
            const PluginInfo& info = placement.prepared.info;
            if(info.isValid() && info.enabled && info.hasCppEntry()) {
                placement.prepared.libraryPath = prepareHotLibrary(targetDir, info.cppEntry);
            }
        } else {
            QDir(targetDir).removeRecursively();
        }

        if(!request.tempToRemove.isEmpty()) {
            QFile::remove(request.tempToRemove);
        }

        return placement;
    }

    // Deletes every folder that holds the plugin. Folders that stay locked are marked so the
    // next scan removes them.
    PluginRemovalResult removePluginDirectories(const QString& id, bool known,
                                                const QStringList& knownDirs,
                                                const QStringList& roots)
    {
        QStringList dirs;
        for(const QString& knownDir : knownDirs) {
            const QString dirPath = QDir::cleanPath(knownDir);
            if(!dirs.contains(dirPath)) {
                dirs << dirPath;
            }
        }

        for(const QString& rootPath : roots) {
            QDir root(rootPath);
            if(!root.exists()) {
                continue;
            }

            const auto entries = root.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
            for(const QString& entry : entries) {
                if(entry.startsWith(QLatin1Char('.'))) {
                    continue;
                }

                const QString dirPath = QDir::cleanPath(root.absoluteFilePath(entry));
                if(manifestIdOfDir(dirPath) == id && !dirs.contains(dirPath)) {
                    dirs << dirPath;
                }
            }
        }

        for(const QString& dirPath : std::as_const(dirs)) {
            if(removeDirectoryPatiently(dirPath, 2000) || !QDir(dirPath).exists()) {
                continue;
            }

            QFile marker(dirPath + QStringLiteral("/.gitease-uninstalled"));
            if(marker.open(QIODevice::WriteOnly)) {
                marker.write("1");
                marker.close();
            }
        }

        PluginRemovalResult result;
        result.foundAny = known || !dirs.isEmpty();
        return result;
    }

    QString downloadsDirectory()
    {
        return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
               + QStringLiteral("/downloads/plugins");
    }

    // Reads the manifest of every package in the downloads folder. When several versions of one
    // plugin are kept, only the newest one is reported.
    QVariantList scanDownloadedPackages(const QString& downloadsDir)
    {
        struct Package
        {
            PluginInfo info;
            QString    path;
            qint64     bytes = 0;
            QDateTime  modified;
        };

        QMap<QString, Package> best;
        const QDir dir(downloadsDir);
        const auto files = dir.entryInfoList({ QStringLiteral("*.gep") }, QDir::Files);
        for(const QFileInfo& file : files) {
            const PluginInfo info = readGepManifest(file.absoluteFilePath());
            if(!info.isValid() || info.version.isEmpty()) {
                continue;
            }

            Package package;
            package.info     = info;
            package.path     = file.absoluteFilePath();
            package.bytes    = file.size();
            package.modified = file.lastModified();

            auto it = best.find(info.id);
            if(it == best.end()) {
                best.insert(info.id, package);
                continue;
            }

            const int order = compareVersions(info.version, it->info.version);
            if(order > 0 || (order == 0 && package.modified > it->modified)) {
                it.value() = package;
            }
        }

        QVariantList result;
        for(auto it = best.cbegin(); it != best.cend(); ++it) {
            QVariantMap map = it->info.toVariantMap();
            map.insert(QStringLiteral("packagePath"), it->path);
            map.insert(QStringLiteral("packageSizeKb"), int((it->bytes + 1023) / 1024));
            result << map;
        }

        return result;
    }

} // namespace

// ── Construction / destruction ───────────────────────────────────────────────

PluginManager::PluginManager(QObject* parent)
    : QObject(parent)
    , m_context(new PluginContext(this))
{
    wireContext();

    // Scans, installs and uninstalls do their file work here, never on the UI thread.
    m_workerThread = new QThread(this);
    m_workerThread->setObjectName(QStringLiteral("GitEasePluginWorker"));
    m_workerContext = new QObject;
    m_workerContext->moveToThread(m_workerThread);
    connect(m_workerThread, &QThread::finished, m_workerContext, &QObject::deleteLater);
    m_workerThread->start();

    // Accumulate dock registrations into m_docks so QML can bind to registeredDocks
    connect(this, &PluginManager::dockRegistered,
            this, [this](const QString& id, const QUrl& url,
                         const QString& title, const QString& icon) {
                m_docks.append(QVariantMap {
                    { QStringLiteral("id"),    id            },
                    { QStringLiteral("url"),   url.toString()},
                    { QStringLiteral("title"), title         },
                    { QStringLiteral("icon"),  icon          },
                });
                emit docksChanged();
            });

    // Accumulate page registrations into m_pages
    connect(this, &PluginManager::pageRegistered,
            this, [this](const QString& id, const QUrl& url,
                         const QString& title, const QString& icon, int order,
                         const QString& pluginId) {
                m_pages.append(QVariantMap {
                    { QStringLiteral("id"),       id       },
                    { QStringLiteral("pluginId"), pluginId },
                    { QStringLiteral("url"),      url.toString()},
                    { QStringLiteral("title"),    title    },
                    { QStringLiteral("icon"),     icon     },
                    { QStringLiteral("order"),    order    },
                });
                // keep sorted by order
                std::sort(m_pages.begin(), m_pages.end(), [](const QVariant& a, const QVariant& b) {
                    return a.toMap().value(QStringLiteral("order")).toInt()
                         < b.toMap().value(QStringLiteral("order")).toInt();
                });
                emit pagesChanged();
            });

    // Accumulate toolbar action registrations
    connect(this, &PluginManager::toolbarActionRegistered,
            this, [this](const QString& pluginId, const QString& id,
                         const QString& tooltip, const QString& icon, int order) {
                m_toolbarActions.append(QVariantMap {
                    { QStringLiteral("pluginId"), pluginId },
                    { QStringLiteral("id"),       id       },
                    { QStringLiteral("tooltip"),  tooltip  },
                    { QStringLiteral("icon"),     icon     },
                    { QStringLiteral("order"),    order    },
                });
                std::sort(m_toolbarActions.begin(), m_toolbarActions.end(),
                          [](const QVariant& a, const QVariant& b) {
                    return a.toMap().value(QStringLiteral("order")).toInt()
                         < b.toMap().value(QStringLiteral("order")).toInt();
                });
                emit toolbarActionsChanged();
            });
}

// A plugin that was deactivated and whose library is still being released.
struct PluginManager::ReleaseJob
{
    QString            id;
    IPlugin*           plugin   = nullptr;
    QPluginLoader*     loader   = nullptr;
    int                attempts = 0;
    bool               shutDown = false;
    std::function<void()> done;
};

PluginManager::~PluginManager()
{
    m_workerThread->quit();
    m_workerThread->wait();

    for(const auto& job : std::as_const(m_releaseJobs)) {
        if(!job->shutDown && job->plugin) {
            job->plugin->shutdown();
        }

        if(job->loader) {
            job->loader->unload();
            delete job->loader;
        }
    }

    for (auto* plugin : std::as_const(m_plugins))
        plugin->shutdown();
    for (auto* loader : std::as_const(m_loaders)) {
        loader->unload();
        delete loader;
    }
}

QObject* PluginManager::backgroundContext() const
{
    return m_workerContext;
}

// ── Context wiring ───────────────────────────────────────────────────────────

void PluginManager::wireContext()
{
    connect(m_context, &PluginContext::notifyRequested,
            this,      &PluginManager::notifyRequested);

    connect(m_context, &PluginContext::dockRegistered,
            this, [this](IDockPlugin* plugin) {
                emit dockRegistered(plugin->id(),
                                    plugin->dockQmlUrl(),
                                    plugin->dockTitle(),
                                    plugin->dockIcon());
            });

    connect(m_context, &PluginContext::diffRegistered,
            this, [this](IDiffPlugin* plugin) {
                const QUrl viewerUrl    = plugin->diffViewerQmlUrl();
                const QUrl colorizerUrl = plugin->colorizerQmlUrl();
                for (const QString& ext : plugin->handledExtensions()) {
                    if (!viewerUrl.isEmpty())
                        m_diffPlugins[ext.toLower()] = viewerUrl;
                    if (!colorizerUrl.isEmpty())
                        m_colorizers[ext.toLower()] = colorizerUrl;
                }
            });

    connect(m_context, &PluginContext::commandRegistered,
            this, [this](ICommandPlugin* plugin) {
                QVariantList cmds;
                for (const auto& cmd : plugin->commands()) {
                    cmds << QVariantMap {
                        { QStringLiteral("id"),       cmd.id       },
                        { QStringLiteral("label"),    cmd.label    },
                        { QStringLiteral("icon"),     cmd.icon     },
                        { QStringLiteral("shortcut"), cmd.shortcut },
                        { QStringLiteral("contexts"), cmd.contexts },
                    };
                }
                emit commandRegistered(plugin->id(), cmds);
            });

    connect(m_context, &PluginContext::pageRegistered,
            this, [this](IPagePlugin* plugin) {
                emit pageRegistered(plugin->pageId(),
                                    plugin->pageQmlUrl(),
                                    plugin->pageTitle(),
                                    plugin->pageIcon(),
                                    plugin->pageOrder(),
                                    plugin->id());
            });

    connect(m_context, &PluginContext::contextMenuRegistered,
            this, [this](IContextMenuPlugin* plugin) {
                m_contextMenuPlugins.append(plugin);
                emit contextMenusChanged();
            });

    connect(m_context, &PluginContext::workflowRegistered,
            this, [this](IWorkflowPlugin* plugin) {
                m_workflowPlugins.append(plugin);
            });

    connect(m_context, &PluginContext::toolbarRegistered,
            this, [this](IToolbarPlugin* plugin) {
                m_toolbarPlugins.append(plugin);
                for (const auto& action : plugin->toolbarActions()) {
                    emit toolbarActionRegistered(plugin->id(),
                                                  action.id,
                                                  action.tooltip,
                                                  action.icon,
                                                  action.order);
                }
            });

    connect(m_context, &PluginContext::ruleRegistered,
            this, [this](IRulePlugin* plugin) {
                m_rulePlugins.append(plugin);
            });
}

// ── Setup ────────────────────────────────────────────────────────────────────

void PluginManager::initialize()
{
    if (auto* engine = qmlEngine(this))
        m_context->setQmlEngine(engine);
}

void PluginManager::scanDefaultDirectory()
{
    const QString base =
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    scanDirectory(base + QStringLiteral("/plugins"));
}

void PluginManager::scanApplicationPluginsDirectory()
{
    scanDirectory(QCoreApplication::applicationDirPath()
                  + QStringLiteral("/plugins"));
}

void PluginManager::scanDirectory(const QString& path)
{
    if(!m_scanQueue.contains(path)) {
        m_scanQueue.append(path);
    }

    startNextScan();
}

bool PluginManager::isBusy(const QString& id) const
{
    return m_installingIds.contains(id) || m_removingIds.contains(id);
}

// Directories are looked through on a worker thread; the plugins found are then loaded one per
// event-loop turn so the window keeps painting and answering input while they come up.
void PluginManager::startNextScan()
{
    if(m_scanRunning || m_scanQueue.isEmpty()) {
        return;
    }

    // Scans never overlap installs or uninstalls; whoever finishes last starts the next scan.
    if(!m_installingIds.isEmpty() || !m_removingIds.isEmpty()) {
        return;
    }

    const QString path = m_scanQueue.takeFirst();

    QSet<QString> skipIds = m_installingIds;
    skipIds.unite(m_removingIds);
    for(const PluginInfo& info : std::as_const(m_infos)) {
        skipIds.insert(info.id);
    }
    for(const PreparedPlugin& queued : std::as_const(m_loadQueue)) {
        skipIds.insert(queued.info.id);
    }

    m_scanRunning = true;
    runInBackground(this,
                    [path, skipIds]() {
                        return scanPluginDirectory(path, skipIds);
                    },
                    [this](const PluginScanResult& result) {
                        finishScan(result);
                    });
}

void PluginManager::finishScan(const PluginScanResult& result)
{
    m_scanRunning = false;

    for(const PreparedPlugin& prepared : result.plugins) {
        m_loadQueue.append(prepared);
    }

    QStringList staleDirs;
    for(const auto& stale : result.staleDirs) {
        if(isBusy(stale.second)) {
            continue;
        }

        const QString clean = QDir::cleanPath(stale.first);
        const bool inUse = std::any_of(m_infos.cbegin(), m_infos.cend(),
                                       [&clean](const PluginInfo& info) {
                                           return QDir::cleanPath(info.pluginDir) == clean;
                                       });
        if(!inUse) {
            staleDirs << stale.first;
        }
    }

    if(!staleDirs.isEmpty()) {
        // Nothing is loaded from older versions, so they can go without waiting.
        runInBackground(this,
                        [staleDirs]() {
                            for(const QString& staleDir : staleDirs) {
                                QDir(staleDir).removeRecursively();
                            }
                            return true;
                        },
                        [](bool) {
                        });
    }

    pumpLoadQueue();
    startNextScan();
}

void PluginManager::pumpLoadQueue()
{
    if(m_loadPumpActive || m_loadQueue.isEmpty()) {
        return;
    }

    m_loadPumpActive = true;
    QTimer::singleShot(0, this, [this]() {
        m_loadPumpActive = false;
        if(m_loadQueue.isEmpty()) {
            return;
        }

        const PreparedPlugin next = m_loadQueue.takeFirst();
        const bool known = isBusy(next.info.id)
                           || std::any_of(m_infos.cbegin(), m_infos.cend(),
                                          [&next](const PluginInfo& info) {
                                              return info.id == next.info.id;
                                          });
        if(!known) {
            loadPlugin(next);
        }

        pumpLoadQueue();
    });
}

void PluginManager::runWhenScanIdle(std::function<void()> action)
{
    if(!m_scanRunning) {
        action();
        return;
    }

    QTimer::singleShot(kScanIdleRetryMs, this, [this, action]() {
        runWhenScanIdle(action);
    });
}

// ── Loading ──────────────────────────────────────────────────────────────────

bool PluginManager::loadPlugin(const QString& pluginDir)
{
    PreparedPlugin prepared;
    prepared.info = parseManifest(pluginDir);
    return loadPlugin(prepared);
}

bool PluginManager::loadPlugin(const PreparedPlugin& prepared)
{
    PluginInfo info = prepared.info;
    if(!info.isValid()) {
        emit pluginError(info.pluginDir, QStringLiteral("Invalid or missing plugin.json"));
        return false;
    }

    const bool ok = info.enabled ? activatePlugin(info, prepared.libraryPath) : false;
    m_infos.append(info);
    emit pluginsChanged();
    return ok;
}

QString PluginManager::hotLoadLibraryPath(const QString& pluginDir, const QString& entry) const
{
    return prepareHotLibrary(pluginDir, entry);
}

QString PluginManager::uniquePluginDir(const QString& pluginRoot, const QString& id,
                                       const QString& version) const
{
    const QString ver = version.isEmpty() ? QStringLiteral("0") : version;
    return pluginRoot + QLatin1Char('/') + id + QLatin1Char('-') + ver
           + QLatin1Char('-') + QString::number(QDateTime::currentMSecsSinceEpoch());
}

bool PluginManager::loadCppPlugin(const PluginInfo& info, const QString& preparedLibrary)
{
    const QString libPath = preparedLibrary.isEmpty()
                                ? hotLoadLibraryPath(info.pluginDir, info.cppEntry)
                                : preparedLibrary;
    if(!QFileInfo::exists(libPath)) {
        emit pluginError(info.id,
                         QStringLiteral("Library not found: ") + libPath);
        return false;
    }

    auto* loader = new QPluginLoader(libPath, this);
    loader->setLoadHints(QLibrary::ExportExternalSymbolsHint);
    QObject* obj = loader->instance();
    if(!obj) {
        emit pluginError(info.id, loader->errorString());
        delete loader;
        return false;
    }

    auto* plugin = qobject_cast<IPlugin*>(obj);
    if(!plugin) {
        emit pluginError(info.id,
                         QStringLiteral("Object does not implement IPlugin"));
        loader->unload();
        delete loader;
        return false;
    }

    plugin->initialize(m_context);

    if(auto* repoAware = dynamic_cast<IRepositoryAwarePlugin*>(plugin)) {
        if(Repository* repo = m_context->currentRepository()) {
            if(const char* workdir = git_repository_workdir(repo->repo)) {
                repoAware->repositoryChanged(QString::fromUtf8(workdir));
            }
        }
    }

    m_loaders[info.id] = loader;
    m_plugins[info.id] = plugin;
    return true;
}

PluginInfo PluginManager::parseManifest(const QString& pluginDir) const
{
    return readManifestFile(pluginDir);
}

// ── State forwarding ─────────────────────────────────────────────────────────

void PluginManager::setCurrentRepository(Repository* repo)
{
    m_context->setCurrentRepository(repo);

    if (!repo)
        return;

    const char* workdir = git_repository_workdir(repo->repo);
    if (!workdir)
        return;

    const QString dir = QString::fromUtf8(workdir);
    for (IPlugin* plugin : std::as_const(m_plugins)) {
        if (auto* repoAware = dynamic_cast<IRepositoryAwarePlugin*>(plugin))
            repoAware->repositoryChanged(dir);
    }
}

void PluginManager::setCurrentBranch(const QString& branch)
{
    m_context->setCurrentBranch(branch);
}

// ── Management ───────────────────────────────────────────────────────────────

bool PluginManager::activatePlugin(PluginInfo& info, const QString& preparedLibrary)
{
    bool ok = true;

    if (info.hasCppEntry())
        ok = loadCppPlugin(info, preparedLibrary);

    if (info.hasQmlEntry()) {
        if (auto* engine = m_context->qmlEngine())
            engine->addImportPath(info.pluginDir);
    }

    // QML-only: register dock directly from the manifest
    if (!info.hasCppEntry() && info.hasQmlEntry()) {
        info.loaded = true;
        if (info.capabilities.contains(QStringLiteral("dock"))) {
            emit dockRegistered(info.id,
                                QUrl::fromLocalFile(
                                    QDir(info.pluginDir).filePath(info.qmlEntry)),
                                info.name,
                                {});
        }
        emit pluginLoaded(info.id);
        return true;
    }

    if (ok) {
        info.loaded = true;
        emit pluginLoaded(info.id);
    } else {
        info.loaded = false;
        info.errorMessage = QStringLiteral("Failed to load C++ library");
    }

    return ok;
}

void PluginManager::deactivatePlugin(const QString& id, std::function<void()> done)
{
    IPlugin* plugin = m_plugins.value(id, nullptr);

    // Drop extension mappings while the plugin object is still alive. qrc:// URLs
    // cannot be matched by pluginDir, so go through IDiffPlugin when we have one.
    if (auto* diff = dynamic_cast<IDiffPlugin*>(plugin)) {
        for (const QString& ext : diff->handledExtensions()) {
            m_diffPlugins.remove(ext.toLower());
            m_colorizers.remove(ext.toLower());
        }
    }

    for (int i = m_docks.size() - 1; i >= 0; --i) {
        if (m_docks.at(i).toMap().value(QStringLiteral("id")).toString() == id)
            m_docks.removeAt(i);
    }

    for (int i = m_pages.size() - 1; i >= 0; --i) {
        const auto map = m_pages.at(i).toMap();
        if (map.value(QStringLiteral("pluginId")).toString() == id
            || map.value(QStringLiteral("id")).toString() == id)
            m_pages.removeAt(i);
    }

    for (int i = m_toolbarActions.size() - 1; i >= 0; --i) {
        if (m_toolbarActions.at(i).toMap().value(QStringLiteral("pluginId")).toString() == id)
            m_toolbarActions.removeAt(i);
    }

    const auto eraseByPluginId = [&id](auto& list) {
        for (auto it = list.begin(); it != list.end(); )
            it = ((*it)->id() == id) ? list.erase(it) : ++it;
    };
    eraseByPluginId(m_contextMenuPlugins);
    eraseByPluginId(m_workflowPlugins);
    eraseByPluginId(m_toolbarPlugins);

    for (auto it = m_rulePlugins.begin(); it != m_rulePlugins.end(); ) {
        auto* ruleOwner = dynamic_cast<IPlugin*>(*it);
        it = (ruleOwner && ruleOwner->id() == id) ? m_rulePlugins.erase(it) : ++it;
    }

    emit docksChanged();
    emit pagesChanged();
    emit toolbarActionsChanged();
    emit contextMenusChanged();
    emit pluginAboutToUnload(id);

    // The plugin object and its library leave the maps right away, so the plugin can be loaded
    // again at once. Shutting it down and unloading the library happens a moment later, from the
    // event loop, instead of blocking the UI while the page of the plugin is torn down.
    auto job = std::make_shared<ReleaseJob>();
    job->id     = id;
    job->plugin = m_plugins.take(id);
    job->loader = m_loaders.take(id);
    job->done   = std::move(done);
    m_releaseJobs.append(job);

    QTimer::singleShot(kUiSettleMs, this, [this, job]() {
        releaseLibrary(job);
    });
}

void PluginManager::releaseLibrary(const std::shared_ptr<ReleaseJob>& job)
{
    // Let QML finish destroying the objects of the plugin before its code goes away.
    QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);

    if(!job->shutDown) {
        job->shutDown = true;
        if(job->plugin) {
            job->plugin->shutdown();
        }
    }

    const bool released = !job->loader || !job->loader->isLoaded() || job->loader->unload();
    if(!released && ++job->attempts < kMaxUnloadAttempts) {
        QTimer::singleShot(kUnloadRetryMs, this, [this, job]() {
            releaseLibrary(job);
        });
        return;
    }

    // The copy the plugin was loaded from is of no use once the library is released.
    const QString loadedPath = (released && job->loader) ? job->loader->fileName() : QString();

    delete job->loader;
    job->loader = nullptr;
    job->plugin = nullptr;
    m_releaseJobs.removeOne(job);

    if(!loadedPath.isEmpty() && isHotCopy(loadedPath)) {
        runInBackground(this,
                        [loadedPath]() {
                            // The system may keep the file mapped for a moment after unloading
                            for(int attempt = 0; attempt < 10; ++attempt) {
                                if(QFile::remove(loadedPath) || !QFile::exists(loadedPath)) {
                                    break;
                                }
                                QThread::msleep(100);
                            }
                            return true;
                        },
                        [](bool) {
                        });
    }

    if(job->done) {
        const auto done = std::move(job->done);
        job->done = nullptr;
        done();
    }
}

void PluginManager::tearDownPlugin(const QString& id, std::function<void()> done)
{
    m_loadQueue.removeIf([&id](const PreparedPlugin& prepared) {
        return prepared.info.id == id;
    });

    deactivatePlugin(id, std::move(done));
    m_infos.removeIf([&](const PluginInfo& info) { return info.id == id; });
}

bool PluginManager::enablePlugin(const QString& id, bool enabled)
{
    for (auto& info : m_infos) {
        if (info.id != id)
            continue;

        info.enabled = enabled;

        const QString manifestPath = QDir(info.pluginDir).filePath(QStringLiteral("plugin.json"));
        QFile mf(manifestPath);

        if (mf.open(QIODevice::ReadOnly)) {
            auto doc = QJsonDocument::fromJson(mf.readAll());
            mf.close();

            if (doc.isObject()) {
                QJsonObject obj = doc.object();
                obj[QStringLiteral("enabled")] = enabled;

                if (mf.open(QIODevice::WriteOnly | QIODevice::Truncate))
                    mf.write(QJsonDocument(obj).toJson());
            }
        }

        if (enabled) {
            activatePlugin(info);
        } else {
            deactivatePlugin(id);
            info.loaded = false;
        }
        emit pluginsChanged();
        return true;
    }
    return false;
}

void PluginManager::unloadPlugin(const QString& id)
{
    enablePlugin(id, false);
}

// ── Queries ──────────────────────────────────────────────────────────────────

QVariant PluginManager::pluginSetting(const QString& pluginId, const QString& key,
                                      const QVariant& defaultValue) const
{
    return m_context->setting(pluginId, key, defaultValue);
}

void PluginManager::setPluginSetting(const QString& pluginId, const QString& key,
                                     const QVariant& value)
{
    m_context->setSetting(pluginId, key, value);
}

void PluginManager::runBeforeAction(ActionContext* context)
{
    if (!context)
        return;

    // Successful checks may still hand data back to the host (e.g. post-merge branch cleanup).
    QVariantMap data;
    for (IRulePlugin* rule : std::as_const(m_rulePlugins)) {
        GitResult result = rule->check(context);
        if (!result.success()) {
            context->result = result;
            return;
        }
        data.insert(result.data().toMap());
    }
    context->result = GitResult(true, data);
}

QVariantList PluginManager::pluginInfos() const
{
    QVariantList result;
    result.reserve(m_infos.size());
    for (const auto& info : m_infos)
        result << info.toVariantMap();
    return result;
}

QVariantList PluginManager::downloadedPackages() const
{
    return m_downloadedPackages;
}

QVariantList PluginManager::registeredDocks() const
{
    return m_docks;
}

QUrl PluginManager::diffPluginUrlFor(const QString& extension) const
{
    return m_diffPlugins.value(extension.toLower());
}

QUrl PluginManager::colorizerUrlFor(const QString& extension) const
{
    return m_colorizers.value(extension.toLower());
}

bool PluginManager::installPluginFromBase64Zip(const QString& pluginId, const QString& base64Data,
                                               const QString& expectedMd5)
{
    const QByteArray archiveData = QByteArray::fromBase64(base64Data.toLatin1());
    if (archiveData.isEmpty()) {
        emit pluginInstallFailed(pluginId, QStringLiteral("Empty download data"));
        return false;
    }

    // Verify MD5 checksum when the server provided one
    if (!expectedMd5.isEmpty()) {
        const QString actualMd5 = QCryptographicHash::hash(archiveData, QCryptographicHash::Md5).toHex();
        if (actualMd5 != expectedMd5.trimmed().toLower()) {
            emit pluginInstallFailed(pluginId,
                QStringLiteral("Checksum mismatch — file may be corrupted or tampered "
                               "(expected: %1, got: %2)").arg(expectedMd5, actualMd5));
            return false;
        }
    }

    const QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    const QString pluginRoot = base + QStringLiteral("/plugins");
    QDir().mkpath(pluginRoot);

    tearDownPlugin(pluginId);

    const QString targetDir = uniquePluginDir(pluginRoot, pluginId, QStringLiteral("0"));

    // Write archive bytes to a temp file so libarchive can use open_filename
    const QString tempPath = QDir::tempPath()
                             + QStringLiteral("/gitease_plugin_%1.zip").arg(pluginId);
    {
        QFile tempFile(tempPath);
        if (!tempFile.open(QIODevice::WriteOnly)) {
            emit pluginInstallFailed(pluginId, QStringLiteral("Cannot create temp file"));
            return false;
        }
        tempFile.write(archiveData);
    }

    // Extract the archive via the shared, safety-checked extractor (it rejects
    // traversal paths and handles per-entry data the same way GEP does).
    if (!extractPackage(tempPath, targetDir)) {
        QFile::remove(tempPath);
        emit pluginInstallFailed(pluginId, QStringLiteral("Failed to extract plugin archive"));
        return false;
    }
    QFile::remove(tempPath);

    // Some archives wrap files in a top-level subdirectory — find where plugin.json actually lives
    QString actualPluginDir = targetDir;
    if (!QFile::exists(targetDir + QStringLiteral("/plugin.json"))) {
        QDirIterator it(targetDir, {QStringLiteral("plugin.json")},
                        QDir::Files, QDirIterator::Subdirectories);
        if (it.hasNext()) {
            it.next();
            actualPluginDir = QFileInfo(it.filePath()).absolutePath();
        }
    }

    const bool ok = loadPlugin(actualPluginDir);
    if (ok)
        emit pluginInstalled(pluginId);
    else
        emit pluginInstallFailed(pluginId, QStringLiteral("Plugin extracted but failed to load"));
    return ok;
}

bool PluginManager::installGepFile(const QString& gepPath)
{
    if(gepPath.isEmpty() || !QFileInfo::exists(gepPath)) {
        return false;
    }

    startGepInstall(gepPath, QString(), QString(), true);
    return true;
}

void PluginManager::scanDownloads()
{
    if(m_downloadScanRunning) {
        m_downloadScanQueued = true;
        return;
    }

    m_downloadScanRunning = true;
    runInBackground(this,
                    []() {
                        return scanDownloadedPackages(downloadsDirectory());
                    },
                    [this](const QVariantList& packages) {
                        m_downloadScanRunning = false;
                        if(packages != m_downloadedPackages) {
                            m_downloadedPackages = packages;
                            emit downloadedPackagesChanged();
                        }

                        if(m_downloadScanQueued) {
                            m_downloadScanQueued = false;
                            scanDownloads();
                        }
                    });
}

bool PluginManager::installDownloadedPackage(const QString& pluginId, const QString& packagePath)
{
    // Only packages that sit in the downloads folder may be installed through this call.
    const QString canonicalDir = QFileInfo(downloadsDirectory()).canonicalFilePath();
    const QString canonicalPackage = QFileInfo(packagePath).canonicalFilePath();
    if(canonicalDir.isEmpty() || canonicalPackage.isEmpty()
       || !canonicalPackage.startsWith(canonicalDir + QLatin1Char('/'))) {
        return false;
    }

    startGepInstall(canonicalPackage, QString(), pluginId, false);
    return true;
}

bool PluginManager::installGepFromBase64(const QString& base64Data, const QString& pluginId)
{
    if(base64Data.isEmpty()) {
        return false;
    }

    const QString tempPath = QDir::tempPath()
                             + QStringLiteral("/gitease_plugin_%1.gep")
                                   .arg(QDateTime::currentMSecsSinceEpoch());

    // Decoding and writing a package takes a while; do it away from the UI thread.
    runInBackground(this,
                    [base64Data, tempPath]() {
                        const QByteArray archiveData = QByteArray::fromBase64(base64Data.toLatin1());
                        if(archiveData.isEmpty()) {
                            return false;
                        }

                        QFile tempFile(tempPath);
                        if(!tempFile.open(QIODevice::WriteOnly)) {
                            return false;
                        }

                        const bool written = tempFile.write(archiveData) == archiveData.size();
                        tempFile.close();
                        return written;
                    },
                    [this, tempPath, pluginId](bool written) {
                        if(!written) {
                            QFile::remove(tempPath);
                            emit pluginInstallFailed(pluginId.isEmpty() ? QStringLiteral("unknown") : pluginId,
                                                     QStringLiteral("Could not read the downloaded package"));
                            return;
                        }

                        // The temp file is removed once the install is over.
                        startGepInstall(tempPath, tempPath, pluginId, false);
                    });
    return true;
}

// An install runs as a chain of steps: the package is inspected on a worker thread, the old
// version is deactivated on the UI thread without blocking, the files are placed on a worker
// thread, and the new plugin is loaded on the UI thread. The UI thread never waits for the disk.
void PluginManager::startGepInstall(const QString& gepPath, const QString& tempToRemove,
                                    const QString& pluginId, bool announce)
{
    const QString appData = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);

    GepRequest request;
    request.gepPath      = gepPath;
    request.tempToRemove = tempToRemove;
    request.pluginId     = pluginId;
    request.pluginRoot   = appData + QStringLiteral("/plugins");
    request.downloadsDir = appData + QStringLiteral("/downloads/plugins");

    if(announce) {
        request.pendingId = QStringLiteral("pending:") + QString::number(++m_pendingCounter);
        emit pluginInstallQueued(request.pendingId, QFileInfo(gepPath).completeBaseName());
    }

    runInBackground(this,
                    [request]() {
                        return inspectGepPackage(request);
                    },
                    [this, request](const GepInspection& inspection) {
                        continueGepInstall(request, inspection);
                    });
}

void PluginManager::continueGepInstall(const GepRequest& request, const GepInspection& inspection)
{
    const PluginInfo& manifest = inspection.manifest;

    const auto abort = [this, &request, &inspection](const QString& message) {
        if(!request.tempToRemove.isEmpty()) {
            QFile::remove(request.tempToRemove);
        }

        if(!inspection.staging.isEmpty()) {
            const QString staging = inspection.staging;
            runInBackground(this,
                            [staging]() {
                                QDir(staging).removeRecursively();
                                return true;
                            },
                            [](bool) {
                            });
        }

        QString failedId = request.pendingId;
        if(failedId.isEmpty()) {
            failedId = request.pluginId.isEmpty() ? QStringLiteral("unknown") : request.pluginId;
        }

        emit pluginInstallFailed(failedId, message);
    };

    if(!manifest.isValid() || manifest.id.isEmpty()) {
        abort(QStringLiteral("Not a valid GEP package (missing plugin.json)"));
        return;
    }

    // Plugin folders are never touched while a scan is looking through them.
    if(m_scanRunning) {
        QTimer::singleShot(kScanIdleRetryMs, this, [this, request, inspection]() {
            continueGepInstall(request, inspection);
        });
        return;
    }

    const QString id   = manifest.id;
    const QString name = manifest.name;

    if(isBusy(id)) {
        abort(QStringLiteral("This plugin is already being installed or removed."));
        return;
    }

    if(!request.pendingId.isEmpty()) {
        emit pluginInstallResolved(request.pendingId, id, name);
    }

    emit pluginInstallStarted(id, name);
    m_installingIds.insert(id);

    const QString targetDir     = uniquePluginDir(request.pluginRoot, id, manifest.version);
    const QString payloadSource = inspection.payloadSource;

    tearDownPlugin(id, [this, request, manifest, payloadSource, targetDir]() {
        runInBackground(this,
                        [request, payloadSource, targetDir, manifest]() {
                            return placeAndPrepare(request, payloadSource, targetDir, manifest);
                        },
                        [this, request](const GepPlacement& placement) {
                            finishGepInstall(request, placement);
                        });
    });
}

void PluginManager::finishGepInstall(const GepRequest& request, const GepPlacement& placement)
{
    Q_UNUSED(request)
    m_installingIds.remove(placement.id);

    scanDownloads();

    switch(placement.result) {
    case GepPlaceResult::Ok: {
        const bool ok = placement.prepared.info.isValid() && loadPlugin(placement.prepared);
        if(ok) {
            emit pluginInstalled(placement.id);
        } else {
            emit pluginInstallFailed(placement.id, QStringLiteral("Plugin extracted but failed to load"));
        }
        break;
    }
    case GepPlaceResult::PlaceFailed:
        // The previous version was already torn down, so let the list catch up before reporting.
        emit pluginsChanged();
        emit pluginInstallFailed(placement.id, QStringLiteral("Failed to place plugin directory"));
        break;
    case GepPlaceResult::ExtractFailed:
        emit pluginsChanged();
        emit pluginInstallFailed(placement.id, QStringLiteral("Failed to extract GEP package"));
        break;
    }

    startNextScan();
}

// An uninstall deactivates the plugin right away, but the library is released and the files are
// deleted in the background. The caller is told when it is over through pluginRemoved() or
// pluginRemoveFailed().
bool PluginManager::removePlugin(const QString& id)
{
    if(id.isEmpty()) {
        return false;
    }

    if(m_removingIds.contains(id)) {
        return true;
    }

    bool known = m_plugins.contains(id) || m_loaders.contains(id);
    QStringList knownDirs;
    for(const PluginInfo& info : std::as_const(m_infos)) {
        if(info.id != id) {
            continue;
        }

        known = true;
        if(!info.pluginDir.isEmpty()) {
            knownDirs << info.pluginDir;
        }
    }

    const QStringList roots {
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + QStringLiteral("/plugins"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/plugins")
    };

    m_removingIds.insert(id);

    // Give the card a moment to show that the plugin is being removed before the work starts.
    QTimer::singleShot(kUiSettleMs, this, [this, id, known, knownDirs, roots]() {
        runWhenScanIdle([this, id, known, knownDirs, roots]() {
            tearDownPlugin(id, [this, id, known, knownDirs, roots]() {
                runInBackground(this,
                                [id, known, knownDirs, roots]() {
                                    return removePluginDirectories(id, known, knownDirs, roots);
                                },
                                [this, id](const PluginRemovalResult& result) {
                                    finishRemoval(id, result);
                                });
            });
        });
    });

    return true;
}

void PluginManager::finishRemoval(const QString& id, const PluginRemovalResult& result)
{
    m_removingIds.remove(id);

    if(result.foundAny) {
        emit pluginsChanged();
        emit pluginRemoved(id);
    } else {
        emit pluginRemoveFailed(id, QStringLiteral("Plugin not found."));
    }

    startNextScan();
}

// ── Queries ──────────────────────────────────────────────────────────────────

QVariantList PluginManager::registeredPages() const
{
    return m_pages;
}

QVariantList PluginManager::registeredToolbarActions() const
{
    return m_toolbarActions;
}

// ── Event bus ────────────────────────────────────────────────────────────────

void PluginManager::publishEvent(const QString& event, const QVariantMap& payload)
{
    m_context->publish(event, payload);
}

int PluginManager::subscribeEvent(const QString& event, const QJSValue& handler)
{
    if (!handler.isCallable()) return -1;
    auto* engine = qmlEngine(this);  // QQmlEngine inherits QJSEngine — valid for toScriptValue
    if (!engine) return -1;
    auto jsHandler = std::make_shared<QJSValue>(handler);
    return m_context->subscribe(event, [jsHandler, engine](const QVariantMap& payload) {
        if (!jsHandler->isCallable()) return;
        QJSValueList args;
        args << engine->toScriptValue(payload);
        jsHandler->call(args);
    });
}

void PluginManager::unsubscribeEvent(int token)
{
    m_context->unsubscribe(token);
}

// ── Context menu ─────────────────────────────────────────────────────────────

QVariantList PluginManager::pluginContextMenuItems(const QString& target,
                                                    const QVariantMap& ctx) const
{
    const IContextMenuPlugin::MenuTarget t = menuTargetFor(target);

    QVariantList result;
    for (auto* plugin : m_contextMenuPlugins) {
        if (!plugin->targets().contains(t)) continue;
        for (const auto& item : plugin->menuItems(t, ctx)) {
            result.append(QVariantMap {
                { QStringLiteral("pluginId"),  plugin->id()   },
                { QStringLiteral("id"),        item.id        },
                { QStringLiteral("label"),     item.label     },
                { QStringLiteral("icon"),      item.icon      },
                { QStringLiteral("separator"), item.separator },
                { QStringLiteral("order"),     item.order     },
            });
        }
    }

    // Sort by order
    std::sort(result.begin(), result.end(), [](const QVariant& a, const QVariant& b) {
        return a.toMap().value(QStringLiteral("order")).toInt()
             < b.toMap().value(QStringLiteral("order")).toInt();
    });

    return result;
}

void PluginManager::executeContextMenuAction(const QString& pluginId,
                                              const QString& itemId,
                                              const QString& target,
                                              const QVariantMap& ctx)
{
    const IContextMenuPlugin::MenuTarget t = menuTargetFor(target);

    for (auto* plugin : m_contextMenuPlugins) {
        if (plugin->id() == pluginId) {
            plugin->executeAction(itemId, t, ctx);
            return;
        }
    }
}

// ── Workflow hooks ────────────────────────────────────────────────────────────

bool PluginManager::hasWorkflowPluginsFor(const QString& event) const
{
    for (const auto* plugin : m_workflowPlugins)
        if (plugin->handledEvents().contains(event))
            return true;
    return false;
}

void PluginManager::notifyWorkflowEvent(const QString& event, const QVariantMap& ctx)
{
    if (m_workflowPlugins.isEmpty()) {
        emit workflowEventResolved(event, ctx, true);
        return;
    }

    const bool isPre = event.startsWith(QStringLiteral("pre-"));

    if (!isPre) {
        // Post-events: notify all plugins, always resolve as allowed
        for (auto* plugin : m_workflowPlugins) {
            if (plugin->handledEvents().contains(event))
                plugin->onEvent(event, ctx, [](bool) {});
        }
        emit workflowEventResolved(event, ctx, true);
        return;
    }

    // Pre-events: chain through plugins; first resolve(false) blocks the operation
    runWorkflowChain(event, ctx, 0, [this, event, ctx](bool allowed) {
        emit workflowEventResolved(event, ctx, allowed);
    });
}

void PluginManager::runWorkflowChain(const QString& event,
                                      const QVariantMap& ctx,
                                      int index,
                                      std::function<void(bool)> finalCallback)
{
    // Find the next plugin that handles this event, starting from index
    while (index < m_workflowPlugins.size()) {
        auto* plugin = m_workflowPlugins[index];
        if (plugin->handledEvents().contains(event)) {
            plugin->onEvent(event, ctx, [this, event, ctx, index, finalCallback](bool allowed) {
                if (!allowed) {
                    finalCallback(false);
                } else {
                    runWorkflowChain(event, ctx, index + 1, finalCallback);
                }
            });
            return;
        }
        ++index;
    }
    // All matching plugins allowed
    finalCallback(true);
}

// ── Toolbar ───────────────────────────────────────────────────────────────────

void PluginManager::executeToolbarAction(const QString& pluginId,
                                          const QString& actionId,
                                          const QVariantMap& ctx)
{
    for (auto* plugin : m_toolbarPlugins) {
        if (plugin->id() == pluginId) {
            plugin->onToolbarAction(actionId, ctx);
            return;
        }
    }
}

template<typename T>
static QList<T*> filterPlugins(const QMap<QString, IPlugin*>& plugins)
{
    QList<T*> result;
    for (auto* p : plugins)
        if (auto* t = dynamic_cast<T*>(p))
            result << t;
    return result;
}

QList<IDockPlugin*>        PluginManager::dockPlugins()        const { return filterPlugins<IDockPlugin>       (m_plugins); }
QList<ICommandPlugin*>     PluginManager::commandPlugins()     const { return filterPlugins<ICommandPlugin>    (m_plugins); }
QList<IAuthPlugin*>        PluginManager::authPlugins()        const { return filterPlugins<IAuthPlugin>       (m_plugins); }
QList<IDiffPlugin*>        PluginManager::diffPlugins()        const { return filterPlugins<IDiffPlugin>       (m_plugins); }
QList<IServicePlugin*>     PluginManager::servicePlugins()     const { return filterPlugins<IServicePlugin>    (m_plugins); }
QList<IContextMenuPlugin*> PluginManager::contextMenuPlugins() const { return m_contextMenuPlugins; }
QList<IWorkflowPlugin*>    PluginManager::workflowPlugins()    const { return m_workflowPlugins;    }
QList<IToolbarPlugin*>     PluginManager::toolbarPlugins()     const { return m_toolbarPlugins;     }
