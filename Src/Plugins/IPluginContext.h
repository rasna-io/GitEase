#pragma once

#include <QString>
#include <QVariant>
#include <QVariantMap>
#include <functional>

class IDockPlugin;
class ICommandPlugin;
class IDiffPlugin;
class IPagePlugin;
class IContextMenuPlugin;
class IWorkflowPlugin;
class IToolbarPlugin;
class IRulePlugin;

/*!
 * \brief Pure abstract interface exposed to plugins.
 *
 * Plugins receive IPluginContext* in initialize() and interact with the host
 * ONLY through this interface. Because all methods are pure virtual, plugins
 * call them through the vtable — no symbol linkage to the host executable
 * is required, which makes the plugin .dll portable on Windows.
 *
 * Do NOT add non-virtual methods here.
 */
class IPluginContext
{
public:
    virtual ~IPluginContext() = default;

    // ── Notifications ────────────────────────────────────────────────────────
    virtual void notify(const QString& message,
                        const QString& type = QStringLiteral("info")) = 0;

    // ── Registration ─────────────────────────────────────────────────────────
    virtual void registerDock       (IDockPlugin*         plugin) = 0;
    virtual void registerCommand    (ICommandPlugin*      plugin) = 0;
    virtual void registerDiff       (IDiffPlugin*         plugin) = 0;
    virtual void registerPage       (IPagePlugin*         plugin) = 0;
    virtual void registerContextMenu(IContextMenuPlugin*  plugin) = 0;
    virtual void registerWorkflow   (IWorkflowPlugin*     plugin) = 0;
    virtual void registerToolbar    (IToolbarPlugin*      plugin) = 0;

    // ── Per-plugin persistent settings ───────────────────────────────────────
    virtual QVariant setting   (const QString& pluginId, const QString& key,
                                const QVariant& defaultValue = {}) const = 0;
    virtual void     setSetting(const QString& pluginId, const QString& key,
                                const QVariant& value)                   = 0;

    // ── Event bus ────────────────────────────────────────────────────────────
    // Subscribe to a named event. Returns a token; pass it to unsubscribe().
    // App-published events: "repo.switched", "branch.changed", "commit.selected", "file.selected"
    virtual int  subscribe  (const QString& event,
                             std::function<void(const QVariantMap&)> handler) = 0;
    virtual void unsubscribe(int token) = 0;
    virtual void publish    (const QString& event, const QVariantMap& payload) = 0;

    // ── NEW extension points (always add at the end to preserve ABI) ─────────
    // registerRule: slot is after publish so existing plugin DLLs are unaffected.
    virtual void registerRule       (IRulePlugin*         plugin) = 0;
};
