import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*!
 * PluginsPage
 * Responsive plugins page showing list of plugins.
 * - On open: fetches page 1 from the server and saves it as the initial state.
 * - Search: local results shown immediately; server results merged in on response.
 * - Cleared search: restores the saved initial state.
 * - Pagination: fetches the next page when the user scrolls to the bottom.
 * - Detail: clicking a card opens the full plugin information page.
 */

Page {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    pageId: "plugins"
    title: "Plugins"
    icon: Style.icons.plugins

    property AppModel       appModel:           null
    property var            pluginController:   null
    property var            pluginsData:        root.appModel ? root.appModel.plugins : []
    property var            categoriesData:     root.appModel ? root.appModel.pluginsCategories : []
    property var            categoriesCounts:     ({})
    readonly property int   minCardWidth:       280
    readonly property int   minCardHeight:      170

    property string         currentMode:        ""
    property string         currentCategory:    "All"
    property string         currentSearch:      ""
    property var            initialPlugins:     []
    property bool           isSearchActive:     false
    property bool           fetchingMore:       false
    property bool           showingDetail:      false
    property var            browseLeftPanel:    null

    property var installedCounts: ({})
    property GuideController guideController: null

    headerContent: Component {
        PluginsPageHeader {
            id: pluginsPageHeader
            pluginsData: root.pluginsData
            onFilterRequested: (text, mode) => root.applyFilter(text, mode)
            onInstallGepRequested: (path) => {
                if (root.pluginController)
                    root.pluginController.installGepFile(path)
            }
        }
    }

    /* Lifecycle
     * ****************************************************************************************/
    onPluginControllerChanged: refreshPlugins()

    onVisibleChanged: {
        if (visible)
            refreshPlugins()
    }

    onPluginsDataChanged: {
        if (!root.isSearchActive)
            root.initialPlugins = root.pluginsData ? root.pluginsData.slice() : []

        root.fetchingMore = false
        applyCurrentMode()
        buildCategoriesCounts()
    }

    onCategoriesDataChanged: {
        if (root.browseLeftPanel)
            root.browseLeftPanel.categoriesData = root.categoriesData.slice()
    }

    /* Children
     * ****************************************************************************************/
    EmptyStateView {
        title: "No plugins to show"
        details: "No plugins available at the moment"
        visible: !root.showingDetail
                 && (root.pluginsData ? root.pluginsData.length === 0 : true)
        z: 1
    }

    Timer {
        id: searchDebounceTimer
        interval: 400
        repeat: false
        onTriggered: root.pluginController?.fetchAvailablePlugins(1, root.currentSearch)
    }

    ListModel { id: installedPluginsModel }
    ListModel { id: availablePluginsModel }

    Item {
        anchors.fill: parent

        // Marketplace browse
        Item {
            id: browseView
            anchors.fill: parent
            visible: !root.showingDetail
            enabled: !root.showingDetail

            RowLayout {
                anchors.fill: parent
                spacing: 0

                PluginsLeftPanel {
                    id: leftPanel
                    pluginsCount: root.pluginsData.length
                    categoriesData: root.categoriesData
                    categoriesCounts: root.categoriesCounts
                    installedCounts: root.installedCounts

                    onCategorySelected: (category) => {
                        root.currentCategory = category
                        leftPanel.selectedInstalledMode = -1
                        root.currentMode = ""
                        root.applyCurrentMode()
                    }

                    onInstalledModeSelected: (mode) => {
                        root.currentMode = mode
                        root.applyCurrentMode()
                    }

                    Component.onCompleted: root.browseLeftPanel = leftPanel
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: Style.colors.pluginPageBackground

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Style.dp(14)
                        spacing: 0

                        GuideHoverTrigger {
                            guideController: root.guideController
                            guideId: "plugins_page_tutorial"
                            guideName: "Plugins"
                            guideIcon: Style.icons.plugins
                            guidePage: "plugins"
                            stepsFactory: function() {
                                return [
                                    {
                                        targetProvider: function() { return leftPanel },
                                        icon: Style.icons.plugins,
                                        title: "Plugin Categories",
                                        description: "Browse plugins by category or filter installed plugins by status."
                                    },
                                    {
                                        targetProvider: function() { return installedGridView },
                                        icon: Style.icons.cube,
                                        title: "Installed Plugins",
                                        description: "Your currently installed plugins. Click a card for full details."
                                    },
                                    {
                                        targetProvider: function() { return availableGridView },
                                        icon: Style.icons.cloudDownload,
                                        title: "Available Plugins",
                                        description: "Browse the marketplace. Click a card for details, or Install to add it."
                                    }
                                ]
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.bottomMargin: Style.dp(10)
                            spacing: Style.dp(8)

                            Label {
                                text: "Installed"
                                color: Style.colors.pluginSectionLabel
                                font.pixelSize: Style.appFont.h4Pt
                                font.weight: Font.DemiBold
                                font.family: Style.fontTypes.inter
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 0.7
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: Style.colors.pluginDivider
                            }

                            Label {
                                text: installedPluginsModel.count + " plugins"
                                color: Style.colors.pluginSectionMetaText
                                font.pixelSize: Style.appFont.smallPt
                                font.family: Style.fontTypes.inter
                            }
                        }

                        GridView {
                            id: installedGridView
                            Layout.fillWidth: true
                            Layout.preferredHeight: installedGridView.contentHeight
                            Layout.bottomMargin: Style.dp(20)
                            clip: true
                            model: installedPluginsModel
                            property int columns: Math.max(1, Math.floor(width / root.minCardWidth))
                            cellWidth: width / columns
                            cellHeight: root.minCardHeight

                            delegate: Item {
                                width: installedGridView.cellWidth
                                height: installedGridView.cellHeight

                                PluginCard {
                                    anchors.centerIn: parent
                                    width: installedGridView.cellWidth - 8
                                    height: installedGridView.cellHeight - 8
                                    plugin: model
                                    pluginBusy: model.busy
                                                || (root.pluginController
                                                    && root.pluginController.installingPluginId === model.pluginId)
                                    installPhase: (root.pluginController
                                                   && root.pluginController.installingPluginId === model.pluginId)
                                                  ? root.pluginController.installPhase : ""
                                    installProgress: (root.pluginController
                                                      && root.pluginController.installingPluginId === model.pluginId)
                                                     ? root.pluginController.installProgress : -1

                                    onDetailsClicked: function(pluginId) { root.openPluginDetails(pluginId) }
                                    onInstallClicked: function(pluginId) { root.pluginController?.installPlugin(pluginId) }
                                    onUninstallClicked: function(pluginId) { root.pluginController?.uninstallPlugin(pluginId) }
                                    onUpdateClicked: function(pluginId) { root.pluginController?.updatePlugin(pluginId) }
                                    onEnableToggled: function(pluginId, enabled) { root.pluginController?.togglePlugin(pluginId, enabled) }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.bottomMargin: Style.dp(10)
                            spacing: Style.dp(8)

                            Label {
                                text: "Available"
                                color: Style.colors.pluginSectionLabel
                                font.pixelSize: Style.appFont.h4Pt
                                font.weight: Font.DemiBold
                                font.family: Style.fontTypes.inter
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 0.7
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: Style.colors.pluginDivider
                            }

                            Label {
                                text: availablePluginsModel.count + " plugins"
                                color: Style.colors.pluginSectionMetaText
                                font.pixelSize: Style.appFont.smallPt
                                font.family: Style.fontTypes.inter
                            }
                        }

                        GridView {
                            id: availableGridView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: availablePluginsModel
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                            property int columns: Math.max(1, Math.floor(width / root.minCardWidth))
                            cellWidth: width / columns
                            cellHeight: root.minCardHeight

                            delegate: Item {
                                width: availableGridView.cellWidth
                                height: availableGridView.cellHeight

                                PluginCard {
                                    anchors.centerIn: parent
                                    width: availableGridView.cellWidth - 8
                                    height: availableGridView.cellHeight - 8
                                    plugin: model
                                    pluginBusy: model.busy
                                                || (root.pluginController
                                                    && root.pluginController.installingPluginId === model.pluginId)
                                    installPhase: (root.pluginController
                                                   && root.pluginController.installingPluginId === model.pluginId)
                                                  ? root.pluginController.installPhase : ""
                                    installProgress: (root.pluginController
                                                      && root.pluginController.installingPluginId === model.pluginId)
                                                     ? root.pluginController.installProgress : -1

                                    onDetailsClicked: function(pluginId) { root.openPluginDetails(pluginId) }
                                    onInstallClicked: function(pluginId) { root.pluginController?.installPlugin(pluginId) }
                                    onUninstallClicked: function(pluginId) { root.pluginController?.uninstallPlugin(pluginId) }
                                    onUpdateClicked: function(pluginId) { root.pluginController?.updatePlugin(pluginId) }
                                    onEnableToggled: function(pluginId, enabled) { root.pluginController?.togglePlugin(pluginId, enabled) }
                                }
                            }

                            onContentYChanged: {
                                if (contentHeight <= height)
                                    return

                                if (contentY + height >= contentHeight - availableGridView.cellHeight
                                        && !root.fetchingMore
                                        && root.pluginController?.hasMorePages) {
                                    root.loadNextPage()
                                }
                            }
                        }
                    }
                }
            }
        }

        // Full plugin information
        PluginDetailView {
            id: detailView
            anchors.fill: parent
            visible: root.showingDetail
            enabled: root.showingDetail
            pluginController: root.pluginController

            onBackRequested: root.closePluginDetails()
            onInstallClicked: function(pluginId) { root.pluginController?.installPlugin(pluginId) }
            onUninstallClicked: function(pluginId) { root.pluginController?.uninstallPlugin(pluginId) }
            onUpdateClicked: function(pluginId) { root.pluginController?.updatePlugin(pluginId) }
            onEnableToggled: function(pluginId, enabled) { root.pluginController?.togglePlugin(pluginId, enabled) }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function openPluginDetails(pluginId) {
        if (!pluginId) {
            console.warn("[PluginsPage] openPluginDetails called without pluginId")
            return
        }
        if (!root.pluginController) {
            console.warn("[PluginsPage] openPluginDetails: pluginController is null")
            return
        }

        console.log("[PluginsPage] Opening plugin details:", pluginId)
        root.pluginController.fetchPluginDetails(pluginId)
        root.showingDetail = true
    }

    function closePluginDetails() {
        root.showingDetail = false
        root.pluginController?.clearPluginDetails()
    }

    function applyFilter(text, mode) {
        root.currentMode = mode || ""

        if (root.browseLeftPanel)
            root.browseLeftPanel.selectedInstalledMode = -1

        if (text === root.currentSearch) {
            applyCurrentMode()
            return
        }

        root.currentSearch = text

        if (text !== "") {
            root.isSearchActive = true
            const lower = text.toLowerCase()
            const localMatches = initialPlugins.filter(function(p) {
                return p.name.toLowerCase().indexOf(lower) !== -1
                    || p.description.toLowerCase().indexOf(lower) !== -1
            })
            root.appModel.plugins = localMatches
            searchDebounceTimer.restart()
        } else {
            root.isSearchActive = false
            searchDebounceTimer.stop()
            root.appModel.plugins = initialPlugins.slice()
        }
    }

    function loadNextPage() {
        if (!root.pluginController || root.fetchingMore || !root.pluginController.hasMorePages)
            return

        root.fetchingMore = true
        root.pluginController.fetchNextPage(root.pluginController.currentPage + 1, currentSearch)
    }

    function refreshPlugins() {
        if (!root.pluginController)
            return

        if (root.showingDetail)
            root.closePluginDetails()

        root.isSearchActive = false
        root.currentSearch  = ""
        root.currentMode    = ""
        root.currentCategory = "All"
        if (root.browseLeftPanel) {
            root.browseLeftPanel.selectedCategory = -1
            root.browseLeftPanel.selectedInstalledMode = -1
        }
        root.pluginController.rescanLocalPlugins()
        root.pluginController.fetchPluginsCategories()
        root.pluginController.fetchAvailablePlugins(1, "")
    }

    function applyCurrentMode() {
        installedPluginsModel.clear()
        availablePluginsModel.clear()

        if (!root.pluginsData)
            return

        for (var i = 0; i < root.pluginsData.length; i++) {
            var plugin = root.pluginsData[i]

            var matchesCategory = plugin.category === root.currentCategory
                                  || root.currentCategory === "All"

            var matchesMode = root.currentMode === ""
                || (root.currentMode === "All"           && plugin.isInstalled)
                || (root.currentMode === "Enabled"       && plugin.isInstalled && plugin.isEnabled)
                || (root.currentMode === "Disabled"      && plugin.isInstalled && !plugin.isEnabled)
                || (root.currentMode === "Needs Update"  && plugin.isInstalled && plugin.updateAvailable)
                || (root.currentMode === "Available"     && !plugin.isInstalled)

            if (matchesCategory && matchesMode) {
                if (plugin.isInstalled)
                    installedPluginsModel.append(plugin)
                else
                    availablePluginsModel.append(plugin)
            }
        }

        buildInstalledCounts()
    }

    function buildCategoriesCounts() {
        let counts = {}

        for (const category of root.categoriesData)
            counts[category.id] = 0

        for (const plugin of root.pluginsData) {
            if (!counts.hasOwnProperty(plugin.category))
                counts[plugin.category] = 0
            counts[plugin.category]++
        }

        root.categoriesCounts = counts
    }

    function buildInstalledCounts() {
        let counts = {
            "Enabled": 0,
            "Disabled": 0,
            "Needs Update": 0
        }

        for (const plugin of root.pluginsData) {
            if (!plugin.isInstalled)
                continue

            if (plugin.isEnabled)
                counts["Enabled"]++
            else
                counts["Disabled"]++

            if (plugin.updateAvailable)
                counts["Needs Update"]++
        }

        root.installedCounts = counts
    }
}
