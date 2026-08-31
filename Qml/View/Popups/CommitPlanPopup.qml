import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * CommitPlanPopup
 * Shows a previewable commits todo list with commit file changes and diff view.
 * ************************************************************************************************/

IWindow {
    id: root

    QtObject {
        id: commitStatus

        readonly property string pending   : "Pending"
        readonly property string inProgress: "In Progress"
        readonly property string rebased   : "Rebased"
        readonly property string skipped   : "Skipped"
        readonly property string conflict  : "Conflict"

        function colorOf(status){
            switch (status) {
                case inProgress:
                    return Style.colors.rebaseStatusInProgress

                case rebased:
                    return Style.colors.rebaseStatusRebased

                case conflict:
                    return Style.colors.rebaseStatusConflict

                case skipped:
                    return Style.colors.rebaseStatusSkipped

                default:
                    return Style.colors.rebaseStatusPending
            }
        }
    }

    QtObject {
        id: rebaseState

        readonly property string idle      : "Start Rebase"
        readonly property string running   : "Rebasing..."
        readonly property string completed : "Close"
        readonly property string failed    : "Start Rebase"
    }

    /* Property Declarations
     * ****************************************************************************************/
    property StatusController       statusController: null
    property CommitController       commitController: null
    property RebaseController       rebaseController: null
    property ConflictController     conflictController: null
    property NotificationController notificationController: null
    property LayoutController       layoutController: null
    property GuideController        guideController: null


    property var    planData            : ({})
    property string selectedCommitHash  : ""
    property string selectedCommitSummary: ""

    property int    selectedIndex       : -1

    property string currentRebaseState  : rebaseState.idle

    //! True while this instance owns the rebase running on the shared RebaseController.
    property bool ownsRebase: false
    readonly property int contentInset: Style.dp(16)

    //! The plan can only be edited before it is handed over.
    readonly property bool planEditable: root.currentRebaseState === rebaseState.idle
                                         || root.currentRebaseState === rebaseState.failed

    property int planRevision: 0

    readonly property var actionCounts: {
        root.planRevision
        let counts = ({})
        for (let i = 0; i < commitModel.count; ++i) {
            let action = commitModel.get(i).action
            counts[action] = (counts[action] ?? 0) + 1
        }
        return counts
    }

    property var planHistory: []
    property int planCursor:  -1

    readonly property bool canUndo: root.planEditable && root.planCursor > 0
    readonly property bool canRedo: root.planEditable
                                    && root.planCursor >= 0
                                    && root.planCursor < root.planHistory.length - 1

    /* Signals
     * ****************************************************************************************/
    signal accepted(var operations)

    /* Object Properties
     * ****************************************************************************************/
    width   : 1180
    height  : 760
    minimumWidth: 720
    minimumHeight: 560

    Connections {
        target: root

        function onVisibleChanged() {
            if (root.visible)
                root.ownsRebase = true
            else {
                root.ownsRebase = false
                root.resetPopupState()
            }
        }
    }

    /* Shortcuts
     * ****************************************************************************************/
    Shortcut {
        sequence: "Alt+Up"
        enabled: root.visible && root.planEditable
        onActivated: root.moveCommit(root.selectedIndex, root.selectedIndex - 1)
    }

    Shortcut {
        sequence: "Alt+Down"
        enabled: root.visible && root.planEditable
        onActivated: root.moveCommit(root.selectedIndex, root.selectedIndex + 1)
    }

    Shortcut {
        sequence: "P"
        enabled: root.visible && root.planEditable
        onActivated: root.setAction(root.selectedIndex, RebaseActions.pick)
    }

    Shortcut {
        sequence: "R"
        enabled: root.visible && root.planEditable
        onActivated: root.setAction(root.selectedIndex, RebaseActions.reword)
    }

    Shortcut {
        sequence: "S"
        enabled: root.visible && root.planEditable
        onActivated: root.setAction(root.selectedIndex, RebaseActions.squash)
    }

    Shortcut {
        sequence: "F"
        enabled: root.visible && root.planEditable
        onActivated: root.setAction(root.selectedIndex, RebaseActions.fixup)
    }

    Shortcut {
        sequence: "E"
        enabled: root.visible && root.planEditable
        onActivated: root.setAction(root.selectedIndex, RebaseActions.edit)
    }

    Shortcut {
        sequence: "D"
        enabled: root.visible && root.planEditable
        onActivated: root.setAction(root.selectedIndex, RebaseActions.drop)
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.cancelPlan()
    }

    /* Children
     * ****************************************************************************************/
    Rectangle {
        anchors.fill: parent
        color: Style.colors.primaryBackground
        radius: 12
        clip: true
        border.color: Style.colors.primaryBorder
        border.width: 1

        /* Guide
         * ****************************************************************************************/
        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "commit_plan_tutorial"
            guideName: "Rebase Plan"
            guideIcon: Style.icons.copy
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return planHeader },
                        icon: Style.icons.gitBranch,
                        title: "What You're Rebasing",
                        description: "The branch being replayed and where it is landing, plus a tally of what the plan currently does to each commit.",
                        isInPopup: true
                    },
                    {
                        targetProvider: function() { return planTable },
                        icon: Style.icons.clockRotateLeft,
                        title: "The Plan",
                        description: "Every commit that will be replayed, oldest first. The coloured tag on each row is what will happen to it — click the tag to change it, or press P, R, S or D with the row selected.",
                        isInPopup: true
                    },
                    {
                        targetProvider: function() { return planTable },
                        icon: Style.icons.list,
                        title: "Reordering",
                        description: "Drag a row by its grip, use the arrows at the end of the row, or hold Alt and press the up and down keys. Commits are replayed top to bottom.",
                        isInPopup: true
                    },
                    {
                        targetProvider: function() { return previewPane },
                        icon: Style.icons.penToSquare,
                        title: "Commit Preview",
                        description: "What the selected commit changes. Collapse it when you want the whole window for the plan.",
                        isInPopup: true
                    },
                    {
                        targetProvider: function() { return planFooter },
                        icon: Style.icons.play,
                        title: "Start Rebase",
                        description: "Nothing touches the repository until you press this. If a conflict comes up, GitEase pauses so you can resolve it before continuing.",
                        commands: [{ command: "git rebase -i <upstream>" }],
                        isInPopup: true
                    }
                ]
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            RebasePlanHeader {
                id: planHeader

                Layout.fillWidth: true
                Layout.leftMargin: root.contentInset
                Layout.rightMargin: root.contentInset
                Layout.topMargin: Style.dp(14)
                Layout.bottomMargin: Style.dp(12)

                windowController: root.windowController

                branch: root.planData.branch || ""
                ontoRef: root.planData.onto || root.planData.upstream || ""
                commitCount: commitModel.count
                actionCounts: root.actionCounts

                onCloseRequested: root.cancelPlan()
                onAdviseRequested: {} // TODO(GE-xxx): no advisor backend yet; button is hidden.
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.primaryBorder
            }

            RebasePlanTable {
                id: planTable

                Layout.fillWidth: true
                Layout.fillHeight: true

                contentInset: root.contentInset
                model: commitModel
                currentIndex: root.selectedIndex
                showStatus: root.currentRebaseState !== rebaseState.idle
                editable: root.planEditable
                statusColorOf: function(status) {
                    return commitStatus.colorOf(status)
                }

                statusIsDone: function(status) {
                    return status === commitStatus.rebased || status === commitStatus.skipped
                }

                onRowClicked: (index) => root.selectCommit(index)
                onActionPicked: (index, action) => root.setAction(index, action)
                onMoveRequested: (from, to) => root.moveCommit(from, to)
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.primaryBorder
            }

            CommitPreviewPane {
                id: previewPane

                Layout.fillWidth: true
                Layout.preferredHeight: previewPane.animatedHeight

                contentInset: root.contentInset
                expandedHeight: Math.round(root.height * 0.34)
                commitSummary: root.selectedCommitSummary

                SplitView {
                    anchors.fill: parent
                    orientation: Qt.Horizontal

                    handle: SplitViewHandle {
                        orientation: Qt.Horizontal
                    }

                    FileChangesDock {
                        id: fileChangesDock

                        minimizable: true
                        icon: Style.icons.list
                        layoutController: root.layoutController
                        layoutId: "commitPlanPopup.fileChangesDock"
                        lastWidth: 320
                        SplitView.preferredWidth: lastWidth
                        SplitView.minimumWidth: 150

                        statusController: root.statusController

                        onFileSelected: function(filePath) { root.loadDiff(filePath) }
                    }

                    DiffView {
                        id: diffView

                        minimizable: true
                        icon: Style.icons.file
                        layoutController: root.layoutController
                        layoutId: "commitPlanPopup.diffView"
                        SplitView.fillWidth: true
                        SplitView.minimumWidth: 150

                        readOnly: true
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.primaryBorder
            }

            RebasePlanFooter {
                id: planFooter

                Layout.fillWidth: true
                Layout.leftMargin: root.contentInset
                Layout.rightMargin: root.contentInset
                Layout.topMargin: Style.dp(10)
                Layout.bottomMargin: Style.dp(12)

                canUndo: root.canUndo
                canRedo: root.canRedo
                canStart: commitModel.count > 0 && root.currentRebaseState !== rebaseState.running
                showCancel: root.currentRebaseState !== rebaseState.completed
                startText: root.currentRebaseState

                onUndoRequested: root.undoPlanEdit()
                onRedoRequested: root.redoPlanEdit()
                onCancelRequested: root.cancelPlan()
                onStartRequested: root.handleStartPressed()
            }
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: commitModel.count === 0
        visible: commitModel.count === 0
        Material.accent: Style.colors.accent
        z: 10
    }

    ListModel {
        id: commitModel
    }

    ConflictPopup {
        id : rebaseConflictPopup

        hostItem: root.hostItem
        currentOperation: ConflictPopup.OperationType.Rebase
        ontoRef: root.planData.onto || root.planData.upstream || ""
        rebaseController: root.rebaseController
        conflictController: root.conflictController
        notificationController: root.notificationController
        statusController: root.statusController
        commitController: root.commitController
        guideController: root.guideController
    }

    Connections {
        target: root.rebaseController
        enabled: root.ownsRebase

        function onPreviewRebasePlanReady(result) {
            if (!result.success) {
                notificationController.error(result.errorMessage || "Failed to load rebase plan", "Rebase", 5000)
                root.close()
                return
            }
            var data = result.data
            if (!data || !data.commits || data.commits.length === 0) {
                notificationController.info("There are no commits to replay for this rebase.", "Rebase", 4000)
                root.close()
                return
            }
            showPlan(data)
        }

        function onRebaseOperationStarted(hash) {
            setCommitStatus(hash, commitStatus.inProgress);

            scrollToCommit(hash);

            var idx = findCommitIndex(hash);
            if (idx >= 0)
                root.selectedIndex = idx;
        }

        function onRebaseOperationCompleted(hash) {
            setCommitStatus(hash, commitStatus.rebased);
        }

        function onRebaseOperationSkipped(hash) {
            setCommitStatus(hash, commitStatus.skipped);
        }

        function onRebaseConflict(hash) {
            setCommitStatus(hash, commitStatus.conflict);

            scrollToCommit(hash);

            rebaseConflictPopup.interactiveMode      = true;
            rebaseConflictPopup.operationCommitHash  = hash;
            rebaseConflictPopup.show();
        }

        function onRebaseFinished(success) {
            root.currentRebaseState = success ? rebaseState.completed : rebaseState.failed;
        }

        function onRebaseAborted() {
            root.currentRebaseState = rebaseState.idle;

            for (var i = 0; i < commitModel.count; i++)
                commitModel.setProperty(i, "status", commitStatus.pending);
        }
    }

    Connections {
        target: rebaseConflictPopup

        function onInteractiveActionRequested(action) {
            switch (action) {

            case ConflictPopup.InteractiveAction.Continue:
                root.rebaseController.interactiveContinue()
                break

            case ConflictPopup.InteractiveAction.Skip:
                root.rebaseController.interactiveSkip()
                break

            case ConflictPopup.InteractiveAction.Abort:
                root.rebaseController.interactiveAbort()
                break

            default:
                return
            }

            rebaseConflictPopup.close()
        }
    }

    /* Functions
     * ****************************************************************************************/
    function resetPopupState() {
        commitModel.clear()

        root.planData               = {}
        diffView.diffData           = null
        fileChangesDock.files       = []
        root.selectedCommitHash     = ""
        root.selectedCommitSummary  = ""
        root.selectedIndex          = -1
        root.currentRebaseState     = rebaseState.idle
        root.planHistory            = []
        root.planCursor             = -1
        root.planRevision++
    }

    function showPlan(data) {
        if (!data || !data.commits || data.commits.length === 0) {
            notificationController.info("There are no commits to replay for this rebase.", "Rebase", 4000)
            root.close()
            return
        }

        root.planData = data

        var commits = root.planData.commits || []
        for (var i = 0; i < commits.length; i++) {
            var commit = commits[i]
            commitModel.append({
                // TODO
                // The backend speaks pick/skip; the plan speaks pick/reword/squash/drop.
                action      : commit.action === "skip" ? RebaseActions.drop : RebaseActions.pick,
                hash        : commit.hash       || "",
                shortHash   : commit.shortHash  || "",
                summary     : commit.summary    || "",
                message     : commit.message    || "",
                author      : commit.author     || "",
                authorDate  : commit.authorDate || "",
                parentHash  : commit.parentHash || "",
                isMerge     : commit.isMerge    || false,
                status      : commitStatus.pending
            })
        }

        root.planRevision++
        root.recordPlanState()

        if (commitModel.count > 0)
            selectCommit(0)
    }

    function selectCommit(index) {
        if (index < 0 || index >= commitModel.count)
            return

        root.selectedIndex      = index
        var commit                  = commitModel.get(index)
        root.selectedCommitHash     = commit.hash
        root.selectedCommitSummary  = commit.summary
        diffView.diffData           = null
        fileChangesDock.commitHash  = commit.hash
    }

    function setAction(index, action) {
        if (!root.planEditable || !action || index < 0 || index >= commitModel.count)
            return

        if (commitModel.get(index).action === action)
            return

        commitModel.setProperty(index, "action", action)
        root.planRevision++
        root.recordPlanState()
    }

    /*! Moves a commit within the plan. Commits are replayed in the order shown, so this genuinely
     *  changes the rebase, not just the view. */
    function moveCommit(fromIndex, toIndex) {
        if (!root.planEditable)
            return

        if (fromIndex < 0 || fromIndex >= commitModel.count)
            return

        if (toIndex < 0 || toIndex >= commitModel.count || fromIndex === toIndex)
            return

        commitModel.move(fromIndex, toIndex, 1)
        root.selectedIndex = toIndex
        planTable.positionViewAtIndex(toIndex, ListView.Contain)
        root.planRevision++
        root.recordPlanState()
    }

    /* Undo history -- see planHistory.
     * ****************************************************************************************/
    function planSnapshot() {
        let state = []
        for (let i = 0; i < commitModel.count; ++i) {
            let row = commitModel.get(i)
            state.push({ hash: row.hash, action: row.action })
        }
        return state
    }

    function recordPlanState() {
        let history = root.planHistory.slice(0, root.planCursor + 1)
        history.push(root.planSnapshot())

        root.planHistory = history
        root.planCursor  = history.length - 1
    }

    function applyPlanSnapshot(state) {
        let rowsByHash = ({})
        for (let i = 0; i < commitModel.count; ++i) {
            let row = commitModel.get(i)
            rowsByHash[row.hash] = {
                action     : row.action,
                hash       : row.hash,
                shortHash  : row.shortHash,
                summary    : row.summary,
                message    : row.message,
                author     : row.author,
                authorDate : row.authorDate,
                parentHash : row.parentHash,
                isMerge    : row.isMerge,
                status     : row.status
            }
        }

        let selected = root.selectedCommitHash

        commitModel.clear()
        for (let entry of state) {
            let row = rowsByHash[entry.hash]
            if (!row)
                continue

            row.action = entry.action
            commitModel.append(row)
        }

        root.planRevision++

        let index = root.findCommitIndex(selected)
        root.selectCommit(index >= 0 ? index : 0)
    }

    function undoPlanEdit() {
        if (!root.canUndo)
            return

        root.planCursor--
        root.applyPlanSnapshot(root.planHistory[root.planCursor])
    }

    function redoPlanEdit() {
        if (!root.canRedo)
            return

        root.planCursor++
        root.applyPlanSnapshot(root.planHistory[root.planCursor])
    }

    /* ****************************************************************************************/
    function loadDiff(filePath) {
        if (!root.selectedCommitHash || !filePath)
            return

        var parentHash = root.commitController.getParentHash(root.selectedCommitHash)
        var selected = commitModel.get(root.selectedIndex)
        if (!parentHash && selected && selected.parentHash)
            parentHash = selected.parentHash

        if (!parentHash)
            return

        var diffRes = root.statusController.getDiff(parentHash, root.selectedCommitHash, filePath)
        if (diffRes && diffRes.success)
            diffView.diffData = diffRes.data
    }

    function operations() {
        var result = []
        for (var i = 0; i < commitModel.count; i++) {
            var commit = commitModel.get(i)
            result.push({
                action  : RebaseActions.operationFor(commit.action),
                hash    : commit.hash,
                summary : commit.summary
            })
        }
        return result
    }

    function cancelPlan() {
        if (root.rebaseController && root.currentRebaseState === rebaseState.running)
            root.rebaseController.interactiveAbort()

        root.close()
    }

    function handleStartPressed() {
        if (root.currentRebaseState === rebaseState.completed) {
            root.close()
            return
        }

        if (root.currentRebaseState !== rebaseState.idle
                && root.currentRebaseState !== rebaseState.failed) {
            return
        }

        if (root.currentRebaseState === rebaseState.failed) {
            for (var i = 0; i < commitModel.count; i++)
                commitModel.setProperty(i, "status", commitStatus.pending)
        }

        beginRebase()
    }

    function beginRebase() {
        if (root.currentRebaseState === rebaseState.running)
            return;

        // TODO(GE-xxx): drop this once GitRebase applies reword and squash. Until then those rows
        // replay unchanged, and saying so is better than letting the plan quietly not happen.
        let unsupported = 0
        for (let i = 0; i < commitModel.count; ++i) {
            if (!RebaseActions.isSupported(commitModel.get(i).action))
                unsupported++
        }

        if (unsupported > 0 && notificationController) {
            notificationController.warning(
                `Reword and squash aren't applied yet — ${unsupported} commit(s) will be replayed as-is.`,
                "Rebase", 5000)
        }

        root.currentRebaseState = rebaseState.running;

        var ops         = operations();
        ops.reverse();

        var onto        = planData.onto     || "";
        var upstream    = planData.upstream || "";
        var branch      = planData.branch   || "";

        var res = rebaseController.startInteractiveRebase(onto, upstream, branch, ops);
        if (!res.success) {
            root.currentRebaseState = rebaseState.failed;
            notificationController.error(res.errorMessage || "Rebased failed", "Rebase", 5000);
        }
    }

    function setCommitStatus(hash, status) {
        for (var i = 0; i < commitModel.count; i++) {
            if (commitModel.get(i).hash === hash) {
                commitModel.setProperty(i, "status", status);
                break;
            }
        }
    }

    function scrollToCommit(hash) {
        var idx = findCommitIndex(hash);
        if (idx >= 0)
            planTable.positionViewAtIndex(idx, ListView.Contain);
    }

    function findCommitIndex(hash) {
        for (var i = 0; i < commitModel.count; i++)
            if (commitModel.get(i).hash === hash)
                return i;

        return -1;
    }
}
