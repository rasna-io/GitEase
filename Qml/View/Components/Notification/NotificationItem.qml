import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * NotificationItem
 * Individual notification card component
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var notification: null
    property bool dismissible: true
    property bool autoHide: notification?.autoHide ?? true
    property int elapsedMs: 0
    property int totalDuration: notification?.duration ?? 3000

    /* Signals
     * ****************************************************************************************/
    signal closeRequested()

    /* Object Properties
     * ****************************************************************************************/
    width: 320
    height: contentColumn.implicitHeight
    radius: 5
    color: Style.colors.secondaryBackground

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: contentColumn
        width: parent.width
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 35
            color: Style.colors.primaryBackground
            radius: 8
            
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 5
                color: Style.colors.primaryBackground
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                
                // Icon
                Text {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    text: {
                        if (!notification)
                            return Style.icons.info
                        
                        switch (notification.type) {
                            case "success":
                                return Style.icons.check
                            case "warning":
                                return Style.icons.warning
                            case "error":
                                return Style.icons.circleExclamation
                            case "info":
                            default:
                                return Style.icons.info
                        }
                    }
                    font.family: Style.fontTypes.font6ProSolid
                    font.pixelSize: 18
                    color: {
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
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                // Title
                Text {
                    Layout.fillWidth: true
                    text: notification?.title ?? ""
                    font.family: Style.fontTypes.roboto
                    font.weight: 600
                    font.pixelSize: 14
                    color: Style.colors.foreground
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
                
                // Close button
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    radius: 4
                    color: closeMouseArea.containsMouse ? "red" : "transparent"
                    visible: root.dismissible

                    Rectangle {
                        width: 12
                        height: 2
                        radius: 1
                        color: Style.colors.foreground
                        anchors.centerIn: parent
                        rotation: 45
                    }

                    Rectangle {
                        width: 12
                        height: 2
                        radius: 1
                        color: Style.colors.foreground
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
        }

        Text {
            Layout.fillWidth: true
            Layout.margins: 12
            text: notification?.message ?? ""
            font.family: Style.fontTypes.roboto
            font.weight: 400
            font.pixelSize: 11
            color: Style.colors.foreground
            wrapMode: Text.WordWrap
        }
        
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            Layout.topMargin: 0
            Layout.bottomMargin: 0
            
            Rectangle {
                visible: root.autoHide
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 4
                color: Style.colors.secondaryBackground
                radius: 8

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom                    
                    width: {
                        if (root.totalDuration <= 0)
                            return 0
                        return parent.width * (root.elapsedMs / root.totalDuration)
                    }
                    radius: 8
                    color: {
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
                }
            }
            
            Text {
                visible: !root.autoHide
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (!notification?.timestamp)
                        return ""

                    var date = notification.timestamp
                    if (typeof date === 'string')
                        date = new Date(date)
                    
                    var year = date.getFullYear()
                    var month = String(date.getMonth() + 1).padStart(2, '0')
                    var day = String(date.getDate()).padStart(2, '0')
                    var hours = String(date.getHours()).padStart(2, '0')
                    var minutes = String(date.getMinutes()).padStart(2, '0')
                    
                    return year + "/" + month + "/" + day + " " + hours + ":" + minutes
                }
                font.pixelSize: 9
                color: Style.colors.mutedText
            }
        }
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
