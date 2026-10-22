import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

import "qrc:/GitEase/Qml/Core/Scripts/GraphUtils.js" as GraphUtils

/*! ***********************************************************************************************
 * CommitRow
 * One row of the commit list: graph slice + ref labels, message, author and date.
 * Owns its background (selected / head / uncommitted / hover) and pointer handling.
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property var commitData
    property var    graphRow        : null      // descriptor from CommitGraphRouting.buildRows
    property int    rowIndex        : -1
    property Item   parentRoot      : null      // item the click position is reported in

    property color  laneColor       : "gray"

    property bool   selected        : false
    property bool   isHead          : false
    property bool   isStash         : false
    property bool   showAvatar      : true

    property real   columnSpacing   : 30
    property real   nodeSize        : 24

    property real   graphWidth      : 0
    property real   refsWidth       : 0
    property real   messageWidth    : 0
    property real   authorWidth     : 0
    property real   dateWidth       : 0

    readonly property bool isHovered        : hoverHandler.hovered
    readonly property bool isUncommitted    : !!commitData && commitData.isUncommitted === true

    /* Signals
     * ****************************************************************************************/
    signal itemClicked(int mouseButton, int mouseModifiers, int index, real mouseX, real mouseY)
    signal itemDoubleClicked(int mouseButton, int mouseModifiers, int index)
    signal resetHeadOne()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: 32

    color: {
        if (root.selected) {
            return Style.colors.graphSelectedRowBg
        }

        if (root.isUncommitted) {
            return Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b,
                           root.isHovered ? 0.35 : 0.22)
        }

        if (root.isHovered) {
            return Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.15)
        }

        return root.isHead ? Style.colors.graphHeadRowBg : Style.colors.primaryBackground
    }

    /* Children
     * ****************************************************************************************/
    HoverHandler {
        id: hoverHandler
        acceptedDevices: PointerDevice.Mouse
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            let pos = root.parentRoot ? root.mapToItem(root.parentRoot, mouse.x, mouse.y)
                                      : Qt.point(mouse.x, mouse.y)
            root.itemClicked(mouse.button, mouse.modifiers, root.rowIndex, pos.x, pos.y)
        }

        onDoubleClicked: function(mouse) {
            root.itemDoubleClicked(mouse.button, mouse.modifiers, root.rowIndex)
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        CommitGraphCell {
            Layout.preferredWidth: root.graphWidth + root.refsWidth
            Layout.fillHeight: true

            graphRow: root.graphRow
            laneColor: root.laneColor
            selected: root.selected
            isStash: root.isStash
            showAvatar: root.showAvatar
            columnSpacing: root.columnSpacing
            graphWidth: root.graphWidth
            refsWidth: root.refsWidth
            nodeSize: root.nodeSize
        }

        RowLayout {
            Layout.preferredWidth: root.messageWidth
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                Layout.preferredWidth: 3
                Layout.preferredHeight: root.height * 0.6
                Layout.alignment: Qt.AlignVCenter
                radius: 6
                color: root.laneColor
            }

            Rectangle {
                visible: root.isStash
                Layout.preferredWidth: stashBadgeRow.implicitWidth + 10
                Layout.preferredHeight: 17
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4
                radius: 2
                color: root.laneColor

                Row {
                    id: stashBadgeRow
                    anchors.centerIn: parent
                    spacing: 3

                    Text {
                        text: Style.icons.archive
                        font.family: Style.fontTypes.font6Pro
                        font.styleName: "Solid"
                        font.pixelSize: Style.appFont.captionPt
                        color: GraphUtils.getContrastColor(root.laneColor.toString())
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        text: root.commitData ? (root.commitData.stashLabel || "stash") : ""
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        color: GraphUtils.getContrastColor(root.laneColor.toString())
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                text: root.commitData && root.commitData.summary ? root.commitData.summary : ""
                color: Style.colors.foreground
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: Style.appFont.smallPt
                font.family: Style.fontTypes.inter
                font.weight: root.isUncommitted ? 700 : (root.isHead ? 900 : 400)
                font.letterSpacing: 0.2
                elide: Text.ElideRight
            }

            // Reset HEAD~1 button, only on the HEAD commit
            Rectangle {
                visible: root.isHead
                Layout.preferredWidth: 22
                Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4
                Layout.rightMargin: 6
                radius: 3
                color: resetButtonArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                border.color: Qt.rgba(1, 1, 1, 0.15)

                Text {
                    anchors.centerIn: parent
                    text: "~"
                    color: resetButtonArea.containsMouse ? Style.colors.foreground : Qt.rgba(1, 1, 1, 0.55)
                    font.pixelSize: Style.appFont.defaultPt
                    font.family: Style.fontTypes.inter
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: resetButtonArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetHeadOne()
                }
            }
        }

        Label {
            Layout.preferredWidth: root.authorWidth
            Layout.fillHeight: true
            text: root.commitData ? (root.commitData.author || "") : ""
            color: Style.colors.foreground
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: Style.appFont.mediumPt
            elide: Text.ElideRight
        }

        Label {
            Layout.preferredWidth: root.dateWidth
            Layout.fillHeight: true
            text: root.commitData ? GraphUtils.formatDate(root.commitData.authorDate) + " "
                                    + GraphUtils.formatTime(root.commitData.authorDate) : ""
            color: Style.colors.foreground
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: Style.appFont.smallPt
            wrapMode: Text.NoWrap
        }
    }
}
