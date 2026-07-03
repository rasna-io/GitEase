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

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property AppModel       appModel:           null
    property var            pluginController:   null
    property var            pluginsData:        root.appModel ? root.appModel.plugins : []
    readonly property int   minCardWidth:       400
    readonly property int   minCardHeight:      270

    property string         currentMode:        ""
    property string         currentSearch:      ""
    property var            initialPlugins:     []   // full list from the last no-search fetch
    property bool           isSearchActive:     false
    property bool           fetchingMore:       false

    // Header exposed to MainWindow
    property Component headerContent: Component {
        PluginsPageHeader {
            id: pluginsPageHeader
            onFilterRequested: (text, mode) => root.applyFilter(text, mode)
        }
    }

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

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
    }

    /* Children
     * ****************************************************************************************/
    EmptyStateView {
        title: "No plugins to show"
        details: "No plugins available at the moment"
        visible: pluginsModel.count === 0
    }

    // Debounce timer — fires the API search after the user stops typing
    Timer {
        id: searchDebounceTimer
        interval: 400
        repeat: false
        onTriggered: root.pluginController?.fetchAvailablePlugins(1, root.currentSearch)
    }

    ListModel {
        id: pluginsModel
    }

    GridView {
        id: gridView
        anchors.fill: parent
        anchors.margins: 10
        clip: true

        model: pluginsModel

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        property int columns: Math.max(1, Math.floor(width / root.minCardWidth))

        cellWidth: width / columns
        cellHeight: root.minCardHeight

        delegate: Item {
            width: gridView.cellWidth
            height: gridView.cellHeight

            PluginCard {
                anchors.centerIn: parent
                width: gridView.cellWidth - 20
                height: gridView.cellHeight - 20
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

            if (contentY + height >= contentHeight - gridView.cellHeight
                    && !root.fetchingMore
                    && root.pluginController?.hasMorePages) {
                root.loadNextPage()
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
        root.pluginController.fetchAvailablePlugins(1, "")
    }

    // Refills pluginsModel from appModel.plugins, applying the active mode filter.
    function applyCurrentMode() {
        pluginsModel.clear()

        if (!root.pluginsData)
            return

        for (var i = 0; i < root.pluginsData.length; i++) {
            var plugin = root.pluginsData[i]

            var matchesMode = currentMode === ""
                || (currentMode === "Installed" && plugin.isInstalled)
                || (currentMode === "Enabled"   && plugin.isEnabled)
                || (currentMode === "Available"  && !plugin.isInstalled)

            if (matchesMode)
                pluginsModel.append(plugin)
        }
    }
}
