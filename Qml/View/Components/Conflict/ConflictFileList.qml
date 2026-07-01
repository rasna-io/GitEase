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
        id: scroll
        anchors.fill: parent
        clip: true

        contentWidth: availableWidth

        ColumnLayout {
            spacing: 0
            width: scroll.availableWidth

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
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 3

            property bool isResolved: {
                if (modelData && modelData.blocks !== undefined)
                    return modelData.blocks.length === 0

                return true
            }
            property bool isStaged  : root.stagedFiles && root.stagedFiles.some(f => f.path === modelData.path)
            property bool isCurrent : root.currentPath === modelData.path
            property bool isHovered : hoverHandler.hovered

            color: isCurrent ? Style.colors.hoverTitle : "transparent"

            HoverHandler {
                id: hoverHandler
            }

            TapHandler {
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: root.fileSelected(modelData.path)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                ScrollingText {
                    Layout.fillWidth: true
                    text: modelData.path || ""
                    font.family: Style.fontTypes.roboto
                    color: Style.colors.lineNumberColor
                    font.pixelSize: 13
                }

                ActionIconButton {
                    property bool canSave: isResolved && !isStaged
                    visible: !isStaged && hoverHandler.hovered
                    opacity: 1.0
                    iconText: Style.icons.plus
                    textColor: Style.colors.mutedText
                    tooltip: canSave ? "Save and Stage" : "Resolve conflicts to stage"

                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    onClicked: {
                        if (canSave) {
                            root.fileSelected(modelData.path)
                            root.stageRequested(modelData.path)
                        }
                    }
                }

                Text {
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 11
                    font.bold: true
                    Layout.preferredWidth: 14
                    horizontalAlignment: Text.AlignHCenter

                    text: {
                        // Determine status based on data source
                        if (modelData.blocks !== undefined) {
                            // It's a conflict file
                            return modelData.blocks.length > 0 ? "!" : "M"
                        } else {
                            // It's a staged file (from stagedFiles)
                            return modelData.status || "M"
                        }
                    }
                    color: {
                        if (modelData.blocks !== undefined && modelData.blocks.length > 0)
                            return Style.colors.conflictStatusConflictColor

                        if (modelData.status === "A")
                            return Style.colors.conflictStatusAddedColor

                        return Style.colors.conflictStatusModifiedColor
                    }
                }
            }
        }
    }
}
