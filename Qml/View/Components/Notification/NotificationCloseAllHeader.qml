import QtQuick
import QtQuick.Window

/*! ***********************************************************************************************
 * NotificationCloseAllHeader
 * Header window that appears above notifications when there are 2+ notifications
 * Allows closing all notifications at once
 * ************************************************************************************************/
Window {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int notificationCount: 0

    /* Signals
     * ****************************************************************************************/
    signal closeAllRequested()

    /* Object Properties
     * ****************************************************************************************/
    width: 320
    height: 40

    flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.BypassWindowManagerHint
    color: "transparent"
    visible: false

    /* Children
     * ****************************************************************************************/
    NotificationCloseAllBar {
        anchors.fill: parent
        notificationCount: root.notificationCount

        onCloseAllRequested: root.closeAllRequested()
    }
}
