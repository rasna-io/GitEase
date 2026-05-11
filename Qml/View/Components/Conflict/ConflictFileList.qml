import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ConflictFileList
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    conflictFiles   : []
    property string currentPath     : ""

    /* Signals
     * ****************************************************************************************/
    signal fileSelected(string path)
    signal stageRequested(string path)

    /* Object Properties
     * ****************************************************************************************/
    Layout.preferredWidth: 240
    Layout.fillHeight: true
    radius: 4
    color: Style.colors.primaryBackground
    border.width: 1
    border.color: Style.colors.primaryBorder

    ListView {
        id: fileListView
        anchors.fill: parent
        model: root.conflictFiles
        spacing: 1
        currentIndex: {
            for (let i = 0; i < root.conflictFiles.length; ++i)
                if (root.conflictFiles[i].path === root.currentPath)
                    return i
            return -1
        }

        delegate: Rectangle {
            width: parent.width
            height: 24
            radius: 3
            color: ListView.isCurrentItem ? Style.colors.hoverTitle : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    text: (index + 1) + "."
                    color: Style.colors.lineNumberColor
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 12
                    opacity: 0.7
                }

                ScrollingText {
                    Layout.fillWidth: true
                    text: modelData.path || ""
                    font.family: Style.fontTypes.roboto
                    color: Style.colors.lineNumberColor
                    font.pixelSize: 13
                }

                Item {
                    Layout.fillWidth: true
                }

                ActionIconButton {
                    property bool canSave: !modelData.blocks || modelData.blocks.length === 0

                    iconText: Style.icons.plus
                    textColor: Style.colors.mutedText

                    opacity: canSave ? 1.0 : 0.5

                    tooltip: canSave ? "Save and Stage" : "Resolve conflicts to stage"

                    onClicked: {
                        if (canSave) {
                            root.fileSelected(modelData.path)
                            root.stageRequested(modelData.path)
                        }
                    }
                }
            }

            TapHandler {
                onTapped: root.fileSelected(modelData.path)
                gesturePolicy: TapHandler.ReleaseWithinBounds
            }
        }
    }
}
