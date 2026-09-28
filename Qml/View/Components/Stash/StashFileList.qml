import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * StashFileList
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    files:          []
    property string currentPath:    ""
    property string sectionTitle:   "FILES"
    property string emptyText:      "No files"

    /* Signals
     * ****************************************************************************************/
    signal fileSelected(string path)

    /* Object Properties
     * ****************************************************************************************/
    Layout.preferredWidth: 250
    Layout.fillHeight: true
    color: Style.colors.secondaryBackground

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 6
        spacing: 0

        SectionLabel {
            Layout.fillWidth: true
            text: `${root.sectionTitle} (${root.files.length})`
        }

        ListView {
            id: fileListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.files

            ScrollBar.vertical: ScrollBar { }

            delegate: Item {
                id: delegateItem

                required property var modelData

                readonly property bool isCurrent: root.currentPath === delegateItem.modelData.path

                width: fileListView.width
                height: Style.dp(30)

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

                    Text {
                        Layout.preferredWidth: 14
                        horizontalAlignment: Text.AlignHCenter
                        text: delegateItem.modelData.statusText || "?"
                        color: delegateItem.modelData.statusColor || Style.colors.mutedText
                        font.family: Style.fontTypes.jetBrainsMono
                        font.weight: Font.DemiBold
                        font.pixelSize: Style.appFont.captionPt
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

                    Text {
                        visible: (delegateItem.modelData.additions || 0) > 0
                        text: `+${delegateItem.modelData.additions}`
                        color: Style.colors.conflictStatusAddedColor
                        font.family: Style.fontTypes.jetBrainsMono
                        font.pixelSize: Style.appFont.microPt
                    }

                    Text {
                        visible: (delegateItem.modelData.deletions || 0) > 0
                        text: `-${delegateItem.modelData.deletions}`
                        color: Style.colors.conflictStatusConflictColor
                        font.family: Style.fontTypes.jetBrainsMono
                        font.pixelSize: Style.appFont.microPt
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.files.length === 0
        text: root.emptyText
        color: Style.colors.mutedText
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.smallPt
    }
}
