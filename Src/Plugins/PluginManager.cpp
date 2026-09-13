#include "PluginManager.h"
#include "IRepositoryAwarePlugin.h"
#include "PluginContext.h"
#include "../Git/Models/Repository.h"
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
#include <QStringList>
#include <QQmlEngine>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDateTime>
#include <QElapsedTimer>
#include <QThread>
#include <QMetaObject>

#include <thread>

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

    enum class GepWorkResult {
        Ok,
        RestartRequired,
        PlaceFailed,
        ExtractFailed
    };

    bool extractPackage(const QString& gepPath, const QString& targetDir);

    GepWorkResult placeGepPayload(const QString& gepPath, const QString& payloadSource,
                                const QString& targetDir, const QString& pluginId,
                                bool hasBinary)
    {
        if (!removeDirectoryPatiently(targetDir, 4000)) {
            if (!payloadSource.isEmpty())
                QDir(payloadSource).removeRecursively();
            return GepWorkResult::RestartRequired;
        }

        if (payloadSource.isEmpty()) {
            // Nothing staged yet: write each file once, in place.
            if (!extractPackage(gepPath, targetDir))
                return GepWorkResult::ExtractFailed;
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
                return GepWorkResult::PlaceFailed;
        }

        if (hasBinary)
            waitUntilReadable(targetDir, 2500);

        if (!pluginId.isEmpty()) {
            const QDir root(QFileInfo(targetDir).absolutePath());
            const auto entries = root.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
            for (const QString& entry : entries) {
                const QString p = root.absoluteFilePath(entry);
                if (p != targetDir && manifestIdOfDir(p) == pluginId)
                    QDir(p).removeRecursively();
            }
        }
        return GepWorkResult::Ok;
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

} // namespace

// ── Construction / destruction ───────────────────────────────────────────────

