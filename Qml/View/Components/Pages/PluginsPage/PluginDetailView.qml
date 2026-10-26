import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import "qrc:/GitEase/Qml/Core/Scripts/PluginDetailFormat.js" as Format

/*! ***********************************************************************************************
 * PluginDetailView
 * Marketplace-style plugin details: hero header with actions, tabbed content
 * (Overview / Features / Changelog) and a details sidebar. Collapses to a single
 * column on narrow widths.
 *
 * This item owns the state derived from the plugin and wires the pieces together;
 * the pieces themselves live in the PluginDetail folder.
 * When the view becomes visible it fades in while rising slightly.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    pluginController: null
    property var    plugin: root.pluginController ? root.pluginController.pluginDetail : null
    property string currentTab: "overview"
    property string lastPluginId: ""

    readonly property bool wide: root.width >= Style.dp(920)
    readonly property real pageWidth: Math.min(root.width - Style.dp(48), Style.dp(1160))

    readonly property color categoryColor: root.plugin?.mainColor || Style.colors.accent

    readonly property var  screenshots: root.plugin?.screenshots || []
    readonly property var  features:  root.plugin?.features  || []
    readonly property var  changelog: root.plugin?.changelog || []
    readonly property var  tags:      root.plugin?.tags      || []
    readonly property int  downloadCount: root.plugin?.downloadsCount ?? root.plugin?.donwloadsCount ?? 0

    readonly property bool isInstalled:     root.plugin?.isInstalled ?? false
    readonly property bool isEnabled:       root.plugin?.isEnabled ?? false
    readonly property bool isCompatible:    root.plugin?.isCompatible ?? true
    readonly property bool updateAvailable: root.plugin?.updateAvailable ?? false

    readonly property var  installState: (root.pluginController && root.plugin)
                                         ? root.pluginController.installStates[root.plugin.pluginId]
                                         : undefined

    readonly property string aboutText: {
        if(root.plugin?.longDescription && root.plugin.longDescription.length > 0) {
            return root.plugin.longDescription
        }

        return root.plugin?.description || ""
    }

    readonly property var tabModel: {
        let tabs = [{ id: "overview", label: "Overview", count: -1 }]

        if(root.features.length > 0) {
            tabs.push({ id: "features", label: "Features", count: root.features.length })
        }

        if(root.changelog.length > 0) {
            tabs.push({ id: "changelog", label: "Changelog", count: root.changelog.length })
        }

        return tabs
    }

    readonly property var detailRows: {
        if(!root.plugin) {
            return []
        }

        let rows = [
            { icon: Style.icons.tag,       label: "Version",
              value: root.plugin.latestVersion ? ("v" + root.plugin.latestVersion) : "", mono: true },
            { icon: Style.icons.calendar,  label: "Released",  value: root.plugin.releaseDate || "", mono: false },
            { icon: Style.icons.file,      label: "Size",      value: root.plugin.size || "", mono: false },
            { icon: Style.icons.download,  label: "Downloads",
              value: root.downloadCount > 0 ? Format.formatCount(root.downloadCount) : "", mono: false },
            { icon: Style.icons.shield,    label: "Requires",
              value: root.plugin.minAppVersion ? ("GitEase " + root.plugin.minAppVersion + "+") : "", mono: false },
            { icon: Style.icons.plugins,   label: "Category",  value: root.plugin.category || "", mono: false }
        ]

        return rows.filter(function(r) {
            return r.value !== ""
        })
    }

    /* Signals
     * ****************************************************************************************/
    signal backRequested()
    signal installClicked(string pluginId)
    signal uninstallClicked(string pluginId)
    signal updateClicked(string pluginId)
    signal enableToggled(string pluginId, bool enabled)

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.pluginPageBackground
    clip: true

    onPluginChanged: {
        let id = root.plugin?.pluginId ?? ""
        if(id === root.lastPluginId) {
            return
        }

        root.lastPluginId = id
        root.currentTab = "overview"
        detailFlick.contentY = 0
    }

    onVisibleChanged: {
        if(root.visible) {
            showAnimation.restart()
        }
    }

    onTabModelChanged: {
        let found = root.tabModel.some(function(t) {
            return t.id === root.currentTab
        })

        if(!found) {
            root.currentTab = "overview"
        }
    }

    /* Children
     * ****************************************************************************************/
    ParallelAnimation {
        id: showAnimation

        NumberAnimation {
            target: root
            property: "opacity"
            from: 0
            to: 1
            duration: 220
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: contentShift
            property: "y"
            from: Style.dp(16)
            to: 0
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        transform: Translate {
            id: contentShift
        }

        PluginDetailTopBar {
            Layout.fillWidth: true
            title: root.plugin?.name || ""
            busy: root.pluginController?.pluginDetailBusy ?? false

            onBackRequested: root.backRequested()
        }

        PluginDetailErrorBanner {
            Layout.fillWidth: true
            message: root.pluginController?.pluginDetailError ?? ""
        }

        Flickable {
            id: detailFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: pageColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: pageColumn
                width: detailFlick.width
                spacing: 0

                PluginDetailHero {
                    Layout.fillWidth: true
                    plugin: root.plugin
                    installState: root.installState
                    categoryColor: root.categoryColor
                    wide: root.wide
                    pageWidth: root.pageWidth
                    downloadCount: root.downloadCount
                    isInstalled: root.isInstalled
                    isEnabled: root.isEnabled
                    isCompatible: root.isCompatible
                    updateAvailable: root.updateAvailable
                    tabs: root.tabModel
                    currentTab: root.currentTab

                    onTabSelected: function(tabId) {
                        root.selectTab(tabId)
                    }

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

                PluginDetailBody {
                    Layout.fillWidth: true
                    plugin: root.plugin
                    wide: root.wide
                    pageWidth: root.pageWidth
                    categoryColor: root.categoryColor
                    currentTab: root.currentTab
                    aboutText: root.aboutText
                    screenshots: root.screenshots
                    features: root.features
                    changelog: root.changelog
                    tags: root.tags
                    detailRows: root.detailRows

                    onTabRequested: function(tabId) {
                        root.selectTab(tabId)
                    }
                }
            }
        }
    }

    Connections {
        target: root.pluginController?.appModel ?? null

        function onPluginsChanged() {
            if(!root.plugin || !root.pluginController?.appModel) {
                return
            }

            let list = root.pluginController.appModel.plugins || []
            for(let i = 0; i < list.length; i++) {
                if(list[i].pluginId !== root.plugin.pluginId) {
                    continue
                }

                root.pluginController.pluginDetail = Object.assign({}, root.plugin, {
                    isInstalled: list[i].isInstalled,
                    isEnabled: list[i].isEnabled,
                    isCompatible: list[i].isCompatible,
                    updateAvailable: list[i].updateAvailable,
                    busy: list[i].busy,
                    latestVersion: list[i].latestVersion || root.plugin.latestVersion,
                    screenshots: root.plugin.screenshots
                })
                break
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function selectTab(tabId) {
        root.currentTab = tabId
        detailFlick.returnToBounds()
    }
}
