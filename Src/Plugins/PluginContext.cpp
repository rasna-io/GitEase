#include "PluginContext.h"
#include "IDockPlugin.h"
#include "ICommandPlugin.h"
#include "IDiffPlugin.h"
#include "IPagePlugin.h"
#include "IContextMenuPlugin.h"
#include "IWorkflowPlugin.h"
#include "IToolbarPlugin.h"
#include "IRulePlugin.h"

#include <QSettings>

PluginContext::PluginContext(QObject* parent)
    : QObject(parent)
{
    // Reload persisted plugin settings on startup
    QSettings s(QStringLiteral("GitEase"), QStringLiteral("PluginSettings"));
    const auto keys = s.allKeys();
    for (const QString& k : keys)
        m_settings[k] = s.value(k);
}

// ── State accessors ──────────────────────────────────────────────────────────

Repository* PluginContext::currentRepository() const { return m_repo;   }
QString     PluginContext::currentBranch()     const { return m_branch; }
QQmlEngine* PluginContext::qmlEngine()         const { return m_engine; }

// ── Notifications ────────────────────────────────────────────────────────────

void PluginContext::notify(const QString& message, const QString& type)
{
    emit notifyRequested(message, type);
}

// ── Registration ─────────────────────────────────────────────────────────────

void PluginContext::registerDock(IDockPlugin* plugin)
{
    emit dockRegistered(plugin);
}

void PluginContext::registerCommand(ICommandPlugin* plugin)
{
    emit commandRegistered(plugin);
}

void PluginContext::registerDiff(IDiffPlugin* plugin)
{
    emit diffRegistered(plugin);
}

void PluginContext::registerPage(IPagePlugin* plugin)
{
    emit pageRegistered(plugin);
}

void PluginContext::registerContextMenu(IContextMenuPlugin* plugin)
{
    emit contextMenuRegistered(plugin);
}

void PluginContext::registerWorkflow(IWorkflowPlugin* plugin)
{
    emit workflowRegistered(plugin);
}

void PluginContext::registerToolbar(IToolbarPlugin* plugin)
{
    emit toolbarRegistered(plugin);
}

void PluginContext::registerRule(IRulePlugin* plugin)
{
    emit ruleRegistered(plugin);
}

// ── Settings ─────────────────────────────────────────────────────────────────

QVariant PluginContext::setting(const QString& pluginId,
                                const QString& key,
                                const QVariant& defaultValue) const
{
    return m_settings.value(pluginId + QChar('/') + key, defaultValue);
}

void PluginContext::setSetting(const QString& pluginId,
                               const QString& key,
                               const QVariant& value)
{
    const QString k = pluginId + QChar('/') + key;
    m_settings[k] = value;
    QSettings s(QStringLiteral("GitEase"), QStringLiteral("PluginSettings"));
    s.setValue(k, value);
}

// ── Event bus ────────────────────────────────────────────────────────────────

int PluginContext::subscribe(const QString& event,
                              std::function<void(const QVariantMap&)> handler)
{
    const int token = ++m_nextToken;
    m_subscriptions[token] = {event, std::move(handler)};
    return token;
}

void PluginContext::unsubscribe(int token)
{
    m_subscriptions.remove(token);
}

void PluginContext::publish(const QString& event, const QVariantMap& payload)
{
    // Snapshot before iterating so subscribe/unsubscribe calls inside handlers are safe.
    const auto snapshot = m_subscriptions;
    for (const auto& entry : snapshot) {
        if (entry.first == event)
            entry.second(payload);
    }
}

// ── Internal setters ─────────────────────────────────────────────────────────

void PluginContext::setQmlEngine(QQmlEngine* engine)
{
    m_engine = engine;
}

void PluginContext::setCurrentRepository(Repository* repo)
{
    if (m_repo == repo) return;
    m_repo = repo;
    emit repositoryChanged(repo);
    publish(QStringLiteral("repo.switched"), {});
}

void PluginContext::setCurrentBranch(const QString& branch)
{
    if (m_branch == branch) return;
    m_branch = branch;
    emit branchChanged(branch);
    publish(QStringLiteral("branch.changed"), {{QStringLiteral("branch"), branch}});
}
