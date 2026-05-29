#pragma once

#include <QObject>
#include <QVariantList>
#include <QMap>
#include <QQmlEngine>

#include "PluginInfo.h"

class IPlugin;
class IDockPlugin;
class ICommandPlugin;
class IAuthPlugin;
class IDiffPlugin;
class IServicePlugin;
class PluginContext;
class QPluginLoader;
class Repository;

/*!
 * \brief Discovers, loads, and manages the lifecycle of external plugins.
 *
 * Exposed to QML as a QML_ELEMENT so PluginController.qml can instantiate it
 * and wire it into the rest of the session.
 *
 * Typical usage from QML:
 * \code
 *   PluginManager {
 *       id: manager
 *       Component.onCompleted: {
 *           initialize()
 *           scanDefaultDirectory()
 *       }
 *   }
 * \endcode
 */
class PluginManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVariantList pluginInfos    READ pluginInfos    NOTIFY pluginsChanged)
    Q_PROPERTY(QVariantList registeredDocks READ registeredDocks NOTIFY docksChanged)

public:
    explicit PluginManager(QObject* parent = nullptr);
    ~PluginManager() override;

    // ── Setup ────────────────────────────────────────────────────────────────
    Q_INVOKABLE void initialize();                  // grabs QQmlEngine from the QML context
    Q_INVOKABLE void scanDefaultDirectory();        // AppData/GitEase/plugins
    Q_INVOKABLE void scanApplicationPluginsDirectory(); // <appDir>/plugins  (dev / portable)
    Q_INVOKABLE void scanDirectory(const QString& path);

    // ── State forwarding (called by PluginController) ────────────────────────
    Q_INVOKABLE void setCurrentRepository(Repository* repo);
    Q_INVOKABLE void setCurrentBranch    (const QString& branch);

    // ── Management ───────────────────────────────────────────────────────────
    Q_INVOKABLE bool enablePlugin(const QString& id, bool enabled);
    Q_INVOKABLE void unloadPlugin(const QString& id);

    // ── Diff plugin lookup (called from QML when file selection changes) ────────
    Q_INVOKABLE QUrl diffPluginUrlFor  (const QString& extension) const;
    Q_INVOKABLE QUrl colorizerUrlFor   (const QString& extension) const;

    // ── Per-plugin settings (accessible from QML plugin docks) ───────────────
    Q_INVOKABLE QVariant pluginSetting   (const QString& pluginId, const QString& key,
                                          const QVariant& defaultValue = {}) const;
    Q_INVOKABLE void     setPluginSetting(const QString& pluginId, const QString& key,
                                          const QVariant& value);

    // ── Queries ──────────────────────────────────────────────────────────────
    QVariantList pluginInfos()    const;
    QVariantList registeredDocks() const;

    QList<IDockPlugin*>    dockPlugins()    const;
    QList<ICommandPlugin*> commandPlugins() const;
    QList<IAuthPlugin*>    authPlugins()    const;
    QList<IDiffPlugin*>    diffPlugins()    const;
    QList<IServicePlugin*> servicePlugins() const;

signals:
    void pluginsChanged   ();
    void docksChanged     ();
    void pluginLoaded     (const QString& id);
    void pluginError      (const QString& id, const QString& error);

    // Forwarded from PluginContext — consumed by PluginController
    void notifyRequested  (const QString& message, const QString& type);

    // Emitted when a plugin registers a dock or command
    void dockRegistered   (const QString& id, const QUrl& qmlUrl,
                           const QString& title, const QString& icon);
    void commandRegistered(const QString& pluginId, const QVariantList& commands);

private:
    bool       loadPlugin   (const QString& pluginDir);
    PluginInfo parseManifest(const QString& pluginDir);
    bool       loadCppPlugin(const PluginInfo& info);
    void       wireContext  ();

    PluginContext* m_context = nullptr;

    QMap<QString, QPluginLoader*> m_loaders;
    QMap<QString, IPlugin*>       m_plugins;
    QList<PluginInfo>             m_infos;
    QVariantList                  m_docks;        // accumulated dock registrations
    QMap<QString, QUrl>           m_diffPlugins;   // extension → custom viewer URL
    QMap<QString, QUrl>           m_colorizers;    // extension → colorizer QtObject URL
};
