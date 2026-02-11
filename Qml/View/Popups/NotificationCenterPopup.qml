import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * NotificationCenterPopup
 * Displays notification history grouped by time periods
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var notificationController: null
    property int currentPeriod: 0  // 0=Today, 1=Yesterday, 2=This Week, 3=Last Week, 4=All
    
    /* Event Handlers
     * ****************************************************************************************/
    onOpened: {
        if (notificationController) {
            notificationController.markAllAsRead()

            notificationListView.model = root.getNotificationsForPeriod(root.currentPeriod)
        }
    }

    /* Object Properties
     * ****************************************************************************************/
    width: parent.width * 0.8
    height: parent.height * 0.8

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 15

            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 15

                // Left sidebar - Time periods
                PagesRail {
                    Layout.preferredWidth: parent.width * 0.15
                    Layout.fillHeight: true
                    currentId: root.currentPeriod
                    radius: 5
                    color: Style.colors.secondaryBackground
                    model: [
                        {id: 0, title: "Today", icon: Style.icons.calendarDay},
                        {id: 1, title: "Yesterday", icon: Style.icons.calendarMinus},
                        {id: 2, title: "This Week", icon: Style.icons.calendarWeek},
                        {id: 3, title: "Last Week", icon: Style.icons.calendarCheck},
                        {id: 4, title: "All", icon: Style.icons.clockRotateLeft}
                    ]
                    expanded: true
                    onClicked: (modelData) => {
                        root.currentPeriod = modelData.id
                    }
                }

                // Right side - Notifications
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Style.colors.secondaryBackground
                    radius: 5
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 10
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 0

                        // Header with buttons
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            spacing: 12

                            Text {
                                Layout.fillWidth: true
                                text: "Notifications"
                                font.family: Style.fontTypes.roboto
                                font.weight: 700
                                font.pixelSize: 17
                                color: Style.colors.foreground
                            }

                            Button {
                                flat: true
                                text: "Mark all read"
                                visible: root.notificationController && root.notificationController.unreadCount > 0
                                Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                                background: Rectangle {
                                    color: parent.hovered ? Style.colors.accent : Style.colors.primaryBackground
                                    border.color: Style.colors.accent
                                    radius: 5
                                    implicitWidth: 120
                                    implicitHeight: 36
                                }

                                onClicked: {
                                    if (root.notificationController) {
                                        root.notificationController.markAllAsRead()
                                    }
                                }
                            }

                            Button {
                                flat: true
                                text: "Clear all"
                                Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                                background: Rectangle {
                                    color: parent.hovered ? Style.colors.accent : Style.colors.primaryBackground
                                    border.color: Style.colors.accent
                                    radius: 5
                                    implicitWidth: 100
                                    implicitHeight: 36
                                }

                                onClicked: {
                                    if (root.notificationController) {
                                        root.notificationController.clearHistory()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 2
                            Layout.topMargin: 5
                            Layout.bottomMargin: 5
                            color: Qt.darker(Style.colors.secondaryBackground, 1.2)
                        }

                        // Notification list
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            
                            ListView {
                                id: notificationListView
                                model: root.getNotificationsForPeriod(root.currentPeriod)
                                spacing: 4
                                
                                Connections {
                                    target: root
                                    function onCurrentPeriodChanged() {
                                        notificationListView.model = root.getNotificationsForPeriod(root.currentPeriod)
                                    }
                                }
                                
                                Connections {
                                    target: root.notificationController
                                    function onHistoryUpdated() {
                                        notificationListView.model = root.getNotificationsForPeriod(root.currentPeriod)
                                    }
                                }

                                delegate: Item {
                                    id: notifDelegate
                                    width: notificationListView.width
                                    height: notifCard.height
                                    
                                    Rectangle {
                                        id: notifCard
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: contentCol.height + 18
                                        radius: 6
                                        color: modelData.read ? Style.colors.primaryBackground : Qt.alpha(Style.colors.accent, 0.03)
                                        border.width: modelData.read ? 1 : 2
                                        border.color: modelData.read ? Style.colors.primaryBorder : Qt.alpha(Style.colors.accent, 0.3)
                                        
                                        // Subtle shadow effect
                                        layer.enabled: true
                                        layer.effect: DropShadow {
                                            horizontalOffset: 0
                                            verticalOffset: 1
                                            radius: 3
                                            samples: 7
                                            color: Qt.rgba(0, 0, 0, 0.08)
                                        }

                                        // Type indicator bar
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.leftMargin: 0
                                            width: modelData.read ? 3 : 4
                                            radius: 6
                                            color: {
                                                switch(modelData.type) {
                                                    case "error":
                                                        return Style.colors.notificationErrorIcon
                                                    case "warning":
                                                        return Style.colors.notificationWarningIcon
                                                    case "success":
                                                        return Style.colors.notificationSuccessIcon
                                                    case "info":
                                                    default:
                                                        return Style.colors.notificationInfoIcon
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            id: contentCol
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: 9
                                            anchors.leftMargin: 14
                                            spacing: 4

                                            // Header row: icon, title, time
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 10

                                                // Icon
                                                Text {
                                                    text: {
                                                        switch(modelData.type) {
                                                            case "error":
                                                                return Style.icons.circleExclamation
                                                            case "warning":
                                                                return Style.icons.warning
                                                            case "success":
                                                                return Style.icons.check
                                                            case "info":
                                                            default:
                                                                return Style.icons.info
                                                        }
                                                    }
                                                    font.family: Style.fontTypes.font6ProSolid
                                                    font.pixelSize: 14
                                                    color: {
                                                        switch(modelData.type) {
                                                            case "error":
                                                                return Style.colors.notificationErrorIcon
                                                            case "warning":
                                                                return Style.colors.notificationWarningIcon
                                                            case "success":
                                                                return Style.colors.notificationSuccessIcon
                                                            case "info":
                                                            default:
                                                                return Style.colors.notificationInfoIcon
                                                        }
                                                    }
                                                }

                                                // Title
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.title
                                                    font.family: Style.fontTypes.roboto
                                                    font.weight: 600
                                                    font.pixelSize: 13
                                                    color: Style.colors.foreground
                                                    elide: Text.ElideRight
                                                }

                                                // Time
                                                Text {
                                                    text: root.getRelativeTime(modelData.timestamp)
                                                    font.family: Style.fontTypes.roboto
                                                    font.weight: 500
                                                    font.pixelSize: 11
                                                    color: modelData.read ? Style.colors.mutedText : Style.colors.accent
                                                }
                                            }

                                            // Message
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.message
                                                font.family: Style.fontTypes.roboto
                                                font.weight: 400
                                                font.pixelSize: 12
                                                lineHeight: 1.4
                                                color: Style.colors.mutedText
                                                wrapMode: Text.Wrap
                                                maximumLineCount: 3
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }
            }

            // Close button at bottom
            Row {
                spacing: 8
                Layout.alignment: Qt.AlignRight

                Button {
                    flat: true
                    text: "Close"
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                    }
                    onClicked: root.close()
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function getNotificationsForPeriod(periodIndex) {
        if (!root.notificationController || !root.notificationController.notificationHistory) {
            return []
        }

        let now = new Date()
        let filtered = []

        for (let i = 0; i < root.notificationController.notificationHistory.length; i++) {
            let notification = root.notificationController.notificationHistory[i]
            let notifDate = new Date(notification.timestamp)

            let include = false
            switch(periodIndex) {
                case 0: // Today
                    include = isToday(notifDate, now)
                    break
                case 1: // Yesterday
                    include = isYesterday(notifDate, now)
                    break
                case 2: // This Week
                    include = isThisWeek(notifDate, now)
                    break
                case 3: // Last Week
                    include = isLastWeek(notifDate, now)
                    break
                case 4: // All
                    include = true
                    break
            }

            if (include) {
                filtered.push(notification)
            }
        }

        return filtered.reverse()
    }

    function isToday(date, now) {
        return date.getFullYear() === now.getFullYear() &&
               date.getMonth() === now.getMonth() &&
               date.getDate() === now.getDate()
    }

    function isYesterday(date, now) {
        let yesterday = new Date(now)
        yesterday.setDate(yesterday.getDate() - 1)
        return date.getFullYear() === yesterday.getFullYear() &&
               date.getMonth() === yesterday.getMonth() &&
               date.getDate() === yesterday.getDate()
    }

    function isThisWeek(date, now) {
        let weekStart = new Date(now)
        weekStart.setDate(now.getDate() - now.getDay())
        weekStart.setHours(0, 0, 0, 0)

        let weekEnd = new Date(weekStart)
        weekEnd.setDate(weekStart.getDate() + 7)

        return date >= weekStart && date < weekEnd
    }

    function isLastWeek(date, now) {
        let lastWeekStart = new Date(now)
        lastWeekStart.setDate(now.getDate() - now.getDay() - 7)
        lastWeekStart.setHours(0, 0, 0, 0)

        let lastWeekEnd = new Date(lastWeekStart)
        lastWeekEnd.setDate(lastWeekStart.getDate() + 7)

        return date >= lastWeekStart && date < lastWeekEnd
    }

    function getRelativeTime(timestamp) {
        let now = new Date()
        let notifDate = new Date(timestamp)
        let diff = now - notifDate
        let seconds = Math.floor(diff / 1000)
        let minutes = Math.floor(seconds / 60)
        let hours = Math.floor(minutes / 60)
        let days = Math.floor(hours / 24)

        if (seconds < 60) {
            return "Just now"
        } else if (minutes < 60) {
            return minutes + "m ago"
        } else if (hours < 24) {
            return hours + "h ago"
        } else if (days === 1) {
            return "Yesterday"
        } else if (days < 7) {
            return days + "d ago"
        } else {
            return Qt.formatDate(notifDate, "MMM d")
        }
    }
}
