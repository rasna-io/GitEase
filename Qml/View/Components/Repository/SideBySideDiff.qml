import QtQuick
import QtQuick.Controls

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * SideBySideDiff
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

    property int gap: 2

    readonly property int rowHeight: Math.ceil(Math.max(leftBlock.implicitHeight, rightBlock.implicitHeight))

    /* Object Properties
     * ****************************************************************************************/
    width: parent ? parent.width : 0
    implicitHeight: content.height

    /* Children
     * ****************************************************************************************/
    Item {
        id: content
        width: parent.width
        height: root.rowHeight

        Row {
            id: row
            anchors.fill: parent
            spacing: root.gap

            Rectangle {
                id: leftBlock
                width: (parent.width - root.gap) / 2
                height: parent.height

                color: (modelData.type === 2 || modelData.type === 3)
                       ? Style.colors.diffRemovedBg
                       : Style.colors.primaryBackground

                implicitHeight: leftRow.implicitHeight + root.padV * 2

                Loader {
                    anchors.fill: parent
                    active: root.modelData.type === 1
                    sourceComponent: active ? root.hatch : null
                    opacity: 0.08
                }

                Row {
                    id: leftRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: root.padH
                    anchors.topMargin: root.padV
                    spacing: 8

                    Text {
                        width: root.gutterWidth
                        text: root.modelData.oldLine !== -1 ? root.modelData.oldLine : ""
                        color: Style.colors.mutedText
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignTop
                    }

                    Text {
                        width: parent.width - root.gutterWidth - leftRow.spacing
                        text: root.modelData.type !== 1 ? root.modelData.content : ""
                        color: Style.colors.foreground
                        font.family: "Consolas"
                        font.pixelSize: 12
                        wrapMode: Text.WrapAnywhere
                        textFormat: Text.PlainText
                        verticalAlignment: Text.AlignTop
                    }
                }
            }

            Rectangle {
                id: rightBlock
                width: (parent.width - root.gap) / 2
                height: parent.height

                color: (modelData.type === 1 || modelData.type === 3)
                       ? Style.colors.diffAddedBg
                       : Style.colors.primaryBackground

                implicitHeight: rightRow.implicitHeight + root.padV * 2

                Loader {
                    anchors.fill: parent
                    active: root.modelData.type === 2
                    sourceComponent: active ? root.hatch : null
                    opacity: 0.08
                }

                Row {
                    id: rightRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: root.padH
                    anchors.topMargin: root.padV
                    spacing: 8

                    Text {
                        width: root.gutterWidth
                        text: root.modelData.newLine !== -1 ? root.modelData.newLine : ""
                        color: Style.colors.mutedText
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignTop
                    }

                    Text {
                        width: parent.width - root.gutterWidth - rightRow.spacing

                        text: root.modelData.type === 3 ? root.modelData.contentNew
                              : (root.modelData.type !== 2 ? root.modelData.content : "")

                        color: Style.colors.foreground
                        font.family: "Consolas"
                        font.pixelSize: 12
                        wrapMode: Text.WrapAnywhere
                        textFormat: Text.PlainText
                        verticalAlignment: Text.AlignTop
                    }
                }
            }
        }
    }
}
