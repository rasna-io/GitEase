import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * NotificationOverlayToast
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    notificationController: null
    property var    notification: null
    property int    notificationIndex: 0
    property string notificationPosition: "right-bottom"

    readonly property bool autoHide: root.notification?.autoHide ?? true
    readonly property int  duration: root.notification?.duration || 3000

    /* Timer state
     * ****************************************************************************************/
    property int    remainingMs: 0
    property double timerStartMs: 0
    property int    totalElapsed: 0
    property int    elapsedMs: 0
    property bool   closing: false

    /* Signals
     * ****************************************************************************************/
    signal closed()

    /* Object Properties
     * ****************************************************************************************/
    width: notificationItem.width
    height: notificationItem.height
    z: 10000

    /* Functions
     * ****************************************************************************************/
    function show() {
        fadeInAnimation.start()

        if(!root.autoHide) {
            return
        }

        root.remainingMs = root.duration
        root.totalElapsed = 0
        root.startTimer(root.remainingMs)
    }

    function startTimer(ms) {
        if(ms <= 0) {
            return
        }

        autoDismissTimer.stop()
        autoDismissTimer.interval = ms

        root.timerStartMs = Date.now()
        autoDismissTimer.start()
    }

    function updateElapsed() {
        let current = autoDismissTimer.running ? Date.now() - root.timerStartMs : 0
        root.elapsedMs = Math.min(root.duration, root.totalElapsed + current)
    }

    function pauseAutoDismiss() {
        if(!autoDismissTimer.running) {
            return
        }

        let elapsed = Date.now() - root.timerStartMs
        root.totalElapsed += elapsed
        root.remainingMs = Math.max(0, autoDismissTimer.interval - elapsed)
        autoDismissTimer.stop()
        root.updateElapsed()
    }

    function resumeAutoDismiss() {
        if(root.remainingMs <= 0) {
            return
        }

        if(autoDismissTimer.running) {
            return
        }

        root.startTimer(root.remainingMs)
    }

    function dismiss() {
        if(root.closing) {
            return
        }

        autoDismissTimer.stop()
        fadeOutAnimation.start()
    }

    //! Closes immediately and tells the controller. Safe to call more than once.
    function close() {
        if(root.closing) {
            return
        }

        root.closing = true
        autoDismissTimer.stop()
        fadeOutAnimation.stop()
        root.closed()
    }

    /* Children
     * ****************************************************************************************/
    NotificationItem {
        id: notificationItem

        notification: root.notification
        dismissible: true
        elapsedMs: root.elapsedMs

        onCloseRequested: root.dismiss()
    }

    MouseArea {
        anchors.fill: notificationItem
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: 999

        onEntered: {
            if(root.notificationController) {
                root.notificationController.pauseAllNotifications()
            }
        }

        onExited: {
            if(root.notificationController) {
                root.notificationController.resumeAllNotifications()
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
        onFinished: root.close()
    }

    Timer {
        id: autoDismissTimer
        repeat: false

        onTriggered: {
            root.remainingMs = 0
            root.elapsedMs = root.duration
            root.dismiss()
        }
    }

    Timer {
        id: progressTimer
        interval: 16
        repeat: true
        running: autoDismissTimer.running

        onTriggered: root.updateElapsed()
    }

    Component.onCompleted: root.show()
}
