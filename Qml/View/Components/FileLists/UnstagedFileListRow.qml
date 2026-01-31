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
                iconText: Style.icons.plus
                tooltip: "Stage"
                textColor: Style.theme == Style.Light ?
                            Qt.darker(Style.colors.addedFile, 1.5) :
                            Qt.lighter(Style.colors.addedFile, 1.5)
                onClicked: root.stageRequested(root.filePath)
            }

            ActionIconButton {
                iconText: Style.icons.trash
                tooltip: "Discard"
                textColor: Style.colors.error
                onClicked: root.discardRequested(root.filePath)
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
