import QtQuick

/*! ***********************************************************************************************
 * NotificationSettings
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property bool   displayRealtimeNotifications: true
    property int    maxVisibleNotifications:      5
    
    // Position of notifications: "right-bottom", "right-top", "left-bottom", "left-top"
    property string notificationPosition:         "right-bottom"

    /* Functions
     * ****************************************************************************************/
    function serialize() {
        let data = {
            displayRealtimeNotifications: root.displayRealtimeNotifications,
            maxVisibleNotifications: root.maxVisibleNotifications,
            notificationPosition: root.notificationPosition
        }

        return data;
    }

    function deserialize(data : var) {
        root.displayRealtimeNotifications = data.displayRealtimeNotifications ?? true
        root.maxVisibleNotifications = data.maxVisibleNotifications ?? 5
        root.notificationPosition = data.notificationPosition ?? "right-bottom"
    }
}

