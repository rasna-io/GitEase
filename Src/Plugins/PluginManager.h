#pragma once

#include <QObject>
#include <QVariantList>
#include <QMap>
#include <QSet>
#include <QQmlEngine>
#include <QJSValue>
#include <QPair>
#include <functional>
#include <memory>

#include "GitResult.h"
#include "PluginInfo.h"

class IPlugin;
class IDockPlugin;
class ICommandPlugin;
class IAuthPlugin;
class IDiffPlugin;
class IServicePlugin;
class IPagePlugin;
class IContextMenuPlugin;
class IWorkflowPlugin;
class IToolbarPlugin;
class IRulePlugin;
class PluginContext;
class QPluginLoader;
class QThread;
class Repository;
class ActionContext;

//! A plugin whose manifest is read and whose library copy is ready, so loading it costs little.
struct PreparedPlugin
{
    PluginInfo info;
    QString    libraryPath; // hot copy of the library; empty when nothing has to be loaded
};

//! Result of looking through one plugin directory on a worker thread.
struct PluginScanResult
{
    QList<PreparedPlugin>          plugins;
    QList<QPair<QString, QString>> staleDirs; // { directory, plugin id } of older versions
};

//! What was found out about a .gep package before anything is installed.
struct GepInspection
{
    PluginInfo manifest;
    QString    payloadSource; // staging directory that already holds the extracted package
    QString    staging;       // staging directory that must be deleted when the package is invalid
};

enum class GepPlaceResult
{
    Ok,
    PlaceFailed,
    ExtractFailed
};

struct GepPlacement
{
    GepPlaceResult result = GepPlaceResult::Ok;
    PreparedPlugin prepared;
    QString        id;
    QString        name;
    QString        targetDir;
};

struct GepRequest
{
    QString gepPath;
    QString tempToRemove;  // temporary copy that is deleted once the install is over
    QString pendingId;     // stands in for the plugin until its manifest is known
    QString pluginId;      // id the caller already knows (downloads), used to report failures
    QString pluginRoot;
    QString downloadsDir;
};

struct PluginRemovalResult
{
    bool foundAny = false;
};

/*!
 * \brief Discovers, loads, and manages the lifecycle of external plugins.
 *
 * Exposed to QML as a QML_ELEMENT so PluginController.qml can instantiate it
 * and wire it into the rest of the session.
 */
class PluginManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVariantList pluginInfos          READ pluginInfos          NOTIFY pluginsChanged)
    Q_PROPERTY(QVariantList downloadedPackages   READ downloadedPackages   NOTIFY downloadedPackagesChanged)
    Q_PROPERTY(QVariantList registeredDocks      READ registeredDocks      NOTIFY docksChanged)
    Q_PROPERTY(QVariantList registeredPages      READ registeredPages      NOTIFY pagesChanged)
    Q_PROPERTY(QVariantList registeredToolbarActions READ registeredToolbarActions NOTIFY toolbarActionsChanged)
    Q_PROPERTY(QVariantList registeredConflictAssists READ registeredConflictAssists NOTIFY conflictAssistsChanged)

