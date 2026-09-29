import QtQuick

import GitEase

/*! ***********************************************************************************************
 * UpdateController
 * Owns the application update flow and exposes updater state for UI surfaces.
 *
 * Flow: check → (available) → prepare download link → download to disk → ready → restart & install.
 * ************************************************************************************************/
UpdateManager {
    id: root

    enum UpdateRequestType {
        None,
        CheckApplicationUpdate,
        GetApplicationUpdateDownload,
        DownloadApplicationInstaller
    }

    /* Property Declarations
     * ****************************************************************************************/
    property NetworkController      networkController:      null
    property NotificationController notificationController: null

    property int    pendingRequestType:     UpdateController.None
    property int    failedRequestType:      UpdateController.None
    property string pendingUpdateVersion:   ""
    property string pendingUpdateOs:        ""
    property bool   hasCheckedOnStartup:    false
    property bool   silentCheck:            false

    // One of: idle, checking, upToDate, available, preparing, downloading, ready, restarting, error
    property string phase:                  "idle"
    property string statusText:             "Not checked yet"
    property string statusType:             "info"
    property bool   updateAvailable:        false
    property bool   isCritical:             false
    property string latestVersion:          ""
    property string downloadSize:           ""
    property string releaseNotes:           ""
    property date   lastCheckedAt
    property bool   hasLastChecked:         false

    property string stagedFilePath:         ""
    property real   bytesReceived:          0
    property real   bytesTotal:             0
    property real   downloadSpeed:          0     // bytes per second, smoothed
    property real   speedSampleTime:        0
    property real   speedSampleBytes:       0

    readonly property bool busy:            root.phase === "checking"
                                            || root.phase === "preparing"
                                            || root.phase === "downloading"
                                            || root.phase === "restarting"
    readonly property bool canCancel:       root.phase === "preparing" || root.phase === "downloading"
    readonly property real downloadProgress: root.bytesTotal > 0
                                             ? Math.min(1, root.bytesReceived / root.bytesTotal)
                                             : -1

    readonly property string appUpdateApiBaseUrl:                    "https://gitease.app/api"
    readonly property string checkApplicationUpdateRequestKey:       "check-application-update"
    readonly property string getApplicationUpdateDownloadRequestKey: "get-application-update-download"
    readonly property string downloadApplicationInstallerRequestKey: "download-application-installer"

    /* Functions
     * ****************************************************************************************/
    function currentOperatingSystem() {
        if (Qt.platform.os === "osx") {
            return "mac"
        }
        return Qt.platform.os
    }

    function setStatus(phase, text, type) {
        root.phase = phase
        root.statusText = text
        root.statusType = type
    }

    function checkForUpdates(silent) {
        if (!root.networkController) {
            root.setStatus("error", "Update service is not available.", "error")
            console.warn("[AppUpdater] Update service is not available.")
            return
        }

        if (root.pendingRequestType !== UpdateController.None) {
            console.warn("[AppUpdater] Application update request is already in progress:", root.pendingRequestType)
            return
        }

        var currentVersion = Qt.application.version || "0.0.0"
        var operatingSystem = root.currentOperatingSystem()
        var requestUrl = root.appUpdateApiBaseUrl
                + "/app/check-update?current_version=" + encodeURIComponent(currentVersion)
                + "&os=" + encodeURIComponent(operatingSystem)

        root.silentCheck = silent === true
        root.failedRequestType = UpdateController.None
        root.setStatus("checking", "Checking for updates…", "info")
        root.pendingRequestType = UpdateController.CheckApplicationUpdate
        root.pendingUpdateOs = operatingSystem
        console.log("[AppUpdater] Checking for application updates:", requestUrl)
        root.networkController.sendRequest(
                    root.checkApplicationUpdateRequestKey,
                    requestUrl,
                    root.networkController.GET
                    )
    }

    function checkForUpdatesOnStartup() {
        root.showCompletedUpdateResult()

        if (root.hasCheckedOnStartup) {
            return
        }

        root.hasCheckedOnStartup = true
        root.checkForUpdates(true)
    }

    function installAvailableUpdate() {
        if (!root.updateAvailable || root.latestVersion === "") {
            root.setStatus("idle", "No update is available to install.", "info")
            return
        }

        root.requestUpdateDownload(root.latestVersion)
    }

    function requestUpdateDownload(version) {
        if (!root.networkController) {
            root.setStatus("error", "Update service is not available.", "error")
            return
        }

        if (root.pendingRequestType !== UpdateController.None) {
            console.warn("[AppUpdater] Application update request is already in progress:", root.pendingRequestType)
            return
        }

        var operatingSystem = root.pendingUpdateOs || root.currentOperatingSystem()
        var requestUrl = root.appUpdateApiBaseUrl
                + "/app/download?version=" + encodeURIComponent(version)
                + "&os=" + encodeURIComponent(operatingSystem)

        root.failedRequestType = UpdateController.None
        root.resetDownloadProgress()
        root.setStatus("preparing", "Preparing download…", "info")
        root.pendingRequestType = UpdateController.GetApplicationUpdateDownload
        root.pendingUpdateVersion = version
        root.pendingUpdateOs = operatingSystem
        console.log("[AppUpdater] Getting application update download link:", requestUrl)
        root.networkController.sendRequest(
                    root.getApplicationUpdateDownloadRequestKey,
                    requestUrl,
                    root.networkController.GET
                    )
    }

    function startInstallerDownload(downloadInfo) {
        var fileUrl = downloadInfo?.file_url ?? downloadInfo?.download_url ?? ""

        if (fileUrl === "") {
            console.warn("[AppUpdater] Update download response did not contain a file URL.")
            root.handleUpdateRequestFailed(UpdateController.GetApplicationUpdateDownload, -1,
                                           "The server did not return a download link.")
            return
        }

        var targetPath = root.prepareUpdateFilePath(fileUrl)
        if (targetPath === "") {
            // UpdateManager already emitted updateFailed with the reason.
            return
        }

        console.log("[AppUpdater] Starting application update download:", fileUrl, "->", targetPath)
        root.stagedFilePath = ""
        root.speedSampleTime = Date.now()
        root.setStatus("downloading", "Downloading version " + root.latestVersion + "…", "info")
        root.pendingRequestType = UpdateController.DownloadApplicationInstaller
        root.networkController.downloadToFile(
                    root.downloadApplicationInstallerRequestKey,
                    fileUrl,
                    targetPath
                    )
    }

    function cancelUpdate() {
        if (!root.canCancel) {
            return
        }

        var requestKey = root.requestKeyForType(root.pendingRequestType)
        if (requestKey !== "" && root.networkController) {
            root.networkController.cancelRequest(requestKey)
        }

        console.log("[AppUpdater] Update download canceled by user.")
        root.pendingRequestType = UpdateController.None
        root.resetDownloadProgress()
        root.setStatus("available", "Download canceled.", "info")
    }

    function retry() {
        if (root.failedRequestType === UpdateController.CheckApplicationUpdate
                || !root.updateAvailable) {
            root.checkForUpdates(false)
            return
        }

        root.installAvailableUpdate()
    }

    function restartToInstall() {
        if (root.phase !== "ready" || root.stagedFilePath === "") {
            return
        }

        // The swap helper only waits ~30s for GitEase to exit, so it is scheduled right before quitting.
        root.installDownloadedUpdate(root.stagedFilePath, root.latestVersion)
    }

    function resetDownloadProgress() {
        root.bytesReceived = 0
        root.bytesTotal = 0
        root.downloadSpeed = 0
        root.speedSampleTime = 0
        root.speedSampleBytes = 0
    }

    function requestKeyForType(requestType) {
        if (requestType === UpdateController.CheckApplicationUpdate) {
            return root.checkApplicationUpdateRequestKey
        }
        if (requestType === UpdateController.GetApplicationUpdateDownload) {
            return root.getApplicationUpdateDownloadRequestKey
        }
        if (requestType === UpdateController.DownloadApplicationInstaller) {
            return root.downloadApplicationInstallerRequestKey
        }
        return ""
    }

    function requestTypeForKey(requestKey) {
        if (requestKey === root.checkApplicationUpdateRequestKey) {
            return UpdateController.CheckApplicationUpdate
        }
        if (requestKey === root.getApplicationUpdateDownloadRequestKey) {
            return UpdateController.GetApplicationUpdateDownload
        }
        if (requestKey === root.downloadApplicationInstallerRequestKey) {
            return UpdateController.DownloadApplicationInstaller
        }
        return UpdateController.None
    }

    // Returns the request type if the key belongs to the in-flight update request, otherwise None.
    function claimPendingRequest(requestKey) {
        var requestType = root.requestTypeForKey(requestKey)

        if (requestType === UpdateController.None || root.pendingRequestType !== requestType) {
            return UpdateController.None
        }

        root.pendingRequestType = UpdateController.None
        return requestType
    }

    function handleUpdateResponse(requestKey, response) {
        var requestType = root.claimPendingRequest(requestKey)

        if (requestType === UpdateController.None) {
            return
        }

        var payload = response?.data ?? {}
        var updateData = payload?.data ?? payload

        if (payload?.success === false) {
            var serverMessage = payload?.error ?? "The update server returned an unsuccessful response."
            root.handleUpdateRequestFailed(requestType, -1, serverMessage)
            return
        }

        if (requestType === UpdateController.CheckApplicationUpdate) {
            root.handleUpdateCheckSuccess(updateData)
        } else if (requestType === UpdateController.GetApplicationUpdateDownload) {
            root.handleUpdateDownloadInfoSuccess(updateData)
        } else if (requestType === UpdateController.DownloadApplicationInstaller) {
            root.handleUpdateFileDownloaded(updateData)
        }
    }

    function handleUpdateError(requestKey, code, message) {
        var requestType = root.claimPendingRequest(requestKey)

        if (requestType !== UpdateController.None) {
            root.handleUpdateRequestFailed(requestType, code, message)
        }
    }

    function handleUpdateTimeout(requestKey) {
        var requestType = root.claimPendingRequest(requestKey)

        if (requestType !== UpdateController.None) {
            root.handleUpdateRequestFailed(requestType, -2, "Request timed out.")
        }
    }

    function handleUpdateCheckSuccess(updateInfo) {
        var currentVersion = Qt.application.version || "0.0.0"
        var wasSilent = root.silentCheck

        root.silentCheck = false
        root.lastCheckedAt = new Date()
        root.hasLastChecked = true
        console.log("[AppUpdater] Application update check response:", JSON.stringify(updateInfo))

        if (!updateInfo?.update_available) {
            root.updateAvailable = false
            root.isCritical = false
            root.latestVersion = updateInfo?.latest_version ?? currentVersion
            root.releaseNotes = ""
            root.setStatus("upToDate", "You're on the latest version.", "success")

            if (!wasSilent) {
                root.notify("success", "GitEase " + currentVersion + " is the latest version.", "GitEase Update")
            }
            return
        }

        var version = updateInfo?.latest_version ?? "unknown"

        // A newer check must not throw away an installer that is already staged for this version.
        if (root.stagedFilePath !== "" && version === root.latestVersion) {
            root.setStatus("ready", "Version " + version + " is downloaded. Restart GitEase to finish updating.", "success")
            return
        }

        root.updateAvailable = true
        root.isCritical = updateInfo?.is_critical === true
        root.latestVersion = version
        root.releaseNotes = updateInfo?.release_notes ?? ""
        root.stagedFilePath = ""
        root.setStatus("available",
                       root.isCritical ? "A critical update is available. Please install it soon."
                                       : "A new version is ready to download.",
                       root.isCritical ? "warning" : "info")

        root.notify(root.isCritical ? "warning" : "info",
                    (root.isCritical ? "Critical update " : "Version ") + version
                    + " is available. Open Settings → Updates to install it.",
                    "GitEase Update", 8000)
    }

    function handleUpdateDownloadInfoSuccess(downloadInfo) {
        var sizeMb = downloadInfo?.size_mb
        console.log("[AppUpdater] Application update download response:", JSON.stringify(downloadInfo))

        if (sizeMb !== undefined && sizeMb !== null) {
            root.downloadSize = sizeMb + " MB"
            root.bytesTotal = sizeMb * 1024 * 1024
        }

        root.startInstallerDownload(downloadInfo)
    }

    function handleUpdateFileDownloaded(downloadInfo) {
        var filePath = downloadInfo?.file_path ?? ""

        if (filePath === "") {
            root.handleUpdateRequestFailed(UpdateController.DownloadApplicationInstaller, -1,
                                           "Downloaded file is missing.")
            return
        }

        root.stagedFilePath = filePath
        root.bytesReceived = root.bytesTotal
        root.downloadSpeed = 0
        console.log("[AppUpdater] Update downloaded:", filePath)
        root.setStatus("ready", "Version " + root.latestVersion + " is downloaded. Restart GitEase to finish updating.", "success")
        root.notify("success", "Version " + root.latestVersion + " is ready. Restart GitEase to finish updating.",
                    "GitEase Update", 8000)
    }

    function friendlyFailureReason(code, message) {
        if (code === -2) {
            return "The connection stalled. Check your internet connection and try again."
        }

        // QNetworkReply connection-level errors (refused, host not found, network unreachable, …).
        if ((code >= 1 && code <= 8 && code !== 5) || code === 99) {
            return "Couldn't reach the update server. Check your internet connection."
        }

        return message
    }

    function handleUpdateRequestFailed(requestType, code, message) {
        console.warn("[AppUpdater] Application update request failed:", requestType, code, message)

        var reason = root.friendlyFailureReason(code, message)
        var prefix = requestType === UpdateController.CheckApplicationUpdate
                ? "Couldn't check for updates."
                : "Update download failed."
        var wasSilent = root.silentCheck && requestType === UpdateController.CheckApplicationUpdate

        root.silentCheck = false
        root.failedRequestType = requestType
        root.resetDownloadProgress()
        root.setStatus("error", prefix + " " + reason, "error")

        if (!wasSilent) {
            root.notify("warning", prefix + " " + reason, "GitEase Update")
        }
    }

    function showCompletedUpdateResult() {
        var updateInfo = root.takeCompletedUpdateInfo()

        if (!updateInfo || Object.keys(updateInfo).length === 0) {
            return
        }

        if (updateInfo.success === true) {
            var versionText = updateInfo.version ? " You're now on version " + updateInfo.version + "." : ""
            console.log("[AppUpdater] Application update completed.", JSON.stringify(updateInfo))
            root.notify("success", "GitEase was updated successfully." + versionText, "GitEase Update", 6000)
            root.updateAvailable = false
            root.isCritical = false
            root.releaseNotes = ""
            root.latestVersion = updateInfo.version ?? ""
            root.setStatus("upToDate", "Update installed successfully.", "success")
            return
        }

        var message = updateInfo.error ?? "Update replacement failed."
        console.warn("[AppUpdater] Application update did not complete:", message)
        root.notify("warning", message, "GitEase Update")
        root.failedRequestType = UpdateController.DownloadApplicationInstaller
        root.setStatus("error", "The last update didn't finish: " + message, "error")
    }

    function notify(type, message, title, timeout, dismissible) {
        if (!root.notificationController) {
            return
        }

        if (type === "success") {
            root.notificationController.success(message, title, timeout)
            return
        }

        if (type === "warning") {
            root.notificationController.warning(message, title, timeout, dismissible)
            return
        }

        if (type === "error") {
            root.notificationController.error(message, title, timeout)
            return
        }

        root.notificationController.info(message, title, timeout, dismissible)
    }

    function updateDownloadSpeed(bytes) {
        var now = Date.now()
        var elapsedMs = now - root.speedSampleTime

        if (root.speedSampleTime === 0) {
            root.speedSampleTime = now
            root.speedSampleBytes = bytes
            return
        }

        if (elapsedMs < 500) {
            return
        }

        var instantSpeed = (bytes - root.speedSampleBytes) * 1000 / elapsedMs
        root.downloadSpeed = root.downloadSpeed > 0
                ? root.downloadSpeed * 0.7 + instantSpeed * 0.3
                : instantSpeed
        root.speedSampleTime = now
        root.speedSampleBytes = bytes
    }

    /* Children
     * ****************************************************************************************/
    property Connections networkConnections: Connections {
        target: root.networkController

        function onRequestFinished(requestKey, response) {
            root.handleUpdateResponse(requestKey, response)
        }

        function onRequestError(requestKey, code, message) {
            root.handleUpdateError(requestKey, code, message)
        }

        function onTimeout(requestKey) {
            root.handleUpdateTimeout(requestKey)
        }

        function onDownloadProgress(requestKey, bytesReceived, bytesTotal) {
            if (requestKey !== root.downloadApplicationInstallerRequestKey
                    || root.phase !== "downloading") {
                return
            }

            root.bytesReceived = bytesReceived
            if (bytesTotal > 0) {
                root.bytesTotal = bytesTotal
            }
            root.updateDownloadSpeed(bytesReceived)
        }
    }

    property Timer restartAppTimer: Timer {
        id: restartAppTimer
        repeat: false
        interval: 1500
        onTriggered: {
            Qt.callLater(function() {
                Qt.exit(0)
            })
        }
    }

    onUpdateInstallScheduled: function(version) {
        console.log("[AppUpdater] Update install scheduled:", version)
        root.setStatus("restarting", "Restarting GitEase to install version " + version + "…", "info")
        restartAppTimer.start()
    }

    onUpdateFailed: function(message) {
        console.warn("[AppUpdater] Update failed:", message)
        root.pendingRequestType = UpdateController.None
        root.failedRequestType = UpdateController.DownloadApplicationInstaller
        root.resetDownloadProgress()
        root.setStatus("error", "Update failed: " + message, "error")
        root.notify("error", message, "GitEase Update")
    }
}
