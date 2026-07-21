import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * NotificationItem
 * Individual notification card component
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var notification: null
    property bool dismissible: true
    property bool autoHide: notification?.autoHide ?? true
    property int elapsedMs: 0
    property int totalDuration: notification?.duration ?? 3000

    readonly property bool hasAction: !!(notification && notification.actionLabel)

    readonly property color accentColor: {
        if (!notification)
            return Style.colors.notificationInfoIcon

        switch (notification.type) {
            case "success":
                return Style.colors.notificationSuccessIcon
            case "warning":
                return Style.colors.notificationWarningIcon
            case "error":
                return Style.colors.notificationErrorIcon
            case "info":
            default:
                return Style.colors.notificationInfoIcon
        }
    }

    readonly property string typeIcon: {
        if (!notification)
            return Style.icons.info

        switch (notification.type) {
            case "success":
                return Style.icons.circleCheck
            case "warning":
                return Style.icons.warning
            case "error":
                return Style.icons.circleExclamation
            case "info":
            default:
                return Style.icons.info
        }
    }

    /* Signals
     * ****************************************************************************************/
    signal closeRequested()
    signal actionRequested()

    /* Object Properties
     * ****************************************************************************************/
    readonly property int progressBarHeight: 2

    width: card.width + 5
    height: card.height + (root.autoHide ? progressBarHeight : 0)

    /* Children
     * ****************************************************************************************/
    // Accent background - peeks out from behind the card on the left and backs the progress bar
    Rectangle {
        id: accentRect
        anchors.fill: parent
        radius: 8
        color: root.accentColor
    }

    Rectangle {
        id: card
        anchors.right: parent.right
        anchors.top: parent.top
        width: 320
        height: 12 + contentColumn.implicitHeight + 12
        radius: 6
        color: Style.colors.secondaryBackground
        clip: true

        RowLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 8

            // Icon
            Text {
                Layout.alignment: Qt.AlignTop
                text: root.typeIcon
                font.family: Style.fontTypes.font6ProSolid
                font.pixelSize: Style.appFont.largePt
                color: root.accentColor
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Title
                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: notification?.title ?? ""
                        font.family: Style.fontTypes.inter
                        font.weight: 600
                        font.pixelSize: Style.appFont.mediumPt
                        color: Style.colors.foreground
                        elide: Text.ElideRight
                    }

                    // Timestamp
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        visible: text.length > 0
                        text: root.formatRelativeTime(notification?.timestamp)
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.mutedText
                    }

                    // Close button
                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        visible: root.dismissible

                        Rectangle {
                            width: 10
                            height: 1.5
                            radius: 1
                            color: closeMouseArea.containsMouse ? Style.colors.foreground : Style.colors.mutedText
                            anchors.centerIn: parent
                            rotation: 45
                        }

                        Rectangle {
                            width: 10
                            height: 1.5
                            radius: 1
                            color: closeMouseArea.containsMouse ? Style.colors.foreground : Style.colors.mutedText
                            anchors.centerIn: parent
                            rotation: -45
                        }

                        MouseArea {
                            id: closeMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeRequested()
                        }
                    }
                }

                // Message
                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: notification?.message ?? ""
                    font.family: Style.fontTypes.inter
                    font.weight: 400
                    font.pixelSize: Style.appFont.smallPt
                    color: Style.colors.mutedText
                    wrapMode: Text.WordWrap
                }

                // Action link
                RowLayout {
                    Layout.fillWidth: true
                    visible: root.hasAction
                    spacing: 4

                    Text {
                        text: (notification?.actionLabel ?? "") + "  " + Style.icons.arrowRight
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.smallPt
                        font.weight: 500
                        color: actionMouseArea.containsMouse ? Style.colors.accentHover : Style.colors.accent

                        MouseArea {
                            id: actionMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.actionRequested()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }

        /* Animations
         * ****************************************************************************************/
        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onEntered: parent.scale = 1.02
            onExited: parent.scale = 1.0
            onPressed: function(mouse) {
                mouse.accepted = false
            }
        }
    }

    // Auto-hide progress bar - flush against the card's bottom edge, backed by the accent rectangle
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: card.bottom
        height: root.progressBarHeight
        visible: root.autoHide
        color: Style.colors.secondaryBackground

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: {
                if (root.totalDuration <= 0)
                    return parent.width
                var remaining = Math.max(0, root.totalDuration - root.elapsedMs)
                return parent.width * (remaining / root.totalDuration)
            }
            color: root.accentColor
        }
    }

    /* Functions
     * ****************************************************************************************/
    function formatRelativeTime(timestamp) {
        if (!timestamp)
            return ""

        var date = timestamp
        if (typeof date === 'string')
            date = new Date(date)

        var diffMs = Date.now() - date.getTime()
        var seconds = Math.floor(diffMs / 1000)

        if (seconds < 60)
            return "now"

        var minutes = Math.floor(seconds / 60)
        if (minutes < 60)
            return minutes + "m"

        var hours = Math.floor(minutes / 60)
        if (hours < 24)
            return hours + "h"

        var days = Math.floor(hours / 24)
        if (days < 7)
            return days + "d"

        return Qt.formatDate(date, "MMM d")
    }

    /* Animations
     * ****************************************************************************************/
    NumberAnimation on opacity {
        id: fadeIn
        from: 0
        to: 1
        duration: 200
        easing.type: Easing.OutQuad
        running: true
    }
}
