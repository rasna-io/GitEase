import QtQuick
import GitEase

/*! ***********************************************************************************************
 * PluginController
 * QML wrapper around PluginManager.
 * - Initialises the manager after the QML engine is ready
 * - Forwards repo / branch state into the plugin context
 * - Routes plugin notifications to NotificationController
 * ************************************************************************************************/
QtObject {
    id: root

    required property var notificationController

    property var    currentRepo:   null
    property string currentBranch: ""

    /* Plugin manager instance
     * ****************************************************************************************/
    property PluginManager pluginManager: PluginManager {

        onPluginLoaded: function(id) {
            console.log("[PluginController] Plugin loaded:", id)
        }

        onPluginError: function(id, error) {
            console.warn("[PluginController] Plugin error —", id, ":", error)
        }

        onDockRegistered: function(id, qmlUrl, title, icon) {
            console.log("[PluginController] Dock registered:", id, "→", qmlUrl)
        }

        onNotifyRequested: function(message, type) {
            switch (type) {
                case "error":   root.notificationController.error(message);   break
                case "warning": root.notificationController.warning(message); break
                case "success": root.notificationController.success(message); break
                default:        root.notificationController.info(message);    break
            }
        }
    }

    /* State forwarding
     * ****************************************************************************************/
    onCurrentRepoChanged:   pluginManager.setCurrentRepository(currentRepo)
    onCurrentBranchChanged: pluginManager.setCurrentBranch(currentBranch)

    /* Lifecycle
     * ****************************************************************************************/
    Component.onCompleted: {
        pluginManager.initialize()
        pluginManager.scanDefaultDirectory()
        pluginManager.scanApplicationPluginsDirectory() // picks up <appDir>/plugins in dev/portable mode
    }
}
