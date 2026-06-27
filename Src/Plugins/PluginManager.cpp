#include "PluginManager.h"
#include "PluginContext.h"
#include "IPlugin.h"
#include "IDockPlugin.h"
#include "ICommandPlugin.h"
#include "IAuthPlugin.h"
#include "IDiffPlugin.h"
#include "IServicePlugin.h"

#include <archive.h>
#include <archive_entry.h>

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QPluginLoader>
#include <QQmlEngine>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QCryptographicHash>

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

    const auto entries = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString& entry : entries)
        loadPlugin(dir.absoluteFilePath(entry));
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
    QFile f(QDir(pluginDir).filePath(QStringLiteral("plugin.json")));
    if (!f.open(QIODevice::ReadOnly)) return {};
    const auto doc = QJsonDocument::fromJson(f.readAll());
    if (doc.isNull() || !doc.isObject()) return {};
    return PluginInfo::fromJson(doc.object(), pluginDir);
}

// ── State forwarding ─────────────────────────────────────────────────────────

void PluginManager::setCurrentRepository(Repository* repo)
{
    m_context->setCurrentRepository(repo);
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

    // Tear down any existing version — cleans all member variables, no intermediate signal.
    tearDownPlugin(pluginId);

    // ── libarchive in-memory extraction ───────────────────────────────────────
    struct archive *reader = archive_read_new();
    struct archive *writer = archive_write_disk_new();
    struct archive_entry *entry  = nullptr;

    archive_read_support_format_all(reader);
    archive_read_support_filter_all(reader);

    archive_write_disk_set_options(writer,
        ARCHIVE_EXTRACT_TIME |
        ARCHIVE_EXTRACT_PERM |
        ARCHIVE_EXTRACT_SECURE_NODOTDOT);

    int r = archive_read_open_memory(reader,
                                     archiveData.constData(),
                                     static_cast<size_t>(archiveData.size()));
    if (r != ARCHIVE_OK) {
        const QString err = QString::fromUtf8(archive_error_string(reader));
        archive_read_free(reader);
        archive_write_free(writer);
        emit pluginInstallFailed(pluginId, QStringLiteral("Cannot open archive: ") + err);
        return false;
    }

    bool extractOk = true;

    while ((r = archive_read_next_header(reader, &entry)) == ARCHIVE_OK) {
        // Rebase the entry path under the plugin's target directory
        const QString entryName = QString::fromUtf8(archive_entry_pathname(entry));
        const QString absolutePath = targetDir + QChar('/') + entryName;
        archive_entry_set_pathname(entry, absolutePath.toUtf8().constData());

        if (archive_write_header(writer, entry) != ARCHIVE_OK) {
            extractOk = false;
            break;
        }

        const void *buf;
        size_t bufSize;
        la_int64_t offset;
        int dataResult;

        while ((dataResult = archive_read_data_block(reader, &buf, &bufSize, &offset)) == ARCHIVE_OK) {
            if (archive_write_data_block(writer, buf, bufSize, offset) != ARCHIVE_OK) {
                extractOk = false;
                break;
            }
        }

        if (!extractOk)
            break;

        if (dataResult != ARCHIVE_EOF) {
            extractOk = false;
            break;
        }

        archive_write_finish_entry(writer);
    }

    if (r != ARCHIVE_EOF)
        extractOk = false;

    archive_read_free(reader);
    archive_write_free(writer);
    // ── end extraction ────────────────────────────────────────────────────────

    if (!extractOk) {
        emit pluginInstallFailed(pluginId, QStringLiteral("Failed to extract plugin archive"));
        return false;
    }

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

bool PluginManager::removePlugin(const QString& id)
{
    QString pluginDir;
    for (const auto& info : std::as_const(m_infos)) {
        if (info.id == id) {
            pluginDir = info.pluginDir;
            break;
        }
    }

    if (pluginDir.isEmpty())
        return false;

    // Tear down — cleans all member variables, no intermediate signal.
    tearDownPlugin(id);

    const bool ok = QDir(pluginDir).removeRecursively();
    emit pluginsChanged();

    if (ok)
        emit pluginRemoved(id);

    return ok;
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

QList<IDockPlugin*>    PluginManager::dockPlugins()    const { return filterPlugins<IDockPlugin>   (m_plugins); }
QList<ICommandPlugin*> PluginManager::commandPlugins() const { return filterPlugins<ICommandPlugin>(m_plugins); }
QList<IAuthPlugin*>    PluginManager::authPlugins()    const { return filterPlugins<IAuthPlugin>   (m_plugins); }
QList<IDiffPlugin*>    PluginManager::diffPlugins()    const { return filterPlugins<IDiffPlugin>   (m_plugins); }
QList<IServicePlugin*> PluginManager::servicePlugins() const { return filterPlugins<IServicePlugin>(m_plugins); }
