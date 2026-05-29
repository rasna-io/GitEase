#include "PluginContext.h"
#include "IDockPlugin.h"
#include "ICommandPlugin.h"
#include "IDiffPlugin.h"

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
}

void PluginContext::setCurrentBranch(const QString& branch)
{
    if (m_branch == branch) return;
    m_branch = branch;
    emit branchChanged(branch);
}
