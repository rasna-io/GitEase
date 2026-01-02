import QtQuick
import QtQuick.Controls

import GitEase
import GitEase_Style


/*! ***********************************************************************************************
 * StackedDiff
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property var modelData

    required property Component hatch

    property int gutterWidth: 35

    property int padH: 8

    property int padV: 6

    readonly property bool hasOld: modelData.oldLine !== undefined && modelData.oldLine !== -1

    readonly property bool hasNew: modelData.newLine !== undefined && modelData.newLine !== -1

    readonly property string oldText:
        (modelData.content !== undefined && modelData.content !== null)
        ? String(modelData.content) : ""

    readonly property string newText:
        (modelData.contentNew !== undefined && modelData.contentNew !== null)
        ? String(modelData.contentNew) : ""

    readonly property bool hasNewText: newText.length > 0

    readonly property string effectiveNewText: hasNewText ? newText : oldText

    readonly property bool isRemovedOnly: hasOld && !hasNew

    readonly property bool isAddedOnly: !hasOld && hasNew

    readonly property bool isModified: hasOld && hasNew && (hasNewText ? newText !== oldText : false)

    readonly property bool isUnchanged: hasOld && hasNew && !isModified

    readonly property bool showTop: hasOld

    readonly property bool showBottom: hasNew && !isUnchanged


    /* Object Properties
     * ****************************************************************************************/
    width: parent ? parent.width : 0
    implicitHeight:
        topBlock.implicitHeight
        + bottomBlock.implicitHeight
        + ((topBlock.visible && bottomBlock.visible) ? 2 : 0)

    /* Children
     * ****************************************************************************************/
    Column {
        anchors.fill: parent
        spacing: 2

        Rectangle {
            id: topBlock
            width: parent.width
            visible: root.showTop
            implicitHeight: visible ? (topRow.implicitHeight + root.padV * 2) : 0

            color: (root.isRemovedOnly || root.isModified)
                   ? Style.colors.diffRemovedBg
                   : Style.colors.primaryBackground

            Loader {
                anchors.fill: parent
                active: root.isRemovedOnly
                sourceComponent: active ? root.hatch : null
                opacity: 0.08
            }

            Row {
                id: topRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.padH
                anchors.topMargin: root.padV
                spacing: 8

                Text {
                    width: root.gutterWidth
                    text: root.hasOld ? modelData.oldLine : ""
                    color: Style.colors.mutedText
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignTop
                }

                Text {
                    width: parent.width - root.gutterWidth - topRow.spacing
                    text: root.oldText
                    color: Style.colors.foreground
                    font.family: "Consolas"
                    font.pixelSize: 12
                    wrapMode: Text.WrapAnywhere
                    textFormat: Text.PlainText
                }
            }
        }

        Rectangle {
            id: bottomBlock
            width: parent.width
            visible: root.showBottom
            implicitHeight: visible ? (bottomRow.implicitHeight + root.padV * 2) : 0

            color: (root.isAddedOnly || root.isModified)
                   ? Style.colors.diffAddedBg
                   : Style.colors.primaryBackground


            Loader {
                anchors.fill: parent
                active: root.isAddedOnly
                sourceComponent: active ? root.hatch : null
                opacity: 0.08
            }

            Row {
                id: bottomRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.padH
                anchors.topMargin: root.padV
                spacing: 8

                Text {
                    width: root.gutterWidth
                    text: root.hasNew ? modelData.newLine : ""
                    color: Style.colors.mutedText
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignTop
                }

                Text {
                    width: parent.width - root.gutterWidth - bottomRow.spacing
                    text: root.isModified
                          ? root.newText
                          : (root.isAddedOnly ? root.effectiveNewText : "")
                    color: Style.colors.foreground
                    font.family: "Consolas"
                    font.pixelSize: 12
                    wrapMode: Text.WrapAnywhere
                    textFormat: Text.PlainText
                }
            }
        }
    }
}
