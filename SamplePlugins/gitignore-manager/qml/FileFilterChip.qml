import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * FileFilterChip
 * Rounded filter button with a count; the chips of a category carry that category's colour.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string key:    ""
    property string label:  ""
    property int    count:  0
    property bool   active: false

    readonly property var statusOfKey: ({ changes: "modified", untracked: "untracked", ignored: "ignored",
                                          committed: "committed", trackedIgnored: "conflicted" })

    /* Signals
     * ****************************************************************************************/
    signal clicked()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: Style.dp(28)
    implicitWidth: chipRow.implicitWidth + Style.dp(20)
    radius: height / 2
    color: active ? Style.colors.accentWash : chipHover.hovered ? Style.colors.controlBackgroundHover
                                                                 : Style.colors.controlBackground
    border.width: 1
    border.color: active ? Style.colors.accent : Style.colors.controlBorder

    Behavior on color { ColorAnimation { duration: Style.motionFast } }

    /* Children
     * ****************************************************************************************/
    HoverHandler {
        id: chipHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler { onTapped: root.clicked() }

    Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: Style.dp(6)

        // Only its colours are used for the dot.
        GitignoreStatusBadge {
            id: swatchSource
            visible: false
            status: root.statusOfKey[root.key] || "committed"
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.statusOfKey[root.key] !== undefined
            width: Style.dp(8)
            height: Style.dp(8)
            radius: width / 2
            color: swatchSource.fillColor
            border.width: 1
            border.color: swatchSource.look.border
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.captionPt
            font.weight: root.active ? Font.DemiBold : Font.Medium
            color: root.active ? Style.colors.accent : Style.colors.secondaryText
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.count
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.microPt
            font.weight: Font.Medium
            color: root.active ? Style.colors.accent : Style.colors.pluginCountPillText
        }
    }
}
