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
    title: "Plugin Manager"
    icon: Style.icons.plugins

    property AppModel       appModel:           null
    property var            pluginController:   null
    property var            pluginsData:        root.appModel ? root.appModel.plugins : []
    property var            categoriesData:     root.appModel ? root.appModel.pluginsCategories : []
    property var            categoriesCounts:     ({})
    property int            downloadedCount:    0
    readonly property string downloadedCategory: "Downloaded"
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
    property bool           initialLoadDone:    false

    property var installedCounts: ({})
    property GuideController guideController: null

    readonly property bool catalogLoading: !!(root.pluginController && root.pluginController.catalogLoading)
    readonly property bool showCatalogSkeleton: !root.showingDetail
                                                && root.catalogLoading
                                                && availablePluginsModel.count === 0
                                                && installedPluginsModel.count === 0
    readonly property string loadingMessage: {
        if (root.pluginController?.pluginsLoading)
            return "Loading installed plugins"
        if (root.pluginController?.busy)
            return "Fetching marketplace"
        return "Loading plugins"
    }

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
    onPluginControllerChanged: {
        if (root.pluginController && !root.initialLoadDone)
            refreshPlugins()
    }

    onVisibleChanged: {
        // Full directory rescan + catalog fetch only on first open. Re-entering the page
        // previously re-ran that path every time and froze the UI while cards rebuilt.
        if (visible && root.pluginController && !root.initialLoadDone)
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
                 && !root.catalogLoading
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
                    downloadedCount: root.downloadedCount
                    installedCounts: root.installedCounts

                    onCategorySelected: (category) => {
                        root.currentCategory = category
                        leftPanel.selectedInstalledMode = -1
                        root.currentMode = ""
                        root.applyCurrentMode()
                        availableGridView.positionViewAtBeginning()
                    }

                    onInstalledModeSelected: (mode) => {
                        root.currentMode = mode
                        root.applyCurrentMode()
                        availableGridView.positionViewAtBeginning()
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

                        PluginsSkeletonView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.showCatalogSkeleton
                            running: root.showCatalogSkeleton
                            message: root.loadingMessage
                            pendingCount: root.pluginController?.pluginsPendingCount ?? 0
                            minCardWidth: root.minCardWidth
                            minCardHeight: root.minCardHeight
                        }

                        // Sibling sections only — never nest a GridView inside another
                        // GridView header (that crashed with 0xc0000005). Available stays
                        // interactive so delegates recycle; Installed is small so a
                        // fixed-height non-interactive grid is fine.
                        RowLayout {
                            visible: !root.showCatalogSkeleton
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
                            Layout.preferredHeight: count === 0
                                                    ? 0
                                                    : Math.ceil(count / Math.max(1, columns)) * cellHeight
                            Layout.bottomMargin: count > 0 ? Style.dp(20) : 0
                            clip: true
                            interactive: false
                            visible: !root.showCatalogSkeleton && count > 0
                            model: installedPluginsModel
                            property int columns: Math.max(1, Math.floor(width / root.minCardWidth))
                            cellWidth: width / columns
                            cellHeight: root.minCardHeight
                            delegate: pluginCardDelegate
                        }

                        RowLayout {
                            visible: !root.showCatalogSkeleton
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

                        AppLoadingBanner {
                            Layout.fillWidth: true
                            Layout.bottomMargin: Style.dp(8)
                            running: !root.showCatalogSkeleton
                                     && !!(root.pluginController
                                           && (root.pluginController.pluginsLoading
                                               || root.pluginController.busy))
                            message: root.loadingMessage
                            pendingCount: root.pluginController?.pluginsPendingCount ?? 0
                        }

                        GridView {
                            id: availableGridView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: !root.showCatalogSkeleton
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: availablePluginsModel
                            cacheBuffer: root.minCardHeight * 4
                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                            }

                            property int columns: Math.max(1, Math.floor(width / root.minCardWidth))
                            cellWidth: width / columns
                            cellHeight: root.minCardHeight

                            onContentYChanged: root.loadMoreIfNeeded()
                            onContentHeightChanged: root.loadMoreIfNeeded()
                            onHeightChanged: root.loadMoreIfNeeded()

                            delegate: pluginCardDelegate
                        }
                    }
                }
            }
        }

        PluginDetailView {
            id: detailView
            anchors.fill: parent
            visible: root.showingDetail
            enabled: root.showingDetail
            pluginController: root.pluginController

            onBackRequested: root.closePluginDetails()
            onInstallClicked: function(pluginId) { root.pluginController?.installPlugin(pluginId) }
            onUninstallClicked: function(pluginId) { root.pluginController?.uninstallPlugin(pluginId) }
            onRemoveDownloadClicked: function(pluginId) { root.pluginController?.removeDownloadedPackage(pluginId) }
            onUpdateClicked: function(pluginId) { root.pluginController?.updatePlugin(pluginId) }
            onEnableToggled: function(pluginId, enabled) { root.pluginController?.togglePlugin(pluginId, enabled) }
        }
    }

    Component {
        id: pluginCardDelegate

        Item {
            // GridView sets width/height from cellWidth/cellHeight on the delegate root.
            width: GridView.view ? GridView.view.cellWidth : root.minCardWidth
            height: GridView.view ? GridView.view.cellHeight : root.minCardHeight

            PluginCard {
                anchors.centerIn: parent
                width: parent.width - 8
                height: parent.height - 8
                plugin: model
                pluginBusy: model.busy
                            || !!(root.pluginController
                                  && root.pluginController.installStates[model.pluginId])
                installPhase: root.pluginController
                              ? (root.pluginController.installStates[model.pluginId]?.phase ?? "")
                              : ""
                installProgress: root.pluginController
                                 ? (root.pluginController.installStates[model.pluginId]?.progress ?? -1)
                                 : -1

                onDetailsClicked: function(pluginId) { root.openPluginDetails(pluginId) }
                onInstallClicked: function(pluginId) { root.pluginController?.installPlugin(pluginId) }
                onUninstallClicked: function(pluginId) { root.pluginController?.uninstallPlugin(pluginId) }
                onRemoveDownloadClicked: function(pluginId) { root.pluginController?.removeDownloadedPackage(pluginId) }
                onUpdateClicked: function(pluginId) { root.pluginController?.updatePlugin(pluginId) }
                onEnableToggled: function(pluginId, enabled) { root.pluginController?.togglePlugin(pluginId, enabled) }
            }
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

    function loadMoreIfNeeded() {
        if (root.fetchingMore || !root.pluginController?.hasMorePages)
            return

        if (availableGridView.atYEnd
                || availableGridView.contentY + availableGridView.height
                   >= availableGridView.contentHeight - root.minCardHeight) {
            root.loadNextPage()
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
        root.initialLoadDone = true
        root.pluginController.rescanLocalPlugins()
        root.pluginController.fetchPluginsCategories()
        root.pluginController.fetchAvailablePlugins(1, "")
    }

    function listRoleEqual(a, b) {
        return a === b
            || (a === undefined && (b === undefined || b === null || b === ""))
            || (b === undefined && (a === undefined || a === null || a === ""))
            || String(a) === String(b)
    }

    function pluginRolesUnchanged(existing, item) {
        // Only roles that PluginCard / filters actually bind. Avoid model.set on every sync.
        const keys = [
            "pluginId", "name", "description", "author", "latestVersion", "iconUrl",
            "category", "mainColor", "isInstalled", "isEnabled", "isCompatible",
            "updateAvailable", "busy", "isPlaceholder", "hasCachedPackage", "isLocal",
            "sourceLabel", "installFromCache"
        ]
        for (let i = 0; i < keys.length; i++) {
            const key = keys[i]
            if (!root.listRoleEqual(existing[key], item[key]))
                return false
        }
        return true
    }

    function syncModel(model, items) {
        let wanted = {}
        for (let i = 0; i < items.length; i++)
            wanted[items[i].pluginId] = true

        for (let r = model.count - 1; r >= 0; r--) {
            if (!wanted[model.get(r).pluginId])
                model.remove(r)
        }

        for (let n = 0; n < items.length; n++) {
            let item = items[n]
            let found = -1
            for (let j = n; j < model.count; j++) {
                if (model.get(j).pluginId === item.pluginId) {
                    found = j
                    break
                }
            }

            if (found === -1) {
                model.insert(n, item)
                continue
            }

            if (found !== n)
                model.move(found, n, 1)

            if (!root.pluginRolesUnchanged(model.get(n), item))
                model.set(n, item)
        }
    }

    function applyCurrentMode() {
        let installedItems = []
        let availableItems = []

        if (!root.pluginsData) {
            root.syncModel(installedPluginsModel, installedItems)
            root.syncModel(availablePluginsModel, availableItems)
            return
        }

        for (var i = 0; i < root.pluginsData.length; i++) {
            var plugin = root.pluginsData[i]

            // A card that stands in for a running install is always shown
            var matchesCategory = plugin.category === root.currentCategory
                                  || root.currentCategory === "All"
                                  || (root.currentCategory === root.downloadedCategory
                                      && plugin.hasCachedPackage === true)
                                  || plugin.isPlaceholder === true

            var matchesMode = root.currentMode === ""
                || plugin.isPlaceholder === true
                || ((root.currentMode === "All" || root.currentMode === "Installed") && plugin.isInstalled)
                || (root.currentMode === "Enabled"       && plugin.isInstalled && plugin.isEnabled)
                || (root.currentMode === "Disabled"      && plugin.isInstalled && !plugin.isEnabled)
                || (root.currentMode === "Needs Update"  && plugin.isInstalled && plugin.updateAvailable)
                || (root.currentMode === "Available"     && !plugin.isInstalled)
                || (root.currentMode === "Downloaded"    && plugin.hasCachedPackage === true)
                || (root.currentMode === "Local"         && plugin.isLocal === true)

            if (matchesCategory && matchesMode) {
                if (plugin.isInstalled)
                    installedItems.push(plugin)
                else
                    availableItems.push(plugin)
            }
        }

        root.syncModel(installedPluginsModel, installedItems)
        root.syncModel(availablePluginsModel, availableItems)

        buildInstalledCounts()
    }

    function buildCategoriesCounts() {
        let counts = {}
        let downloaded = 0

        for (const category of root.categoriesData)
            counts[category.id] = 0

        for (const plugin of root.pluginsData) {
            if(plugin.isPlaceholder) {
                continue
            }

            if(plugin.hasCachedPackage === true) {
                downloaded++
            }

            if (!counts.hasOwnProperty(plugin.category))
                counts[plugin.category] = 0
            counts[plugin.category]++
        }

        root.categoriesCounts = counts
        root.downloadedCount = downloaded
    }

    function buildInstalledCounts() {
        let counts = {
            "Enabled": 0,
            "Disabled": 0,
            "Needs Update": 0
        }

        for (const plugin of root.pluginsData) {
            if (!plugin.isInstalled || plugin.isPlaceholder)
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
