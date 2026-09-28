import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * ReleaseEmptyState
 * Centered icon, title, message and an optional action.
 * ************************************************************************************************/
ColumnLayout {
    id: root

    property string iconText:   ""
    property color  iconColor:  Style.colors.accent
    property color  iconFill:   Style.colors.accentWash
    property string title:      ""
    property string message:    ""
    property bool   busy:       false
    property string actionText: ""
    property string actionIcon: ""

    signal actionClicked()

    spacing: Style.dp(10)

    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Style.dp(64)
        Layout.preferredHeight: Style.dp(64)
        radius: Style.dp(18)
        color: root.iconFill

        BusyIndicator {
            anchors.centerIn: parent
            width: Style.dp(30)
            height: Style.dp(30)
            padding: 0
            visible: root.busy
            running: visible
            Material.accent: Style.colors.accent
        }

        Text {
            anchors.centerIn: parent
            visible: !root.busy
            text: root.iconText
            font.family: Style.fontTypes.font6Pro
            font.pixelSize: Style.appFont.h2Pt
            color: root.iconColor
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Style.dp(4)
        Layout.maximumWidth: Style.dp(440)
        text: root.title
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.largePt
        font.weight: Font.DemiBold
        color: Style.colors.pluginCardTitle
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: Style.dp(440)
        visible: text.length > 0
        text: root.message
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.captionPt
        color: Style.colors.pluginCardDescription
    }

    ReleaseButton {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Style.dp(6)
        visible: root.actionText.length > 0
        large: true
        iconText: root.actionIcon
        text: root.actionText
        onClicked: root.actionClicked()
    }
}
