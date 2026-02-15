import QtQuick
import QtQuick.Controls
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

    /* Signals
     * ****************************************************************************************/
    signal closeRequested()

    /* Object Properties
     * ****************************************************************************************/
    width: 320
    height: contentColumn.height + 24
    radius: 4
    color: {
        if (!notification)
            return Style.colors.cardBackground
        
        switch (notification.type) {
            case "success":
                return Style.colors.notificationSuccess
            case "warning":
                return Style.colors.notificationWarning
            case "error":
                return Style.colors.notificationError
            case "info":
            default:
                return Style.colors.notificationInfo
        }
    }

    border.width: 1
    border.color: {
        if (!notification)
            return Style.colors.primaryBorder
        
        switch (notification.type) {
            case "success":
                return Style.colors.notificationSuccessBorder
            case "warning":
                return Style.colors.notificationWarningBorder
            case "error":
                return Style.colors.notificationErrorBorder
            case "info":
            default:
                return Style.colors.notificationInfoBorder
        }
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Image {
                Layout.preferredWidth: 50
                Layout.preferredHeight: 14
                source: "qrc:/GitEase/Resources/Images/Logo.svg"
                fillMode: Image.PreserveAspectFit
            }

            Item {
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Icon
            Text {
                Layout.alignment: Qt.AlignVCenter
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
                        return Style.colors.foreground
                    
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

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: notification?.title ?? ""
                    visible: text.length > 0
                    font.family: Style.fontTypes.roboto
                    font.weight: 600
                    font.pixelSize: 14
                    color: {
                        if (!notification)
                            return Style.colors.foreground

                        switch (notification.type) {
                            case "success":
                                return Style.colors.notificationSuccessText
                            case "warning":
                                return Style.colors.notificationWarningText
                            case "error":
                                return Style.colors.notificationErrorText
                            case "info":
                            default:
                                return Style.colors.notificationInfoText
                        }
                    }
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: notification?.message ?? ""
                    font.family: Style.fontTypes.roboto
                    font.weight: 400
                    font.pixelSize: 11
                    color: {
                        if (!notification)
                            return Style.colors.foreground

                        switch (notification.type) {
                            case "success":
                                return Style.colors.notificationSuccessText
                            case "warning":
                                return Style.colors.notificationWarningText
                            case "error":
                                return Style.colors.notificationErrorText
                            case "info":
                            default:
                                return Style.colors.notificationInfoText
                        }
                    }
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 4
                color: closeMouseArea.containsMouse ? "red" : "transparent"
                visible: root.dismissible

                Rectangle {
                    width: 12
                    height: 2
                    radius: 1
                    color: {
                        if (!notification)
                            return Style.colors.foreground

                        switch (notification.type) {
                            case "success":
                                return Style.colors.notificationSuccessText
                            case "warning":
                                return Style.colors.notificationWarningText
                            case "error":
                                return Style.colors.notificationErrorText
                            case "info":
                            default:
                                return Style.colors.notificationInfoText
                        }
                    }
                    anchors.centerIn: parent
                    rotation: 45
                }

                Rectangle {
                    width: 12
                    height: 2
                    radius: 1
                    color: {
                        if (!notification)
                            return Style.colors.foreground

                        switch (notification.type) {
                            case "success":
                                return Style.colors.notificationSuccessText
                            case "warning":
                                return Style.colors.notificationWarningText
                            case "error":
                                return Style.colors.notificationErrorText
                            case "info":
                            default:
                                return Style.colors.notificationInfoText
                        }
                    }
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
