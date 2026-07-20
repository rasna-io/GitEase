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
 * A right-edge sliding drawer that displays notification history grouped by time periods
 * ************************************************************************************************/
Drawer {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var notificationController: null
    property string readFilter: "All"   // "All" | "Unread" | "Read"
    property string typeFilter: ""       // "" (any type) | "info" | "success" | "warning" | "error"
    property Item   scrim:      null

    /* Event Handlers
     * ****************************************************************************************/
    onAboutToShow: {
        if (!root.scrim && Overlay.overlay) {
            root.scrim = scrimComponent.createObject(Overlay.overlay)
        }
    }

    onOpened: {
        notificationListView.model = root.getFilteredNotifications()
    }

    onClosed: {
        if (root.scrim) {
            root.scrim.destroy()
            root.scrim = null
        }

        if (notificationController) {
            notificationController.markAllAsRead()
        }
    }

    onParentChanged: {
        if (root.parent !== Overlay.overlay) {
            root.parent = Overlay.overlay
        }
    }

    /* Object Properties
     * ****************************************************************************************/
    edge: Qt.RightEdge
    modal: false
    dim: false
    focus: true
    interactive: false
    closePolicy: Popup.CloseOnEscape

    width: Math.min(420, parent.width * 0.4)
    height: parent.height

    padding: 0
    topInset: 0
    leftInset: 0
    rightInset: 0
    bottomInset: 0

    /* Components
     * ****************************************************************************************/
    Component {
        id: scrimComponent

        Rectangle {
            anchors.fill: parent
            z: -1
            color: "#000000"
            opacity: root.position * 0.45

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }
    }

    enter: Transition {
        NumberAnimation {
            property: "position"
            from: 0.0
            to: 1.0
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "position"
            from: 1.0
            to: 0.0
            duration: 200
            easing.type: Easing.InCubic
        }
    }

    /* Children
     * ****************************************************************************************/
    background: Rectangle {
        color: Style.colors.primaryBackground

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Style.colors.primaryBorder
        }
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: Style.dp(16)
        anchors.bottomMargin: Style.dp(16)

        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Style.dp(16)
            Layout.rightMargin: Style.dp(16)
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Notifications"
                font.pointSize: Style.appFont.h4Pt
                font.weight: Font.DemiBold
                color: Style.colors.foreground
            }

            Text {
                text: "Mark all read"
                visible: root.notificationController && root.notificationController.unreadCount > 0
                font.pixelSize: Style.appFont.smallPt
                color: markAllMouseArea.containsMouse ? Style.colors.accentHover : Style.colors.accent

                MouseArea {
                    id: markAllMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.notificationController) {
                            root.notificationController.markAllAsRead()
                            notificationListView.model = root.getFilteredNotifications()
                        }
                    }
                }
            }
        }

        // Filter row: read-state filter, type filter, clear
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: rowLayout.implicitHeight + Style.dp(10)
            color: Qt.darker(Style.colors.primaryBackground, 1.2)

            border {
                width: 1
                color: Style.colors.primaryBorder
            }

            RowLayout {
                id: rowLayout
                anchors.fill: parent
                anchors.leftMargin: Style.dp(16)
                anchors.rightMargin: Style.dp(16)
                spacing: 10

                ComboBox {
                    id: readFilterCombo
                    Layout.preferredWidth: Style.dp(80)
                    minHeight: 25
                    borderWidth: 0
                    focusBorderWidth: 1
                    model: ["All", "Unread", "Read"]
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: Style.appFont.smallPt
                    Material.background: Style.colors.primaryBackground
                    Material.foreground: Style.colors.foreground
                    background: Rectangle {
                        radius: 5
                        color: readFilterCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                        border.color: Style.colors.primaryBorder
                        border.width: 1
                    }
                    onCurrentTextChanged: {
                        root.readFilter = currentText
                        notificationListView.model = root.getFilteredNotifications()
                    }
                }

                ComboBox {
                    id: typeFilterCombo
                    Layout.preferredWidth: Style.dp(80)
                    minHeight: 25
                    borderWidth: 0
                    focusBorderWidth: 1
                    currentIndex: 0
                    model: ["Type", "Info", "Success", "Warning", "Error"]
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: Style.appFont.smallPt
                    Material.background: Style.colors.primaryBackground
                    Material.foreground: Style.colors.foreground
                    background: Rectangle {
                        radius: 5
                        color: typeFilterCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                        border.color: Style.colors.primaryBorder
                        border.width: 1
                    }
                    onCurrentTextChanged: {
                        root.typeFilter = currentIndex === 0 ? "" : currentText.toLowerCase()
                        notificationListView.model = root.getFilteredNotifications()
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Item {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: clearRow.implicitWidth
                    implicitHeight: clearRow.implicitHeight

                    RowLayout {
                        id: clearRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: Style.icons.trash
                            font.family: Style.fontTypes.font6ProSolid
                            font.pixelSize: Style.appFont.smallPt
                            color: clearMouseArea.containsMouse ? Style.colors.foreground : Style.colors.mutedText
                        }

                        Text {
                            text: "Clear"
                            font.pixelSize: Style.appFont.smallPt
                            color: clearMouseArea.containsMouse ? Style.colors.foreground : Style.colors.mutedText
                        }
                    }

                    MouseArea {
                        id: clearMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.notificationController) {
                                root.notificationController.clearHistory()
                            }
                        }
                    }
                }
            }
        }

        // Notification list
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Style.dp(16)
            Layout.rightMargin: Style.dp(16)
            clip: true

            ListView {
                id: notificationListView
                model: root.getFilteredNotifications()
                spacing: 2

                Connections {
                    target: root.notificationController
                    function onHistoryUpdated() {
                        notificationListView.model = root.getFilteredNotifications()
                    }
                }

                // Empty State
                EmptyStateView {
                    visible: notificationListView.count === 0
                    title: (root.notificationController && root.notificationController.notificationHistory && root.notificationController.notificationHistory.length > 0)
                           ? "No notifications match this filter"
                           : "No notifications yet"
                }

                delegate: Item {
                    id: notifDelegate
                    width: notificationListView.width
                    height: (modelData && modelData.isHeader)
                            ? sectionLabel.implicitHeight + (index === 0 ? 8 : 20)
                            : rowContent.implicitHeight + 8

                    // Section header (e.g. "TODAY", "YESTERDAY")
                    Text {
                        id: sectionLabel
                        visible: modelData && modelData.isHeader === true
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        text: visible ? modelData.label : ""
                        font.pixelSize: Style.appFont.captionPt
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                        color: Style.colors.mutedText
                    }

                    // Notification row
                    RowLayout {
                        id: rowContent
                        visible: !(modelData && modelData.isHeader)
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 8

                        // Unread indicator dot
                        Rectangle {
                            Layout.preferredWidth: 6
                            Layout.preferredHeight: 6
                            Layout.alignment: Qt.AlignVCenter
                            radius: 3
                            color: (modelData && !modelData.isHeader && !modelData.read) ? Style.colors.accent : "transparent"
                        }

                        // Icon
                        Text {
                            Layout.preferredWidth: 16
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 2
                            text: {
                                if (!modelData || modelData.isHeader)
                                    return ""
                                switch (modelData.type) {
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
                            font.pixelSize: Style.appFont.mediumPt
                            horizontalAlignment: Text.AlignHCenter
                            color: {
                                if (!modelData || modelData.isHeader)
                                    return Style.colors.notificationInfoIcon
                                switch (modelData.type) {
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
                            Layout.fillWidth: true
                            Layout.rightMargin: Style.dp(8)
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    Layout.fillWidth: true
                                    text: (modelData && !modelData.isHeader) ? modelData.title : ""
                                    font.pixelSize: Style.appFont.mediumPt
                                    font.weight: Font.Medium
                                    color: Style.colors.foreground
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: (modelData && !modelData.isHeader) ? root.getRelativeTime(modelData.timestamp) : ""
                                    font.pixelSize: Style.appFont.smallPt
                                    color: Style.colors.mutedText
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (modelData && !modelData.isHeader) ? modelData.message : ""
                                font.pixelSize: Style.appFont.defaultPt
                                lineHeight: 1.3
                                color: Style.colors.mutedText
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: rowContent
                        visible: rowContent.visible
                        z: -1
                        radius: 6
                        color: rowMouseArea.containsMouse ? Qt.alpha(Style.colors.accent, 0.05) : "transparent"
                    }

                    MouseArea {
                        id: rowMouseArea
                        anchors.fill: rowContent
                        visible: rowContent.visible
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }
    }


    /* Functions
     * ****************************************************************************************/
    function getFilteredNotifications() {
        if (!root.notificationController || !root.notificationController.notificationHistory) {
            return []
        }

        let now = new Date()
        let source = root.notificationController.notificationHistory.slice().reverse()

        let filtered = source.filter(function(notification) {
            if (root.readFilter === "Unread" && notification.read) {
                return false
            }
            if (root.readFilter === "Read" && !notification.read) {
                return false
            }
            if (root.typeFilter !== "" && notification.type !== root.typeFilter) {
                return false
            }
            return true
        })

        let result = []
        let lastLabel = ""
        for (let i = 0; i < filtered.length; i++) {
            let notification = filtered[i]
            let label = root.getSectionLabel(new Date(notification.timestamp), now)

            if (label !== lastLabel) {
                result.push({isHeader: true, label: label})
                lastLabel = label
            }

            result.push(notification)
        }

        return result
    }

    function getSectionLabel(date, now) {
        if (isToday(date, now)) {
            return "TODAY"
        } else if (isYesterday(date, now)) {
            return "YESTERDAY"
        } else if (isThisWeek(date, now)) {
            return "THIS WEEK"
        } else if (isLastWeek(date, now)) {
            return "LAST WEEK"
        }
        return Qt.formatDate(date, "MMMM yyyy").toUpperCase()
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
