import QtQuick

import GitEase

/*! ***********************************************************************************************
 * NotificationController
 * Manages application-wide notifications using floating window
 * ************************************************************************************************/
QtObject {
    id: root

    required property FileIO fileIO
    required property var    appSettings

    /* Property Declarations
     * ****************************************************************************************/
    property int    maxVisibleNotifications:      appSettings?.notificationSettings?.maxVisibleNotifications ?? 5
    property int    defaultDuration:              3000
    property string currentRepositoryKey:         ""
    property string previousRepositoryKey:        ""
    property string notificationPosition:         appSettings?.notificationSettings?.notificationPosition ?? "right-bottom"
    property bool   displayRealtimeNotifications: appSettings?.notificationSettings?.displayRealtimeNotifications ?? true
    
    property var activeNotifications: []      // Currently visible notification windows
    property var queuedNotifications: []      // Queued notifications waiting to be shown
    property var closeAllHeader: null         // The "Close All" header window
    property var notificationHistory: []      // All notifications history
    property int unreadCount: 0               // Count of unread notifications
    
    /* Signals
     * ****************************************************************************************/
    signal historyUpdated()
    
    /* Private Properties
     * ****************************************************************************************/
    property int screenWidth: 0
    property int screenHeight: 0
    property int rightMargin: 16
    property int bottomMargin: 16
    property int topMargin: 16
    property int notificationSpacing: 5
    readonly property string baseFilePath: fileIO.configFilePath + "/notifications"
    
    /* Signal Handlers
     * ****************************************************************************************/
    onCurrentRepositoryKeyChanged: {
        if (root.notificationHistory.length > 0) {
            saveNotificationsForRepository(root.previousRepositoryKey)
        }

        root.previousRepositoryKey = root.currentRepositoryKey
        root.notificationHistory = []
        root.unreadCount = 0

        loadNotifications()
        historyUpdated()
    }
    
    function getNotificationFilePath() {
        return getNotificationFilePathForRepository(root.currentRepositoryKey)
    }
    
    function getNotificationFilePathForRepository(repositoryKey) {
        if (repositoryKey && repositoryKey !== "") {
            return root.baseFilePath + "_" + repositoryKey + ".json"
        }
        return root.baseFilePath + ".json"
    }

    /* Functions
     * ****************************************************************************************/
    
    /**
     * Show a notification message
     */
    function showNotification(title, message, type, duration, autoHide) {
        type = type || "info"
        duration = duration !== undefined ? duration : defaultDuration
        title = title || ""
        autoHide = autoHide !== undefined ? autoHide : true
        
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
            "autoHide": autoHide,
            "timestamp": new Date(),
            "read": false,
            "repositoryKey": currentRepositoryKey
        }
        
        notificationHistory.push(notificationData)
        unreadCount++
        
        if (!root.displayRealtimeNotifications) {
            historyUpdated()
            return
        }
        
        // Check if we can show it now or need to queue
        if (activeNotifications.length >= maxVisibleNotifications) {
            queuedNotifications.push(notificationData)
            updateCloseAllHeader()
            return
        }
        
        createNotificationWindow(notificationData)
    }
    
    function info(message, title, duration, autoHide) {
        title = title || "GitEase"
        showNotification(title, message, "info", duration, autoHide)
    }
    
    function success(message, title, duration, autoHide) {
        title = title || "Success"
        showNotification(title, message, "success", duration, autoHide)
    }
    
    function warning(message, title, duration, autoHide) {
        title = title || "Warning"
        showNotification(title, message, "warning", duration, autoHide)
    }
    
    function error(message, title, duration, autoHide) {
        title = title || "Error"
        duration = duration !== undefined ? duration : 5000
        showNotification(title, message, "error", duration, autoHide)
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
        
        var notificationsToClose = activeNotifications.slice()
        
        for (var i = 0; i < notificationsToClose.length; i++) {
            var window = notificationsToClose[i]
            if (window) {
                window.close()
            }
        }
    }
    
    function markAllAsRead() {
        for (var i = 0; i < notificationHistory.length; i++) {
            notificationHistory[i].read = true
        }
        unreadCount = 0
    }
    
    function clearHistory() {
        notificationHistory = []
        unreadCount = 0
        historyUpdated()
    }
    
    function getLatestNotificationType() {
        if (unreadCount === 0 || notificationHistory.length === 0) {
            return ""
        }
        
        // Find the most recent unread notification
        for (var i = notificationHistory.length - 1; i >= 0; i--) {
            if (!notificationHistory[i].read) {
                return notificationHistory[i].type
            }
        }
        return ""
    }
    
    function saveNotifications() {
        saveNotificationsForRepository(root.currentRepositoryKey)
    }
    
    function saveNotificationsForRepository(repositoryKey) {
        var filePath = getNotificationFilePathForRepository(repositoryKey)
        
        var data = {
            "repositoryKey": repositoryKey,
            "notifications": [],
            "unreadCount": root.unreadCount
        }
        
        for (var i = 0; i < root.notificationHistory.length; i++) {
            var notif = root.notificationHistory[i]
            data.notifications.push({
                "id": notif.id,
                "message": notif.message,
                "title": notif.title,
                "type": notif.type,
                "duration": notif.duration,
                "autoHide": notif.autoHide ?? true,
                "timestamp": notif.timestamp.toISOString(),
                "read": notif.read,
                "repositoryKey": notif.repositoryKey || ""
            })
        }
        
        fileIO.fileName = filePath
        fileIO.fileContent = JSON.stringify(data, null, 2)
        fileIO.write()
    }
    
    function loadNotifications() {
        var filePath = getNotificationFilePath()
        if (!fileIO.isFileExist(filePath)) {
            console.log("[NotificationController] No saved notifications file found for repository:", currentRepositoryKey)
            return
        }
                
        fileIO.fileName = filePath
        fileIO.read()
        
        var jsonString = fileIO.fileContent
        if (!jsonString || jsonString.trim() === "") {
            console.warn("[NotificationController] Empty notifications file")
            return
        }
        
        try {
            var data = JSON.parse(jsonString)

            if (data.notifications && Array.isArray(data.notifications)) {
                root.notificationHistory = []
                for (var i = 0; i < data.notifications.length; i++) {
                    var notifData = data.notifications[i]
                    root.notificationHistory.push({
                        "id": notifData.id,
                        "message": notifData.message,
                        "title": notifData.title,
                        "type": notifData.type,
                        "duration": notifData.duration,
                        "autoHide": notifData.autoHide ?? true,
                        "timestamp": new Date(notifData.timestamp),
                        "read": notifData.read,
                        "repositoryKey": notifData.repositoryKey || ""
                    })
                }
            }
            
            if (data.unreadCount !== undefined) {
                unreadCount = data.unreadCount
            }
        } catch (e) {
            console.error("[NotificationController] Failed to parse notifications JSON:", e)
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
                                                "notificationController": root,
                                                "notificationPosition": root.notificationPosition
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
        
        var notifId = window.notification?.id
        if (notifId) {
            for (var i = 0; i < notificationHistory.length; i++) {
                if (notificationHistory[i].id === notifId) {
                    notificationHistory[i].read = true
                    if (unreadCount > 0) {
                        unreadCount--
                    }
                    saveNotifications()
                    historyUpdated()
                    break
                }
            }
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
            var headerMargin = 16

            switch(root.notificationPosition) {
                case "right-top":
                    closeAllHeader.x = screenWidth - closeAllHeader.width - rightMargin
                    closeAllHeader.y = topMargin + totalHeight + (totalHeight > 0 ? notificationSpacing : 0)
                    break
                case "left-bottom":
                    closeAllHeader.x = headerMargin
                    closeAllHeader.y = screenHeight - bottomMargin - closeAllHeader.height - totalHeight - (totalHeight > 0 ? notificationSpacing : 0)
                    break
                case "left-top":
                    closeAllHeader.x = headerMargin
                    closeAllHeader.y = topMargin + totalHeight + (totalHeight > 0 ? notificationSpacing : 0)
                    break
                case "right-bottom":
                default:
                    closeAllHeader.x = screenWidth - closeAllHeader.width - rightMargin
                    closeAllHeader.y = screenHeight - bottomMargin - closeAllHeader.height - totalHeight - (totalHeight > 0 ? notificationSpacing : 0)
                    break
            }
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
        
        loadNotifications()
    }
}
