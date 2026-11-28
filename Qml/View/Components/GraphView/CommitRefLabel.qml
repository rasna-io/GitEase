import QtQuick
import QtQuick.Layouts

import GitEase_Style

import "qrc:/GitEase/Qml/Core/Scripts/GraphUtils.js" as GraphUtils

/*! ***********************************************************************************************
 * CommitRefLabel
 * A branch or tag pill shown next to a commit node. Shrinks (eliding its text) when space is short.
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string text    : ""
    property bool   isTag   : false

    readonly property color contrastColor: GraphUtils.getContrastColor(color.toString())

    /* Object Properties
     * ****************************************************************************************/
    // Room for the icon (tags), one character and the ellipsis
    readonly property real minimumWidth: isTag ? 44 : 26

    implicitWidth   : (tagIcon.visible ? tagIcon.implicitWidth + labelRow.spacing : 0) + nameText.implicitWidth + 8
    implicitHeight  : 20
    radius          : 2
    opacity         : 0.95

    /* Children
     * ****************************************************************************************/
    Row {
        id: labelRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 4
        width: Math.max(0, root.width - 8)
        spacing: 4

        Text {
            id: tagIcon
            visible: root.isTag
            anchors.verticalCenter: parent.verticalCenter
            text: Style.icons.tag
            color: root.contrastColor
            font.family: Style.fontTypes.font6Pro
            font.weight: Font.Black
            font.pixelSize: 9
        }

        Text {
            id: nameText
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, Math.max(0, labelRow.width - (tagIcon.visible ? tagIcon.implicitWidth + labelRow.spacing : 0)))
            text: root.text
            color: root.contrastColor
            elide: Text.ElideRight
            font.family: Style.fontTypes.inter
            font.weight: Font.Bold
            font.pixelSize: 11
        }
    }
}
