import QtQuick
import QtQuick.Window

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * FloatingNotificationWindow
 * A frameless window that displays notifications outside the main application
 * ************************************************************************************************/
Window {
    id: root

    property var notificationController: null

    /* Property Declarations
     * ****************************************************************************************/
    property var notification: null
    property int notificationIndex: 0
    property int spacing: 5
    property int rightMargin: 16
    property int bottomMargin: 16
    property int leftMargin: 16
    property int topMargin: 16
    property int headerHeight: 0
    property string notificationPosition: "right-bottom"

    /* Object Properties
     * ****************************************************************************************/
    property int contentHeight: 100

    width: 320
    height: contentHeight    
    
    flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.BypassWindowManagerHint
    color: "transparent"
    visible: false
    
    /* Signals
     * ****************************************************************************************/
    signal closeRequested()

    /* Timer state
     * ****************************************************************************************/
    property int remainingMs: 0
    property double timerStartMs: 0

    /* Functions
     * ****************************************************************************************/
    function show() {
        contentHeight = notificationItem.height

        visible = true
        positionWindow()
        fadeInAnimation.start()

        let autoHide = notificationObject.autoHide ?? true
        if (autoHide) {
            let dur = notificationObject.duration
            remainingMs = dur
            if (dur > 0) {
                startTimer(remainingMs)
            }
        }
    }

    function startTimer(ms) {
        if (ms <= 0)
            return

        autoDismissTimer.stop()
        autoDismissTimer.interval = ms

        timerStartMs = Date.now()
        autoDismissTimer.start()
    }

    function pauseAutoDismiss() {
        if (!autoDismissTimer.running)
            return

        let elapsed = Date.now() - timerStartMs
        remainingMs = Math.max(0, remainingMs - elapsed)
        autoDismissTimer.stop()
    }

    function resumeAutoDismiss() {
        if (remainingMs <= 0)
            return

        if (autoDismissTimer.running)
            return

        startTimer(remainingMs)
    }
    
    function positionWindow() {
        let screens = Qt.application.screens
        if (screens.length === 0) {
            return
        }
        
        let primaryScreen = screens[0]
        let screenWidth = primaryScreen.width
        let screenHeight = primaryScreen.height
        
        // Calculate position based on notificationPosition setting
        switch(notificationPosition) {
            case "right-top":
                root.x = screenWidth - width - rightMargin
                root.y = topMargin + headerHeight + (notificationIndex * (height + spacing))
                break
            case "left-bottom":
                root.x = leftMargin
                root.y = screenHeight - bottomMargin - headerHeight - height - (notificationIndex * (height + spacing))
                break
            case "left-top":
                root.x = leftMargin
                root.y = topMargin + headerHeight + (notificationIndex * (height + spacing))
                break
            case "right-bottom":
            default:
                root.x = screenWidth - width - rightMargin
                root.y = screenHeight - bottomMargin - headerHeight - height - (notificationIndex * (height + spacing))
                break
        }
    }
    
    function dismiss() {
        fadeOutAnimation.start()
    }

    /* Children
     * ****************************************************************************************/
    QtObject {
        id: notificationObject
        property string id:        (root.notification && root.notification.id) || ""
        property string message:   (root.notification && root.notification.message) || "notification message"
        property string title:     (root.notification && root.notification.title) || "notification title"
        property string type:      (root.notification && root.notification.type) || "info"
        property int    duration:  (root.notification && root.notification.duration) || 3000
        property bool   autoHide:  (root.notification && root.notification.autoHide !== undefined) ? root.notification.autoHide : true
        property var    timestamp: (root.notification && root.notification.timestamp) || new Date()
    }
    
    Item {
        id: container
        anchors.fill: parent

        NotificationItem {
            id: notificationItem
            anchors.centerIn: parent

            notification: notificationObject
            dismissible: true

            onCloseRequested: {
                root.dismiss()
            }

            Component.onCompleted: {
                root.contentHeight = height
            }

            onHeightChanged: {
                root.contentHeight = height
                if (root.visible) {
                    root.positionWindow()
                    root.heightChanged()
                }
            }
        }

        MouseArea {
            anchors.fill: notificationItem
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            z: 999
            propagateComposedEvents: true
            
            onEntered: {
                if (root.notificationController) {
                    root.notificationController.pauseAllNotifications()
                }
            }
            onExited: {
                if (root.notificationController) {
                    root.notificationController.resumeAllNotifications()
                }
            }
        }
    }

    /* Animations
     * ****************************************************************************************/
    NumberAnimation {
        id: fadeInAnimation
        target: root
        property: "opacity"
        from: 0
        to: 1
        duration: 300
        easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: fadeOutAnimation
        target: root
        property: "opacity"
        from: 1
        to: 0
        duration: 200
        easing.type: Easing.InQuad
        onStopped: {
            root.closeRequested()
            root.close()
        }
    }

    Timer {
        id: autoDismissTimer
        repeat: false
        onTriggered: {
            remainingMs = 0
            root.dismiss()
        }
    }

    Component.onCompleted: {
        show()
    }
}
