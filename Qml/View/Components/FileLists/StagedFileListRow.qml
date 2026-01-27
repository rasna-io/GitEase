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
        RowLayout {
            id: actionBar
            spacing: 2

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

            ActionIconButton {
                iconText: Style.icons.minus
                tooltip: "Unstage"
                textColor: Style.colors.deletededFile
                onClicked: root.unstageRequested(root.filePath)
            }

            ActionIconButton {
                iconText: Style.icons.file
                tooltip: "Open"
                textColor: Style.colors.secondaryText
                onClicked: root.openRequested(root.filePath)
            }
        }
    }
}
