import QtQuick

/*! ***********************************************************************************************
 * NotificationController
 * Manages application-wide notifications using floating window
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int maxVisibleNotifications: 5
    property int defaultDuration: 3000
    
    property var activeNotifications: []      // Currently visible notification windows
    property var queuedNotifications: []      // Queued notifications waiting to be shown
    property var closeAllHeader: null         // The "Close All" header window
    
    /* Private Properties
     * ****************************************************************************************/
    property int screenWidth: 0
    property int screenHeight: 0
    property int rightMargin: 16
    property int bottomMargin: 16
    property int notificationSpacing: 5

    /* Functions
     * ****************************************************************************************/
    
    /**
     * Show a notification message
     */
    function showNotification(title, message, type, duration) {
        type = type || "info"
        duration = duration !== undefined ? duration : defaultDuration
        title = title || ""
        
        // Update screen dimensions
        if (Qt.application.screens.length > 0) {
            screenWidth = Qt.application.screens[0].width
            screenHeight = Qt.application.screens[0].height
        }
        
        // Create notification data
        var notificationData = {
            "id": "notification_" + Date.now() + "_" + Math.random(),
            "message": message,
            "title": title,
            "type": type,
            "duration": duration,
            "timestamp": new Date()
        }
        
        // Check if we can show it now or need to queue
        if (activeNotifications.length >= maxVisibleNotifications) {
            queuedNotifications.push(notificationData)
            updateCloseAllHeader()
            return
        }
        
        createNotificationWindow(notificationData)
    }
    
    function info(message, title, duration) {
        title = title || "GitEase"
        showNotification(title, message, "info", duration)
    }
    
    function success(message, title, duration) {
        title = title || "Success"
        showNotification(title, message, "success", duration)
    }
    
    function warning(message, title, duration) {
        title = title || "Warning"
        showNotification(title, message, "warning", duration)
    }
    
    function error(message, title, duration) {
        title = title || "Error"
        duration = duration !== undefined ? duration : 5000
        showNotification(title, message, "error", duration)
    }
    
    function pauseAllNotifications() {
        for (var i = 0; i < activeNotifications.length; i++) {
            var window = activeNotifications[i]
            if (window && typeof window.pauseAutoDismiss === 'function') {
                window.pauseAutoDismiss()
            }
        }
    }
    
    function resumeAllNotifications() {
        for (var i = 0; i < activeNotifications.length; i++) {
            var window = activeNotifications[i]
            if (window && typeof window.resumeAutoDismiss === 'function') {
                window.resumeAutoDismiss()
            }
        }
    }
    
    function clearAllNotifications() {
        queuedNotifications = []
        
        for (var i = 0; i < activeNotifications.length; i++) {
            var window = activeNotifications[i]
            if (window) {
                window.close()
            }
        }
    }

    function createNotificationWindow(notificationData) {
        var component = Qt.createComponent("qrc:/GitEase/Qml/View/FloatingNotificationWindow.qml")
        if (component.status !== Component.Ready) {
            console.error("[NotificationController] Failed to create notification:", component.errorString())
            return
        }
        
        var window = component.createObject(root, {
                                                "notification": notificationData,
                                                "notificationIndex": activeNotifications.length,
                                                "notificationController": root
                                            })

        if (!window) {
            console.error("[NotificationController] Failed to create notification window")
            return
        }

        window.visibleChanged.connect(function () {
            if (!window.visible) {
                onNotificationClosed(window)
            }
        })

        window.heightChanged.connect(function () {
            repositionNotifications()
        })
        
        activeNotifications.push(window)
        
        updateCloseAllHeader()
        repositionNotifications()
    }
    
    function onNotificationClosed(window) {
        var index = activeNotifications.indexOf(window)
        if (index !== -1) {
            activeNotifications.splice(index, 1)
        }
        
        window.destroy()
        
        showNextQueued()
        updateCloseAllHeader()
        repositionNotifications()
    }

    function showNextQueued() {
        if (queuedNotifications.length === 0 || activeNotifications.length >= maxVisibleNotifications) {
            return
        }
        
        var notificationData = queuedNotifications.shift()
        createNotificationWindow(notificationData)
    }

    function repositionNotifications() {
        if (screenWidth === 0 || screenHeight === 0) {
            return
        }
        
        // Calculate total height of all notifications
        var totalHeight = 0
        for (var i = 0; i < activeNotifications.length; i++) {
            var notifItem = activeNotifications[i]
            if (notifItem) {
                totalHeight += notifItem.height
                if (i > 0) {
                    totalHeight += notificationSpacing
                }
            }
        }
        
        if (closeAllHeader && closeAllHeader.visible) {
            closeAllHeader.x = screenWidth - closeAllHeader.width - rightMargin
            closeAllHeader.y = screenHeight - bottomMargin - closeAllHeader.height - totalHeight - (totalHeight > 0 ? notificationSpacing : 0)
        }
        
        for (var j = 0; j < activeNotifications.length; j++) {
            var notifWindow = activeNotifications[j]
            if (notifWindow) {
                notifWindow.notificationIndex = j
                notifWindow.positionWindow()
            }
        }
    }
    
    function updateCloseAllHeader() {
        var totalCount = activeNotifications.length + queuedNotifications.length
        
        if (totalCount > 1) {
            if (closeAllHeader) {
                closeAllHeader.notificationCount = totalCount
                closeAllHeader.visible = true
                repositionNotifications()
            }
        } else {
            if (closeAllHeader) {
                closeAllHeader.visible = false
            }
        }
    }

    Component.onCompleted: {
        var component = Qt.createComponent("qrc:/GitEase/Qml/View/Components/Notification/NotificationCloseAllHeader.qml")
        if (component.status !== Component.Ready) {
            console.error("[NotificationController] Failed to load close all header:", component.errorString())
            return
        }
        
        closeAllHeader = component.createObject(root)
        if (!closeAllHeader) {
            console.error("[NotificationController] Failed to create close all header window")
            return
        }
        
        closeAllHeader.closeAllRequested.connect(clearAllNotifications)
    }
}
