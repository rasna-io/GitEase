import QtQuick

import GitEase

/*! ***********************************************************************************************
 * AppSettings
 * Simple flag holder for application state
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    
    // Flag to determine if the welcome flow has been completed
    // If true, show main application window
    // If false, show welcome page flow
    // You can manually set this flag as needed
    property bool hasCompletedWelcome: false

    property bool guidesEnabled: true
    property var shownGuides: []

    property GeneralSettings generalSettings: GeneralSettings {}

    property AppearanceSettings appearanceSettings: AppearanceSettings {}

    property NotificationSettings notificationSettings: NotificationSettings {}

    property ProxySettings proxySettings: ProxySettings {}

    /* Functions
     * ****************************************************************************************/
    function serialize() {
        let data = {
            hasCompletedWelcome: root.hasCompletedWelcome,
            guidesEnabled: root.guidesEnabled,
            shownGuides: root.shownGuides,
            general: root.generalSettings.serialize(),
            appearance: root.appearanceSettings.serialize(),
            notifications: root.notificationSettings.serialize(),
            proxy: root.proxySettings.serialize()
        }

        return data;
    }

    function deserialize(data : var) {
        root.hasCompletedWelcome = data?.hasCompletedWelcome ?? false
        root.guidesEnabled = data?.guidesEnabled ?? true
        root.shownGuides = data?.shownGuides ?? []

        root.generalSettings.deserialize(data?.general ?? {})
        root.appearanceSettings.deserialize(data?.appearance ?? {})
        root.notificationSettings.deserialize(data?.notifications ?? {})
        root.proxySettings.deserialize(data?.proxy ?? {})
    }

}

