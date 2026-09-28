import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * UnstagedFileListRow
 * Adds row actions for unstaged files: Stage (+), Discard, Open
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
    signal stageRequested(string filePath)
    signal discardRequested(string filePath)
    signal openRequested(string filePath)
    signal stashRequested(string filePath)

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
                    iconText: Style.icons.archive
                    tooltip: "Stash"
                    hoverTextColor: Style.colors.stashAmber
                    textColor: Style.colors.actionIconIdle
                    hoverBackgroundColor: Qt.rgba(Style.colors.stashAmber.r, Style.colors.stashAmber.g, Style.colors.stashAmber.b, 0.1)
                    onClicked: root.stashRequested(root.filePath)
                }

                ActionIconButton {
                    iconText: Style.icons.plus
                    tooltip: "Stage"
                    textColor: Style.colors.actionIconIdle
                    hoverTextColor: Style.colors.stageGreen
                    hoverBackgroundColor: Qt.rgba(Style.colors.stageGreen.r, Style.colors.stageGreen.g, Style.colors.stageGreen.b, 0.1)
                    onClicked: root.stageRequested(root.filePath)
                }

                ActionIconButton {
                    iconText: Style.icons.undo
                    tooltip: "Revert changes"
                    textColor: Style.colors.actionIconIdle
                    hoverTextColor: Style.colors.discardRed
                    hoverBackgroundColor: Qt.rgba(Style.colors.discardRed.r, Style.colors.discardRed.g, Style.colors.discardRed.b, 0.1)
                    onClicked: root.discardRequested(root.filePath)
                }
            }
        }
    }
}
