import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * GitignoreHeader
 * Page header: icon, title, repository summary, the view switch and a refresh button that turns
 * into a spinner while the repository is being read. On narrow pages the switch moves below.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string title:        "Gitignore"
    property string subtitle:     ""
    property var    tabs:         []
    property string currentTab:   ""
    property bool   busy:         false
    property bool   canRefresh:   false
    property bool   narrow:       false
    property real   sidePadding:  Style.dp(20)

    /* Signals
     * ****************************************************************************************/
    signal tabClicked(string key)
    signal refreshRequested()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: headerColumn.implicitHeight + Style.dp(24)
    color: Style.colors.pluginPanelBackground

    /* Children
     * ****************************************************************************************/
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Style.colors.pluginPanelBorder
    }

    ColumnLayout {
        id: headerColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.sidePadding
        anchors.rightMargin: root.sidePadding
        spacing: Style.dp(10)

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.dp(12)

            Rectangle {
                Layout.preferredWidth: Style.dp(38)
                Layout.preferredHeight: Style.dp(38)
                radius: Style.dp(10)
                color: Style.colors.accentWash

                Text {
                    anchors.centerIn: parent
                    text: "\uf05e"
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: Style.appFont.defaultPt
                    color: Style.colors.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    elide: Text.ElideRight
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.largePt
                    font.weight: Font.DemiBold
                    color: Style.colors.pluginCardTitle
                }

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.subtitle
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                    color: Style.colors.pluginSectionMetaText
                }
            }

            GitignoreHeaderTabs {
                visible: !root.narrow
                tabs: root.tabs
                current: root.currentTab
                onTabClicked: function(key) { root.tabClicked(key) }
            }

            Item {
                Layout.preferredWidth: Style.dp(32)
                Layout.preferredHeight: Style.dp(32)

                BusyIndicator {
                    anchors.centerIn: parent
                    width: Style.dp(18)
                    height: Style.dp(18)
                    padding: 0
                    running: root.busy
                    visible: running
                    Material.accent: Style.colors.accent
                }

                ActionIconButton {
                    anchors.fill: parent
                    visible: !root.busy
                    enabled: root.canRefresh
                    iconText: Style.icons.refresh
                    tooltip: "Refresh"
                    backgroundColor: "transparent"
                    textColor: Style.colors.pluginSectionMetaText
                    onClicked: root.refreshRequested()
                }
            }
        }

        GitignoreHeaderTabs {
            Layout.fillWidth: true
            visible: root.narrow
            stretch: true
            tabs: root.tabs
            current: root.currentTab
            onTabClicked: function(key) { root.tabClicked(key) }
        }
    }
}
