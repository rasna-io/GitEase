import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailTopBar
 * Breadcrumb bar with the back button and the plugin name.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string title: ""
    property bool   busy: false

    /* Signals
     * ****************************************************************************************/
    signal backRequested()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: Style.dp(48)
    color: Style.colors.pluginCardBackground

    /* Children
     * ****************************************************************************************/
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Style.colors.pluginDivider
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.dp(14)
        anchors.rightMargin: Style.dp(18)
        spacing: Style.dp(6)

        Button {
            id: backButton
            flat: true
            hoverEnabled: true
            topInset: 0
            bottomInset: 0
            leftInset: 0
            rightInset: 0
            topPadding: Style.dp(6)
            bottomPadding: Style.dp(6)
            leftPadding: Style.dp(10)
            rightPadding: Style.dp(12)

            background: Rectangle {
                radius: Style.dp(7)
                color: backButton.hovered ? Style.colors.pluginSidebarRowHoverBg : "transparent"
            }

            contentItem: Row {
                spacing: Style.dp(8)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Style.icons.arrowLeft
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.appFont.captionPt
                    color: backButton.hovered ? Style.colors.pluginSidebarRowActiveText
                                              : Style.colors.pluginSectionLabel
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Plugins"
                    color: backButton.hovered ? Style.colors.pluginSidebarRowActiveText
                                              : Style.colors.pluginSectionLabel
                    font.pixelSize: Style.appFont.mediumPt
                    font.weight: Font.Medium
                    font.family: Style.fontTypes.inter
                }
            }

            onClicked: root.backRequested()
        }

        Label {
            text: "/"
            color: Style.colors.pluginSectionMetaText
            font.pixelSize: Style.appFont.mediumPt
            font.family: Style.fontTypes.inter
        }

        Label {
            Layout.fillWidth: true
            Layout.leftMargin: Style.dp(6)
            text: root.title !== "" ? root.title : "Plugin details"
            color: Style.colors.pluginCardTitle
            font.pixelSize: Style.appFont.mediumPt
            font.weight: Font.DemiBold
            font.family: Style.fontTypes.inter
            elide: Text.ElideRight
        }

        BusyIndicator {
            visible: root.busy
            running: visible
            Layout.preferredWidth: Style.dp(20)
            Layout.preferredHeight: Style.dp(20)
        }
    }
}
