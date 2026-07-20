import QtQuick

import GitEase
/*! ***********************************************************************************************
 * RemoteOperationsSession
 *
 * Single shared owner of "fetch all remotes / push current branch / pull current branch" state
 * and logic.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations (dependencies)
     * ****************************************************************************************/
    property RemoteController         remoteController:        null
    property RepositoryController     repositoryController:    null
    property BranchController         branchController:        null
    property NotificationController   notificationController:  null
    property UserAuthenticationPopup  userAuthenticationPopup: null
    property FetchSummaryPopup        fetchSummaryPopup:       null

    /* State
     * ****************************************************************************************/
    property bool   isFetching:              false
    property var    activeFetchRemotes:      []
    property string authPurpose:             "push"  // "push" | "pushForce" | "fetch" | "pull"
    property var    pendingFetchRemoteNames: []
    property var    fetchBatchResults:       []

    /* Functions
     * ****************************************************************************************/
    function fetch() {
        let remotesRes = remoteController.getRemotes()
        if (!remotesRes.success || !remotesRes.data || remotesRes.data.length === 0) {
            if (notificationController)
                notificationController.error("No remotes configured", "Fetch", 5000)
            return
        }
        root.fetchBatchResults = []
        let httpsRemotes = []
        let sshFailed = []
        root.activeFetchRemotes = []
        root.isFetching = true
        for (let i = 0; i < remotesRes.data.length; i++) {
            let remote = remotesRes.data[i]
            let urlRes = remoteController.getRemoteUrl(remote.name)
            if (!urlRes.success) {
                sshFailed.push({ name: remote.name, message: urlRes.errorMessage || "No URL" })
                continue
            }
            let url = urlRes.data.url
            let protocol = repositoryController.detectGitProtocol(url)
            switch (protocol) {
            case RepositoryController.GitProtocol.SSH: {
                let res = remoteController.fetch(remote.name)
                if (res.success) {
                    if (root.activeFetchRemotes.indexOf(remote.name) === -1)
                        root.activeFetchRemotes.push(remote.name)
                } else {
                    let msg = res.errorMessage || "Fetch failed"
                    sshFailed.push({ name: remote.name, message: msg })
                    root.fetchBatchResults.push({
                                                    remote: remote.name,
                                                    success: false,
                                                    errorMessage: msg,
                                                    data: { timestamp: Qt.formatDateTime(new Date(), Qt.ISODate), status: "Fetch did not start" }
                                                })
                }
                break
            }
            case RepositoryController.GitProtocol.HTTPS:
            case RepositoryController.GitProtocol.HTTP:
                httpsRemotes.push(remote.name)
                break
            default:
                sshFailed.push({ name: remote.name, message: "Unsupported protocol" })
            }
        }
        if (sshFailed.length > 0 && notificationController) {
            let msg = sshFailed.map(f => f.name + ": " + f.message).join("; ")
            notificationController.error(msg, "Fetch Error", 7000)
        }
        if (httpsRemotes.length > 0) {
            root.pendingFetchRemoteNames = httpsRemotes
            root.authPurpose = "fetch"
            authConnection.enabled = true
            userAuthenticationPopup.open()
        }
        if (httpsRemotes.length === 0 && root.activeFetchRemotes.length === 0)
            root.isFetching = false
    }

    function push(force) {
        force = force || false

        let urlRes = remoteController.getRemoteUrl("origin")
        if (!urlRes.success) {
            if (notificationController)
                notificationController.error(urlRes.errorMessage || "Failed to get remote URL", `${force ? "Force" : ""} Push Error`, 5000)
            return
        }
        let protocol = repositoryController.detectGitProtocol(urlRes.data.url)
        switch (protocol) {
        case RepositoryController.GitProtocol.SSH: {
            let branchName = branchController.getCurrentBranchName()
            remoteController.push("origin", branchName, force)
            if (notificationController)
                notificationController.info("Push operation started", "Push", 3000)

            break
        }

        // Fall-through: both HTTP/HTTPS require auth popup
        case RepositoryController.GitProtocol.HTTPS:
        case RepositoryController.GitProtocol.HTTP:
            root.authPurpose = force ? "pushForce" : "push"
            authConnection.enabled = true
            userAuthenticationPopup.open()
            break
        default:
            if (notificationController)
                notificationController.error("Unsupported protocol", `${force ? "Force" : ""} Push Error`, 5000)
        }
    }

    function pushAndUpdate(force) {
        root.push(force)
    }

    function pull(secret) {
        let res = remoteController.getRemoteUrl("origin")
        if (!res.success) {
            if (notificationController)
                notificationController.error(res.errorMessage || "Failed to get remote URL", "Pull Error", 5000)
            return
        }
        let url = res.data.url
        let protocol = repositoryController.detectGitProtocol(url)
        switch (protocol) {
        case RepositoryController.GitProtocol.SSH: {
            let pullRes = remoteController.pull("origin", root.branchController.getCurrentBranchName())
            if (!pullRes.success) {
                if (notificationController)
                    notificationController.error(pullRes.errorMessage || "Pull failed", "Pull Error", 5000)
            }
            break
        }
        case RepositoryController.GitProtocol.HTTPS:
        case RepositoryController.GitProtocol.HTTP:
            if (secret && secret.length > 0 && secret !== "undefined") {
                let res = root.remoteController.pull("origin", root.branchController.getCurrentBranchName(), secret)
                if (!res.success) {
                    if (notificationController)
                        notificationController.error(res.errorMessage || "Pull failed", "Pull Error", 5000)
                }
            } else {
                root.authPurpose = "pull"
                authConnection.enabled = true
                userAuthenticationPopup.open()
            }
            break
        default:
            if (notificationController)
                notificationController.error("Unsupported protocol", "Pull Error", 5000)
        }
    }

    function pullAndUpdate(secret) {
        root.pull(secret)
    }

    /* Connections
     * ****************************************************************************************/
    Connections {
        target: root.remoteController

        function onFetchFinished(result) {
            if (!result || !result.remote)
                return

            const remoteName = result.remote
            root.activeFetchRemotes = root.activeFetchRemotes.filter(function(name) { return name !== remoteName })
            root.fetchBatchResults.push(result)

            if (root.notificationController) {
                if (result.success)
                    root.notificationController.success("Fetched from " + remoteName, "Fetch", 5000)
                else
                    root.notificationController.error("Fetch failed for " + remoteName + ": " + (result.errorMessage || "Unknown error"), "Fetch Error", 7000)
            }

            root.isFetching = root.activeFetchRemotes.length > 0 || root.pendingFetchRemoteNames.length > 0
            if (root.activeFetchRemotes.length === 0 && root.pendingFetchRemoteNames.length === 0 && root.fetchBatchResults.length > 0) {
                if (root.fetchSummaryPopup) {
                    root.fetchSummaryPopup.results = []
                    root.fetchSummaryPopup.results = root.fetchBatchResults
                    root.fetchSummaryPopup.open()
                }
            }
        }

        function onPushFinished(result) {
            if (!result || result.remote !== "origin")
                return

            root.isFetching = false

            if (!root.notificationController)
                return

            if (result.success) {
                let isForce = result.data.force === true
                root.notificationController.success(isForce ? "Changes force pushed successfully" : "Changes pushed successfully", isForce ? "Push Force" : "Push", 3000)
            } else {
                root.notificationController.error(result.errorMessage || "Push error", "Push Error", 5000)
            }
        }

        // The real success/failure of a pull (see the note on pull() above).
        function onPullFinished(result) {
            if (!result || result.remote !== "origin")
                return

            if (!root.notificationController)
                return

            if (result.success)
                root.notificationController.success("Pulled successfully", "Pull", 3000)
            else
                root.notificationController.error(result.errorMessage || "Pull failed", "Pull Error", 5000)
        }
    }

    // Gated so it only reacts when THIS session itself opened the shared auth popup — otherwise
    // it would misfire on a push/pull/fetch auth prompt started elsewhere.
    Connections {
        id: authConnection
        target: root.userAuthenticationPopup
        enabled: false

        function onPasswordConfirm(password) {
            if (root.authPurpose === "fetch") {
                let failed = []
                for (let i = 0; i < root.pendingFetchRemoteNames.length; i++) {
                    let name = root.pendingFetchRemoteNames[i]
                    let res = root.remoteController.fetchWithToken(name, password)
                    if (res.success) {
                        if (root.activeFetchRemotes.indexOf(name) === -1)
                            root.activeFetchRemotes.push(name)
                    } else {
                        failed.push({ name: name, message: res.errorMessage || "Unknown error" })
                        root.fetchBatchResults.push({
                                                        remote: name,
                                                        success: false,
                                                        errorMessage: res.errorMessage || "Unknown error",
                                                        data: { timestamp: Qt.formatDateTime(new Date(), Qt.ISODate), status: "Fetch did not start" }
                                                    })
                    }
                }
                if (failed.length > 0 && root.notificationController) {
                    root.notificationController.error("Fetch failed for: " + failed.map(function(f){ return f.name + " (" + f.message + ")" }).join("; "), "Fetch Error", 7000)
                }
                root.isFetching = root.activeFetchRemotes.length > 0
                root.pendingFetchRemoteNames = []
                authConnection.enabled = false
                return
            }

            if (root.authPurpose === "pull") {
                root.pull(password)
                authConnection.enabled = false
                return
            }

            let branchName = root.branchController.getCurrentBranchName()
            if (branchName.length === 0) {
                if (root.notificationController)
                    root.notificationController.error("Current branch name is invalid", "Branch Error", 5000)
            } else {
                let isForce = root.authPurpose === "pushForce"
                root.remoteController.push("origin", branchName, password, isForce)
                if (root.notificationController)
                    root.notificationController.info("Push operation started", "Push", 3000)
            }
            authConnection.enabled = false
        }

        function onRejected() {
            if (root.authPurpose === "fetch") {
                root.isFetching = root.activeFetchRemotes.length > 0
                root.pendingFetchRemoteNames = []
            }
            authConnection.enabled = false
        }
    }
}
