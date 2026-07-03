import QtQuick

import GitEase

/*! ***********************************************************************************************
 * UpdateController
 * Owns the application update flow and exposes updater state for UI surfaces.
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
    property string pendingUpdateVersion:   ""
    property string pendingUpdateOs:        ""
    property bool   hasCheckedOnStartup:    false
    property bool   busy:                   false
    property string statusText:             "Not checked yet"
    property string statusType:             "info"
    property bool   updateAvailable:        false
    property bool   isCritical:             false
    property string latestVersion:          ""
    property string downloadSize:           ""
    property string releaseNotes:           ""

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

    function checkForUpdates() {
        if (!root.networkController) {
            root.setStatus("Update service is not available.", "error", false)
            console.warn("[AppUpdater] Update service is not available.")
            return
        }

        if (root.pendingRequestType !== UpdateController.None) {
            console.warn("[AppUpdater] Application update check is already in progress:", root.pendingRequestType)
            root.setStatus("Another update request is already running.", "warning", false)
            return
        }

        var currentVersion = Qt.application.version || "0.0.0"
        var operatingSystem = root.currentOperatingSystem()
        var requestUrl = root.appUpdateApiBaseUrl
                + "/app/check-update?current_version=" + encodeURIComponent(currentVersion)
                + "&os=" + encodeURIComponent(operatingSystem)

        root.updateAvailable = false
        root.isCritical = false
        root.releaseNotes = ""
        root.setStatus("Checking for updates...", "info", true, "", "")
        root.pendingRequestType = UpdateController.CheckApplicationUpdate
        root.pendingUpdateVersion = currentVersion
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
        root.checkForUpdates()
    }

    function setStatus(text, type, busyState, version, size) {
        root.statusText = text
        root.statusType = type
        root.busy = busyState

        if (version !== undefined) {
            root.latestVersion = version
        }

        if (size !== undefined) {
            root.downloadSize = size
        }
    }

    function requestUpdateDownload(version) {
        if (!root.networkController) {
            root.setStatus("Update service is not available.", "error", false)
            return
        }

        if (root.pendingRequestType !== UpdateController.None) {
            console.warn("[AppUpdater] Application update download request is already in progress:", root.pendingRequestType)
            root.setStatus("Another update request is already running.", "warning", false)
            return
        }

        version = version || root.pendingUpdateVersion
        var operatingSystem = root.pendingUpdateOs || root.currentOperatingSystem()
        var requestUrl = root.appUpdateApiBaseUrl
                + "/app/download?version=" + encodeURIComponent(version)
                + "&os=" + encodeURIComponent(operatingSystem)

        root.setStatus("Update available. Preparing download...", "warning", true, version)
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

    function installAvailableUpdate() {
        if (!root.updateAvailable) {
            root.setStatus("No update is available to install.", "info", false)
            return
        }

        if (root.latestVersion === "") {
            root.setStatus("Update version is not available.", "error", false)
            return
        }

        root.requestUpdateDownload(root.latestVersion)
    }

    function openUpdateDownload(downloadInfo) {
        var fileUrl = downloadInfo?.file_url ?? downloadInfo?.download_url ?? ""

        if (fileUrl === "") {
            console.warn("[AppUpdater] Update download response did not contain a file URL.")
            root.setStatus("Update download link was not available.", "error", false)
            root.notify("warning", "Update download link was not available.", "GitEase Update")
            return
        }

        console.log("[AppUpdater] Starting application update download:", fileUrl)
        root.setStatus("Downloading update...", "info", true)
        root.notify("info", "Downloading update.", "GitEase Update")
        // The transport layer only fetches bytes. Saving and installation stay in the update flow.
        root.pendingRequestType = UpdateController.DownloadApplicationInstaller
        root.networkController.downloadRequest(
                    root.downloadApplicationInstallerRequestKey,
                    fileUrl
                    )
    }

    function updateRequestTypeName(requestType) {
        if (requestType === UpdateController.CheckApplicationUpdate) {
            return "check update"
        }
        if (requestType === UpdateController.GetApplicationUpdateDownload) {
            return "download update"
        }
        if (requestType === UpdateController.DownloadApplicationInstaller) {
            return "download installer"
        }
        return "application update"
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

    function handleUpdateResponse(requestKey, response) {
        var requestType = root.requestTypeForKey(requestKey)

        if (requestType === UpdateController.None) {
            return
        }

        if (root.pendingRequestType === requestType) {
            root.pendingRequestType = UpdateController.None
        }

        var payload = response?.data ?? {}
        var updateData = payload?.data ?? payload

        if (payload?.success === false) {
            var serverMessage = payload?.message ?? "The update server returned an unsuccessful response."
            console.warn("[AppUpdater] Application update request failed:", requestType, serverMessage)
            root.handleUpdateRequestFailed(requestType, -1, serverMessage)
            return
        }

        if (requestType === UpdateController.CheckApplicationUpdate) {
            root.handleUpdateCheckSuccess(updateData)
            return
        }

        if (requestType === UpdateController.GetApplicationUpdateDownload) {
            if (requestKey === root.getApplicationUpdateDownloadRequestKey) {
                // First updater response gives us the installer URL and metadata.
                root.handleUpdateDownloadInfoSuccess(updateData)
                return
            }
        }

        if (requestType === UpdateController.DownloadApplicationInstaller) {
            // Second updater response carries the raw installer payload from NetworkManager.
            root.handleUpdateFileDownloaded(updateData)
        }
    }

    function handleUpdateError(requestKey, code, message) {
        var requestType = root.requestTypeForKey(requestKey)

        if (requestType === UpdateController.None) {
            return
        }

        if (root.pendingRequestType === requestType) {
            root.pendingRequestType = UpdateController.None
        }

        root.handleUpdateRequestFailed(requestType, code, message)
    }

    function handleUpdateTimeout(requestKey) {
        var requestType = root.requestTypeForKey(requestKey)

        if (requestType === UpdateController.None) {
            return
        }

        if (root.pendingRequestType === requestType) {
            root.pendingRequestType = UpdateController.None
        }

        root.handleUpdateRequestFailed(requestType, -2, "Request timed out.")
    }

    function handleUpdateCheckSuccess(updateInfo) {
        var currentVersion = Qt.application.version || "0.0.0"

        if (!updateInfo?.update_available) {
            var upToDateMessage = "GitEase is up to date (" + currentVersion + ")."
            console.log("[AppUpdater]", upToDateMessage)
            root.updateAvailable = false
            root.isCritical = false
            root.releaseNotes = updateInfo?.release_notes ?? ""
            root.setStatus(upToDateMessage, "success", false, updateInfo?.latest_version ?? "", "")
            root.notify("success", upToDateMessage, "GitEase Update")
            return
        }

        root.updateAvailable = true
        root.isCritical = updateInfo?.is_critical === true
        root.latestVersion = updateInfo?.latest_version ?? "unknown"
        root.releaseNotes = updateInfo?.release_notes ?? ""

        var criticalPrefix = root.isCritical ? "Critical update available" : "Update available"
        var message = criticalPrefix + ": version " + root.latestVersion

        if (root.releaseNotes !== "") {
            message += "\n" + root.releaseNotes
        }

        console.log("[AppUpdater] Application update check response:", JSON.stringify(updateInfo))
        root.setStatus("Update available. Click Update to download and install.", "warning", false, root.latestVersion)
        root.notify("info", message, "GitEase Update", 8000)
    }

    function handleUpdateDownloadInfoSuccess(downloadInfo) {
        var sizeMb = downloadInfo?.size_mb
        var sizeText = sizeMb !== undefined ? sizeMb + " MB" : ""
        console.log("[AppUpdater] Application update download response:", JSON.stringify(downloadInfo))
        root.setStatus("Download link is ready.", "success", true, undefined, sizeText)
        root.openUpdateDownload(downloadInfo)
    }

    function handleUpdateFileDownloaded(downloadInfo) {
        var fileDataBase64 = downloadInfo?.file_data_base64 ?? ""
        var stagedFilePath = root.prepareUpdateFilePath(
                    "GitEase-Setup-" + (root.latestVersion || "update") + ".exe"
                    )

        if (fileDataBase64 === "") {
            root.handleUpdateRequestFailed(UpdateController.DownloadApplicationInstaller, -1, "Downloaded file data is missing.")
            return
        }

        if (stagedFilePath === "") {
            root.handleUpdateRequestFailed(UpdateController.DownloadApplicationInstaller, -1, "Downloaded file path is missing.")
            return
        }

        if (!root.saveDownloadedUpdateBase64(stagedFilePath, fileDataBase64)) {
            root.setStatus("Could not save downloaded update.", "error", false)
            root.notify("error", "Could not save downloaded update.", "GitEase Update")
            return
        }

        // Once the file is staged locally, UpdateManager takes over to replace the app on restart.
        if (!root.installDownloadedUpdate(stagedFilePath, root.latestVersion)) {
            console.warn("[AppUpdater] Could not start update install:", stagedFilePath)
            root.setStatus("Could not start update install.", "error", false)
            root.notify("error", "Could not start update install.", "GitEase Update")
        }
    }

    function handleUpdateRequestFailed(requestType, code, message) {
        var actionName = root.updateRequestTypeName(requestType)
        console.warn("[AppUpdater] Application update request failed:", requestType, code, message)
        root.setStatus("Could not " + actionName + ": " + message, "error", false)
        root.notify("warning", "Could not " + actionName + ": " + message, "GitEase Update")
    }

    function showCompletedUpdateResult() {
        var updateInfo = root.takeCompletedUpdateInfo()

        if (!updateInfo || Object.keys(updateInfo).length === 0) {
            return
        }

        if (updateInfo.success === true) {
            var versionText = updateInfo.version ? " Version " + updateInfo.version + " is installed." : ""
            console.log("[AppUpdater] Application update completed.", JSON.stringify(updateInfo))
            root.notify("success", "Update completed successfully." + versionText, "GitEase Update", 6000)
            root.updateAvailable = false
            root.isCritical = false
            root.releaseNotes = ""
            root.setStatus("Update completed successfully.", "success", false, updateInfo.version ?? "")
            return
        }

        var message = updateInfo.error ?? "Update replacement failed."
        console.warn("[AppUpdater] Application update did not complete:", message)
        root.notify("warning", message, "GitEase Update")
        root.setStatus(message, "error", false)
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
            if (requestKey !== root.downloadApplicationInstallerRequestKey) {
                return
            }

            // Only the installer payload should drive the visible download progress.
            if (bytesTotal <= 0) {
                root.setStatus("Downloading update...", "info", true)
                return
            }

            var percent = Math.round((bytesReceived / bytesTotal) * 100)
            root.setStatus("Downloading update... " + percent + "%", "info", true)
        }
    }

    property Timer resetAppTimer: Timer {
        id: resetAppTimer
        repeat: false
        interval: 5000
        onTriggered: {
            Qt.callLater(function() {
                Qt.exit(0)
            })
        }
    }

    onUpdateInstallScheduled: function(version) {
        console.log("[AppUpdater] Update install scheduled:", version)
        root.setStatus("Installing update after restart...", "warning", true, version)
        root.notify("info", "GitEase will restart to finish the update.", "GitEase Update", 5000, false)
        resetAppTimer.start()
    }

    onUpdateFailed: function(message) {
        console.warn("[AppUpdater] Update failed:", message)
        root.setStatus("Update failed: " + message, "error", false)
        root.notify("error", message, "GitEase Update")
    }
}
