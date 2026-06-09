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

IPopup {
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
                    return "#FFA500"

                case rebased:
                    return "#2ECC40"

                case conflict:
                    return "#FF4136"

                case skipped:
                    return Style.colors.mutedText

                default:
                    return Style.colors.mutedText
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

    QtObject {
        id: actionType

        readonly property string pick: "pick"
        readonly property string skip: "skip"

        function colorOf(action) {
            switch (action) {
            case pick:
                return Style.colors.foreground

            case skip:
                return Style.colors.mutedText

            default:
                return Style.colors.accent
            }
        }
    }

    /* Property Declarations
     * ****************************************************************************************/
    property StatusController   statusController: null
    property CommitController   commitController: null
    property RebaseController   rebaseController: null
    property ConflictPopup      conflictPopup   : null


    property var    planData            : ({})
    property string selectedCommitHash  : ""

    property string currentRebaseState  : rebaseState.idle

    /* Signals
     * ****************************************************************************************/
    signal accepted(var operations)

    /* Object Properties
     * ****************************************************************************************/
    width   : Math.min(1180 , Overlay.overlay   ? Overlay.overlay.width - 80    : 1180)
    height  : Math.min(760  , Overlay.overlay   ? Overlay.overlay.height - 80   : 760)

    modal           : true
    closePolicy     : Popup.NoAutoClose
    anchors.centerIn: Overlay.overlay

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 12
        clip: true
        border.color: Style.colors.primaryBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Interactive Rebase Plan"
                        color: Style.colors.foreground
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        text: planSummary()
                        color: Style.colors.mutedText
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Text {
                    text: pickedCount() + " pick / " + skippedCount() + " skip"
                    color: Style.colors.secondaryText
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 11
                }
            }

            // Main content: vertical split
            SplitView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Vertical

                handle: Rectangle {
                    implicitWidth: 6
                    implicitHeight: 6
                    color: SplitHandle.pressed ? Style.colors.resizeHandlePressed
                         : SplitHandle.hovered ? Style.colors.resizeHandle
                         : "transparent"

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: 2
                        radius: 1
                        color: SplitHandle.pressed ? Style.colors.accent : Style.colors.primaryBorder
                    }
                }

                // Top: commit list (full width)
                Rectangle {
                    SplitView.preferredHeight: 300
                    SplitView.minimumHeight: 150
                    color: Style.colors.secondaryBackground
                    border.color: Style.colors.primaryBorder
                    radius: 8
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Column header
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            color: Style.colors.primaryBackground

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: "Action"
                                    Layout.preferredWidth: 78
                                    font.bold: true
                                    color: Style.colors.foreground
                                    font.pixelSize: 11
                                }

                                Text {
                                    text: "Commit"
                                    Layout.fillWidth: true
                                    font.bold: true; color: Style.colors.foreground
                                    font.pixelSize: 11
                                }

                                Text {
                                    text: "Author"
                                    Layout.preferredWidth: 130
                                    font.bold: true; color: Style.colors.foreground
                                    font.pixelSize: 11
                                }

                                Text {
                                    text: "Date"
                                    Layout.preferredWidth: 130
                                    font.bold: true; color: Style.colors.foreground
                                    font.pixelSize: 11
                                }

                                Text {
                                    text: (root.currentRebaseState !== rebaseState.idle) ? "Status" : ""
                                    Layout.preferredWidth: (root.currentRebaseState !== rebaseState.idle) ? 80 : 0
                                    font.bold: true
                                    color: Style.colors.foreground
                                    font.pixelSize: 11
                                }
                            }
                        }

                        ListView {
                            id: commitList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: commitModel
                            currentIndex: commitModel.count > 0 ? 0 : -1

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 32
                                color: ListView.isCurrentItem ? Qt.rgba(0.533, 0.694, 0.875, 0.38)
                                      : commitMouse.containsMouse ? Style.colors.hoverTitle
                                      : Style.colors.secondaryBackground

                                MouseArea {
                                    id: commitMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    onClicked: selectCommit(index)
                                    cursorShape: Qt.PointingHandCursor
                                }

                                RowLayout {
                                    id: layout
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    readonly property bool isDimmed     : action === actionType.skip
                                    readonly property color actionColor : actionType.colorOf(action)

                                    // Action combo (pick / skip)
                                    ComboBox {
                                        id: actionCombo
                                        Layout.preferredWidth: 78
                                        Layout.preferredHeight: 26
                                        model: root.planData.supportedActions || []
                                        font.pixelSize: 11

                                        background: Rectangle {
                                            color: Style.colors.secondaryBackground
                                            border.color: Style.colors.primaryBorder
                                            border.width: 1
                                            radius: 4
                                        }

                                        contentItem: Text {
                                            text: actionCombo.displayText
                                            color: Style.colors.foreground
                                            font.pixelSize: 11
                                            verticalAlignment: Text.AlignVCenter
                                            leftPadding: 8
                                            rightPadding: actionCombo.indicator.width + 8
                                            elide: Text.ElideRight
                                        }

                                        indicator: Canvas {
                                            id: comboIndicator
                                            x: actionCombo.width - width - 8
                                            y: (actionCombo.height - height) / 2
                                            width: 10
                                            height: 6
                                            contextType: "2d"

                                            onPaint: {
                                                context.reset()
                                                context.moveTo(0, 0)
                                                context.lineTo(width, 0)
                                                context.lineTo(width / 2, height)
                                                context.closePath()
                                                context.fillStyle = Style.colors.foreground
                                                context.fill()
                                            }
                                        }

                                        popup: Popup {
                                            y: actionCombo.height
                                            width: actionCombo.width
                                            implicitHeight: contentItem.implicitHeight
                                            padding: 1

                                            contentItem: ListView {
                                                clip: true
                                                implicitHeight: contentHeight
                                                model: actionCombo.popup.visible ? actionCombo.delegateModel : null
                                                currentIndex: actionCombo.highlightedIndex
                                            }

                                            background: Rectangle {
                                                color: Style.colors.secondaryBackground
                                                border.color: Style.colors.primaryBorder
                                                border.width: 1
                                                radius: 4
                                            }
                                        }

                                        delegate: ItemDelegate {
                                            width: actionCombo.width
                                            hoverEnabled: true
                                            contentItem: Text {
                                                text: modelData
                                                color: Style.colors.foreground
                                                font.pixelSize: 11
                                                verticalAlignment: Text.AlignVCenter
                                                elide: Text.ElideRight
                                            }

                                            background: Rectangle {
                                                color: hovered
                                                       ? Style.colors.hoverTitle
                                                       : Style.colors.secondaryBackground
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                acceptedButtons: Qt.NoButton
                                            }
                                        }

                                        onActivated: commitModel.setProperty(index, "action", currentText)

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            acceptedButtons: Qt.NoButton
                                        }
                                    }


                                    // Commit info (short hash + message)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: shortHash
                                            color: Style.colors.accent
                                            font.family: Style.fontTypes.roboto
                                            font.pixelSize: 11
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: summary
                                            color: layout.actionColor
                                            opacity: layout.isDimmed ? 0.5 : 1.0
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }

                                    // Author
                                    Text {
                                        text: author
                                        color: layout.actionColor
                                        opacity: layout.isDimmed ? 0.5 : 1.0
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        Layout.preferredWidth: 130
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    // Date
                                    Text {
                                        text: authorDate ? Qt.formatDateTime(new Date(authorDate), "yyyy-MM-dd hh:mm") : ""
                                        color: layout.actionColor
                                        opacity: layout.isDimmed ? 0.5 : 1.0
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                        Layout.preferredWidth: 130
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Text {
                                        text: status
                                        color: commitStatus.colorOf(status)
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                        Layout.preferredWidth: (root.currentRebaseState !== rebaseState.idle) ? 80 : 0
                                        visible: root.currentRebaseState !== rebaseState.idle
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // Bottom: file changes + diff view side‑by‑side
                SplitView {
                    orientation: Qt.Horizontal

                    handle: Rectangle {
                        implicitWidth: 6
                        implicitHeight: 6
                        color: SplitHandle.pressed ? Style.colors.resizeHandlePressed
                             : SplitHandle.hovered ? Style.colors.resizeHandle
                             : "transparent"

                        Rectangle {
                            anchors.centerIn: parent
                            width: 2
                            height: parent.height
                            radius: 1
                            color: SplitHandle.pressed ? Style.colors.accent : Style.colors.primaryBorder
                        }
                    }

                    FileChangesDock {
                        id: fileChangesDock

                        SplitView.preferredWidth: 500

                        statusController: root.statusController

                        onFileSelected: function(filePath) { root.loadDiff(filePath) }
                    }

                    DiffView {
                        id: diffView
                        readOnly: true
                    }
                }
            }

            // Bottom action bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: "Cancel"
                    flat: true
                    Layout.preferredWidth: 100
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 6
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            root.rebaseController.interactiveAbort()
                            root.close()
                        }
                    }
                }

                Button {
                    id: startButton
                    text: root.currentRebaseState
                    Layout.preferredWidth: 130
                    enabled: commitModel.count > 0  &&
                             root.currentRebaseState !== rebaseState.running

                    Material.foreground: Style.colors.textButton
                    background: Rectangle {
                        implicitHeight: 34
                        color: startButton.enabled
                               ? (startButton.hovered ? Style.colors.accentHover : Style.colors.accent)
                               : Style.colors.disabledButton
                        radius: 6
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: startButton.enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor

                        onClicked: {
                            if (root.currentRebaseState === rebaseState.completed) {
                                root.close();

                            }
                            else if (root.currentRebaseState === rebaseState.idle || root.currentRebaseState === rebaseState.failed) {
                                if (root.currentRebaseState === rebaseState.failed) {
                                    for (var i = 0; i < commitModel.count; i++)
                                        commitModel.setProperty(i, "status", commitStatus.pending);
                                }
                                beginRebase();
                            }
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: commitModel
    }

    Connections {
        target: root.rebaseController

        function onRebaseOperationStarted(hash) {
            setCommitStatus(hash, commitStatus.inProgress);

            scrollToCommit(hash);

            var idx = findCommitIndex(hash);
            if (idx >= 0)
                commitList.currentIndex = idx;
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

            root.conflictPopup.interactiveMode  = true;
            root.conflictPopup.currentOperation = ConflictPopup.OperationType.Rebase;
            root.conflictPopup.show();
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

    function planSummary() {
        var upstream    = planData.upstream || ""
        var onto        = planData.onto || ""
        var branch      = planData.branch || "current branch"

        return onto.length > 0
               ? branch + " after " + upstream + " onto " + onto
               : branch + " onto " + upstream
    }

    function pickedCount() {
        var count = 0
        for (var i = 0; i < commitModel.count; i++) {
            if (commitModel.get(i).action !== "skip")
                count++
        }
        return count
    }

    function skippedCount() {
        return commitModel.count - pickedCount()
    }

    function showPlan(data) {
        commitModel.clear()

        root.planData           = data || {}
        diffView.diffData       = null
        fileChangesDock.files   = []
        root.selectedCommitHash = ""

        var commits = root.planData.commits || []
        for (var i = 0; i < commits.length; i++) {
            var commit = commits[i]
            commitModel.append({
                action      : commit.action     || "pick",
                hash        : commit.hash       || "",
                shortHash   : commit.shortHash  || "",
                summary     : commit.summary    || "",
                message     : commit.message    || "",
                author      : commit.author     || "",
                authorDate  : commit.authorDate || "",
                parentHash  : commit.parentHash || "",
                isMerge     : commit.isMerge    || false
            })
        }

        if (commitModel.count > 0)
            selectCommit(0)

        root.open()
    }

    function selectCommit(index) {
        if (index < 0 || index >= commitModel.count)
            return

        commitList.currentIndex     = index
        var commit                  = commitModel.get(index)
        root.selectedCommitHash     = commit.hash
        diffView.diffData           = null
        fileChangesDock.commitHash  = commit.hash
    }

    function loadDiff(filePath) {
        if (!root.selectedCommitHash || !filePath)
            return

        var parentHash = root.commitController.getParentHash(root.selectedCommitHash)
        var selected = commitModel.get(commitList.currentIndex)
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
                action  : commit.action,
                hash    : commit.hash,
                summary : commit.summary
            })
        }
        return result
    }

    function beginRebase() {
        if (root.currentRebaseState === rebaseState.running)
            return;

        root.currentRebaseState = rebaseState.running;

        var ops         = operations();
        ops.reverse();

        var onto        = planData.onto     || "";
        var upstream    = planData.upstream || "";
        var branch      = planData.branch   || "";

        rebaseController.startInteractiveRebase(onto, upstream, branch, ops);
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
            commitList.positionViewAtIndex(idx, ListView.Contain);
    }

    function findCommitIndex(hash) {
        for (var i = 0; i < commitModel.count; i++)
            if (commitModel.get(i).hash === hash)
                return i;

        return -1;
    }
}
