import QtQuick
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * CommitPreviewPane
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string commitSummary:  ""
    property bool   expanded:       false
    property int    expandedHeight: Style.dp(240)
    property int    contentInset:   Style.dp(16)
    default property alias content: contentHolder.data
    readonly property int collapsedHeight: Style.dp(30)
    property real animatedHeight: root.expanded ? root.expandedHeight : root.collapsedHeight

    Behavior on animatedHeight {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: root.collapsedHeight

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: bar

            Layout.fillWidth: true
            Layout.preferredHeight: root.collapsedHeight
            color: "transparent"

            HoverHandler {
                id: barHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: root.expanded = !root.expanded
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.contentInset
                anchors.rightMargin: root.contentInset
                spacing: 8

                Text {
                    text: "Commit Preview"
                    color: barHover.hovered ? Style.colors.foreground : Style.colors.secondaryText
                    font.family: Style.fontTypes.inter
                    font.weight: Font.Medium
                    font.pixelSize: Style.appFont.captionPt
                }

                Text {
                    Layout.fillWidth: true
                    text: root.commitSummary
                    color: Style.colors.mutedText
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.captionPt
                    elide: Text.ElideRight
                }

                Text {
                    text: root.expanded ? Style.icons.caretDown : Style.icons.caretUp
                    color: Style.colors.mutedText
                    font.family: Style.fontTypes.font6ProSolid
                    font.pixelSize: Style.appFont.microPt
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            visible: root.expanded
            color: Style.colors.primaryBorder
        }

        Item {
            id: contentHolder
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.expanded
        }
    }
}