public:
    explicit PluginManager(QObject* parent = nullptr);
    ~PluginManager() override;

    // ── Setup ────────────────────────────────────────────────────────────────
    Q_INVOKABLE void initialize();
    Q_INVOKABLE void scanDefaultDirectory();
    Q_INVOKABLE void scanApplicationPluginsDirectory();
    Q_INVOKABLE void scanDirectory(const QString& path);

    // ── State forwarding (called by PluginController) ────────────────────────
    Q_INVOKABLE void setCurrentRepository(Repository* repo);
    Q_INVOKABLE void setCurrentBranch    (const QString& branch);

    // ── Management ───────────────────────────────────────────────────────────
    Q_INVOKABLE bool enablePlugin(const QString& id, bool enabled);
    Q_INVOKABLE void unloadPlugin(const QString& id);
    Q_INVOKABLE bool installPluginFromBase64Zip(const QString& pluginId, const QString& base64Data,
                                                const QString& expectedMd5 = {});
    Q_INVOKABLE bool installGepFile(const QString& gepPath);
    Q_INVOKABLE bool installGepFromBase64(const QString& base64Data, const QString& pluginId = {});
    Q_INVOKABLE bool removePlugin(const QString& id);

    // ── Downloads folder ─────────────────────────────────────────────────────
    Q_INVOKABLE void scanDownloads();
    Q_INVOKABLE bool installDownloadedPackage(const QString& pluginId, const QString& packagePath);

    // ── Diff plugin lookup ────────────────────────────────────────────────────
    Q_INVOKABLE QUrl diffPluginUrlFor(const QString& extension) const;
    Q_INVOKABLE QUrl colorizerUrlFor (const QString& extension) const;

    // ── Per-plugin settings (accessible from QML plugin docks) ───────────────
    Q_INVOKABLE QVariant pluginSetting   (const QString& pluginId, const QString& key,
                                          const QVariant& defaultValue = {}) const;
    Q_INVOKABLE void     setPluginSetting(const QString& pluginId, const QString& key,
                                          const QVariant& value);

    // ── Event bus (QML-accessible) ────────────────────────────────────────────
    Q_INVOKABLE void publishEvent    (const QString& event, const QVariantMap& payload);
    Q_INVOKABLE int  subscribeEvent  (const QString& event, const QJSValue& handler);
    Q_INVOKABLE void unsubscribeEvent(int token);

    // ── Context menu (QML-accessible) ────────────────────────────────────────
    // target: "commit" | "branch" | "file"
    Q_INVOKABLE QVariantList pluginContextMenuItems     (const QString& target,
                                                         const QVariantMap& ctx) const;
    Q_INVOKABLE void         executeContextMenuAction   (const QString& pluginId,
                                                         const QString& itemId,
                                                         const QString& target,
                                                         const QVariantMap& ctx);

    // ── Rule checks (QML-accessible) ─────────────────────────────────────────
    // Synchronously runs all registered IRulePlugins; returns first failure or success.
    Q_INVOKABLE void runBeforeAction(ActionContext* context);

    // ── Workflow hooks (QML-accessible) ──────────────────────────────────────
    // Call before a git operation; listen to workflowEventResolved to proceed/cancel.
    Q_INVOKABLE void notifyWorkflowEvent    (const QString& event, const QVariantMap& ctx);
    Q_INVOKABLE bool hasWorkflowPluginsFor  (const QString& event) const;

    // ── Toolbar (QML-accessible) ─────────────────────────────────────────────
    Q_INVOKABLE void executeToolbarAction(const QString& pluginId,
                                          const QString& actionId,
                                          const QVariantMap& ctx = {});

    // ── Queries ──────────────────────────────────────────────────────────────
    QVariantList pluginInfos()           const;
    QVariantList downloadedPackages()    const;
    QVariantList registeredDocks()       const;
    QVariantList registeredPages()       const;
    QVariantList registeredToolbarActions() const;
    QVariantList registeredConflictAssists() const;

    QList<IDockPlugin*>          dockPlugins()    const;
    QList<ICommandPlugin*>       commandPlugins() const;
    QList<IAuthPlugin*>          authPlugins()    const;
    QList<IDiffPlugin*>          diffPlugins()    const;
    QList<IServicePlugin*>       servicePlugins() const;
    QList<IContextMenuPlugin*>   contextMenuPlugins() const;
    QList<IWorkflowPlugin*>      workflowPlugins()    const;
    QList<IToolbarPlugin*>       toolbarPlugins()     const;

    QObject* backgroundContext() const;

