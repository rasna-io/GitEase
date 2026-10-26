import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailTab
 * Single tab with an optional count pill and an underline when active.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string label: ""
    property int    count: -1
    property bool   active: false
    property color  tint: Style.colors.accent

    /* Signals
     * ****************************************************************************************/
    signal clicked()

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: tabRow.implicitWidth
    implicitHeight: tabRow.implicitHeight + Style.dp(22)

    /* Children
     * ****************************************************************************************/
    Row {
        id: tabRow
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        spacing: Style.dp(7)

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.active || tabHover.hovered ? Style.colors.pluginCardTitle
                                                   : Style.colors.pluginSectionLabel
            font.pixelSize: Style.appFont.mediumPt
            font.weight: root.active ? Font.DemiBold : Font.Medium
            font.family: Style.fontTypes.inter
        }

        Rectangle {
            visible: root.count > 0
            anchors.verticalCenter: parent.verticalCenter
            radius: height / 2
            color: root.active ? Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.14)
                               : Style.colors.pluginCountPillBackground
            implicitWidth: Math.max(implicitHeight, countLabel.implicitWidth + Style.dp(12))
            implicitHeight: countLabel.implicitHeight + Style.dp(4)

            Label {
                id: countLabel
                anchors.centerIn: parent
                text: root.count
                color: root.active ? root.tint : Style.colors.pluginCountPillText
                font.pixelSize: Style.appFont.captionPt
                font.weight: Font.DemiBold
                font.family: Style.fontTypes.inter
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        radius: 1
        color: root.tint
        opacity: root.active ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 140
            }
        }
    }

    HoverHandler {
        id: tabHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.clicked()
    }
}
