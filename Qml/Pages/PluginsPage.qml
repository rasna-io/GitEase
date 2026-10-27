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
                    downloadedCount: root.downloadedCount
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

                        Flickable {
                            id: pluginsFlick
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: width
                            contentHeight: sectionsColumn.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar {
                                id: pluginsScrollBar
                                policy: ScrollBar.AsNeeded
                            }

                            onContentYChanged: root.loadMoreIfNeeded()
                            onContentHeightChanged: root.loadMoreIfNeeded()
                            onHeightChanged: root.loadMoreIfNeeded()

                            ColumnLayout {
                                id: sectionsColumn
                                width: pluginsFlick.width - pluginsScrollBar.width - Style.dp(6)
                                spacing: 0
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
                                    Layout.preferredHeight: installedGridView.sectionHeight
                                    Layout.bottomMargin: Style.dp(20)
                                    clip: true
                                    interactive: false
                                    model: installedPluginsModel
                                    property int columns: Math.max(1, Math.floor(width / root.minCardWidth))
                                    cellWidth: width / columns
                                    cellHeight: root.minCardHeight

                                    property real sectionHeight: contentHeight
                                    Behavior on sectionHeight {
                                        NumberAnimation {
                                            duration: 240
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    add: Transition {
                                        ParallelAnimation {
                                            NumberAnimation {
                                                property: "opacity"
                                                from: 0
                                                to: 1
                                                duration: 240
                                                easing.type: Easing.OutCubic
                                            }

                                            NumberAnimation {
                                                property: "scale"
                                                from: 0.9
                                                to: 1
                                                duration: 240
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    remove: Transition {
                                        ParallelAnimation {
                                            NumberAnimation {
                                                property: "opacity"
                                                to: 0
                                                duration: 180
                                                easing.type: Easing.InCubic
                                            }

                                            NumberAnimation {
                                                property: "scale"
                                                to: 0.9
                                                duration: 180
                                                easing.type: Easing.InCubic
                                            }
                                        }
                                    }

                                    displaced: Transition {
                                        NumberAnimation {
                                            properties: "x,y"
                                            duration: 240
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    delegate: Item {
                                        width: installedGridView.cellWidth
                                        height: installedGridView.cellHeight

                                        PluginCard {
                                            anchors.centerIn: parent
                                            width: installedGridView.cellWidth - 8
                                            height: installedGridView.cellHeight - 8
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
                                    Layout.preferredHeight: availableGridView.sectionHeight
                                    clip: true
                                    interactive: false
                                    model: availablePluginsModel
                                    property int columns: Math.max(1, Math.floor(width / root.minCardWidth))
                                    cellWidth: width / columns
                                    cellHeight: root.minCardHeight

                                    property real sectionHeight: contentHeight
                                    Behavior on sectionHeight {
                                        NumberAnimation {
                                            duration: 240
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    add: Transition {
                                        ParallelAnimation {
                                            NumberAnimation {
                                                property: "opacity"
                                                from: 0
                                                to: 1
                                                duration: 240
                                                easing.type: Easing.OutCubic
                                            }

                                            NumberAnimation {
                                                property: "scale"
                                                from: 0.9
                                                to: 1
                                                duration: 240
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    remove: Transition {
                                        ParallelAnimation {
                                            NumberAnimation {
                                                property: "opacity"
                                                to: 0
                                                duration: 180
                                                easing.type: Easing.InCubic
                                            }

                                            NumberAnimation {
                                                property: "scale"
                                                to: 0.9
                                                duration: 180
                                                easing.type: Easing.InCubic
                                            }
                                        }
                                    }

                                    displaced: Transition {
                                        NumberAnimation {
                                            properties: "x,y"
                                            duration: 240
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    delegate: Item {
                                        width: availableGridView.cellWidth
                                        height: availableGridView.cellHeight

                                        PluginCard {
                                            anchors.centerIn: parent
                                            width: availableGridView.cellWidth - 8
                                            height: availableGridView.cellHeight - 8
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
                                            onUpdateClicked: function(pluginId) { root.pluginController?.updatePlugin(pluginId) }
                                            onEnableToggled: function(pluginId, enabled) { root.pluginController?.togglePlugin(pluginId, enabled) }
                                        }
                                    }
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

    function loadMoreIfNeeded() {
        if(root.fetchingMore || !root.pluginController?.hasMorePages) {
            return
        }

        if(pluginsFlick.contentY + pluginsFlick.height >= pluginsFlick.contentHeight - root.minCardHeight) {
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
        root.pluginController.rescanLocalPlugins()
        root.pluginController.fetchPluginsCategories()
        root.pluginController.fetchAvailablePlugins(1, "")
    }

    function syncModel(model, items) {
        let wanted = {}
        for(let i = 0; i < items.length; i++) {
            wanted[items[i].pluginId] = true
        }

        for(let r = model.count - 1; r >= 0; r--) {
            if(!wanted[model.get(r).pluginId]) {
                model.remove(r)
            }
        }

        for(let n = 0; n < items.length; n++) {
            let item = items[n]
            let found = -1
            for(let j = n; j < model.count; j++) {
                if(model.get(j).pluginId === item.pluginId) {
                    found = j
                    break
                }
            }

            if(found === -1) {
                model.insert(n, item)
                continue
            }

            if(found !== n) {
                model.move(found, n, 1)
            }

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
                || (root.currentMode === "All"           && plugin.isInstalled)
                || (root.currentMode === "Enabled"       && plugin.isInstalled && plugin.isEnabled)
                || (root.currentMode === "Disabled"      && plugin.isInstalled && !plugin.isEnabled)
                || (root.currentMode === "Needs Update"  && plugin.isInstalled && plugin.updateAvailable)
                || (root.currentMode === "Available"     && !plugin.isInstalled)

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