PluginManager::PluginManager(QObject* parent)
    : QObject(parent)
    , m_context(new PluginContext(this))
{
    wireContext();

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
                         const QString& title, const QString& icon, int order) {
                m_pages.append(QVariantMap {
                    { QStringLiteral("id"),    id            },
                    { QStringLiteral("url"),   url.toString()},
                    { QStringLiteral("title"), title         },
                    { QStringLiteral("icon"),  icon          },
                    { QStringLiteral("order"), order         },
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

PluginManager::~PluginManager()
{
    for (auto* plugin : std::as_const(m_plugins))
        plugin->shutdown();
    for (auto* loader : std::as_const(m_loaders)) {
        loader->unload();
        delete loader;
    }
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
                                    plugin->pageOrder());
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
    QDir dir(path);
    if (!dir.exists()) return;

    struct Candidate { QString dir; QString id; QString version; };
    QList<Candidate> candidates;

    const auto entries = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString& entry : entries) {
        if (entry.startsWith(QLatin1Char('.')))
            continue; // staging dirs / markers

        const QString dirPath = dir.absoluteFilePath(entry);
        if (QFile::exists(dirPath + QStringLiteral("/.gitease-uninstalled"))) {
            QDir(dirPath).removeRecursively(); // marked for removal on a previous run
            continue;
        }

        const PluginInfo info = parseManifest(dirPath);
        if (!info.isValid() || info.id.isEmpty() || info.version.isEmpty())
            continue;
        candidates.append({ dirPath, info.id, info.version });
    }

    QMap<QString, QString> bestVersion;
    QMap<QString, QString> bestDir;
    for (const auto& c : std::as_const(candidates)) {
        auto it = bestVersion.find(c.id);
        if (it == bestVersion.end() || compareVersions(c.version, it.value()) > 0) {
            bestVersion[c.id] = c.version;
            bestDir[c.id]     = c.dir;
        }
    }

    // Drop older versions of the same plugin id (nothing is loaded yet).
    for (const auto& c : std::as_const(candidates)) {
        if (bestDir.value(c.id) != c.dir)
            QDir(c.dir).removeRecursively();
    }

    for (auto it = bestDir.cbegin(); it != bestDir.cend(); ++it)
        loadPlugin(it.value());
}

// ── Loading ──────────────────────────────────────────────────────────────────

bool PluginManager::loadPlugin(const QString& pluginDir)
{
    PluginInfo info = parseManifest(pluginDir);
    if (!info.isValid()) {
        emit pluginError(pluginDir, QStringLiteral("Invalid or missing plugin.json"));
        return false;
    }

    const bool ok = info.enabled ? activatePlugin(info) : false;
    m_infos.append(info);
    emit pluginsChanged();
    return ok;
}

static QString resolveLibraryPath(const QString& pluginDir, const QString& entry)
{
    // If the entry already has a known extension, use it as-is
    if (entry.endsWith(QStringLiteral(".dll"), Qt::CaseInsensitive) ||
        entry.endsWith(QStringLiteral(".so"),  Qt::CaseInsensitive) ||
        entry.endsWith(QStringLiteral(".dylib"), Qt::CaseInsensitive))
    {
        return QDir(pluginDir).filePath(entry);
    }

    // No extension — append the platform-specific one
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

bool PluginManager::loadCppPlugin(const PluginInfo& info)
{
    const QString libPath = resolveLibraryPath(info.pluginDir, info.cppEntry);
    if (!QFileInfo::exists(libPath)) {
        emit pluginError(info.id,
                         QStringLiteral("Library not found: ") + libPath);
        return false;
    }

    auto* loader  = new QPluginLoader(libPath, this);
    QObject* obj  = loader->instance();
    if (!obj) {
        emit pluginError(info.id, loader->errorString());
        delete loader;
        return false;
    }

    auto* plugin = qobject_cast<IPlugin*>(obj);
    if (!plugin) {
        emit pluginError(info.id,
                         QStringLiteral("Object does not implement IPlugin"));
        loader->unload();
        delete loader;
        return false;
    }

    plugin->initialize(m_context);

    m_loaders[info.id] = loader;
    m_plugins[info.id] = plugin;
    return true;
}

PluginInfo PluginManager::parseManifest(const QString& pluginDir)
{
    QJsonObject obj;
    QFile f(QDir(pluginDir).filePath(QStringLiteral("plugin.json")));
    if (!f.open(QIODevice::ReadOnly)) return {};
    const auto doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isNull() && doc.isObject())
        obj = doc.object();

    return PluginInfo::fromJson(obj, pluginDir);
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

bool PluginManager::activatePlugin(PluginInfo& info)
{
    bool ok = true;

    if (info.hasCppEntry())
        ok = loadCppPlugin(info);

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

void PluginManager::deactivatePlugin(const QString& id)
{
    // C++ runtime
    if (m_plugins.contains(id)) {
        m_plugins[id]->shutdown();
        m_loaders[id]->unload();
        delete m_loaders.take(id);
        m_plugins.remove(id);
    }

    // Dock registrations
    for (int i = m_docks.size() - 1; i >= 0; --i) {
        if (m_docks.at(i).toMap().value(QStringLiteral("id")).toString() == id)
            m_docks.removeAt(i);
    }
    emit docksChanged();

    // Toolbar action registrations (same story as docks).
    for (int i = m_toolbarActions.size() - 1; i >= 0; --i) {
        if (m_toolbarActions.at(i).toMap().value(QStringLiteral("pluginId")).toString() == id)
            m_toolbarActions.removeAt(i);
    }
    emit toolbarActionsChanged();

    // Diff viewer / colorizer extension mappings — matched by plugin dir
    const QString pluginDir = [&]() -> QString {
        for (const auto& info : std::as_const(m_infos))
            if (info.id == id) return info.pluginDir;
        return {};
    }();

    if (!pluginDir.isEmpty()) {
        for (auto it = m_diffPlugins.begin(); it != m_diffPlugins.end(); )
            it = it.value().toLocalFile().startsWith(pluginDir) ? m_diffPlugins.erase(it) : ++it;
        for (auto it = m_colorizers.begin(); it != m_colorizers.end(); )
            it = it.value().toLocalFile().startsWith(pluginDir) ? m_colorizers.erase(it) : ++it;
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
    emit contextMenusChanged();
}

void PluginManager::tearDownPlugin(const QString& id)
{
    deactivatePlugin(id);
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
    for (IRulePlugin* rule : std::as_const(m_rulePlugins)) {
        GitResult result = rule->check(context);
        if (!result.success()) {
            context->result = result;
            return;
        }
    }
    context->result = GitResult(true);
}

QVariantList PluginManager::pluginInfos() const
{
    QVariantList result;
    result.reserve(m_infos.size());
    for (const auto& info : m_infos)
        result << info.toVariantMap();
    return result;
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
    const QString targetDir = base + QStringLiteral("/plugins/") + pluginId;

    if (!QDir().mkpath(targetDir)) {
        emit pluginInstallFailed(pluginId, QStringLiteral("Cannot create plugin directory"));
        return false;
    }

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

    // Tear down any existing version — cleans all member variables, no intermediate signal.
    tearDownPlugin(pluginId);

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
    if (gepPath.isEmpty() || !QFileInfo::exists(gepPath))
        return false;
    startGepInstall(gepPath, QString());
    return true;
}

bool PluginManager::installGepFromBase64(const QString& base64Data)
{
    const QByteArray archiveData = QByteArray::fromBase64(base64Data.toLatin1());
    if (archiveData.isEmpty())
        return false;

    const QString tempPath = QDir::tempPath()
                             + QStringLiteral("/gitease_plugin_%1.gep")
                                   .arg(QDateTime::currentMSecsSinceEpoch());
    {
        QFile tempFile(tempPath);
        if (!tempFile.open(QIODevice::WriteOnly)) {
            qWarning() << "[GEP] Cannot create temp file:" << tempPath;
            return false;
        }
        tempFile.write(archiveData);
    }

    // Temp file is handed off and removed once the async install finishes.
    startGepInstall(tempPath, tempPath);
    return true;
}

void PluginManager::startGepInstall(const QString& gepPath, const QString& tempToRemove)
{
    const QString appData    = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    const QString pluginRoot = appData + QStringLiteral("/plugins");
    QDir().mkpath(pluginRoot);

    PluginInfo manifest = readGepManifest(gepPath);
    QString payloadSource;
    QString staging;
    if (!manifest.isValid() || manifest.id.isEmpty()) {
        staging = pluginRoot + QStringLiteral("/.stage_")
                  + QString::number(QDateTime::currentMSecsSinceEpoch());
        if (extractPackage(gepPath, staging)) {
            QString actualStagingDir = staging;
            if (!QFile::exists(staging + QStringLiteral("/plugin.json"))) {
                QDirIterator it(staging, {QStringLiteral("plugin.json")},
                                QDir::Files, QDirIterator::Subdirectories);
                if (it.hasNext()) {
                    it.next();
                    actualStagingDir = QFileInfo(it.filePath()).absolutePath();
                }
            }
            manifest = parseManifest(actualStagingDir);
            if (manifest.isValid() && !manifest.id.isEmpty())
                payloadSource = staging; // already extracted — reuse it
        }
    }

    const auto abort = [this, tempToRemove](const QString& id, const QString& msg) {
        if (!tempToRemove.isEmpty())
            QFile::remove(tempToRemove);
        emit pluginInstallFailed(id, msg);
    };

    if (!manifest.isValid() || manifest.id.isEmpty()) {
        if (!staging.isEmpty() && staging != payloadSource)
            QDir(staging).removeRecursively();
        abort(QStringLiteral("unknown"),
              QStringLiteral("Not a valid GEP package (missing plugin.json)"));
        return;
    }

    const QString id      = manifest.id;
    const QString name    = manifest.name;
    const QString version = manifest.version;

    emit pluginInstallStarted(id, name);

    tearDownPlugin(id);

    const QString targetDir = pluginRoot + QLatin1Char('/') + id + QLatin1Char('-') + version;
    const bool hasBinary = !manifest.cppEntry.isEmpty();

    std::thread([gepPath, payloadSource, targetDir, id, hasBinary, name, tempToRemove, this]() {
        const GepWorkResult result = placeGepPayload(gepPath, payloadSource, targetDir, id, hasBinary);
        QMetaObject::invokeMethod(this, [this, result, id, name, targetDir, tempToRemove]() {
            if (!tempToRemove.isEmpty())
                QFile::remove(tempToRemove);
            finishGepInstall(static_cast<int>(result), id, name, targetDir);
        }, Qt::QueuedConnection);
    }).detach();

    const QString downloadsDir = appData + QStringLiteral("/downloads/plugins");
    if (QDir().mkpath(downloadsDir)) {
        const QString savedName = slugify(name).isEmpty() ? id : slugify(name);
        const QString savedPath = downloadsDir + QLatin1Char('/')
                                  + savedName + QLatin1Char('-') + version
                                  + QStringLiteral(".gep");
        QFile::remove(savedPath);
        QFile::copy(gepPath, savedPath);
    }
}

void PluginManager::finishGepInstall(int resultCode, const QString& id,
                                     const QString& name, const QString& targetDir)
{
    switch (static_cast<GepWorkResult>(resultCode)) {
    case GepWorkResult::Ok: {
        const bool ok = loadPlugin(targetDir);
        if (ok)
            emit pluginInstalled(id);
        else
            emit pluginInstallFailed(id, QStringLiteral("Plugin extracted but failed to load"));
        break;
    }
    case GepWorkResult::RestartRequired: {
        QDir(targetDir).removeRecursively();
        const QString displayName = name.isEmpty() ? id : name;
        emit notifyRequested(
            QStringLiteral("The plugin \"%1\" is currently loaded in this session. "
                           "Please restart GitEase, then install it again.").arg(displayName),
            QStringLiteral("warning"));
        emit pluginInstallFailed(id, QString()); // resets UI busy state; no toast
        break;
    }
    case GepWorkResult::PlaceFailed:
        QDir(targetDir).removeRecursively();
        emit pluginInstallFailed(id, QStringLiteral("Failed to place plugin directory"));
        break;
    case GepWorkResult::ExtractFailed:
        QDir(targetDir).removeRecursively();
        emit pluginInstallFailed(id, QStringLiteral("Failed to extract GEP package"));
        break;
    }
}

bool PluginManager::removePlugin(const QString& id)
{
    // Locate every version folder of this plugin (plugins/<id>-<version>/,
    // including legacy plugins/<id>/ installs).
    const QString pluginRoot = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
                               + QStringLiteral("/plugins");
    QDir root(pluginRoot);
    QStringList dirs;
    const auto entries = root.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString& entry : entries) {
        if (entry.startsWith(QLatin1Char('.')))
            continue;
        const QString dirPath = root.absoluteFilePath(entry);
        if (parseManifest(dirPath).id == id)
            dirs << dirPath;
    }

    if (dirs.isEmpty())
        return false;

    // Tear down — cleans all member variables, no intermediate signal.
    tearDownPlugin(id);

    bool allRemoved = true;
    for (const QString& dirPath : std::as_const(dirs)) {
        if (!QDir(dirPath).removeRecursively() && QDir(dirPath).exists()) {
            // The DLL may still be memory-mapped by this session. Mark the folder
            // so the next launch deletes it instead of reloading the plugin.
            allRemoved = false;
            QFile marker(dirPath + QStringLiteral("/.gitease-uninstalled"));
            if (marker.open(QIODevice::WriteOnly)) {
                marker.write("1");
                marker.close();
            }
        }
    }

    emit pluginsChanged();
    emit pluginRemoved(id);
    if (!allRemoved) {
        emit notifyRequested(
            QStringLiteral("\"%1\" was removed — its files will be cleaned up on the next launch.")
                .arg(id),
            QStringLiteral("info"));
    }
    return allRemoved;
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
