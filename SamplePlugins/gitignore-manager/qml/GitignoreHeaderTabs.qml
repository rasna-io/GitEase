import QtQuick
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * GitignoreHeaderTabs
 * View switch of the page header: a pill with one tab per view and an optional count badge.
 * \a stretch makes the tabs share the full width.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! [{ key, label, icon, count }] where count is a string, empty for no badge.
    property var    tabs:    []
    property string current: ""
    property bool   stretch: false

    readonly property color hoverFill: Style.colors.controlBackgroundHover

    /* Signals
     * ****************************************************************************************/
    signal tabClicked(string key)

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: Style.dp(36)
    implicitWidth: tabsRow.implicitWidth + Style.dp(8)
    radius: Style.dp(10)
    color: Style.colors.controlBackground
    border.width: 1
    border.color: Style.colors.controlBorder

    /* Children
     * ****************************************************************************************/
    RowLayout {
        id: tabsRow
        anchors.fill: parent
        anchors.margins: Style.dp(4)
        spacing: Style.dp(4)

        Repeater {
            model: root.tabs

            delegate: Rectangle {
                id: tabItem

                required property var modelData
                readonly property bool selected: root.current === modelData.key

                Layout.fillWidth: root.stretch
                Layout.fillHeight: true
                Layout.preferredWidth: tabContent.implicitWidth + Style.dp(24)
                radius: Style.dp(7)
                color: selected ? Style.colors.pluginCardBackground
                     : tabHover.hovered ? root.hoverFill
                                        : Qt.rgba(root.hoverFill.r, root.hoverFill.g, root.hoverFill.b, 0)
                border.width: selected ? 1 : 0
                border.color: Style.colors.pluginCardBorder

                Behavior on color { ColorAnimation { duration: Style.motionFast } }

                HoverHandler {
                    id: tabHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler { onTapped: root.tabClicked(tabItem.modelData.key) }

                Row {
                    id: tabContent
                    anchors.centerIn: parent
                    spacing: Style.dp(7)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tabItem.modelData.icon
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: Style.appFont.microPt
                        color: tabItem.selected ? Style.colors.accent : Style.colors.mutedText
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tabItem.modelData.label
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        font.weight: tabItem.selected ? Font.DemiBold : Font.Medium
                        color: tabItem.selected ? Style.colors.foreground : Style.colors.secondaryText
                    }

                    GitignoreBadge {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: tabItem.modelData.count.length > 0
                        implicitHeight: Style.dp(17)
                        label: tabItem.modelData.count
                        strong: true
                        textColor: Style.colors.pluginCountPillText
                        fillColor: Style.colors.pluginCountPillBackground
                    }
                }
            }
        }
    }
}
