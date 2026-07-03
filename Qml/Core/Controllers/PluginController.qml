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

    // server plugin IDs seen so far — used in syncLocalPlugins to distinguish server vs local-only entries
    property var    serverPluginIds:    ({})
    // map of in-progress install requests: requestKey → pluginId
    property var    pendingInstallKeys:   ({})
    // map of expected MD5 hashes for in-progress downloads: requestKey → md5 hex string
    property var    pendingInstallHashes: ({})


    readonly property string pluginApiBaseUrl:               "https://gitease.app/api"
    readonly property string fetchPluginsRequestKey:         "plugin-fetch"
    readonly property string checkUpdatesRequestKey:         "plugin-check-updates"
    readonly property string getPluginDownloadKeyPrefix:     "plugin-get-download-"
    readonly property string downloadPluginKeyPrefix:        "plugin-download-"

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

        onPluginInstalled: function(id) {
            console.log("[PluginController] Plugin installed:", id)
            root.setPluginBusy(id, false)
            root.notificationController.success("Plugin installed successfully.", "Plugins")
        }

        onPluginRemoved: function(id) {
            console.log("[PluginController] Plugin removed:", id)
            root.setPluginBusy(id, false)
            root.notificationController.info("Plugin uninstalled.", "Plugins")
        }

        onPluginInstallFailed: function(id, error) {
            console.warn("[PluginController] Plugin install failed:", id, error)
            root.setPluginBusy(id, false)
            root.notificationController.error("Could not install plugin: " + error, "Plugins")
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
            } else if (requestKey.startsWith(root.getPluginDownloadKeyPrefix)) {
                root.handleGetPluginDownloadResponse(requestKey, response)
            } else if (requestKey.startsWith(root.downloadPluginKeyPrefix)) {
                root.handlePluginDownloadResponse(requestKey, response)
            }
        }

        function onRequestError(requestKey, code, message) {
            if (requestKey === root.fetchPluginsRequestKey || requestKey === root.checkUpdatesRequestKey) {
                root.busy       = false
                root.appendMode = false
                console.warn("[PluginController] Request error:", requestKey, code, message)
                return
            }

            if (requestKey.startsWith(root.getPluginDownloadKeyPrefix)
                    || requestKey.startsWith(root.downloadPluginKeyPrefix)) {
                let pluginId = root.pendingInstallKeys[requestKey] ?? ""

                delete root.pendingInstallKeys[requestKey]
                delete root.pendingInstallHashes[requestKey]

                if (pluginId) {
                    root.setPluginBusy(pluginId, false)
                    root.notificationController.error("Plugin operation failed: " + message, "Plugins")
                }
            }
        }

        function onTimeout(requestKey) {
            if (requestKey === root.fetchPluginsRequestKey || requestKey === root.checkUpdatesRequestKey) {
                root.busy       = false
                root.appendMode = false
                console.warn("[PluginController] Request timed out:", requestKey)
                return
            }

            if (requestKey.startsWith(root.getPluginDownloadKeyPrefix)
                    || requestKey.startsWith(root.downloadPluginKeyPrefix)) {
                let pluginId = root.pendingInstallKeys[requestKey] ?? ""

                delete root.pendingInstallKeys[requestKey]
                delete root.pendingInstallHashes[requestKey]

                if (pluginId) {
                    root.setPluginBusy(pluginId, false)
                    root.notificationController.error("Plugin operation timed out.", "Plugins")
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    // Fetches page 1 and REPLACES the current list (initial load or new search).
    function fetchAvailablePlugins(page, search) {
        console.warn("[fetchAvailablePlugins]", page, search)

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

    function setPluginBusy(pluginId, busy) {
        if (!root.appModel)
            return

        root.appModel.plugins = root.appModel.plugins.map(function(p) {
            if (p.pluginId !== pluginId)
                return p

            return Object.assign({}, p, { busy: busy })
        })
    }

    function togglePlugin(pluginId, enabled) {
        pluginManager.enablePlugin(pluginId, enabled)

        let ids = root.appModel.enabledPluginIds ? root.appModel.enabledPluginIds.slice() : []
        if (enabled) {
            if (ids.indexOf(pluginId) === -1)
                ids.push(pluginId)
        } else {
            ids = ids.filter(function(id) {
                return id !== pluginId
            })
        }
        root.appModel.enabledPluginIds = ids
        root.appModel.save()
    }

    function installPlugin(pluginId) {
        if (!root.networkController)
            return

        root.setPluginBusy(pluginId, true)

        let requestKey = root.getPluginDownloadKeyPrefix + pluginId
        root.pendingInstallKeys[requestKey] = pluginId

        root.networkController.sendRequest(
            requestKey,
            root.pluginApiBaseUrl + "/plugins/" + encodeURIComponent(pluginId) + "/download",
            root.networkController.GET
        )
    }

    function uninstallPlugin(pluginId) {
        root.setPluginBusy(pluginId, true)
        if (!pluginManager.removePlugin(pluginId))
            root.setPluginBusy(pluginId, false)
    }

    function updatePlugin(pluginId) {
        root.installPlugin(pluginId)
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
            console.warn("[PluginController] Fetch plugins failed:", payload?.error ?? "unknown error")
            root.appendMode = false
            return
        }

        let serverPlugins = payload?.data ?? []
        let pagination     = payload?.pagination ?? {}
        root.hasMorePages  = (pagination.page ?? 1) < (pagination.total_pages ?? 1)

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

    function handleGetPluginDownloadResponse(requestKey, response) {
        let pluginId = root.pendingInstallKeys[requestKey] ?? ""

        delete root.pendingInstallKeys[requestKey]

        if (!pluginId)
            return

        let payload = response?.data ?? {}
        if (payload?.success === false) {
            console.warn("[PluginController] Get plugin download failed:", payload?.error ?? "unknown error")
            root.setPluginBusy(pluginId, false)
            root.notificationController.error("Failed to get download link for plugin.", "Plugins")
            return
        }

        let downloadUrl = payload?.data?.download_url ?? ""
        if (!downloadUrl) {
            console.warn("[PluginController] No download URL in response for:", pluginId)
            root.setPluginBusy(pluginId, false)
            root.notificationController.error("Server returned no download URL.", "Plugins")
            return
        }

        let expectedMd5 = payload?.data?.checksum_md5 ?? ""

        let dlKey = root.downloadPluginKeyPrefix + pluginId
        root.pendingInstallKeys[dlKey] = pluginId
        root.pendingInstallHashes[dlKey] = expectedMd5  // store for verification after download
        root.networkController.downloadRequest(dlKey, downloadUrl)
    }

    function handlePluginDownloadResponse(requestKey, response) {
        let pluginId = root.pendingInstallKeys[requestKey]   ?? ""
        let expectedMd5 = root.pendingInstallHashes[requestKey] ?? ""

        delete root.pendingInstallKeys[requestKey]
        delete root.pendingInstallHashes[requestKey]

        if (!pluginId)
            return

        let payload = response?.data ?? {}
        let base64Data = payload?.file_data_base64 ?? ""

        if (!base64Data) {
            console.warn("[PluginController] Empty download data for:", pluginId)
            root.setPluginBusy(pluginId, false)
            root.notificationController.error("Download failed for plugin: " + pluginId, "Plugins")
            return
        }

        // Pass expectedMd5 — empty string means "skip verification" (server didn't provide a hash)
        pluginManager.installPluginFromBase64Zip(pluginId, base64Data, expectedMd5)
    }

    // Replaces appModel.plugins with the server list merged with local state.
    function mergePlugins(serverPlugins) {
        if (!root.appModel)
            return

        let searchLower = root.lastFetchedSearch.toLowerCase()
        let newServerIds = {}

        let merged = serverPlugins.map(function(sp) {
            newServerIds[sp.id] = true
            let local = root.localPluginMap[sp.id]
            return buildPluginEntry(sp, local)
        })

        root.serverPluginIds = newServerIds

        // Append locally-installed plugins absent from the server list.
        for (var id in root.localPluginMap) {
            if (newServerIds[id])
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
    function appendPlugins(serverPlugins) {
        if (!root.appModel)
            return

        let existingIds = {}
        root.appModel.plugins.forEach(function(p) { existingIds[p.pluginId] = true })

        let newItems = serverPlugins
            .filter(function(sp) { return !existingIds[sp.id] })
            .map(function(sp) {
                root.serverPluginIds[sp.id] = true
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
            updateAvailable: false,
            busy:            false
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
            updateAvailable: false,
            busy:            false
        }
    }

    // Called whenever PluginManager.pluginsChanged fires.
    function syncLocalPlugins() {
        if (!root.appModel)
            return

        let infos = pluginManager.pluginInfos
        let localMap = {}

        for (var i = 0; i < infos.length; i++)
            localMap[infos[i].id] = infos[i]

        root.localPluginMap = localMap

        if (root.appModel.plugins.length > 0) {
            root.appModel.plugins = root.appModel.plugins
                .map(function(p) {
                    let local = localMap[p.pluginId]
                    if (!local)
                        return Object.assign({}, p, {
                                                 isInstalled: false,
                                                 isEnabled: false,
                                                 isCompatible: true,
                                                 updateAvailable: false,
                                                 busy: false })

                    return Object.assign({}, p, {
                        isInstalled: true,
                        isEnabled: local.enabled,
                        isCompatible: local.loaded
                    })
                })

                // Drop local-only entries that are no longer installed
                .filter(function(p) {
                    return root.serverPluginIds[p.pluginId] || p.isInstalled
                })
            return
        }

        // No server data yet — show local plugins as an immediate fallback
        root.appModel.plugins = infos.map(function(info) {
            return buildLocalEntry(info)
        })
    }
}
