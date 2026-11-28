import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailChip
 * Small rounded label with an optional icon, tinted by a single colour.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string text: ""
    property string iconText: ""
    property color  tint: Style.colors.accent
    property bool   mono: false

    property bool   shown: true

    property string displayedText: root.text
    property string displayedIcon: root.iconText
    property real   openProgress: root.shown ? 1.0 : 0.0

    /* Object Properties
     * ****************************************************************************************/
    radius: height / 2
    color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.10)
    border.width: 1
    border.color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.26)
    implicitHeight: chipRow.implicitHeight + Style.dp(6)
    implicitWidth: (chipRow.implicitWidth + Style.dp(18)) * root.openProgress
    visible: root.openProgress > 0
    opacity: root.openProgress
    scale: 0.85 + 0.15 * root.openProgress
    clip: true

    Behavior on openProgress {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    onTextChanged: {
        if(root.text !== "") {
            root.displayedText = root.text
        }
    }

    onIconTextChanged: {
        if(root.iconText !== "") {
            root.displayedIcon = root.iconText
        }
    }

    /* Children
     * ****************************************************************************************/
    Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: Style.dp(5)

        Text {
            visible: root.displayedIcon !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.displayedIcon
            font.family: Style.fontTypes.font6Pro
            font.styleName: "Solid"
            font.pixelSize: Style.appFont.captionPt
            color: root.tint
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.displayedText
            color: root.tint
            font.pixelSize: Style.appFont.smallPt
            font.weight: Font.DemiBold
            font.family: root.mono ? Style.fontTypes.jetBrainsMono : Style.fontTypes.inter
        }
    }
}
