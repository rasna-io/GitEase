#pragma once

#include <QMap>
#include <QObject>
#include <QPair>
#include <QVariant>
#include <QVariantMap>
#include <functional>

#include "IPluginContext.h"

class Repository;
class IDockPlugin;
class ICommandPlugin;
class IDiffPlugin;
class IPagePlugin;
class IContextMenuPlugin;
class IWorkflowPlugin;
class IToolbarPlugin;
class IRulePlugin;
class QQmlEngine;

/*!
 * \brief API surface exposed to plugins during initialize().
 *
 * Plugins receive a PluginContext* and use it to:
 *  - Query application state (current repo, branch)
 *  - Push notifications into the UI
 *  - Register their capabilities (docks, commands, pages, menus, etc.)
 *  - Read / write per-plugin persistent settings
 *  - Subscribe/publish app events via the event bus
 */
class PluginContext : public QObject, public IPluginContext
{
    Q_OBJECT

public:
    explicit PluginContext(QObject* parent = nullptr);

    // ── State (read by plugins) ──────────────────────────────────────────────
    Repository* currentRepository() const;
    QString     currentBranch()     const;
    QQmlEngine* qmlEngine()         const;

    // ── IPluginContext interface (callable from plugin .dll via vtable) ──────
    void notify        (const QString& message,
                        const QString& type = QStringLiteral("info")) override;
    void registerDock       (IDockPlugin*        plugin) override;
    void registerCommand    (ICommandPlugin*     plugin) override;
    void registerDiff       (IDiffPlugin*        plugin) override;
    void registerPage       (IPagePlugin*        plugin) override;
    void registerContextMenu(IContextMenuPlugin* plugin) override;
    void registerWorkflow   (IWorkflowPlugin*    plugin) override;
    void registerToolbar    (IToolbarPlugin*     plugin) override;
    void registerRule       (IRulePlugin*        plugin) override;

    QVariant setting    (const QString& pluginId, const QString& key,
                         const QVariant& defaultValue = {}) const override;
    void setSetting     (const QString& pluginId, const QString& key,
                         const QVariant& value)              override;

    // ── Event bus ────────────────────────────────────────────────────────────
    int  subscribe  (const QString& event,
                     std::function<void(const QVariantMap&)> handler) override;
    void unsubscribe(int token)                                        override;
    void publish    (const QString& event, const QVariantMap& payload) override;

    // ── Internal setters (called by PluginManager) ───────────────────────────
    void setQmlEngine        (QQmlEngine* engine);
    void setCurrentRepository(Repository* repo);
    void setCurrentBranch    (const QString& branch);

signals:
    void repositoryChanged (Repository* repo);
    void branchChanged     (const QString& name);
    void commitSelected    (const QString& hash);
    void fileSelected      (const QString& path);

    void notifyRequested   (const QString& message, const QString& type);
    void dockRegistered    (IDockPlugin*        plugin);
    void commandRegistered (ICommandPlugin*     plugin);
    void diffRegistered    (IDiffPlugin*        plugin);
    void pageRegistered    (IPagePlugin*        plugin);
    void contextMenuRegistered(IContextMenuPlugin* plugin);
    void workflowRegistered(IWorkflowPlugin*    plugin);
    void toolbarRegistered (IToolbarPlugin*     plugin);
    void ruleRegistered    (IRulePlugin*        plugin);

private:
    QQmlEngine* m_engine  = nullptr;
    Repository* m_repo    = nullptr;
    QString     m_branch;
    QVariantMap m_settings; // "pluginId/key" → value

    // Event bus
    QMap<int, QPair<QString, std::function<void(const QVariantMap&)>>> m_subscriptions;
    int m_nextToken = 0;
};
