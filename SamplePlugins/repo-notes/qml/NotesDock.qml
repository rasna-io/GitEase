import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Templates as T

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * NotesDock
 * Tasks and a branch reminder for the open repository, plus a scratch note.
 * The host injects pluginManager, pluginId, repositoryController, branchController
 * and guideController. Everything is stored on this computer, keyed by the
 * repository path, and is never committed.
 * ************************************************************************************************/
UtilitiesCard {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    pluginManager: null
    property string pluginId:      "com.gitease.repo-notes"
    property var    repositoryController: null
    property var    branchController: null
    property GuideController guideController: null

    readonly property string repoPath: repositoryController?.appModel?.currentRepository?.path ?? ""
    readonly property string repoName: repositoryController?.appModel?.currentRepository?.name ?? ""
    readonly property string repoKey:  normalizePath(repoPath)
    readonly property bool   hasRepo:  repoKey.length > 0

    property string activeKey: ""
    property string currentBranch: ""
    property string branchNote: ""
    property string noteText: ""
    property var    tasks: []
    property bool   showDone: false
    property bool   scratchOpen: false
    property bool   applyingText: false
    property bool   pendingSave: false
    property bool   copied: false
    property double savedAt: 0

    readonly property int openCount: {
        let count = 0
        for (let i = 0; i < tasks.length; ++i)
            if (!tasks[i].done)
                ++count
        return count
    }
    readonly property int doneCount: tasks.length - openCount

    readonly property var listedTasks: {
        const needle = root.filterNeedle
        const searching = root.filterActive && !root.titleMatchesFilter
        const result = []
        for (let i = 0; i < tasks.length; ++i) {
            const task = tasks[i]
            if (!searching && !root.showDone && task.done)
                continue
            if (searching && String(task.text || "").toLowerCase().indexOf(needle) === -1)
                continue
            result.push(task)
        }
        return result
    }

    readonly property bool contentMatchesFilter: {
        if (!root.filterActive)
            return false
        const needle = root.filterNeedle
        if (root.currentBranch.toLowerCase().indexOf(needle) !== -1)
            return true
        if (root.branchNote.toLowerCase().indexOf(needle) !== -1)
            return true
        if (root.noteText.toLowerCase().indexOf(needle) !== -1)
            return true
        for (let i = 0; i < tasks.length; ++i) {
            if (String(tasks[i].text || "").toLowerCase().indexOf(needle) !== -1)
                return true
        }
        return false
    }

    /* Object Properties
     * ****************************************************************************************/
    title: "Repo Notes"
    icon: Style.icons.list
    badgeCount: root.openCount > 0 ? root.openCount : -1
    filteredCount: root.filterActive ? root.listedTasks.length : -1

    Component.onCompleted: root.reload()
    Component.onDestruction: {
        saveTimer.stop()
        root.saveActive()
    }
    onPluginManagerChanged: root.reload()
    onRepoKeyChanged: root.reload()

    /* Functions
     * ****************************************************************************************/
    function normalizePath(path) {
        if (repositoryController && typeof repositoryController.normalizeRepoPath === "function")
            return repositoryController.normalizeRepoPath(path)

        let normalized = (path || "").replace(/\\/g, "/").toLowerCase()
        while (normalized.length > 1 && normalized.endsWith("/"))
            normalized = normalized.slice(0, -1)
        return normalized
    }

    function readCurrentBranchName() {
        if (!root.hasRepo || !root.branchController)
            return ""
        if (typeof root.branchController.getCurrentBranchName !== "function")
            return ""
        return root.branchController.getCurrentBranchName() || ""
    }

    function readMap() {
        if (!pluginManager)
            return {}

        const raw = pluginManager.pluginSetting(pluginId, "notesByRepo", "")
        if (typeof raw !== "string" || raw.length === 0)
            return {}

        try {
            const parsed = JSON.parse(raw)
            return (parsed && typeof parsed === "object") ? parsed : {}
        } catch (error) {
            return {}
        }
    }

    function writeMap(map) {
        if (!pluginManager)
            return
        pluginManager.setPluginSetting(pluginId, "notesByRepo", JSON.stringify(map))
    }

    function entryOf(value) {
        if (typeof value === "string")
            return { text: value, updatedAt: 0, tasks: [], branches: {} }
        if (value && typeof value === "object") {
            return {
                text: String(value.text ?? ""),
                updatedAt: Number(value.updatedAt) || 0,
                tasks: Array.isArray(value.tasks) ? value.tasks : [],
                branches: (value.branches && typeof value.branches === "object") ? value.branches : {}
            }
        }
        return { text: "", updatedAt: 0, tasks: [], branches: {} }
    }

    function cleanTasks(list) {
        const cleaned = []
        if (!list)
            return cleaned
        for (let i = 0; i < list.length; ++i) {
            const item = list[i]
            if (!item)
                continue
            const text = String(item.text || "").trim()
            if (text.length === 0)
                continue
            cleaned.push({
                id: String(item.id || ("t" + i)),
                text: text,
                done: !!item.done
            })
        }
        return cleaned
    }

    function textOnBranch(entry, branchName) {
        if (!branchName || !entry || !entry.branches)
            return ""
        const value = entry.branches[branchName]
        if (!value)
            return ""
        if (typeof value === "string")
            return value
        return String(value.text || "")
    }

    function branchTextFrom(map, key, branch) {
        if (!key || !branch || !map[key])
            return ""
        return textOnBranch(entryOf(map[key]), branch)
    }

    function saveActive() {
        if (!pluginManager || root.applyingText || root.activeKey.length === 0)
            return

        const map = readMap()
        const previous = entryOf(map[root.activeKey])
        const branches = Object.assign({}, previous.branches)
        if (root.currentBranch.length > 0)
            branches[root.currentBranch] = { text: root.branchNote, updatedAt: Date.now() }

        const when = Date.now()
        map[root.activeKey] = {
            text: root.noteText,
            updatedAt: when,
            tasks: root.tasks,
            branches: branches
        }
        writeMap(map)
        root.savedAt = when
        root.pendingSave = false
    }

    function loadRepo(branchName) {
        let entry = { text: "", updatedAt: 0, tasks: [], branches: {} }
        if (root.hasRepo) {
            const map = readMap()
            if (Object.prototype.hasOwnProperty.call(map, root.repoKey)) {
                entry = entryOf(map[root.repoKey])
            } else {
                const legacy = pluginManager.pluginSetting(pluginId, "notes", "")
                if (typeof legacy === "string" && legacy.length > 0) {
                    entry = { text: legacy, updatedAt: Date.now(), tasks: [], branches: {} }
                    map[root.repoKey] = entry
                    writeMap(map)
                    pluginManager.setPluginSetting(pluginId, "notes", "")
                }
            }
        }

        root.activeKey = root.repoKey
        root.applyingText = true
        root.noteText = entry.text
        root.savedAt = entry.updatedAt
        root.tasks = root.cleanTasks(entry.tasks)
        root.currentBranch = branchName
        root.branchNote = root.textOnBranch(entry, branchName)
        root.pendingSave = false
        root.copied = false
        root.scratchOpen = entry.text.length > 0
        root.applyingText = false
    }

    function reload() {
        if (!root.pluginManager)
            return

        const nextBranch = root.readCurrentBranchName()
        const switchingRepo = root.activeKey !== root.repoKey
        const switchingBranch = nextBranch !== root.currentBranch
        if (!switchingRepo && !switchingBranch && root.activeKey.length > 0)
            return

        if (saveTimer.running) {
            saveTimer.stop()
            root.saveActive()
        } else if (root.activeKey.length > 0) {
            root.saveActive()
        }

        if (switchingRepo) {
            root.loadRepo(nextBranch)
            return
        }

        root.applyingText = true
        root.currentBranch = nextBranch
        root.branchNote = root.branchTextFrom(root.readMap(), root.activeKey, nextBranch)
        root.applyingText = false
    }

    function scheduleSave() {
        if (root.applyingText || root.activeKey.length === 0)
            return
        root.copied = false
        root.pendingSave = true
        saveTimer.restart()
    }

    function replaceTasks(next) {
        root.tasks = next
        root.scheduleSave()
    }

    function addTask(text) {
        const trimmed = (text || "").trim()
        if (!root.hasRepo || trimmed.length === 0)
            return
        const next = root.tasks.slice()
        next.unshift({
            id: Date.now().toString(36) + Math.floor(Math.random() * 1000).toString(36),
            text: trimmed,
            done: false
        })
        root.replaceTasks(next)
    }

    function toggleTask(id) {
        const next = []
        for (let i = 0; i < root.tasks.length; ++i) {
            const task = root.tasks[i]
            if (task.id === id)
                next.push({ id: task.id, text: task.text, done: !task.done })
            else
                next.push(task)
        }
        root.replaceTasks(next)
    }

    function renameTask(id, text) {
        const trimmed = (text || "").trim()
        if (trimmed.length === 0) {
            root.deleteTask(id)
            return
        }
        let changed = false
        const next = []
        for (let i = 0; i < root.tasks.length; ++i) {
            const task = root.tasks[i]
            if (task.id === id) {
                if (task.text !== trimmed)
                    changed = true
                next.push({ id: task.id, text: trimmed, done: task.done })
            } else {
                next.push(task)
            }
        }
        if (changed)
            root.replaceTasks(next)
    }

    function deleteTask(id) {
        root.replaceTasks(root.tasks.filter(task => task.id !== id))
    }

    function clearDone() {
        root.replaceTasks(root.tasks.filter(task => !task.done))
        root.showDone = false
    }

    function copyNote() {
        if (root.noteText.length === 0)
            return
        clipboardHelper.text = root.noteText
        clipboardHelper.selectAll()
        clipboardHelper.copy()
        root.copied = true
        copyTimer.restart()
    }

    /* Children
     * ****************************************************************************************/
    content: ColumnLayout {
        spacing: Style.dp(10)

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "repo_notes_tutorial"
            guideName: "Repo Notes"
            guideIcon: Style.icons.list
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return root },
                        icon: Style.icons.list,
                        title: "Repo Notes",
                        description: "A task list and a reminder for the branch you have checked out. Click the header to expand it. The badge is the number of open tasks.",
                        isInPopup: false,
                        activationDelay: 300,
                        onActivate: function() { root.collapsed = false }
                    },
                    {
                        targetProvider: function() { return branchField },
                        icon: Style.icons.branch,
                        title: "Branch Reminder",
                        description: "Leave a short note for this branch — what it is for, or what you still have to finish. It comes back the next time you check the branch out."
                    },
                    {
                        targetProvider: function() { return taskField },
                        icon: Style.icons.check,
                        title: "Tasks",
                        description: "Add tasks for this repository. Check one off and it leaves the list. Done tasks stay available until you clear them."
                    }
                ]
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.dp(4)
            enabled: root.hasRepo

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.dp(6)

                Text {
                    text: Style.icons.branch
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: Style.appFont.smallPt
                    color: Style.colors.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: !root.hasRepo
                          ? "No repository open"
                          : (root.currentBranch.length > 0 ? root.currentBranch : "No branch")
                    elide: Text.ElideMiddle
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt
                    font.weight: Font.DemiBold
                    color: Style.colors.utilitiesRowText
                }
            }

            TextField {
                id: branchField
                Layout.fillWidth: true
                enabled: root.hasRepo && root.currentBranch.length > 0
                placeholderText: root.hasRepo
                                 ? "Reminder for this branch"
                                 : "Open a repository first"
                minHeight: Style.dp(28)
                implicitWidth: Style.dp(40)
                topPadding: Style.dp(4)
                bottomPadding: Style.dp(4)
                leftPadding: Style.dp(8)
                rightPadding: Style.dp(8)
                baseFontSize: Style.appFont.smallPt
                backgroundColor: Style.colors.utilitiesSurfaceBackground
                borderColor: Style.colors.utilitiesSurfaceBorder
                focusBorderColor: Style.colors.accent
                focusBorderWidth: 1
                borderRadius: Style.dp(6)

                Component.onCompleted: text = root.branchNote

                Connections {
                    target: root
                    function onBranchNoteChanged() {
                        if (branchField.text !== root.branchNote)
                            branchField.text = root.branchNote
                    }
                }

                onTextChanged: {
                    if (root.applyingText || text === root.branchNote)
                        return
                    root.branchNote = text
                    root.scheduleSave()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.dp(4)

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.dp(6)

                Text {
                    text: "Tasks"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt
                    font.weight: Font.DemiBold
                    color: Style.colors.utilitiesRowText
                }

                Text {
                    text: root.openCount === 1 ? "1 open" : (root.openCount + " open")
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                    color: Style.colors.utilitiesRowSubText
                }

                Item { Layout.fillWidth: true }

                NoteLink {
                    visible: root.doneCount > 0
                    text: root.showDone ? "Hide done" : ("Done " + root.doneCount)
                    onActivated: root.showDone = !root.showDone
                }

                NoteLink {
                    visible: root.showDone && root.doneCount > 0
                    text: "Clear"
                    onActivated: root.clearDone()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.dp(4)
                enabled: root.hasRepo

                TextField {
                    id: taskField
                    Layout.fillWidth: true
                    placeholderText: "Add a task"
                    minHeight: Style.dp(28)
                    implicitWidth: Style.dp(40)
                    topPadding: Style.dp(4)
                    bottomPadding: Style.dp(4)
                    leftPadding: Style.dp(8)
                    rightPadding: Style.dp(8)
                    baseFontSize: Style.appFont.smallPt
                    backgroundColor: Style.colors.utilitiesSurfaceBackground
                    borderColor: Style.colors.utilitiesSurfaceBorder
                    focusBorderColor: Style.colors.accent
                    focusBorderWidth: 1
                    borderRadius: Style.dp(6)
                    onAccepted: {
                        root.addTask(text)
                        text = ""
                    }
                }

                ActionIconButton {
                    enabled: root.hasRepo && taskField.text.trim().length > 0
                    iconText: Style.icons.plus
                    tooltip: "Add task"
                    textColor: Style.colors.accent
                    onClicked: {
                        root.addTask(taskField.text)
                        taskField.text = ""
                    }
                }
            }

            Flickable {
                id: taskFlick
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(
                    Math.max(taskColumn.implicitHeight, root.listedTasks.length === 0 ? Style.dp(28) : 0),
                    Style.dp(168))
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                contentWidth: width
                contentHeight: taskColumn.implicitHeight
                interactive: contentHeight > height

                ScrollBar.vertical: NoteScrollBar {
                    policy: T.ScrollBar.AsNeeded
                }

                Column {
                    id: taskColumn
                    width: taskFlick.width
                    spacing: Style.dp(4)

                    Repeater {
                        model: root.listedTasks

                        delegate: Rectangle {
                            id: taskRow
                            required property var modelData
                            width: taskColumn.width
                            height: Style.dp(32)
                            radius: Style.dp(4)
                            color: taskHover.hovered
                                   ? Style.colors.utilitiesRowHoverBackground
                                   : Style.colors.utilitiesRowBackground
                            border.width: 1
                            border.color: Style.colors.utilitiesRowBorder

                            HoverHandler { id: taskHover }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Style.dp(6)
                                anchors.rightMargin: Style.dp(4)
                                spacing: Style.dp(6)

                                TaskCheck {
                                    on: taskRow.modelData.done
                                    onToggled: root.toggleTask(taskRow.modelData.id)
                                }

                                TextField {
                                    Layout.fillWidth: true
                                    implicitWidth: Style.dp(40)
                                    minHeight: Style.dp(22)
                                    topPadding: 0
                                    bottomPadding: 0
                                    leftPadding: 0
                                    rightPadding: Style.dp(4)
                                    baseFontSize: Style.appFont.smallPt
                                    backgroundColor: "transparent"
                                    borderWidth: 0
                                    focusBorderWidth: 0
                                    color: taskRow.modelData.done
                                           ? Style.colors.mutedText
                                           : Style.colors.utilitiesRowText
                                    font.strikeout: taskRow.modelData.done
                                    Component.onCompleted: text = taskRow.modelData.text
                                    onEditingFinished: root.renameTask(taskRow.modelData.id, text)
                                }

                                ActionIconButton {
                                    iconText: Style.icons.trash
                                    tooltip: "Delete task"
                                    textColor: Style.colors.utilitiesRowIcon
                                    onClicked: root.deleteTask(taskRow.modelData.id)
                                }
                            }
                        }
                    }

                    Text {
                        width: taskColumn.width
                        visible: root.listedTasks.length === 0
                        horizontalAlignment: Text.AlignHCenter
                        text: !root.hasRepo
                              ? "Open a repository to keep tasks."
                              : (root.filterActive && !root.titleMatchesFilter && root.tasks.length > 0
                                 ? "No matching tasks"
                                 : (root.tasks.length === 0 ? "No tasks yet" : "All tasks are done"))
                        color: Style.colors.utilitiesEmptyStateText
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.smallPt
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.dp(4)

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Style.dp(22)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.scratchOpen = !root.scratchOpen
                }

                RowLayout {
                    id: scratchHeader
                    anchors.fill: parent
                    spacing: Style.dp(6)

                    Text {
                        text: root.scratchOpen ? Style.icons.caretDown : Style.icons.caretRight
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.utilitiesRowIcon
                    }

                    Text {
                        text: "Scratch"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.smallPt
                        font.weight: Font.DemiBold
                        color: Style.colors.utilitiesRowText
                    }

                    Text {
                        visible: !root.scratchOpen && root.noteText.trim().length > 0
                        text: "Saved"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.utilitiesRowSubText
                    }

                    Item { Layout.fillWidth: true }

                    ActionIconButton {
                        id: copyBtn
                        visible: root.scratchOpen
                        enabled: root.noteText.length > 0
                        iconText: root.copied ? Style.icons.check : Style.icons.copy
                        tooltip: root.copied ? "Copied" : "Copy note"
                        textColor: root.copied ? Style.colors.accent : Style.colors.utilitiesRowIcon
                        onClicked: root.copyNote()
                    }

                    ActionIconButton {
                        visible: root.scratchOpen
                        enabled: root.hasRepo && root.noteText.length > 0
                        iconText: Style.icons.trash
                        tooltip: "Clear note"
                        textColor: Style.colors.utilitiesRowIcon
                        onClicked: {
                            root.noteText = ""
                            root.scheduleSave()
                        }
                    }
                }
            }

            Rectangle {
                id: editorShell
                visible: root.scratchOpen
                Layout.fillWidth: true
                Layout.preferredHeight: Style.dp(96)
                radius: Style.dp(6)
                clip: true
                color: Style.colors.utilitiesSurfaceBackground
                border.width: 1
                border.color: noteArea.activeFocus
                              ? Style.colors.accent
                              : Style.colors.utilitiesSurfaceBorder

                Flickable {
                    id: flick
                    anchors.fill: parent
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    contentWidth: width
                    contentHeight: Math.max(noteArea.implicitHeight + Style.dp(16), height)

                    ScrollBar.vertical: NoteScrollBar {
                        policy: T.ScrollBar.AsNeeded
                    }

                    TextArea {
                        id: noteArea
                        x: Style.dp(8)
                        y: Style.dp(6)
                        width: flick.width - Style.dp(20)
                        height: Math.max(implicitHeight, flick.height - Style.dp(12))
                        wrapMode: TextArea.Wrap
                        readOnly: !root.hasRepo
                        selectByMouse: true
                        persistentSelection: true
                        color: Style.colors.foreground
                        selectionColor: Style.colors.accent
                        selectedTextColor: Style.colors.onAccentText
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.smallPt
                        placeholderText: root.hasRepo
                                         ? "Anything else you want to remember…"
                                         : "Open a repository first."
                        placeholderTextColor: Style.colors.mutedText
                        background: null
                        padding: 0

                        Component.onCompleted: text = root.noteText

                        Connections {
                            target: root
                            function onNoteTextChanged() {
                                if (noteArea.text !== root.noteText)
                                    noteArea.text = root.noteText
                            }
                        }

                        onTextChanged: {
                            if (root.applyingText || text === root.noteText)
                                return
                            root.noteText = text
                            root.scheduleSave()
                        }
                    }
                }
            }
        }

        TextEdit {
            id: clipboardHelper
            visible: false
            width: 0
            height: 0
        }
    }

    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: root.saveActive()
    }

    Timer {
        id: copyTimer
        interval: 1400
        repeat: false
        onTriggered: root.copied = false
    }

    component TaskCheck: Rectangle {
        id: box
        property bool on: false
        signal toggled()

        Layout.alignment: Qt.AlignVCenter
        width: Style.dp(16)
        height: Style.dp(16)
        radius: Style.dp(4)
        color: box.on ? Style.colors.accent : "transparent"
        border.width: 1
        border.color: box.on ? Style.colors.accent : Style.colors.controlBorder

        Text {
            anchors.centerIn: parent
            visible: box.on
            text: Style.icons.check
            font.family: Style.fontTypes.font6Pro
            font.styleName: "Solid"
            font.pixelSize: Style.appFont.microPt
            color: Style.colors.onAccentText
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -Style.dp(4)
            cursorShape: Qt.PointingHandCursor
            onClicked: box.toggled()
        }
    }

    component NoteLink: Text {
        id: link
        signal activated()

        color: linkArea.containsMouse ? Style.colors.accentHover : Style.colors.accent
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.captionPt

        MouseArea {
            id: linkArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: link.activated()
        }
    }

    component NoteScrollBar: T.ScrollBar {
        id: bar

        padding: 2
        hoverEnabled: true
        policy: T.ScrollBar.AsNeeded
        visible: bar.size < 0.999
        minimumSize: 0.18

        contentItem: Rectangle {
            implicitWidth: 4
            implicitHeight: 4
            radius: width / 2
            color: bar.pressed ? Style.colors.scrollBarHandlePressed
                               : bar.hovered ? Style.colors.scrollBarHandleHover
                                             : Style.colors.scrollBarHandle
        }

        background: Item {
            implicitWidth: 8
        }
    }
}
