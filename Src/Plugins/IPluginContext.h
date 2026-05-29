#pragma once

#include <QString>
#include <QVariant>

class IDockPlugin;
class ICommandPlugin;
class IDiffPlugin;

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
    virtual void registerDock   (IDockPlugin*    plugin) = 0;
    virtual void registerCommand(ICommandPlugin* plugin) = 0;
    virtual void registerDiff   (IDiffPlugin*    plugin) = 0;

    // ── Per-plugin persistent settings ───────────────────────────────────────
    virtual QVariant setting   (const QString& pluginId, const QString& key,
                                const QVariant& defaultValue = {}) const = 0;
    virtual void     setSetting(const QString& pluginId, const QString& key,
                                const QVariant& value)                   = 0;
};
