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
    property var          pageController:  null  // set by MainWindow after SwipeView is ready
    property CommitController          commitController: null

    // All pages that have been registered so far (populated before pageController exists).
    // MainWindow reads this list after setting pageController to drain any early registrations.
    property var registeredPages: []

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
    property string installingPluginId:   ""
    property string installingPluginName: ""
    property string installPhase:         ""
    property real   installProgress:      -1   // 0-100, or -1 for indeterminate
    property var    pluginDetail:         null  // rich detail payload for the detail page
    property bool   pluginDetailBusy:     false
    property string pluginDetailError:    ""


    readonly property string pluginApiBaseUrl:               "http://localhost/api"
    readonly property string fetchPluginsRequestKey:         "plugin-fetch"
    readonly property string fetchCategoriesRequestKey:      "plugin-fetch-categories"
    readonly property string checkUpdatesRequestKey:         "plugin-check-updates"
    readonly property string fetchPluginDetailKeyPrefix:     "plugin-detail-"
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

        onPageRegistered: function(id, qmlUrl, title, icon, order, pluginId) {
            console.log("[PluginController] Page registered:", id, "→", qmlUrl)
            root.registeredPages = root.registeredPages.concat([{
                id: id, title: title, qmlUrl: qmlUrl, icon: icon, pluginId: pluginId || id
            }])
            if (root.pageController)
                root.pageController.createPage(id, title, qmlUrl, icon)
        }

        onPluginAboutToUnload: function(id) {
            let kept = []
            for (let i = 0; i < root.registeredPages.length; i++) {
                let p = root.registeredPages[i]
                if (p.pluginId === id || p.id === id) {
                    if (root.pageController && root.pageController.removePage)
                        root.pageController.removePage(p.id)
                } else {
                    kept.push(p)
                }
            }
            root.registeredPages = kept
        }

        onNotifyRequested: function(message, type) {
            switch (type) {
                case "error":   root.notificationController.error(message);   break
                case "warning": root.notificationController.warning(message); break
                case "success": root.notificationController.success(message); break
                default:        root.notificationController.info(message);    break
            }
        }

        onPluginInstallStarted: function(id, name) {
            console.log("[PluginController] Plugin install started:", id, name)
            root.installingPluginId   = id
            root.installingPluginName = name
            root.setInstallState(id, true, "Installing", -1)
        }

        onPluginInstalled: function(id) {
            console.log("[PluginController] Plugin installed:", id)
            root.setInstallState(id, false)
            if (root.appModel) {
                let ids = root.appModel.enabledPluginIds ? root.appModel.enabledPluginIds.slice() : []
                if (ids.indexOf(id) === -1)
                    ids.push(id)
                root.appModel.enabledPluginIds = ids
                root.appModel.save()
            }
            root.notificationController.success("Plugin installed successfully.", "Plugins")
        }

        onPluginRemoved: function(id) {
            console.log("[PluginController] Plugin removed:", id)
            root.setInstallState(id, false)

            if (root.appModel) {
                let ids = (root.appModel.enabledPluginIds || []).filter(function(x) {
                    return x !== id
                })
                root.appModel.enabledPluginIds = ids
                root.appModel.save()
            }

            root.notificationController.info("Plugin uninstalled.", "Plugins")
        }

        onPluginInstallFailed: function(id, error) {
            console.warn("[PluginController] Plugin install failed:", id, error)
            root.setInstallState(id, false)
            if (error)
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
        // Defer scanning one event-loop tick so that all Component.onCompleted handlers fire
        // first — including MainWindow's SwipeView which sets pageController. Without this
        // deferral, pageRegistered signals arrive before pageController is available.
        Qt.callLater(function() {
            pluginManager.scanDefaultDirectory()
            pluginManager.scanApplicationPluginsDirectory()
        })
    }

    property Connections commitConnections: Connections {
        target: root.commitController

        function onBeforeAction(ccc) {
            pluginManager.runBeforeAction(ccc)
        }
    }

    /* Network connections
     * ****************************************************************************************/
    property Connections networkConnections: Connections {
        target: root.networkController

        function onRequestFinished(requestKey, response) {
            if (requestKey === root.fetchPluginsRequestKey) {
                root.handleFetchPluginsResponse(response)
            } else if (requestKey === root.fetchCategoriesRequestKey) {
                root.handleFetchPluginsCategoriesResponse(response)
            } else if (requestKey === root.checkUpdatesRequestKey) {
                root.handleCheckUpdatesResponse(response)
            } else if (requestKey.startsWith(root.fetchPluginDetailKeyPrefix)) {
                root.handleFetchPluginDetailResponse(requestKey, response)
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

            if (requestKey.startsWith(root.fetchPluginDetailKeyPrefix)) {
                root.pluginDetailBusy = false
                root.pluginDetailError = message || "Failed to load plugin details."
                console.warn("[PluginController] Plugin detail error:", requestKey, code, message)
                return
            }

            if (requestKey.startsWith(root.getPluginDownloadKeyPrefix)
                    || requestKey.startsWith(root.downloadPluginKeyPrefix)) {
                let pluginId = root.pendingInstallKeys[requestKey] ?? ""

                delete root.pendingInstallKeys[requestKey]
                delete root.pendingInstallHashes[requestKey]

                if (pluginId) {
                    root.setInstallState(pluginId, false)
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

            if (requestKey.startsWith(root.fetchPluginDetailKeyPrefix)) {
                root.pluginDetailBusy = false
                root.pluginDetailError = "Request timed out."
                return
            }

            if (requestKey.startsWith(root.getPluginDownloadKeyPrefix)
                    || requestKey.startsWith(root.downloadPluginKeyPrefix)) {
                let pluginId = root.pendingInstallKeys[requestKey] ?? ""

                delete root.pendingInstallKeys[requestKey]
                delete root.pendingInstallHashes[requestKey]

                if (pluginId) {
                    root.setInstallState(pluginId, false)
                    root.notificationController.error("Plugin operation timed out.", "Plugins")
                }
            }
        }

        function onDownloadProgress(requestKey, bytesReceived, bytesTotal) {
            if (!requestKey.startsWith(root.downloadPluginKeyPrefix))
                return

            let pluginId = root.pendingInstallKeys[requestKey] ?? ""
            if (!pluginId || root.installingPluginId !== pluginId)
                return

            if (bytesTotal > 0) {
                let progress = Math.max(0, Math.min(100, Math.round((bytesReceived / bytesTotal) * 100)))
                if (progress === root.installProgress && root.installPhase === "Downloading")
                    return
                root.installPhase = "Downloading"
                root.installProgress = progress
            } else {
                root.installPhase = "Downloading"
                root.installProgress = -1
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    // The catalog returns root-relative paths ("/api/plugins/..."). Image and
    // QNetworkAccessManager need an absolute URL; a leading slash otherwise
    // becomes qrc:/... or a request whose scheme is empty.
    function resolveApiUrl(url) {
        if (!url)
            return ""

        if (url.indexOf("://") !== -1 || url.startsWith("qrc:") || url.startsWith("file:"))
            return url

        let base = root.pluginApiBaseUrl
        if (url.charAt(0) === "/") {
            let schemeEnd = base.indexOf("://")
            let hostStart = schemeEnd === -1 ? 0 : schemeEnd + 3
            let pathStart = base.indexOf("/", hostStart)
            let origin = pathStart === -1 ? base : base.substring(0, pathStart)
            return origin + url
        }

        if (base.charAt(base.length - 1) === "/")
            return base + url
        return base + "/" + url
    }

    // Fetches plugins categories
    function fetchPluginsCategories() {
        console.warn("[fetchPluginsCategories]")

        if (!root.networkController || root.busy)
            return

        root.busy = true

        let url = root.pluginApiBaseUrl + "/plugins/categories"

        root.networkController.sendRequest(
            root.fetchCategoriesRequestKey,
            url,
            root.networkController.GET
        )
    }

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

    function setInstallState(pluginId, busy, phase, progress) {
        if (busy) {
            if (root.installingPluginId !== pluginId) {
                root.installingPluginId = pluginId
                let name = ""
                if (root.appModel) {
                    for (let i = 0; i < root.appModel.plugins.length; i++) {
                        if (root.appModel.plugins[i].pluginId === pluginId) {
                            name = root.appModel.plugins[i].name || ""
                            break
                        }
                    }
                }
                root.installingPluginName = name
            }
            root.installPhase = phase || "Preparing"
            root.installProgress = (progress === undefined || progress === null) ? -1 : progress
            root.setPluginBusy(pluginId, true)
        } else {
            if (root.installingPluginId === pluginId || !pluginId) {
                root.installingPluginId = ""
                root.installingPluginName = ""
                root.installPhase = ""
                root.installProgress = -1
            }
            if (pluginId)
                root.setPluginBusy(pluginId, false)
        }
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

    function fetchPluginDetails(pluginId) {
        if (!root.networkController || !pluginId)
            return

        // Seed from the catalog entry so the page can render immediately.
        let local = null
        if (root.appModel) {
            for (let i = 0; i < root.appModel.plugins.length; i++) {
                if (root.appModel.plugins[i].pluginId === pluginId) {
                    local = root.appModel.plugins[i]
                    break
                }
            }
        }

        root.pluginDetailError = ""
        root.pluginDetailBusy = true
        root.pluginDetail = local ? Object.assign({}, local) : { pluginId: pluginId, name: pluginId }

        root.networkController.sendRequest(
            root.fetchPluginDetailKeyPrefix + pluginId,
            root.pluginApiBaseUrl + "/plugins/" + encodeURIComponent(pluginId),
            root.networkController.GET
        )
    }

    function clearPluginDetails() {
        root.pluginDetail = null
        root.pluginDetailBusy = false
        root.pluginDetailError = ""
    }

    function handleFetchPluginDetailResponse(requestKey, response) {
        root.pluginDetailBusy = false
        let payload = response?.data ?? {}

        if (payload?.success === false) {
            root.pluginDetailError = payload?.error || "Failed to load plugin details."
            return
        }

        let sp = payload?.data ?? null
        if (!sp) {
            root.pluginDetailError = "Plugin details were empty."
            return
        }

        let local = root.localPluginMap[sp.id]
        let existing = null
        if (root.appModel) {
            for (let i = 0; i < root.appModel.plugins.length; i++) {
                if (root.appModel.plugins[i].pluginId === sp.id) {
                    existing = root.appModel.plugins[i]
                    break
                }
            }
        }

        let entry = buildPluginEntry(sp, local)
        if (existing) {
            entry.isInstalled = existing.isInstalled
            entry.isEnabled = existing.isEnabled
            entry.isCompatible = existing.isCompatible
            entry.updateAvailable = existing.updateAvailable
            entry.busy = existing.busy
            if (existing.latestVersion && !entry.latestVersion)
                entry.latestVersion = existing.latestVersion
        }

        root.pluginDetail = entry
    }

    function installPlugin(pluginId, phase) {
        if (!root.networkController)
            return

        root.setInstallState(pluginId, true, phase || "Preparing", 0)

        let requestKey = root.getPluginDownloadKeyPrefix + pluginId
        root.pendingInstallKeys[requestKey] = pluginId

        root.networkController.sendRequest(
            requestKey,
            root.pluginApiBaseUrl + "/plugins/" + encodeURIComponent(pluginId) + "/download",
            root.networkController.GET
        )
    }

    function installGepFile(gepPath) {
        if (!gepPath)
            return
        pluginManager.installGepFile(gepPath)
    }

    function uninstallPlugin(pluginId) {
        if (!pluginId)
            return
        root.setInstallState(pluginId, true, "Uninstalling", -1)
        if (!pluginManager.removePlugin(pluginId)) {
            root.setInstallState(pluginId, false)
            root.notificationController.error("Could not uninstall plugin.", "Plugins")
        }
    }

    function updatePlugin(pluginId) {
        root.installPlugin(pluginId, "Updating")
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
            NetworkManager.POST,
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

    function handleFetchPluginsCategoriesResponse(response) {
        if (!root.appModel)
            return

        root.busy = false
        let payload = response?.data ?? {}

        if (payload?.success === false) {
            console.warn("[PluginController] Fetch plugins categories failed:", payload?.error ?? "unknown error")
            return
        }

        let categories = payload?.data ?? []
        let addedCategories = {}
        let next = []

        for (let i = 0; i < categories.length; i++) {
            let category = categories[i]
            if (!category || addedCategories[category.id])
                continue

            addedCategories[category.id] = true
            next.push({
                id: category.id,
                name: category.name,
                color: category.color,
                iconUrl: root.resolveApiUrl(category.icon_url)
            })
        }

        root.appModel.pluginsCategories = next
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
            root.setInstallState(pluginId, false)
            root.notificationController.error("Failed to get download link for plugin.", "Plugins")
            return
        }

        let downloadUrl = root.resolveApiUrl(payload?.data?.download_url ?? "")
        if (!downloadUrl) {
            console.warn("[PluginController] No download URL in response for:", pluginId)
            root.setInstallState(pluginId, false)
            root.notificationController.error("Server returned no download URL.", "Plugins")
            return
        }

        let expectedMd5 = payload?.data?.checksum_md5 ?? ""

        let dlKey = root.downloadPluginKeyPrefix + pluginId
        root.pendingInstallKeys[dlKey] = pluginId
        root.pendingInstallHashes[dlKey] = expectedMd5  // store for verification after download
        root.setInstallState(pluginId, true, "Downloading", 0)
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
            root.setInstallState(pluginId, false)
            root.notificationController.error("Download failed for plugin: " + pluginId, "Plugins")
            return
        }

        root.setInstallState(pluginId, true, "Installing", 100)
        if (!pluginManager.installGepFromBase64(base64Data))
            root.setInstallState(pluginId, false)
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
        let downloads = sp.downloads_count ?? sp.donwloads_count ?? 0
        let sizeKb = sp.size_kb || 0
        return {
            pluginId:         sp.id,
            name:             sp.name,
            description:      sp.description || "",
            longDescription:  sp.long_description || "",
            features:         sp.features || [],
            installGuide:     sp.install_guide || "",
            changelog:        sp.changelog || [],
            tags:             sp.tags || [],
            screenshots:      root.normalizeScreenshots(sp.screenshots),
            githubUrl:        sp.github_url || "",
            author:           sp.author,
            latestVersion:    sp.latest_version   || "",
            minAppVersion:    sp.min_app_version  || "",
            size:             sizeKb ? (sizeKb + " KB") : "",
            sizeKb:           sizeKb,
            iconUrl:          root.resolveApiUrl(sp.icon_url || ""),
            releaseDate:      sp.release_date     || "",
            category:         sp.category || "",
            mainColor:        getCategoryColor(sp.category),
            donwloadsCount:   downloads,
            downloadsCount:   downloads,
            isInstalled:      !!local,
            isEnabled:        local ? local.enabled : false,
            isCompatible:     local ? local.loaded  : true,
            updateAvailable:  false,
            busy:             false
        }
    }

    // Accepts string URLs or {url,src,image_url,caption} objects from the catalog.
    function normalizeScreenshots(raw) {
        let list = raw || []
        let out = []

        for (let i = 0; i < list.length; i++) {
            let item = list[i]
            let url = ""
            let caption = ""

            if (typeof item === "string") {
                url = item
            } else if (item && typeof item === "object") {
                url = item.url || item.src || item.image_url || item.path || item.file || ""
                caption = item.caption || item.title || item.alt || ""
            }

            url = root.resolveApiUrl(url)
            if (!url)
                continue

            let lower = url.toLowerCase()
            let isGif = lower.indexOf(".gif") !== -1
                        || lower.indexOf("image/gif") !== -1
                        || (item && item.type === "gif")

            out.push({
                url: url,
                caption: caption,
                isGif: isGif
            })
        }

        return out
    }

    // Builds a display object from a locally-installed plugin only.
    function buildLocalEntry(local) {
        return {
            pluginId:         local.id,
            name:             local.name,
            description:      local.description || "",
            longDescription:  "",
            features:         [],
            installGuide:     "",
            changelog:        [],
            tags:             local.capabilities || [],
            screenshots:      [],
            githubUrl:        "",
            author:           local.author,
            latestVersion:    local.version    || "",
            minAppVersion:    local.minAppVersion || local.apiVersion || "",
            category:         local.category || "",
            mainColor:        getCategoryColor(local.category),
            size:             local.size       || "",
            sizeKb:           0,
            iconUrl:          local.iconUrl     ? local.iconUrl : (local.icon ? ("file://" + local.pluginDir + "/" + local.icon) : ""),
            releaseDate:      local.releaseDate || "",
            donwloadsCount:   0,
            downloadsCount:   0,
            isInstalled:      true,
            isEnabled:        local.enabled,
            isCompatible:     local.loaded,
            updateAvailable:  false,
            busy:             false
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

    // Get plugin main color based on its categoryId
    function getCategoryColor(categoryId) {
        let cats = root.appModel?.pluginsCategories ?? []
        for (let i = 0; i < cats.length; i++) {
            if (cats[i].id === categoryId)
                return cats[i].color
        }

        return ""
    }
}
