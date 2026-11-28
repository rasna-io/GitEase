import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * StagedFileListRow
 * Adds row actions for staged files: Unstage (-), Open
 * ************************************************************************************************/

FileListRow {
    id: root

    /* Object Properties
     * ****************************************************************************************/
    readonly property string filePath: root.text
    property bool actionHovered: false
    readonly property bool showActionBar: root.selected || root.isHovered || root.actionHovered

    /* Signals
     * ****************************************************************************************/
    signal unstageRequested(string filePath)
    signal openRequested(string filePath)

    /* Children
     * ****************************************************************************************/
    rightAccessory: Component {
        Rectangle {
            id: actionPill
            implicitWidth: actionBar.implicitWidth + 4
            implicitHeight: actionBar.implicitHeight + 2
            radius: 4
            color: Style.colors.actionPillBg
            border.width: 1
            border.color: Style.colors.actionPillBorder

            HoverHandler {
                acceptedDevices: PointerDevice.Mouse
                onHoveredChanged: root.actionHovered = hovered
            }

            visible: root.showActionBar
            opacity: visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                }
            }

            RowLayout {
                id: actionBar
                anchors.centerIn: parent
                spacing: 1

                ActionIconButton {
                    iconText: Style.icons.file
                    tooltip: "Open"
                    textColor: Style.colors.actionIconIdle
                    hoverTextColor: Style.colors.openBlue
                    hoverBackgroundColor: Qt.rgba(Style.colors.openBlue.r, Style.colors.openBlue.g, Style.colors.openBlue.b, 0.1)
                    onClicked: root.openRequested(root.filePath)
                }

                ActionIconButton {
                    iconText: Style.icons.minus
                    tooltip: "Unstage"
                    textColor: Style.colors.actionIconIdle
                    hoverTextColor: Style.colors.discardRed
                    hoverBackgroundColor: Qt.rgba(Style.colors.discardRed.r, Style.colors.discardRed.g, Style.colors.discardRed.b, 0.1)
                    onClicked: root.unstageRequested(root.filePath)
                }
            }
        }
    }
}
