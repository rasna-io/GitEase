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
    property TagController            tagController:           null
    property RepositoryController     repositoryController:    null
    property BranchController         branchController:        null
    property NotificationController   notificationController:  null
    property GitStateNotifier         gitStateNotifier:        null
    property UserAuthenticationPopup  userAuthenticationPopup: null
    property FetchSummaryPopup        fetchSummaryPopup:       null
    property RemoteTargetPopup        remoteTargetPopup:       null
    property ConfirmCommandDialog     confirmDialog:           null

    property AppModel                 appModel:                null
    property RemoteTargetPopup        remoteTargetPopup:       null
    property ConfirmCommandDialog     confirmDialog:           null

    property AppModel                 appModel:                null


    /* State
     * ****************************************************************************************/
    property bool   isFetching:              false
    property var    activeFetchRemotes:      []
    property string authPurpose:             "push"  // "push" | "pushForce" | "fetch" | "pull"
    property var    pendingFetchRemoteNames: []
    property var    fetchBatchResults:       []

    property var    target:                  ({})

    readonly property var    remotes:    root.target.remotes || []
    readonly property bool   hasRemotes: root.remotes.length > 0
    readonly property string branch:     root.target.branch || ""
    //! A branch with commits is checked out. Not "onBranch": QML reads on<Name> as a signal handler.
    readonly property bool   isOnBranch: root.branch !== "" && root.target.unborn !== true
    readonly property bool   pushBusy:   root.remoteController ? root.remoteController.pushInProgress : false

    readonly property bool   canFetch:   root.hasRemotes && !root.isFetching
    readonly property bool   canPull:    root.hasRemotes && root.isOnBranch
    readonly property bool   canPush:    root.hasRemotes && root.isOnBranch && !root.pushBusy

    readonly property string defaultRemote: root.target.defaultRemote || ""

    readonly property bool   alwaysAskRemote: root.appModel?.appSettings?.generalSettings?.alwaysAskRemote ?? false

    readonly property string fetchTooltip: {
        if (root.isFetching)
            return "Fetching…"
        if (!root.hasRemotes)
            return "No remotes yet. Add a remote first to fetch."
        if (root.alwaysAskRemote)
            return "Fetch - you choose all remotes or one each time"
        return "Fetch all remotes (" + root.shortList(root.remotes.map(remote => remote.name)) + ")"
    }

    readonly property string pullTooltip: {
        if (!root.hasRemotes)
            return "No remotes yet. Add a remote first to pull."
        if (root.target.detached)
            return "HEAD is detached. Check out a branch to pull."
        if (!root.isOnBranch)
            return "This branch has no commits yet."
        if (root.alwaysAskRemote)
            return "Pull into '" + root.branch + "' - you choose the remote each time"
        if (root.target.pullRemote)
            return "Pull from " + root.target.pullRemote + "/" + root.target.pullBranch
        return "Pull into '" + root.branch + "' - choose the remote branch"
    }

    readonly property string pushTooltip:      root.pushTooltipFor(false)
    readonly property string forcePushTooltip: root.pushTooltipFor(true)

    // Pending answers from the shared popups
    property var    _authQueue:      []
    property var    _authActive:     null
    property var    _choiceCallback: null
    property var    _confirmCallback: null

    /* Signal
     * ****************************************************************************************/
    signal fetchCompleted()

    /* Children
     * ****************************************************************************************/
    Connections {
        target: root.gitStateNotifier

        function onRepositoryChanged() {
            root.refreshTarget()
        }
    }

    Connections {
        target: root.remoteController

        function onCurrentRepoChanged() {
            root.refreshTarget()
        }
    }

    Connections {
        target: root.userAuthenticationPopup

        function onPasswordConfirm(password) {
            let request = root._authActive
            if (!request || request.answered)
                return

            request.answered = true
            request.onToken(password)
        }

        function onClosed() {
            // Deferred so the popup finishes closing before it can be asked again
            Qt.callLater(root._finishCredentialRequest)
        }
    }

    Connections {
        target: root.remoteTargetPopup

        function onChosen(remote, branch, setUpstream, alwaysAsk) {
            let callback = root._choiceCallback
            root._choiceCallback = null

            if (root.remoteTargetPopup.offerAlwaysAsk)
                root.setAlwaysAskRemote(alwaysAsk)

            if (callback)
                callback(remote, branch, setUpstream)
        }
    }

    Connections {
        target: root.confirmDialog

        function onConfirmed(context) {
            let callback = root._confirmCallback
            root._confirmCallback = null

            if (callback && context && context.fromRemoteSession === true)
                callback()
        }
    }

    Component.onCompleted: root.refreshTarget()

    /* Functions
     * ****************************************************************************************/
    //! Reads where pull and push go now, keeps it in `target` and returns it.
    function refreshTarget() {
        let res = root.remoteController ? root.remoteController.remoteTarget() : null
        root.target = res && res.success ? res.data : ({})
        return root.target
    }

    function pushTooltipFor(force) {
        let verb = force ? "Force push" : "Push"

        if (!root.hasRemotes)
            return "No remotes yet. Add a remote first to push."
        if (root.target.detached)
            return "HEAD is detached. Check out a branch to push."
        if (!root.isOnBranch)
            return "Nothing to push yet. Make a first commit."
        if (root.alwaysAskRemote)
            return verb + " '" + root.branch + "' - you choose the remote each time"
        if (root.target.pushRemote && root.target.pushBranch)
            return verb + " to " + root.target.pushRemote + "/" + root.target.pushBranch
                    + (root.target.pushRemote === root.defaultRemote ? " (default remote)" : "")
                    + (root.target.publish ? " and track it as upstream" : "")
        return verb + " '" + root.branch + "' - choose the remote branch"
    }

    function setAlwaysAskRemote(enabled) {
        let settings = root.appModel?.appSettings?.generalSettings
        if (!settings || settings.alwaysAskRemote === enabled)
            return

        settings.alwaysAskRemote = enabled
        root.appModel.save()
    }

    function setDefaultRemote(remoteName) {
        let res = root.remoteController ? root.remoteController.setDefaultRemote(remoteName) : null

        // Writing git config raises no repositoryChanged, so pick the change up here
        root.refreshTarget()

        if (!root.notificationController || !res)
            return

        if (!res.success)
            root.notificationController.error(res.errorMessage || "Failed to change the default remote", "Remote", 5000)
        else if (remoteName)
            root.notificationController.success("Push now goes to '" + remoteName + "' by default", "Default Remote", 3000)
        else
            root.notificationController.success("No default remote: Push follows each branch's upstream", "Default Remote", 3000)
    }

    function shortList(names) {
        if (names.length <= 3)
            return names.join(", ")

        return names.slice(0, 3).join(", ") + " and " + (names.length - 3) + " more"
    }

    function remoteNamed(name) {
        return root.remotes.find(remote => remote.name === name) || null
    }

    function needsToken(url) {
        if (!url || !root.repositoryController)
            return false

        let protocol = root.repositoryController.detectGitProtocol(url)
        return protocol === RepositoryController.GitProtocol.HTTPS
            || protocol === RepositoryController.GitProtocol.HTTP
    }

    function credentialKey(url) {
        let match = /^[a-z][a-z0-9+.-]*:\/\/(?:([^@\/]*)@)?([^\/:]+)(?::(\d+))?/i.exec(url || "")
        if (!match)
            return url || ""

        return (match[1] ? match[1] + "@" : "") + match[2].toLowerCase() + (match[3] ? ":" + match[3] : "")
    }

    function branchChoices(target, forPush) {
        let choices = []

        if (target.upstreamRemote && target.upstreamBranch !== target.branch) {
            let upstreamRemote = root.remoteNamed(target.upstreamRemote)
            choices.push({
                remote: target.upstreamRemote,
                branch: target.upstreamBranch,
                url:    upstreamRemote ? (forPush ? upstreamRemote.pushUrl : upstreamRemote.url) : "",
                note:   "upstream"
            })
        }

        for (let remote of target.remotes || []) {
            let notes = []
            if (remote.name === target.defaultRemote)
                notes.push("default")
            if (remote.name === target.upstreamRemote && target.branch === target.upstreamBranch)
                notes.push("upstream")
            if (!remote.hasBranch)
                notes.push(forPush ? "new branch" : "not seen on this remote")

            choices.push({
                remote: remote.name,
                branch: target.branch,
                url:    forPush ? remote.pushUrl : remote.url,
                note:   notes.join(" · ")
            })
        }

        return choices
    }

    function indexOfChoice(choices, remote, branch) {
        return Math.max(0, choices.findIndex(choice => choice.remote === remote && choice.branch === branch))
    }

    //! "origin/main" for a branch that tracks origin/main, empty when it tracks nothing.
    function upstreamOf(target) {
        return target.upstreamRemote ? target.upstreamRemote + "/" + target.upstreamBranch : ""
    }

    function canRunBranchOperation(title) {
        let message = ""
        if (!root.hasRemotes)
            message = "This repository has no remotes yet. Add a remote first."
        else if (root.target.detached)
            message = "HEAD is detached. Check out a branch first."
        else if (!root.isOnBranch)
            message = "This branch has no commits yet."

        if (message !== "" && root.notificationController)
            root.notificationController.error(message, title, 5000)

        return message === ""
    }

    function hostPopup(popup, host) {
        if (popup && popup.hasOwnProperty("hostItem"))
            popup.hostItem = host || null
    }

    function chooseTarget(options, host, onChosen) {
        if (!root.remoteTargetPopup)
            return

        root._choiceCallback = onChosen
        root.hostPopup(root.remoteTargetPopup, host)
        root.remoteTargetPopup.ask(options)
    }

    function confirm(title, message, command, buttonText, host, onConfirmed) {
        if (!root.confirmDialog) {
            onConfirmed()
            return
        }

        root._confirmCallback = onConfirmed
        root.hostPopup(root.confirmDialog, host)
        root.confirmDialog.ask(title, message, command, buttonText, { fromRemoteSession: true })
    }

    function withCredentials(operation, remoteName, forPush, host, onToken, onCancel) {
        let remote = root.remoteNamed(remoteName)
        let url = remote ? (forPush ? remote.pushUrl : remote.url) : ""

        if (!root.needsToken(url) || !root.userAuthenticationPopup) {
            onToken("")
            return
        }

        root.requestCredentials(operation, remoteName, url, host, onToken, onCancel)
    }

    //! Queues a token prompt; the popup is shared, so prompts are shown one after the other.
    function requestCredentials(operation, remoteLabel, url, host, onToken, onCancel) {
        root._authQueue = root._authQueue.concat([{
            operation:   operation,
            remoteLabel: remoteLabel,
            url:         url,
            host:        host,
            onToken:     onToken,
            onCancel:    onCancel,
            answered:    false
        }])

        root._showNextCredentialRequest()
    }

    function _showNextCredentialRequest() {
        let popup = root.userAuthenticationPopup
        if (root._authActive || root._authQueue.length === 0 || !popup || popup.visible)
            return

        let request = root._authQueue[0]
        root._authQueue = root._authQueue.slice(1)
        root._authActive = request

        root.hostPopup(popup, request.host)
        popup.request(request.operation, request.remoteLabel, request.url)
    }

    function _finishCredentialRequest() {
        let request = root._authActive
        root._authActive = null

        if (request && !request.answered && request.onCancel)
            request.onCancel()

        root._showNextCredentialRequest()
    }

    //! Fetches every remote, or the remote the user picks while "Always ask" is on.
    function fetch(host) {
        if (root.isFetching)
            return

        let target = root.refreshTarget()
        let remotes = target.remotes || []

        if (remotes.length === 0) {
            if (root.notificationController)
                root.notificationController.error("This repository has no remotes yet. Add a remote first.", "Fetch", 5000)
            return
        }

        if (!root.alwaysAskRemote) {
            root.fetchRemotes(remotes.map(remote => remote.name), host)
            return
        }

        // Every remote at once, or just one
        let names = remotes.map(remote => remote.name)
        let choices = [{ remote: "", branch: "", url: "", label: "All remotes", note: root.shortList(names) }]
                .concat(remotes.map(remote => ({
                    remote: remote.name,
                    branch: "",
                    url:    remote.url,
                    note:   remote.name === target.defaultRemote ? "default" : ""
                })))

        root.chooseTarget({
            operation:      "fetch",
            message:        "Choose what to fetch.",
            choices:        choices,
            selectedIndex:  0,
            offerAlwaysAsk: true,
            alwaysAsk:      root.alwaysAskRemote
        }, host, function(remote) {
            root.fetchRemotes(remote === "" ? names : [remote], host)
        })
    }

    //! Fetches \a remoteNames. HTTP(S) remotes get one token prompt per host, not one for all.
    function fetchRemotes(remoteNames, host) {
        if (root.isFetching)
            return

        let remotes = remoteNames.map(name => root.remoteNamed(name)).filter(remote => remote !== null)
        if (remotes.length === 0)
            return

        let direct = []
        let groups = []

        for (let remote of remotes) {
            if (!root.needsToken(remote.url)) {
                direct.push(remote.name)
                continue
            }

            let key = root.credentialKey(remote.url)
            let group = groups.find(candidate => candidate.key === key)
            if (!group) {
                group = { key: key, url: remote.url, names: [] }
                groups.push(group)
            }
            group.names.push(remote.name)
        }

        root.fetchBatchResults = []
        root.activeFetchRemotes = []
        root.pendingFetchRemoteNames = groups.reduce((names, group) => names.concat(group.names), [])
        root.isFetching = true

        for (let name of direct)
            root.startFetch(name)

        for (let group of groups) {
            root.requestCredentials("fetch", group.names.join(", "), group.url, host,
                function(token) {
                    root.pendingFetchRemoteNames = root.pendingFetchRemoteNames.filter(name => group.names.indexOf(name) === -1)
                    for (let name of group.names)
                        root.startFetchWithToken(name, token)
                },
                function() {
                    root.pendingFetchRemoteNames = root.pendingFetchRemoteNames.filter(name => group.names.indexOf(name) === -1)
                    root.finishFetchIfDone()
                })
        }

        root.finishFetchIfDone()
    }

    function startFetch(remoteName) {
        root.activeFetchRemotes = root.activeFetchRemotes.concat([remoteName])
        AsyncGit.call(root.remoteController, "fetch", [remoteName],
            function(result) { root.handleFetchResult(remoteName, result) },
            function(error) { root.handleFetchResult(remoteName, { success: false, errorMessage: error, stale: error === AsyncGit.STALE }) }
        )
    }

    function startFetchWithToken(remoteName, token) {
        root.activeFetchRemotes = root.activeFetchRemotes.concat([remoteName])
        AsyncGit.call(root.remoteController, "fetchWithToken", [remoteName, token],
            function(result) { root.handleFetchResult(remoteName, result) },
            function(error) { root.handleFetchResult(remoteName, { success: false, errorMessage: error, stale: error === AsyncGit.STALE }) }
        )
    }

    function handleFetchResult(remoteName, gitResult) {
        root.activeFetchRemotes = root.activeFetchRemotes.filter(name => name !== remoteName)

        if (gitResult && gitResult.stale === true) {
            if (root.notificationController)
                root.notificationController.info("Fetch finished for the repository you switched away from", "Fetch", 4000)
        } else {
            let payload = {
                remote:       remoteName,
                success:      gitResult ? gitResult.success : false,
                errorMessage: gitResult ? gitResult.errorMessage : "Unknown error",
                data:         gitResult ? gitResult.data : null
            }
            root.fetchBatchResults = root.fetchBatchResults.concat([payload])

            if (root.notificationController) {
                if (payload.success)
                    root.notificationController.success("Fetched from " + remoteName, "Fetch", 5000)
                else
                    root.notificationController.error("Fetch failed for " + remoteName + ": " + (payload.errorMessage || "Unknown error"), "Fetch Error", 7000)
            }
        }

        root.finishFetchIfDone()
    }

    //! Shows the summary once every fetch has finished and no token prompt is outstanding.
    function finishFetchIfDone() {
        root.isFetching = root.activeFetchRemotes.length > 0 || root.pendingFetchRemoteNames.length > 0

        if (root.isFetching || root.fetchBatchResults.length === 0)
            return

        root.fetchCompleted()

        if (root.fetchSummaryPopup) {
            root.fetchSummaryPopup.results = []
            root.fetchSummaryPopup.results = root.fetchBatchResults
            root.fetchSummaryPopup.open()
        }

        root.fetchBatchResults = []
    }

    function pull(host) {
        let target = root.refreshTarget()
        if (!root.canRunBranchOperation("Pull"))
            return
        if (target.pullRemote && !root.alwaysAskRemote) {
            root.runPull(target.pullRemote, target.pullBranch, false, host)
            return
        }

        let choices = root.branchChoices(target, false)
        let preselect = target.pullRemote
                ? root.indexOfChoice(choices, target.pullRemote, target.pullBranch)
                : root.indexOfChoice(choices, target.suggestedRemote, target.branch)

        root.chooseTarget({
            operation:       "pull",
            subject:         target.branch,
            message:         target.pullRemote
                             ? "Choose where to pull '" + target.branch + "' from."
                             : "'" + target.branch + "' has no upstream branch yet. Choose where to pull it from.",
            choices:         choices,
            selectedIndex:   preselect,
            offerUpstream:   true,
            setUpstream:     target.upstreamRemote === "",
            currentUpstream: root.upstreamOf(target),
            defaultRemote:   target.defaultRemote,
            offerAlwaysAsk:  true,
            alwaysAsk:       root.alwaysAskRemote
        }, host, function(remote, remoteBranch, setUpstream) {
            root.runPull(remote, remoteBranch, setUpstream, host)
        })
    }

    function pullAndUpdate(host) {
        root.pull(host)
    }

    function runPull(remote, remoteBranch, setUpstream, host) {
        root.withCredentials("pull", remote, false, host, function(token) {
            AsyncGit.call(root.remoteController, "pull", [remote, remoteBranch, token, setUpstream],
                function(result) { root.handlePullResult(result) },
                function(error) { root.handlePullResult({ success: false, errorMessage: error, stale: error === AsyncGit.STALE }) }
            )
        })
    }

    function handlePullResult(gitResult) {
        if (!root.notificationController)
            return

        if (gitResult && gitResult.stale === true) {
            root.notificationController.info("Pull finished for the repository you switched away from", "Pull", 4000)
            return
        }

        if (gitResult && gitResult.success) {
            let data = gitResult.data || {}
            let source = data.remote + "/" + data.remoteBranch
            let upToDate = data.status === "Already up to date"
            root.notificationController.success(upToDate ? "Already up to date with " + source : "Pulled from " + source, "Pull", 3000)
        } else {
            root.notificationController.error((gitResult && gitResult.errorMessage) || "Pull failed", "Pull Error", 5000)
        }
    }

    function push(force, host) {
        force = force === true

        let target = root.refreshTarget()
        if (!root.canRunBranchOperation(force ? "Force Push" : "Push"))
            return

        let decided = target.pushRemote && target.pushBranch
        if (decided && !root.alwaysAskRemote) {
            root.confirmPush(target.branch, target.pushRemote, target.pushBranch, force, target.publish, host)
            return
        }

        let renamedUpstream = target.upstreamRemote !== "" && target.upstreamBranch !== target.branch
        let message = decided
                ? "Choose where to push '" + target.branch + "'."
                : renamedUpstream
                  ? "'" + target.branch + "' tracks " + target.upstreamRemote + "/" + target.upstreamBranch
                    + ", which has a different name. Choose the remote branch to update."
                  : "'" + target.branch + "' has no upstream branch yet. Choose where to push it."

        let choices = root.branchChoices(target, true)
        let preselect = decided
                ? root.indexOfChoice(choices, target.pushRemote, target.pushBranch)
                : root.indexOfChoice(choices, target.suggestedRemote, target.branch)

        root.chooseTarget({
            operation:       force ? "pushForce" : "push",
            subject:         target.branch,
            message:         message,
            choices:         choices,
            selectedIndex:   preselect,
            offerUpstream:   true,
            setUpstream:     target.upstreamRemote === "",
            currentUpstream: root.upstreamOf(target),
            defaultRemote:   target.defaultRemote,
            offerAlwaysAsk:  true,
            alwaysAsk:       root.alwaysAskRemote
        }, host, function(remote, remoteBranch, setUpstream) {
            root.confirmPush(target.branch, remote, remoteBranch, force, setUpstream, host)
        })
    }

    function pushToRemote(remoteName, host) {
        let target = root.refreshTarget()
        if (!root.canRunBranchOperation("Push"))
            return

        root.confirmPush(target.branch, remoteName, target.branch, false, target.upstreamRemote === "", host)
    }

    function pushAndUpdate(force, host) {
        root.push(force, host)
    }

    function confirmPush(localBranch, remote, remoteBranch, force, setUpstream, host) {
        if (!force) {
            root.runPush(localBranch, remote, remoteBranch, false, setUpstream, host)
            return
        }

        root.confirm("Force Push",
                     "Overwrite '" + remoteBranch + "' on " + remote + " with your local history? "
                     + "Commits on the remote that you do not have are lost.",
                     GitCommandText.push(remote, localBranch, remoteBranch, true, setUpstream),
                     "Force Push",
                     host,
                     function() { root.runPush(localBranch, remote, remoteBranch, true, setUpstream, host) })
    }

    function runPush(localBranch, remote, remoteBranch, force, setUpstream, host) {
        let rules = root.remoteController.checkPushRules(remote, localBranch, remoteBranch, force)
        if (rules && !rules.success) {
            root.handlePushResult(rules)
            return
        }

        root.withCredentials(force ? "pushForce" : "push", remote, true, host, function(token) {
            if (root.notificationController)
                root.notificationController.info("Pushing to " + remote + "/" + remoteBranch, force ? "Force Push" : "Push", 3000)

            AsyncGit.call(root.remoteController, "push", [remote, localBranch, remoteBranch, token, force, setUpstream],
                function(result) { root.handlePushResult(result) },
                function(error) { root.handlePushResult({ success: false, errorMessage: error, stale: error === AsyncGit.STALE }) }
            )
        })
    }

    function handlePushResult(gitResult) {
        if (!root.notificationController)
            return

        if (gitResult && gitResult.stale === true) {
            root.notificationController.info("Push finished for the repository you switched away from", "Push", 4000)
            return
        }

        if (!gitResult || !gitResult.success) {
            root.notificationController.error((gitResult && gitResult.errorMessage) || "Push error", "Push Error", 5000)
            return
        }

        let data = gitResult.data || {}
        let isForce = data.force === true
        let destination = data.remote + "/" + data.remoteBranch

        root.notificationController.success((isForce ? "Force pushed to " : "Pushed to ") + destination
                                            + (data.upstreamSet ? ", now the upstream of '" + data.branch + "'" : ""),
                                            isForce ? "Force Push" : "Push", 3000)

        if (data.upstreamError)
            root.notificationController.warning("The push worked, but " + destination + " could not be set as the upstream: "
                                                + data.upstreamError, "Push", 6000)
    }

    function chooseTagRemote(operation, tagName, onChosen, host) {
        let target = root.refreshTarget()
        let remotes = target.remotes || []

        if (remotes.length === 0) {
            if (root.notificationController)
                root.notificationController.error("This repository has no remotes yet. Add a remote first.", "Tag", 5000)
            return
        }

        if (target.pushRemote && !root.alwaysAskRemote) {
            onChosen(target.pushRemote)
            return
        }

        let choices = remotes.map(remote => ({
            remote: remote.name,
            branch: "",
            url:    remote.pushUrl,
            note:   remote.name === target.defaultRemote ? "default" : ""
        }))
        let preselect = target.pushRemote || target.suggestedRemote

        root.chooseTarget({
            operation:      operation,
            subject:        tagName,
            message:        operation === "deleteTag" ? "Choose the remote to delete the tag from."
                                                      : "Choose the remote to push the tag to.",
            choices:        choices,
            selectedIndex:  Math.max(0, choices.findIndex(choice => choice.remote === preselect)),
            offerUpstream:  false,
            offerAlwaysAsk: true,
            alwaysAsk:      root.alwaysAskRemote
        }, host, function(remote) {
            onChosen(remote)
        })
    }

    function pushTag(tagName, onFinished, host) {
        root.chooseTagRemote("pushTag", tagName, function(remote) {
            root.pushTagTo(remote, tagName, onFinished, host)
        }, host)
    }

    function pushTagTo(remote, tagName, onFinished, host) {
        root.runTagOperation("pushTag", remote, tagName, onFinished, host)
    }

    function deleteRemoteTag(remote, tagName, onFinished, host) {
        root.runTagOperation("pushDeleteTag", remote, tagName, onFinished, host)
    }

    function runTagOperation(method, remote, tagName, onFinished, host) {
        root.withCredentials("push", remote, true, host, function(token) {
            AsyncGit.call(root.tagController, method, [remote, tagName, token],
                function(result) {
                    if (onFinished)
                        onFinished(result, remote)
                },
                function(error) {
                    if (onFinished)
                        onFinished({ success: false, errorMessage: error, stale: error === AsyncGit.STALE }, remote)
                }
            )
        })
    }
}
