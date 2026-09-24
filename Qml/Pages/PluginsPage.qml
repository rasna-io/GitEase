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
    property var            initialPlugins:     []   // full list from the last no-search fetch
    property bool           isSearchActive:     false
    property bool           fetchingMore:       false

    // Counts for the left panel Installed filter rows
    property var installedCounts: ({})

    property GuideController guideController: null

    // Header exposed to MainWindow
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
        // Save the full list as initial state whenever we are NOT in search mode
        if (!root.isSearchActive)
            root.initialPlugins = root.pluginsData ? root.pluginsData.slice() : []

        root.fetchingMore = false
        applyCurrentMode()
        buildCategoriesCounts()
    }

    onCategoriesDataChanged: {
        leftPanel.categoriesData = root.categoriesData.slice()
    }

    /* Children
     * ****************************************************************************************/
    EmptyStateView {
        title: (root.pluginController && root.pluginController.installingPluginName)
            ? "Installing " + root.pluginController.installingPluginName + "…"
            : "No plugins to show"
        details: (root.pluginController && root.pluginController.installingPluginName)
            ? "Please wait, this usually takes a few seconds"
            : "No plugins available at the moment"
        visible: (root.pluginsData ? root.pluginsData.length === 0 : true)
                 || (root.pluginController && root.pluginController.installingPluginName)
    }

    // Debounce timer — fires the API search after the user stops typing
    Timer {
        id: searchDebounceTimer
        interval: 400
        repeat: false
        onTriggered: root.pluginController?.fetchAvailablePlugins(1, root.currentSearch)
    }

    ListModel {
        id: installedPluginsModel
    }

    ListModel {
        id: availablePluginsModel
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        PluginsLeftPanel {
            id: leftPanel
            pluginsCount: root.pluginsData.length
            categoriesData: root.categoriesData
            categoriesCounts: root.categoriesCounts
            installedCounts: root.installedCounts

            onCategorySelected:  (category) => {
                root.currentCategory = category
                leftPanel.selectedInstalledMode = -1
                root.currentMode = ""
                root.applyCurrentMode()
            }

            onInstalledModeSelected: (mode) => {
                root.currentMode = mode
                root.applyCurrentMode()
            }
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
                                description: "Browse plugins by category (All, Git, UI, Workflow, etc.) or filter installed plugins by status (Enabled, Disabled, Needs Update)."
                            },
                            {
                                targetProvider: function() { return pluginsPageHeader?.textFilterField },
                                icon: Style.icons.search,
                                title: "Search Plugins",
                                description: "Type a plugin name or keyword to search both installed and available plugins instantly.",
                                activationDelay: 300,
                            },
                            {
                                targetProvider: function() { return installedGridView },
                                icon: Style.icons.cube,
                                title: "Installed Plugins",
                                description: "Your currently installed plugins. Click the gear icon to configure, the toggle to enable/disable, or the trash icon to uninstall."
                            },
                            {
                                targetProvider: function() { return availableGridView },
                                icon: Style.icons.cloudDownload,
                                title: "Available Plugins",
                                description: "Browse the plugin marketplace. Click Install to add a plugin — it downloads and enables automatically."
                            }
                        ]
                    }
                }

                // ── Installed section header ─────────────────────────
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

                            onInstallClicked: function(pluginId) {
                                root.pluginController?.installPlugin(pluginId)
                            }
                            onUninstallClicked: function(pluginId) {
                                root.pluginController?.uninstallPlugin(pluginId)
                            }
                            onUpdateClicked: function(pluginId) {
                                root.pluginController?.updatePlugin(pluginId)
                            }
                            onEnableToggled: function(pluginId, enabled) {
                                root.pluginController?.togglePlugin(pluginId, enabled)
                            }
                        }
                    }
                }

                // ── Available section header ─────────────────────────
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

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

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

                            onInstallClicked: function(pluginId) {
                                root.pluginController?.installPlugin(pluginId)
                            }
                            onUninstallClicked: function(pluginId) {
                                root.pluginController?.uninstallPlugin(pluginId)
                            }
                            onUpdateClicked: function(pluginId) {
                                root.pluginController?.updatePlugin(pluginId)
                            }
                            onEnableToggled: function(pluginId, enabled) {
                                root.pluginController?.togglePlugin(pluginId, enabled)
                            }
                        }
                    }

                    // Load next page when the user scrolls within one row of the bottom
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


    /* Functions
     * ****************************************************************************************/
    function applyFilter(text, mode) {
        root.currentMode = mode || ""

        // Header filter overrides the left-panel Installed selection
        leftPanel.selectedInstalledMode = -1

        if (text === root.currentSearch) {
            // Only mode changed — re-filter the current list locally
            applyCurrentMode()
            return
        }

        root.currentSearch = text

        if (text !== "") {
            root.isSearchActive = true

            // 1. Show local matches immediately for instant feedback
            const lower = text.toLowerCase()
            const localMatches = initialPlugins.filter(function(p) {
                return p.name.toLowerCase().indexOf(lower)        !== -1
                    || p.description.toLowerCase().indexOf(lower) !== -1
            })
            root.appModel.plugins = localMatches

            // 2. Debounce the API call so we merge in server results shortly after
            searchDebounceTimer.restart()
        } else {
            // Search cleared — restore the saved initial state
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

        root.isSearchActive = false
        root.currentSearch  = ""
        root.currentMode    = ""
        root.currentCategory = "All"
        leftPanel.selectedCategory = -1
        leftPanel.selectedInstalledMode = -1
        root.pluginController.fetchPluginsCategories()
        root.pluginController.fetchAvailablePlugins(1, "")
    }

    // Refills installed/available models from appModel.plugins, applying the active
    // category and mode filters.
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

        // Initialize all categories to 0
        for (const category of root.categoriesData)
            counts[category.id] = 0

        // Count plugins
        for (const plugin of root.pluginsData) {
            if (!counts.hasOwnProperty(plugin.category))
                counts[plugin.category] = 0

            counts[plugin.category]++
        }

        root.categoriesCounts = counts
    }

    // Counts for the left panel Installed filter rows
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