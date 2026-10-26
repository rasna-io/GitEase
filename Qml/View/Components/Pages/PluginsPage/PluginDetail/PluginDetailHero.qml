import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import "qrc:/GitEase/Qml/Core/Scripts/PluginDetailFormat.js" as Format

/*! ***********************************************************************************************
 * PluginDetailHero
 * Header band of the plugin details: icon, identity, status chips, actions and the tab bar.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    plugin: null
    property var    installState: undefined
    property color  categoryColor: Style.colors.accent
    property bool   wide: true
    property real   pageWidth: 0
    property int    downloadCount: 0
    property bool   isInstalled: false
    property bool   isEnabled: false
    property bool   isCompatible: true
    property bool   updateAvailable: false
    property var    tabs: []
    property string currentTab: "overview"

    /* Signals
     * ****************************************************************************************/
    signal tabSelected(string tabId)
    signal installClicked(string pluginId)
    signal uninstallClicked(string pluginId)
    signal updateClicked(string pluginId)
    signal enableToggled(string pluginId, bool enabled)

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: heroColumn.implicitHeight + Style.dp(28)
    color: Style.colors.pluginCardBackground

    /* Children
     * ****************************************************************************************/

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Format.withAlpha(root.categoryColor, 0.16)
            }

            GradientStop {
                position: 1.0
                color: Format.withAlpha(root.categoryColor, 0.0)
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Style.colors.pluginDivider
    }

    ColumnLayout {
        id: heroColumn
        width: root.pageWidth
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        spacing: Style.dp(22)

        GridLayout {
            id: heroGrid
            Layout.fillWidth: true
            columns: root.wide ? 3 : 2
            columnSpacing: Style.dp(20)
            rowSpacing: Style.dp(18)

            // Icon tile
            Rectangle {
                Layout.preferredWidth: Style.dp(88)
                Layout.preferredHeight: Style.dp(88)
                Layout.alignment: Qt.AlignTop
                radius: Style.dp(20)
                color: Style.colors.pluginCardBackground
                border.width: 1
                border.color: Format.withAlpha(root.categoryColor, 0.28)

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: parent.radius - 1
                    color: Format.withAlpha(root.categoryColor, 0.10)
                }

                Image {
                    id: heroIcon
                    anchors.centerIn: parent
                    width: parent.width - Style.dp(16)
                    height: width
                    source: root.plugin?.iconUrl ?? ""
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: heroIcon.status !== Image.Ready
                    text: Style.icons.plugins
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.appFont.displaySmPt
                    color: root.categoryColor
                }
            }

            // Identity
            ColumnLayout {
                id: identityColumn
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: Style.dp(8)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.dp(10)

                    Label {
                        Layout.maximumWidth: identityColumn.width
                                             - (versionChip.visible ? versionChip.width + Style.dp(10) : 0)
                        text: root.plugin?.name || "Plugin"
                        color: Style.colors.pluginCardTitle
                        font.pixelSize: Style.appFont.xlPt
                        font.weight: Font.Bold
                        font.family: Style.fontTypes.inter
                        elide: Text.ElideRight
                    }

                    PluginDetailChip {
                        id: versionChip
                        visible: !!(root.plugin?.latestVersion)
                        text: "v" + (root.plugin?.latestVersion || "")
                        tint: Style.colors.pluginSectionLabel
                        mono: true
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Style.dp(14)

                    PluginDetailMetaItem {
                        visible: !!(root.plugin?.author)
                        iconText: Style.icons.user
                        text: root.plugin?.author || ""
                    }

                    PluginDetailMetaItem {
                        visible: root.downloadCount > 0
                        iconText: Style.icons.download
                        text: Format.formatCount(root.downloadCount) + " downloads"
                    }

                    PluginDetailMetaItem {
                        visible: !!(root.plugin?.releaseDate)
                        iconText: Style.icons.calendar
                        text: root.plugin?.releaseDate || ""
                    }
                }

                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: Style.dp(2)
                    visible: text !== ""
                    text: root.plugin?.description || ""
                    color: Style.colors.pluginCardDescription
                    font.pixelSize: Style.appFont.mediumPt
                    font.family: Style.fontTypes.inter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    lineHeight: 1.45
                    lineHeightMode: Text.ProportionalHeight
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: Style.dp(2)
                    spacing: Style.dp(6)

                    PluginDetailChip {
                        visible: !!(root.plugin?.category)
                        text: root.plugin?.category || ""
                        tint: root.categoryColor
                    }

                    PluginDetailChip {
                        visible: root.isInstalled && root.isEnabled
                        iconText: Style.icons.circleCheck
                        text: "Installed"
                        tint: Style.colors.vibrantMint
                    }

                    PluginDetailChip {
                        visible: root.isInstalled && !root.isEnabled
                        text: "Installed · Disabled"
                        tint: Style.colors.pluginSectionLabel
                    }

                    PluginDetailChip {
                        visible: root.updateAvailable
                        iconText: Style.icons.update
                        text: "Update available"
                        tint: Style.colors.marigold
                    }

                    PluginDetailChip {
                        visible: !root.isCompatible
                        iconText: Style.icons.warning
                        text: "Incompatible"
                        tint: Style.colors.incompatible
                    }
                }
            }

            // Actions
            PluginDetailActions {
                Layout.columnSpan: root.wide ? 1 : 2
                Layout.fillWidth: !root.wide
                Layout.preferredWidth: root.wide ? Style.dp(290) : -1
                Layout.alignment: root.wide ? (Qt.AlignTop | Qt.AlignRight) : Qt.AlignTop

                plugin: root.plugin
                installState: root.installState
                wide: root.wide
                isInstalled: root.isInstalled
                isEnabled: root.isEnabled
                isCompatible: root.isCompatible
                updateAvailable: root.updateAvailable

                onInstallClicked: function(pluginId) {
                    root.installClicked(pluginId)
                }

                onUninstallClicked: function(pluginId) {
                    root.uninstallClicked(pluginId)
                }

                onUpdateClicked: function(pluginId) {
                    root.updateClicked(pluginId)
                }

                onEnableToggled: function(pluginId, enabled) {
                    root.enableToggled(pluginId, enabled)
                }
            }
        }

        PluginDetailTabBar {
            Layout.fillWidth: true
            tabs: root.tabs
            currentTab: root.currentTab
            tint: root.categoryColor

            onTabSelected: function(tabId) {
                root.tabSelected(tabId)
            }
        }
    }
}
