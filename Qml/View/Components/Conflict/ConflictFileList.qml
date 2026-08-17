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
    Layout.preferredWidth: 250
    Layout.fillHeight: true
    color: Style.colors.secondaryBackground

    /* Children
     * ****************************************************************************************/
    ScrollView {
        id: scroll
        anchors.fill: parent
        anchors.topMargin: 6
        clip: true

        contentWidth: availableWidth

        ColumnLayout {
            spacing: 0
            width: scroll.availableWidth

            SectionLabel {
                Layout.fillWidth: true
                visible: root.conflictFiles.length > 0
                text: `CONFLICTS (${root.conflictFiles.length})`
            }

            Repeater {
                model: root.conflictFiles
                delegate: fileDelegate
            }

            SectionLabel {
                Layout.fillWidth: true
                Layout.topMargin: root.conflictFiles.length > 0 ? 8 : 0
                visible: root.stagedFiles.length > 0
                text: `RESOLVED (${root.stagedFiles.length})`
            }

            Repeater {
                model: root.stagedFiles
                delegate: fileDelegate
            }
        }
    }

    /* Components
     * ****************************************************************************************/
    Component {
        id: fileDelegate

        Item {
            id: delegateItem

            required property var modelData

            readonly property bool isStaged  : root.stagedFiles.some(f => f.path === modelData.path)
            readonly property bool isCurrent : root.currentPath === modelData.path
            readonly property bool hasMarkers: modelData.blocks !== undefined
                                               && modelData.blocks.length > 0

            Layout.fillWidth: true
            Layout.preferredHeight: Style.dp(30)

            Rectangle {
                anchors.fill: parent
                color: {
                    if (delegateItem.isCurrent)
                        return Style.colors.conflictFileSelectedBg

                    return hoverHandler.hovered ? Style.colors.cardBackground : "transparent"
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 3
                radius: 1.5
                visible: delegateItem.isCurrent
                color: Style.colors.accent
            }

            HoverHandler {
                id: hoverHandler
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: root.fileSelected(delegateItem.modelData.path)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 8
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    // Tick / Cross
                Text {
                    Layout.preferredWidth: 14
                    horizontalAlignment: Text.AlignHCenter
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.appFont.captionPt

                    text: delegateItem.hasMarkers ? Style.icons.circleExclamation
                                                  : Style.icons.circleCheck

                    color: {
                        if (delegateItem.hasMarkers)
                            return Style.colors.conflictStatusConflictColor

                        if (delegateItem.modelData.status === "A")
                            return Style.colors.conflictStatusAddedColor

                        return Style.colors.conflictStatusAddedColor
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: delegateItem.modelData.path || ""
                    color: delegateItem.isCurrent ? Style.colors.accent : Style.colors.mutedText
                    font.family: Style.fontTypes.inter
                    font.weight: delegateItem.isCurrent ? Font.DemiBold : Font.Normal
                    font.pixelSize: Style.appFont.smallPt
                    elide: Text.ElideLeft

                    ToolTip {
                        visible: hoverHandler.hovered && parent.truncated
                        text: delegateItem.modelData.path || ""
                        delay: 500
                    }
                }

                ActionIconButton {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    opacity: !delegateItem.isStaged && hoverHandler.hovered ? 1 : 0
                    iconText: Style.icons.plus
                    textColor: Style.colors.mutedText
                    tooltip: "Stage Changes"

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    onClicked: {
                        root.fileSelected(delegateItem.modelData.path)
                        root.stageRequested(delegateItem.modelData.path)
                    }
                }
            }
        }
    }
}
