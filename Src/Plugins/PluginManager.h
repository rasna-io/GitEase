#pragma once

#include <QObject>
#include <QVariantList>
#include <QMap>
#include <QQmlEngine>
#include <QJSValue>
#include <functional>

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
class PluginContext;
class QPluginLoader;
class Repository;

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
    Q_PROPERTY(QVariantList registeredDocks      READ registeredDocks      NOTIFY docksChanged)
    Q_PROPERTY(QVariantList registeredPages      READ registeredPages      NOTIFY pagesChanged)
    Q_PROPERTY(QVariantList registeredToolbarActions READ registeredToolbarActions NOTIFY toolbarActionsChanged)

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
    Q_INVOKABLE bool removePlugin(const QString& id);

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
    QVariantList registeredDocks()       const;
    QVariantList registeredPages()       const;
    QVariantList registeredToolbarActions() const;

    QList<IDockPlugin*>          dockPlugins()    const;
    QList<ICommandPlugin*>       commandPlugins() const;
    QList<IAuthPlugin*>          authPlugins()    const;
    QList<IDiffPlugin*>          diffPlugins()    const;
    QList<IServicePlugin*>       servicePlugins() const;
    QList<IContextMenuPlugin*>   contextMenuPlugins() const;
    QList<IWorkflowPlugin*>      workflowPlugins()    const;
    QList<IToolbarPlugin*>       toolbarPlugins()     const;

signals:
    void pluginsChanged   ();
    void docksChanged     ();
    void pagesChanged     ();
    void toolbarActionsChanged();
    void contextMenusChanged  ();

    void pluginLoaded     (const QString& id);
    void pluginError      (const QString& id, const QString& error);
    void pluginInstalled  (const QString& id);
    void pluginRemoved    (const QString& id);
    void pluginInstallFailed(const QString& id, const QString& error);

    // Forwarded from PluginContext — consumed by PluginController
    void notifyRequested  (const QString& message, const QString& type);

    // Emitted when a plugin registers a dock or command
    void dockRegistered   (const QString& id, const QUrl& qmlUrl,
                           const QString& title, const QString& icon);
    void commandRegistered(const QString& pluginId, const QVariantList& commands);

    // Emitted when a plugin registers a page (consumed by PluginController.qml)
    void pageRegistered   (const QString& id, const QUrl& qmlUrl,
                           const QString& title, const QString& icon, int order);

    // Emitted after all workflow plugins resolve for the given event
    void workflowEventResolved(const QString& event, const QVariantMap& ctx, bool allowed);

    // Emitted when a toolbar plugin action is added
    void toolbarActionRegistered(const QString& pluginId, const QString& id,
                                  const QString& tooltip, const QString& icon, int order);

private:
    bool       loadPlugin   (const QString& pluginDir);
    PluginInfo parseManifest(const QString& pluginDir);
    bool       loadCppPlugin(const PluginInfo& info);
    void       wireContext  ();
    bool       activatePlugin(PluginInfo& info);
    void       deactivatePlugin(const QString& id);
    void       tearDownPlugin(const QString& id);

    void runWorkflowChain(const QString& event,
                          const QVariantMap& ctx,
                          int index,
                          std::function<void(bool)> finalCallback);

    PluginContext* m_context = nullptr;

    QMap<QString, QPluginLoader*> m_loaders;
    QMap<QString, IPlugin*>       m_plugins;
    QList<PluginInfo>             m_infos;

    QVariantList                  m_docks;        // accumulated dock registrations
    QVariantList                  m_pages;        // accumulated page registrations
    QVariantList                  m_toolbarActions; // accumulated toolbar action registrations

    QMap<QString, QUrl>           m_diffPlugins;   // extension → custom viewer URL
    QMap<QString, QUrl>           m_colorizers;    // extension → colorizer QtObject URL

    QList<IContextMenuPlugin*>    m_contextMenuPlugins;
    QList<IWorkflowPlugin*>       m_workflowPlugins;
    QList<IToolbarPlugin*>        m_toolbarPlugins;
};
