import QtQuick

import GitEase

import "qrc:/GitEase/Qml/Core/Scripts/AsyncGit.js" as AsyncGit
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

    /* Signal
     * ****************************************************************************************/
    signal fetchCompleted()

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
                    if (root.activeFetchRemotes.indexOf(remote.name) === -1)
                        root.activeFetchRemotes.push(remote.name)
                root.startFetch(remote.name)
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
            root.startPush(branchName, force)
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
            root.startPull("origin", root.branchController.getCurrentBranchName())
            break
        }
        case RepositoryController.GitProtocol.HTTPS:
        case RepositoryController.GitProtocol.HTTP:
            if (secret && secret.length > 0 && secret !== "undefined") {
                root.startPull("origin", root.branchController.getCurrentBranchName(), secret)
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

    function startFetch(remoteName) {
        AsyncGit.call(root.remoteController, "fetch", [remoteName],
            function(result) { root.handleFetchResult(remoteName, result) },
            function(error) { root.handleFetchResult(remoteName, { success: false, errorMessage: error, stale: error === AsyncGit.STALE }) }
        )
    }

    function startFetchWithToken(remoteName, token) {
        AsyncGit.call(root.remoteController, "fetchWithToken", [remoteName, token],
            function(result) { root.handleFetchResult(remoteName, result) },
            function(error) { root.handleFetchResult(remoteName, { success: false, errorMessage: error, stale: error === AsyncGit.STALE }) }
        )
    }

    function handleFetchResult(remoteName, gitResult) {
        root.activeFetchRemotes = root.activeFetchRemotes.filter(function(name) { return name !== remoteName })

        let stale = gitResult && gitResult.stale === true

        if (stale) {
            root.notificationController.info("Fetch finished for the repository you switched away from", "Fetch", 4000)
        } else {
            let payload = {
                remote:         remoteName,
                success:        gitResult ? gitResult.success : false,
                errorMessage:   gitResult ? gitResult.errorMessage : "Unknown error",
                data:           gitResult ? gitResult.data : null
            }
            root.fetchBatchResults.push(payload)

            if (root.notificationController) {
                if (payload.success)
                    root.notificationController.success("Fetched from " + remoteName, "Fetch", 5000)
                else
                    root.notificationController.error("Fetch failed for " + remoteName + ": " + (payload.errorMessage || "Unknown error"), "Fetch Error", 7000)
            }
        }

            root.isFetching = root.activeFetchRemotes.length > 0 || root.pendingFetchRemoteNames.length > 0
            if (root.activeFetchRemotes.length === 0 && root.pendingFetchRemoteNames.length === 0 && root.fetchBatchResults.length > 0) {

                root.fetchCompleted()

                if (root.fetchSummaryPopup) {
                    root.fetchSummaryPopup.results = []
                    root.fetchSummaryPopup.results = root.fetchBatchResults
                    root.fetchSummaryPopup.open()
                }
            }
        }

    function startPush(branchName, force, token) {
        let args = token !== undefined ? ["origin", branchName, token, force] : ["origin", branchName, force]
        AsyncGit.call(root.remoteController, "push", args,
            function(result) { root.handlePushResult(result) },
            function(error) { root.handlePushResult({ success: false, errorMessage: error, stale: error === AsyncGit.STALE }) }
        )
    }

    function handlePushResult(gitResult) {
            root.isFetching = false

            if (!root.notificationController)
                return

        if (gitResult && gitResult.stale === true) {
            root.notificationController.info("Push finished for the repository you switched away from", "Push", 4000)
            return
        }

        let success = gitResult ? gitResult.success : false

        if (success) {
            let data = gitResult.data
            let isForce = data && data.force === true
                root.notificationController.success(isForce ? "Changes force pushed successfully" : "Changes pushed successfully", isForce ? "Push Force" : "Push", 3000)
            } else {
            root.notificationController.error((gitResult && gitResult.errorMessage) || "Push error", "Push Error", 5000)
            }
        }

    function startPull(remoteName, branchName, token) {
        let args = token !== undefined ? [remoteName, branchName, token] : [remoteName, branchName]
        AsyncGit.call(root.remoteController, "pull", args,
            function(result) { root.handlePullResult(result) },
            function(error) { root.handlePullResult({ success: false, errorMessage: error, stale: error === AsyncGit.STALE }) }
        )
    }

    function handlePullResult(gitResult) {
            if (!root.notificationController)
                return

        if (gitResult && gitResult.stale === true) {
            root.notificationController.info("Pull finished for the repository you switched away from", "Pull", 4000)
            return
        }

        if (gitResult && gitResult.success)
                root.notificationController.success("Pulled successfully", "Pull", 3000)
            else
            root.notificationController.error((gitResult && gitResult.errorMessage) || "Pull failed", "Pull Error", 5000)
    }

    // Gated so it only reacts when THIS session itself opened the shared auth popup — otherwise
    // it would misfire on a push/pull/fetch auth prompt started elsewhere.
    Connections {
        id: authConnection
        target: root.userAuthenticationPopup
        enabled: false

        function onPasswordConfirm(password) {
            if (root.authPurpose === "fetch") {
                let names = root.pendingFetchRemoteNames
                root.pendingFetchRemoteNames = []
                for (let i = 0; i < names.length; i++) {
                    let name = names[i]
                        if (root.activeFetchRemotes.indexOf(name) === -1)
                            root.activeFetchRemotes.push(name)
                    root.startFetchWithToken(name, password)
                }
                root.isFetching = root.activeFetchRemotes.length > 0
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
                root.startPush(branchName, isForce, password)
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
