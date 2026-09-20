import QtQuick

import GitEase

/*! ***********************************************************************************************
 * ProxyController
 * Wraps ProxyManager and keeps the live proxy in sync with the persisted ProxySettings owned by
 * AppSettings, so AppModel.save() stores the configuration currently in effect. This is also what
 * makes Settings -> Cancel revert live proxy edits (it restores the settings snapshot).
 * ************************************************************************************************/
ProxyManager {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property AppModel appModel: null

    readonly property ProxySettings settings: root.appModel ? root.appModel.appSettings.proxySettings : null

    /* Private state
     * ****************************************************************************************/
    property bool _syncing: false

    /* Functions
     * ****************************************************************************************/
    function loadFromSettings() {
        if (!root.settings || root._syncing)
            return

        root._syncing = true
        root.deserialize(root.settings.serialize())
        root._syncing = false
    }

    function saveToSettings() {
        if (!root.settings || root._syncing)
            return

        root._syncing = true
        root.settings.deserialize(root.serialize())
        root._syncing = false
    }

    /* Connections
     * ****************************************************************************************/
    Component.onCompleted: root.loadFromSettings()
    onProxyTypeChanged:    root.saveToSettings()
    onHostChanged:         root.saveToSettings()
    onPortChanged:         root.saveToSettings()
    onRequiresAuthChanged: root.saveToSettings()
    onUsernameChanged:     root.saveToSettings()
    onPasswordChanged:     root.saveToSettings()
    onNoProxyListChanged:  root.saveToSettings()

    property Connections settingsConnection : Connections {
        target: root.settings

        function onProxyTypeChanged() {
            root.loadFromSettings()
        }

        function onHostChanged() {
            root.loadFromSettings()
        }

        function onPortChanged() {
            root.loadFromSettings()
        }

        function onRequiresAuthChanged() {
            root.loadFromSettings()
        }

        function onUsernameChanged() {
            root.loadFromSettings()
        }

        function onPasswordChanged() {
            root.loadFromSettings()
        }

        function onNoProxyListChanged() {
            root.loadFromSettings()
        }
    }
}
