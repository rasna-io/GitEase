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
    property var    stagedFiles     : []

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

    ScrollView {
        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 0

            // Conflict Changes header
            Text {
                visible: conflictFiles.length > 0
                text: "Conflict Changes"
                color: Style.colors.secondaryText
                font.family: Style.fontTypes.roboto
                font.bold: true
                font.pixelSize: 11
                leftPadding: 12
                topPadding: 6
                bottomPadding: 2
            }

            Repeater {
                model: conflictFiles
                delegate: fileDelegate
            }

            // Staged Changes header
            Text {
                visible: stagedFiles.length > 0
                text: "Staged Changes"
                color: Style.colors.secondaryText
                font.family: Style.fontTypes.roboto
                font.bold: true
                font.pixelSize: 11
                leftPadding: 12
                topPadding: 6
                bottomPadding: 2
            }

            Repeater {
                model: stagedFiles
                delegate: fileDelegate
            }
        }
    }

    Component {
        id: fileDelegate
        Rectangle {
            id: delegateItem
            width: parent.width
            height: 28
            radius: 3
            property bool isResolved: modelData && (!modelData.blocks || modelData.blocks.length === 0)
            property bool isStaged  : root.stagedFiles && root.stagedFiles.some(f => f.path === modelData.path)
            property bool isCurrent : root.currentPath === modelData.path

            color: {
                if (isCurrent)
                    return Style.colors.hoverTitle

                if (isResolved && !isStaged)
                    return Style.colors.conflictResolvedBg

                return "transparent"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 11
                    font.bold: true
                    Layout.preferredWidth: 14
                    horizontalAlignment: Text.AlignHCenter

                    text: {
                        if (modelData.blocks && modelData.blocks.length > 0)
                            return "!"

                        return "M"
                    }

                    color: {
                        if (modelData.blocks && modelData.blocks.length > 0)
                            return Style.colors.error

                        return Style.colors.mutedText
                    }

                    ToolTip {
                        text: {
                            if (modelData.blocks && modelData.blocks.length > 0)
                                return "Contains unresolved conflicts"

                            return "Index Modified"
                        }
                        visible: parent.hovered
                        delay: 500
                    }
                }

                ScrollingText {
                    Layout.fillWidth: true
                    text: modelData.path || ""
                    font.family: Style.fontTypes.roboto
                    color: Style.colors.lineNumberColor
                    font.pixelSize: 13
                }

                Item { Layout.fillWidth: true }

                ActionIconButton {
                    visible: !isStaged
                    property bool canSave: isResolved && !isStaged
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
