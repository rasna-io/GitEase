import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

import "qrc:/GitEase/Qml/Core/Scripts/GraphUtils.js" as GraphUtils

/*! ***********************************************************************************************
 * CommitListDelegate
 * ************************************************************************************************/

Rectangle {
    id: commitItem

    /* Property Declarations
     * ****************************************************************************************/
    property var    commitData      : typeof modelData !== "undefined" ? modelData : null

    property real   messageWidth    : 0
    property real   authorWidth     : 0
    property real   dateWidth       : 0

    property color  indicatorColor  : "gray"

    property bool   isSelected      : false
    property bool   isHead          : false
    property bool   isStash         : false

    property bool   isHovered       : mouseArea.containsMouse

    property Item   parentRoot      : null

    /* Signals
     * ****************************************************************************************/
    signal itemClicked(int mouseButton, int mouseModifiers, int _index, real mouseX, real mouseY)
    signal itemDoubleClicked(int mouseButton, int mouseModifiers, var _index)
    signal resetHeadOne()

    /* Object Properties
     * ****************************************************************************************/
    width   : ListView.view ? ListView.view.width : parent.width
    height  : 24 + 4*2

    radius  : (isSelected || isHovered) ? 4 : 0

    color: {
        if (!commitData)
            return Style.colors.primaryBackground;

        if (isSelected)
            return "#6088B2DF";

        if (commitData.isUncommitted) {
            return isHovered ? Qt.darker(Style.colors.hoverTitle, 1.03)
                             : (Style.colors.secondaryBackground || Style.colors.primaryBackground);
        }

        if (isHovered)
            return Style.colors.hoverTitle;

        if (isHead)
            return "#40FFA500";

        return Style.colors.primaryBackground;
    }

    /* Children
     * ****************************************************************************************/
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (mouse) => {
            var pos = parentRoot ? commitItem.mapToItem(parentRoot, mouse.x, mouse.y) : Qt.point(mouse.x, mouse.y)
            commitItem.itemClicked(mouse.button, mouse.modifiers, index, pos.x, pos.y)
        }

        onDoubleClicked: (mouse) => {
            commitItem.itemDoubleClicked(mouse.button, mouse.modifiers, index)
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        anchors.topMargin: 4
        anchors.bottomMargin: 4

        // Message column
        ColumnLayout {
            Layout.fillWidth: false
            Layout.preferredWidth: commitItem.messageWidth
            Layout.fillHeight: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true

                // Lane colour bar
                Rectangle {
                    Layout.preferredWidth: 3
                    Layout.preferredHeight: parent.height * 0.8
                    Layout.alignment: Qt.AlignVCenter
                    radius: 6
                    color: indicatorColor
                }

                // Stash badge
                Rectangle {
                    visible: commitItem.isStash
                    Layout.preferredWidth: stashBadgeRow.implicitWidth + 10
                    Layout.preferredHeight: 17
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 4
                    radius: 2
                    color: indicatorColor
                    Row {
                        id: stashBadgeRow
                        anchors.centerIn: parent
                        spacing: 3
                        Text {
                            text: Style.icons.archive
                            font.family: Style.fontTypes.font6Pro
                            font.styleName: "Solid"
                            font.pixelSize: Style.appFont.captionPt
                            color: GraphUtils.getContrastColor(indicatorColor.toString())
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            text: commitData ? (commitData.stashLabel || "stash") : ""
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.captionPt
                            color: GraphUtils.getContrastColor(indicatorColor.toString())
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                // Summary text
                Label {
                    text: (commitData && commitData.summary) ? commitData.summary : ""
                    color: Style.colors.foreground
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Style.appFont.smallPt
                    font.family: Style.fontTypes.inter
                    font.weight: commitData && commitData.isUncommitted ? 700 :
                                  (isHead ? 900 : 400)
                    font.letterSpacing: 0.2
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    elide: Text.ElideRight
                }

                // Reset HEAD~1 button — only on HEAD commit
                Rectangle {
                    visible: commitItem.isHead
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 6
                    Layout.leftMargin: 4
                    radius: 3
                    color: resetBtnArea.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06)
                    border.color: Qt.rgba(1,1,1,0.15)
                    z: 1

                    Text {
                        anchors.centerIn: parent
                        text: "~"
                        color: resetBtnArea.containsMouse ? Style.colors.foreground : Qt.rgba(1,1,1,0.55)
                        font.pixelSize: Style.appFont.defaultPt
                        font.family: Style.fontTypes.inter
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: resetBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: commitItem.resetHeadOne()
                    }
                }
            }
        }

        // Author column
        ColumnLayout {
            Layout.fillWidth: false
            Layout.preferredWidth: commitItem.authorWidth
            Layout.fillHeight: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: commitData ? (commitData.author || "") : ""
                    color: Style.colors.foreground
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Style.appFont.mediumPt
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                }
            }
        }

        // Date column
        ColumnLayout {
            Layout.fillWidth: false
            Layout.preferredWidth: commitItem.dateWidth
            Layout.fillHeight: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: commitData ? (
                        GraphUtils.formatDate(commitData.authorDate) + " " +
                        GraphUtils.formatTime(commitData.authorDate)
                    ) : ""
                    color: Style.colors.foreground
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Style.appFont.smallPt
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
                }
            }
        }
    }

}
