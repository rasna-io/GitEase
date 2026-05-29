#pragma once

#include <QObject>
#include <QVariant>
#include <QVariantMap>
#include "IPluginContext.h"

class Repository;
class IDockPlugin;
class ICommandPlugin;
class IDiffPlugin;
class QQmlEngine;

/*!
 * \brief API surface exposed to plugins during initialize().
 *
 * Plugins receive a PluginContext* and use it to:
 *  - Query application state (current repo, branch)
 *  - Push notifications into the UI
 *  - Register their capabilities (docks, commands)
 *  - Read / write per-plugin persistent settings
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

    // ── IPluginContext interface (callable from plugin .dll via vtable) ─────────
    void notify        (const QString& message,
                        const QString& type = QStringLiteral("info")) override;
    void registerDock   (IDockPlugin*    plugin)                       override;
    void registerCommand(ICommandPlugin* plugin)                       override;
    void registerDiff   (IDiffPlugin*    plugin)                       override;
    QVariant setting    (const QString& pluginId, const QString& key,
                         const QVariant& defaultValue = {}) const      override;
    void setSetting     (const QString& pluginId, const QString& key,
                         const QVariant& value)                        override;

    // ── Internal setters (called by PluginManager / PluginController) ────────
    void setQmlEngine        (QQmlEngine* engine);
    void setCurrentRepository(Repository* repo);
    void setCurrentBranch    (const QString& branch);

signals:
    void repositoryChanged (Repository* repo);
    void branchChanged     (const QString& name);
    void commitSelected    (const QString& hash);
    void fileSelected      (const QString& path);

    void notifyRequested   (const QString& message, const QString& type);
    void dockRegistered    (IDockPlugin*    plugin);
    void commandRegistered (ICommandPlugin* plugin);
    void diffRegistered    (IDiffPlugin*    plugin);

private:
    QQmlEngine* m_engine  = nullptr;
    Repository* m_repo    = nullptr;
    QString     m_branch;
    QVariantMap m_settings; // "pluginId/key" → value
};