signals:
    void pluginsChanged   ();
    void downloadedPackagesChanged();
    void docksChanged     ();
    void pagesChanged     ();
    void toolbarActionsChanged();
    void conflictAssistsChanged();
    void contextMenusChanged  ();

    void pluginLoaded     (const QString& id);
    void pluginError      (const QString& id, const QString& error);
    void pluginInstalled  (const QString& id);
    void pluginRemoved    (const QString& id);
    void pluginAboutToUnload(const QString& id);
    void pluginInstallStarted(const QString& id, const QString& name);
    void pluginInstallFailed(const QString& id, const QString& error);

    void pluginInstallQueued(const QString& pendingId, const QString& displayName);
    void pluginInstallResolved(const QString& pendingId, const QString& id, const QString& name);
    void pluginRemoveFailed(const QString& id, const QString& error);

    // Forwarded from PluginContext — consumed by PluginController
    void notifyRequested  (const QString& message, const QString& type);

    // Emitted when a plugin registers a dock or command
    void dockRegistered   (const QString& id, const QUrl& qmlUrl,
                           const QString& title, const QString& icon);
    void commandRegistered(const QString& pluginId, const QVariantList& commands);

    // Emitted when a plugin registers a page (consumed by PluginController.qml)
    void pageRegistered   (const QString& id, const QUrl& qmlUrl,
                           const QString& title, const QString& icon, int order,
                           const QString& pluginId);

    // Emitted after all workflow plugins resolve for the given event
    void workflowEventResolved(const QString& event, const QVariantMap& ctx, bool allowed);

    // Emitted when a toolbar plugin action is added
    void toolbarActionRegistered(const QString& pluginId, const QString& id,
                                  const QString& tooltip, const QString& icon, int order);

private:
    struct ReleaseJob;

    bool       loadPlugin   (const QString& pluginDir);
    bool       loadPlugin   (const PreparedPlugin& prepared);
    PluginInfo parseManifest(const QString& pluginDir) const;
    void       startGepInstall(const QString& gepPath, const QString& tempFileToRemove,
                               const QString& pluginId, bool announce);
    void       continueGepInstall(const GepRequest& request, const GepInspection& inspection);
    void       finishGepInstall(const GepRequest& request, const GepPlacement& placement);
    bool       loadCppPlugin(const PluginInfo& info, const QString& preparedLibrary = {});
    void       wireContext  ();
    bool       activatePlugin(PluginInfo& info, const QString& preparedLibrary = {});

    void       deactivatePlugin(const QString& id, std::function<void()> done = {});
    void       tearDownPlugin(const QString& id, std::function<void()> done = {});
    void       releaseLibrary(const std::shared_ptr<ReleaseJob>& job);

    void       startNextScan();
    void       finishScan(const PluginScanResult& result);
    void       pumpLoadQueue();
    void       runWhenScanIdle(std::function<void()> action);
    void       finishRemoval(const QString& id, const PluginRemovalResult& result);
    bool       isBusy(const QString& id) const;

    QString    hotLoadLibraryPath(const QString& pluginDir, const QString& entry) const;
    QString    uniquePluginDir(const QString& pluginRoot, const QString& id,
                               const QString& version) const;

    void runWorkflowChain(const QString& event,
                          const QVariantMap& ctx,
                          int index,
                          std::function<void(bool)> finalCallback);

    PluginContext* m_context = nullptr;
    QThread*       m_workerThread  = nullptr;
    QObject*       m_workerContext = nullptr;

    QMap<QString, QPluginLoader*> m_loaders;
    QMap<QString, IPlugin*>       m_plugins;
    QList<PluginInfo>             m_infos;
    QSet<QString>                 m_installingIds; // .gep installs still being placed on disk
    QSet<QString>                 m_removingIds;   // uninstalls still deleting files

    QStringList                   m_scanQueue;     // directories waiting for a background scan
    bool                          m_scanRunning    = false;
    QList<PreparedPlugin>         m_loadQueue;     // scanned plugins waiting to be loaded one by one
    bool                          m_loadPumpActive = false;
    QList<std::shared_ptr<ReleaseJob>> m_releaseJobs;
    int                           m_pendingCounter = 0;

    QVariantList                  m_downloadedPackages; // best package per plugin in the downloads folder
    bool                          m_downloadScanRunning = false;
    bool                          m_downloadScanQueued  = false;

    QVariantList                  m_docks;        // accumulated dock registrations
    QVariantList                  m_pages;        // accumulated page registrations
    QVariantList                  m_toolbarActions; // accumulated toolbar action registrations
    QVariantList                  m_conflictAssists;

    QMap<QString, QUrl>           m_diffPlugins;   // extension → custom viewer URL
    QMap<QString, QUrl>           m_colorizers;    // extension → colorizer QtObject URL

    QList<IContextMenuPlugin*>    m_contextMenuPlugins;
    QList<IWorkflowPlugin*>       m_workflowPlugins;
    QList<IToolbarPlugin*>        m_toolbarPlugins;
    QList<IRulePlugin*>           m_rulePlugins;
};
