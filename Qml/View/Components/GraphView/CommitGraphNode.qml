import QtQuick

import GitEase_Style
import GitEase_Style_Impl

import "qrc:/GitEase/Qml/Core/Scripts/GraphUtils.js" as GraphUtils

/*! ***********************************************************************************************
 * CommitGraphNode
 * The marker of a single commit: a circle (optionally with avatar) or a square stash badge.
 * Centered on its own geometry; the parent positions it by `center`.
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property color  branchColor : "gray"
    property bool   selected    : false
    property bool   isStash     : false
    property bool   showAvatar  : true
    property real   avatarSize  : 24

    readonly property real diameter     : showAvatar ? avatarSize : 10
    readonly property real borderWidth  : selected ? 4 : 2.5
    readonly property color borderColor : selected ? GraphUtils.darkenColor(branchColor, 0.2)
                                                   : GraphUtils.lightenColor(branchColor, 0.3)

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth   : diameter + borderWidth
    implicitHeight  : diameter + borderWidth

    /* Children
     * ****************************************************************************************/
    Rectangle {
        anchors.fill: parent
        radius: root.isStash ? 2 : width / 2
        antialiasing: true
        color: {
            if (root.isStash) {
                return root.branchColor
            }

            return root.showAvatar ? Style.colors.graphAvatarBackground
                                   : GraphUtils.lightenColor(root.branchColor, 0.3)
        }
        border.width: root.borderWidth
        border.color: root.borderColor
    }

    Image {
        visible: root.showAvatar && !root.isStash
        anchors.centerIn: parent
        width: 14
        height: 14
        source: "qrc:/GitEase/Resources/Images/defaultUserIcon.svg"
        sourceSize: Qt.size(Math.ceil(14 * Screen.devicePixelRatio), Math.ceil(14 * Screen.devicePixelRatio))
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    Text {
        visible: root.showAvatar && root.isStash
        anchors.centerIn: parent
        text: Style.icons.archive
        color: Style.colors.onColorText
        font.family: Style.fontTypes.font6Pro
        font.weight: Font.Black
        font.pixelSize: Math.round(root.diameter / 2)
    }
}
