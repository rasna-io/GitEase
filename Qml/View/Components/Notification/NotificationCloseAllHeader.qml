import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import GitEase_Style

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
    Rectangle {
        anchors.fill: parent
        radius: 4
        color: Style.colors.cardBackground
        border.width: 1
        border.color: Style.colors.primaryBorder

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            // Text
            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                text: notificationCount + " notification" + (notificationCount > 1 ? "s" : "")
                font.family: Style.fontTypes.inter
                font.weight: 600
                font.pixelSize: Style.appFont.h3Pt
                color: Style.colors.foreground
            }

            // Close all button
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 80
                Layout.preferredHeight: 26
                radius: 4
                color: closeAllMouseArea.containsMouse ? Style.colors.accent : Style.colors.secondaryBackground
                border.width: 1
                border.color: Style.colors.accent

                Text {
                    anchors.centerIn: parent
                    text: "Close All"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt
                    font.weight: 600
                    color: closeAllMouseArea.containsMouse ? Style.colors.foreground : Style.colors.accent
                }

                MouseArea {
                    id: closeAllMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeAllRequested()
                }
            }
        }

        /* Animations
         * ****************************************************************************************/
        NumberAnimation on opacity {
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
    }
}
