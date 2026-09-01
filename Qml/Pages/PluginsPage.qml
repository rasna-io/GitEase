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
    readonly property int   minCardWidth:       400
    readonly property int   minCardHeight:      250

    property string         currentMode:        ""
    property string         currentSearch:      ""
    property var            initialPlugins:     []   // full list from the last no-search fetch
    property bool           isSearchActive:     false
    property bool           fetchingMore:       false

    property var installedModel: [
        { name: "Enabled",      iconName: Style.icons.check,   iconColor: Style.colors.compatible },
        { name: "Disabled",     iconName: Style.icons.pause,   iconColor: "#363650" },
        { name: "Needs Update", iconName: Style.icons.warning, iconColor: Style.colors.warning }
    ]

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
        visible: (installedPluginsModel.count === 0 && availablePluginsModel.count === 0)
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

        PluginsLeftPanel {
            id: leftPanel
            pluginsCount: root.pluginsData.length
            categoriesData: root.categoriesData
            installedModel: root.installedModel
            categoriesCounts: root.categoriesCounts

            onCategorySelected:  (category) => {
                installedPluginsModel.clear()
                availablePluginsModel.clear()
                for (var i = 0; i < root.pluginsData.length; i++) {
                    var plugin = root.pluginsData[i]

                    var matchesCategory = plugin.category === category || category === "All"
                    var matchesMode = root.currentMode === ""
                        || (root.currentMode === "Installed" && plugin.isInstalled)
                        || (root.currentMode === "Enabled"   && plugin.isEnabled)
                        || (root.currentMode === "Available"  && !plugin.isInstalled)

                    if (matchesCategory && matchesMode) {
                        if (plugin.isInstalled)
                            installedPluginsModel.append(plugin)
                        else
                            availablePluginsModel.append(plugin)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: Style.colors.obsidianDark

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "INSTALLED"
                        color: "#363650"
                        font.pixelSize: Style.appFont.largePt
                        font.family: Style.fontTypes.roboto
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Style.colors.primaryBorder
                    }

                    Text {
                        text: (root.pluginsData ? root.pluginsData.filter(function(p) { return p.isInstalled }).length : 0) + " plugins"
                        color: "#363650"
                        font.pixelSize: Style.appFont.largePt
                        font.family: Style.fontTypes.roboto
                    }
                }

                GridView {
                    id: installedGridView
                    Layout.fillWidth: true
                    Layout.preferredHeight: installedGridView.contentHeight
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
                            width: installedGridView.cellWidth - 20
                            height: installedGridView.cellHeight - 20
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

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "AVAILABLE"
                        color: "#363650"
                        font.pixelSize: Style.appFont.largePt
                        font.family: Style.fontTypes.roboto
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Style.colors.primaryBorder
                    }

                    Text {
                        text: (root.pluginsData ? root.pluginsData.filter(function(p) { return !p.isInstalled }).length : 0) + " plugins"
                        color: "#363650"
                        font.pixelSize: Style.appFont.largePt
                        font.family: Style.fontTypes.roboto
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
                            width: availableGridView.cellWidth - 20
                            height: availableGridView.cellHeight - 20
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
        root.pluginController.fetchPluginsCategories()
        root.pluginController.fetchAvailablePlugins(1, "")
    }

    // Refills installed/available models from appModel.plugins, applying the active mode filter.
    function applyCurrentMode() {
        installedPluginsModel.clear()
        availablePluginsModel.clear()

        if (!root.pluginsData)
            return

        for (var i = 0; i < root.pluginsData.length; i++) {
            var plugin = root.pluginsData[i]

            var matchesMode = root.currentMode === ""
                || (root.currentMode === "Installed" && plugin.isInstalled)
                || (root.currentMode === "Enabled"   && plugin.isEnabled)
                || (root.currentMode === "Available"  && !plugin.isInstalled)

            if (matchesMode) {
                if (plugin.isInstalled)
                    installedPluginsModel.append(plugin)
                else
                    availablePluginsModel.append(plugin)
            }
        }
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
}
