import QtQuick
import GitEase

/*! ***********************************************************************************************
 * PluginController
 * QML wrapper around PluginManager.
 * - Initialises the manager after the QML engine is ready
 * - Forwards repo / branch state into the plugin context
 * - Routes plugin notifications to NotificationController
 * - Fetches available plugins and update info from the server
 * ************************************************************************************************/
QtObject {
    id: root

    required property var appModel
    required property var notificationController
    required property var networkController

    property var    currentRepo:        null
    property string currentBranch:      ""
    property bool   busy:               false
    property int    currentPage:        1
    property bool   hasMorePages:       false

    // local plugin map: id → PluginInfo variantmap (rebuilt on every pluginsChanged)
    property var    localPluginMap:     ({})
    property bool   appendMode:         false   // true when fetching next page (append vs replace)
    property string lastFetchedSearch:  ""      // used to filter local-only appends on search

    readonly property string pluginApiBaseUrl:       "https://api.your-awesome-app.com/v1"
    readonly property string fetchPluginsRequestKey: "plugin-fetch"
    readonly property string checkUpdatesRequestKey: "plugin-check-updates"

    /* Plugin manager instance
     * ****************************************************************************************/
    property PluginManager pluginManager: PluginManager {

        onPluginsChanged: root.syncLocalPlugins()

        onPluginLoaded: function(id) {
            console.log("[PluginController] Plugin loaded:", id)
        }

        onPluginError: function(id, error) {
            console.warn("[PluginController] Plugin error —", id, ":", error)
        }

        onDockRegistered: function(id, qmlUrl, title, icon) {
            console.log("[PluginController] Dock registered:", id, "→", qmlUrl)
        }

        onNotifyRequested: function(message, type) {
            switch (type) {
                case "error":   root.notificationController.error(message);   break
                case "warning": root.notificationController.warning(message); break
                case "success": root.notificationController.success(message); break
                default:        root.notificationController.info(message);    break
            }
        }
    }

    /* State forwarding
     * ****************************************************************************************/
    onCurrentRepoChanged:   pluginManager.setCurrentRepository(currentRepo)
    onCurrentBranchChanged: pluginManager.setCurrentBranch(currentBranch)

    /* Lifecycle
     * ****************************************************************************************/
    Component.onCompleted: {
        pluginManager.initialize()
        pluginManager.scanDefaultDirectory()
        pluginManager.scanApplicationPluginsDirectory() // picks up <appDir>/plugins in dev/portable mode
    }

    /* Network connections
     * ****************************************************************************************/
    property Connections networkConnections: Connections {
        target: root.networkController

        function onRequestFinished(requestKey, response) {
            if (requestKey === root.fetchPluginsRequestKey) {
                root.handleFetchPluginsResponse(response)
            } else if (requestKey === root.checkUpdatesRequestKey) {
                root.handleCheckUpdatesResponse(response)
            }
        }

        function onRequestError(requestKey, code, message) {
            if (requestKey !== root.fetchPluginsRequestKey && requestKey !== root.checkUpdatesRequestKey)
                return

            root.busy       = false
            root.appendMode = false
            console.warn("[PluginController] Request error:", requestKey, code, message)
        }

        function onTimeout(requestKey) {
            if (requestKey !== root.fetchPluginsRequestKey && requestKey !== root.checkUpdatesRequestKey)
                return

            root.busy       = false
            root.appendMode = false
            console.warn("[PluginController] Request timed out:", requestKey)
        }
    }

    /* Functions
     * ****************************************************************************************/
    // Fetches page 1 and REPLACES the current list (initial load or new search).
    function fetchAvailablePlugins(page, search) {
        if (!root.networkController)
            return

        page   = page   || 1
        search = search || ""

        root.appendMode        = false
        root.currentPage       = page
        root.lastFetchedSearch = search
        root.busy              = true

        let url = root.pluginApiBaseUrl + "/plugins?page=" + page
        if (search !== "")
            url += "&search=" + encodeURIComponent(search)

        root.networkController.sendRequest(
            root.fetchPluginsRequestKey,
            url,
            root.networkController.GET
        )
    }

    // Fetches the next page and APPENDS to the current list (pagination).
    function fetchNextPage(page, search) {
        if (!root.networkController || root.busy)
            return

        page   = page   || root.currentPage + 1
        search = search || root.lastFetchedSearch

        root.appendMode        = true
        root.currentPage       = page
        root.lastFetchedSearch = search
        root.busy              = true

        let url = root.pluginApiBaseUrl + "/plugins?page=" + page
        if (search !== "")
            url += "&search=" + encodeURIComponent(search)

        root.networkController.sendRequest(
            root.fetchPluginsRequestKey,
            url,
            root.networkController.GET
        )
    }

    function checkUpdates() {
        if (!root.networkController)
            return

        let installed = []
        let infos = pluginManager.pluginInfos

        for (var i = 0; i < infos.length; i++) {
            let info = infos[i]

            if (info.loaded && info.version)
                installed.push({ "id": info.id, "version": info.version })
        }

        if (installed.length === 0)
            return

        root.networkController.sendRequest(
            root.checkUpdatesRequestKey,
            root.pluginApiBaseUrl + "/plugins/check-updates",
            root.networkController.POST,
            { "installed_plugins": installed }
        )
    }

    function handleFetchPluginsResponse(response) {
        root.busy = false
        let payload = response?.data ?? {}

        if (payload?.success === false) {
            console.warn("[PluginController] Fetch plugins failed:", payload?.message ?? "unknown error")
            root.appendMode = false
            return
        }

        let serverPlugins = payload?.data ?? []
        root.hasMorePages = serverPlugins.length >= 50

        if (root.appendMode) {
            root.appendMode = false
            appendPlugins(serverPlugins)
        } else {
            mergePlugins(serverPlugins)
        }
    }

    function handleCheckUpdatesResponse(response) {
        let payload = response?.data ?? {}

        if (payload?.success === false)
            return

        let updates = payload?.data?.updates_available ?? []
        if (!root.appModel || updates.length === 0)
            return

        let updateMap = {}
        for (var i = 0; i < updates.length; i++)
            updateMap[updates[i].id] = updates[i]

        root.appModel.plugins = root.appModel.plugins.map(function(p) {
            let update = updateMap[p.pluginId]
            if (!update)
                return p

            return Object.assign({}, p, {
                updateAvailable: true,
                latestVersion:   update.latest_version
            })
        })
    }

    // Replaces appModel.plugins with the server list merged with local state.
    // When a search is active, only locally-installed plugins whose name/description
    // match the search text are appended (so local results blend in seamlessly).
    function mergePlugins(serverPlugins) {
        if (!root.appModel)
            return

        let searchLower = root.lastFetchedSearch.toLowerCase()
        let serverIds   = new Set()

        let merged = serverPlugins.map(function(sp) {
            serverIds.add(sp.id)
            let local = root.localPluginMap[sp.id]
            return buildPluginEntry(sp, local)
        })

        // Append locally-installed plugins absent from the server list.
        // When searching, restrict to entries that match the search text.
        for (var id in root.localPluginMap) {
            if (serverIds.has(id))
                continue

            let local = root.localPluginMap[id]
            if (searchLower !== "") {
                let nameMatch = local.name.toLowerCase().indexOf(searchLower) !== -1
                let descMatch = local.description.toLowerCase().indexOf(searchLower) !== -1

                if (!nameMatch && !descMatch)
                    continue
            }
            merged.push(buildLocalEntry(local))
        }

        root.appModel.plugins = merged
        checkUpdates()
    }

    // Appends new server results to the existing list (pagination).
    // Skips entries already present; does not re-append local-only plugins.
    function appendPlugins(serverPlugins) {
        if (!root.appModel)
            return

        let existingIds = new Set(root.appModel.plugins.map(function(p) { return p.pluginId }))

        let newItems = serverPlugins
            .filter(function(sp) { return !existingIds.has(sp.id) })
            .map(function(sp) {
                return buildPluginEntry(sp, root.localPluginMap[sp.id])
            })

        if (newItems.length > 0) {
            root.appModel.plugins = root.appModel.plugins.concat(newItems)
            checkUpdates()
        }
    }

    // Builds a display object from a server plugin entry and optional local info.
    function buildPluginEntry(sp, local) {
        return {
            pluginId:        sp.id,
            name:            sp.name,
            description:     sp.description,
            author:          sp.author,
            latestVersion:   sp.latest_version   || "",
            minAppVersion:   sp.min_app_version  || "",
            size:            sp.size_kb ? (sp.size_kb + " KB") : "",
            iconUrl:         sp.icon_url         || "",
            releaseDate:     sp.release_date     || "",
            isInstalled:     !!local,
            isEnabled:       local ? local.enabled : false,
            isCompatible:    local ? local.loaded  : true,
            updateAvailable: false
        }
    }

    // Builds a display object from a locally-installed plugin only.
    function buildLocalEntry(local) {
        return {
            pluginId:        local.id,
            name:            local.name,
            description:     local.description,
            author:          local.author,
            latestVersion:   local.version    || "",
            minAppVersion:   local.apiVersion || "",
            size:            "",
            iconUrl:         "",
            releaseDate:     "",
            isInstalled:     true,
            isEnabled:       local.enabled,
            isCompatible:    local.loaded,
            updateAvailable: false
        }
    }

    // Called whenever PluginManager.pluginsChanged fires.
    // Rebuilds localPluginMap and either patches existing entries or shows
    // local plugins as a fallback when no server data has been fetched yet.
    function syncLocalPlugins() {
        if (!root.appModel)
            return

        let infos = pluginManager.pluginInfos
        let localMap = {}

        for (var i = 0; i < infos.length; i++)
            localMap[infos[i].id] = infos[i]

        root.localPluginMap = localMap

        // Server data already loaded — just patch installation state
        if (root.appModel.plugins.length > 0) {
            root.appModel.plugins = root.appModel.plugins.map(function(p) {
                let local = localMap[p.pluginId]
                if (!local)
                    return p

                return Object.assign({}, p, {
                    isInstalled:  true,
                    isEnabled:    local.enabled,
                    isCompatible: local.loaded
                })
            })
            return
        }

        // No server data yet — show local plugins as an immediate fallback
        root.appModel.plugins = infos.map(function(info) {
            return buildLocalEntry(info)
        })
    }
}
