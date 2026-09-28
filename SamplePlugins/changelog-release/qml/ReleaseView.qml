import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl
import GitEaseChangelog

/*! ***********************************************************************************************
 * ReleaseView
 * Prepares a release: choose the version and commits, review the notes, then update the
 * changelog, commit, tag and push.
 *
 * Layout adapts to the width: the summary sits beside the work area on wide screens and below
 * it otherwise; changes and notes are side by side when there is room and tabs when not.
 *
 * The release commit and tag go through the host controllers so GitEase refreshes and
 * organization rules apply; the push goes through git so the user's credential helper is used.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property ReleaseEngine          engine:                 null
    property var                    analysis:               null
    property CommitController       commitController:       null
    property StatusController       statusController:       null
    property TagController          tagController:          null
    property RemoteController       remoteController:       null
    property NotificationController notificationController: null
    property var                    pluginManager:          null
    property string                 pluginId:               ""

    //! "major", "minor", "patch" or "custom".
    property string bumpChoice:      "minor"
    property string customVersion:   ""
    property string tagPrefix:       "v"
    property string changelogFile:   "CHANGELOG.md"
    property bool   updateChangelog: true
    property bool   createTag:       true
    property bool   pushAfter:       false
    property bool   includeAuthors:  false
    property bool   linkCommits:     true

    property string notes:           ""
    property bool   notesEdited:     false
    //! "preview" or "edit".
    property string notesMode:       "preview"
    //! Visible pane when changes and notes do not fit side by side: "changes" or "notes".
    property string workspaceTab:    "changes"
    property string commitFilter:    ""

    property bool   running:         false
    property bool   finished:        false
    property int    failedIndex:     -1
    property int    includedCount:   0

    // Responsive breakpoints
    readonly property bool wide:    width >= Style.dp(1080)
    readonly property bool compact: width < Style.dp(640)
    readonly property bool split:   workspaceCard.width >= Style.dp(720)

    readonly property bool   failed:       failedIndex >= 0 && !running
    readonly property bool   inProgress:   running || finished || failed
    readonly property string lastTag:      analysis ? analysis.lastTag || "" : ""
    readonly property string lastVersion:  analysis ? analysis.lastVersion || "0.0.0" : "0.0.0"
    readonly property string branch:       analysis ? analysis.branch || "" : ""
    readonly property bool   detached:     branch === "HEAD"
    readonly property string webUrl:       analysis ? analysis.webUrl || "" : ""
    readonly property string provider:     analysis ? analysis.provider || "" : ""
    readonly property string providerName: provider === "github" ? "GitHub" : provider === "gitlab" ? "GitLab" : ""
    readonly property int    totalCommits: analysis ? (analysis.commits || []).length : 0
    readonly property var    counts:       analysis ? analysis.counts || null : null

    readonly property string version: bumpChoice === "custom" ? customVersion.trim() : versionFor(bumpChoice)
    readonly property bool   versionValid: engine ? engine.isValidVersion(version) : false
    readonly property string tagName: tagPrefix + version
    readonly property bool   tagTaken: analysis !== null && (analysis.existingTags || []).indexOf(tagName) !== -1

    //! Pre-flight checks; blocking ones disable the release.
    readonly property var checks: {
        let list = []
        list.push(root.versionValid
                  ? { state: "ok",    text: "Version " + root.version + " is valid" }
                  : { state: "block", text: "Enter a valid semantic version, for example 1.4.0 or 2.0.0-rc.1" })
        if (root.createTag)
            list.push(root.tagTaken
                      ? { state: "block", text: "Tag " + root.tagName + " already exists" }
                      : { state: "ok",    text: "Tag " + root.tagName + " is available" })
        if (root.updateChangelog)
            list.push(root.otherStagedFiles.length > 0
                      ? { state: "block", text: root.otherStagedFiles.length + " other staged file(s) would join the release commit" }
                      : { state: "ok",    text: "Nothing else is staged" })
        if (root.pushAfter) {
            if (root.analysis && !root.analysis.hasOrigin)
                list.push({ state: "block", text: "No 'origin' remote to push to" })
            list.push(root.detached ? { state: "block", text: "HEAD is detached; check out a branch to push" }
                                    : { state: "ok",    text: "Pushing " + root.branch + " to origin" })
        }
        if (!root.updateChangelog && !root.createTag && !root.pushAfter)
            list.push({ state: "block", text: "Turn on at least one publish step" })
        if (root.includedCount === 0 && root.totalCommits > 0)
            list.push({ state: "warn", text: "No commits selected; the notes will be empty" })
        if (root.updateChangelog && !root.pushAfter && root.detached)
            list.push({ state: "warn", text: "HEAD is detached; the release commit will not be on a branch" })
        if (root.analysis && root.analysis.truncated)
            list.push({ state: "warn", text: "Only the latest 1000 commits are listed" })
        return list
    }

    readonly property var blockingIssues: checks.filter(c => c.state === "block").map(c => c.text)
    readonly property var warnings:       checks.filter(c => c.state === "warn").map(c => c.text)

    readonly property var otherStagedFiles: {
        const staged = root.analysis ? root.analysis.stagedFiles || [] : []
        const file = root.changelogFile.trim().replace(/\\/g, "/")
        return staged.filter(f => f !== file)
    }

    readonly property bool canRelease: !inProgress && blockingIssues.length === 0

    property var    _commitsByHash: ({})
    property var    _rows:          []
    property var    _included:      ({})
    property string _changelogPath: ""
    property int    _pushIndex:     -1

    /* Signals
     * ****************************************************************************************/
    signal resetRequested()
    signal released(string tagName)

    /* Object Properties
     * ****************************************************************************************/
    onVersionChanged:         regenTimer.restart()
    onTagPrefixChanged:       regenTimer.restart()
    onIncludeAuthorsChanged:  { saveSetting("includeAuthors", includeAuthors); regenTimer.restart() }
    onLinkCommitsChanged:     { saveSetting("linkCommits", linkCommits); regenTimer.restart() }
    onUpdateChangelogChanged: saveSetting("updateChangelog", updateChangelog)
    onCreateTagChanged:       saveSetting("createTag", createTag)
    onPushAfterChanged:       saveSetting("pushAfter", pushAfter)
    onCommitFilterChanged:    rebuildVisible()

    /* Functions
     * ****************************************************************************************/
    function setting(key, fallback) {
        if (!root.pluginManager || !root.pluginId)
            return fallback
        const value = root.pluginManager.pluginSetting(root.pluginId, key, fallback)
        if (typeof fallback === "boolean")
            return value === true || value === "true"
        return value === undefined || value === null || value === "" ? fallback : value
    }

    function saveSetting(key, value) {
        if (root.pluginManager && root.pluginId && root.analysis)
            root.pluginManager.setPluginSetting(root.pluginId, key, value)
    }

    function versionFor(bump) {
        if (!root.engine)
            return ""
        return root.engine.bumpVersion(root.lastVersion, bump)
    }

    //! Resets the view with fresh analysis.
    function load(result) {
        root.analysis = result
        root.running = false
        root.finished = false
        root.failedIndex = -1
        root.notesEdited = false
        root.notesMode = "preview"
        root.workspaceTab = "changes"
        stepsModel.clear()

        root.includeAuthors  = root.setting("includeAuthors", false)
        root.linkCommits     = root.setting("linkCommits", true)
        root.updateChangelog = root.setting("updateChangelog", true)
        root.createTag       = root.setting("createTag", true)
        root.pushAfter       = root.setting("pushAfter", false)
        root.changelogFile   = root.setting("changelogFile", "CHANGELOG.md")
        root.tagPrefix       = result.lastTag ? result.tagPrefix : root.setting("tagPrefix", "v")

        let bump = result.suggestedBump || "patch"
        if (!result.lastTag && bump === "patch")
            bump = "minor"
        root.bumpChoice = bump
        root.customVersion = result.suggestedVersion || ""

        root.fillCommits(result.commits || [])
        root.regenerate()
    }

    function groupOf(commit) {
        if (commit.breaking)
            return { title: "Breaking changes", order: 0 }
        switch (commit.type) {
        case "feat":     return { title: "Features", order: 1 }
        case "fix":      return { title: "Bug fixes", order: 2 }
        case "perf":     return { title: "Performance", order: 3 }
        case "revert":   return { title: "Reverts", order: 4 }
        case "refactor": return { title: "Refactoring", order: 5 }
        case "docs":     return { title: "Documentation", order: 6 }
        case "":         return { title: "Other changes", order: 9 }
        default:         return { title: "Maintenance", order: 8 }
        }
    }

    function includedByDefault(commit) {
        return commit.breaking || ["feat", "fix", "perf", "revert"].indexOf(commit.type) !== -1
    }

    // ── Commit selection ─────────────────────────────────────────────────────────────────────
    // _rows holds every commit and _included the selection; commitsModel only shows the rows
    // matching the filter, so filtering never loses what was selected.
    function fillCommits(commits) {
        let byHash = {}
        let included = {}
        let rows = commits.map((c, i) => {
            byHash[c.hash] = c
            included[c.hash] = root.includedByDefault(c)
            const group = root.groupOf(c)
            return {
                hash: c.hash, shortHash: c.shortHash, author: c.author, date: c.date,
                type: c.type, scope: c.scope, subject: c.subject, breaking: c.breaking,
                group: group.title, order: group.order * 100000 + i
            }
        })
        rows.sort((a, b) => a.order - b.order)

        root._commitsByHash = byHash
        root._included = included
        root._rows = rows
        if (root.commitFilter.length > 0)
            root.commitFilter = ""
        else
            root.rebuildVisible()
    }

    function matchesFilter(row) {
        const filter = root.commitFilter.trim().toLowerCase()
        if (filter.length === 0)
            return true
        return [row.subject, row.scope, row.type, row.author, row.shortHash].join(" ").toLowerCase().indexOf(filter) !== -1
    }

    function rebuildVisible() {
        commitsModel.clear()
        root._rows.forEach(r => {
            if (root.matchesFilter(r))
                commitsModel.append(Object.assign({ included: root._included[r.hash] === true }, r))
        })
        root.recountIncluded()
    }

    function recountIncluded() {
        let n = 0
        root._rows.forEach(r => { if (root._included[r.hash]) n++ })
        root.includedCount = n
    }

    function setIncludedAt(index, value) {
        root._included[commitsModel.get(index).hash] = value
        commitsModel.setProperty(index, "included", value)
    }

    //! Applies \a predicate to the commits matching the filter.
    function setIncluded(predicate) {
        for (let i = 0; i < commitsModel.count; i++)
            root.setIncludedAt(i, predicate(commitsModel.get(i)))
        root.recountIncluded()
        regenTimer.restart()
    }

    function toggleAt(index) {
        root.setIncludedAt(index, !commitsModel.get(index).included)
        root.recountIncluded()
        regenTimer.restart()
    }

    function toggleGroup(group) {
        const stats = root.groupCount(group)
        const value = stats.on !== stats.total
        for (let i = 0; i < commitsModel.count; i++)
            if (commitsModel.get(i).group === group)
                root.setIncludedAt(i, value)
        root.recountIncluded()
        regenTimer.restart()
    }

    function groupCount(group) {
        let total = 0, on = 0
        for (let i = 0; i < commitsModel.count; i++) {
            const row = commitsModel.get(i)
            if (row.group !== group)
                continue
            total++
            if (row.included)
                on++
        }
        return { total: total, on: on }
    }

    function includedCommits() {
        const all = root.analysis ? root.analysis.commits || [] : []
        return all.filter(c => root._included[c.hash] === true)
    }

    function includedCountOf(type) {
        return root.includedCommits().filter(c => type === "breaking" ? c.breaking : c.type === type).length
    }

    // ── Notes ────────────────────────────────────────────────────────────────────────────────
    function regenerate() {
        if (!root.engine || !root.analysis || root.notesEdited)
            return
        root.notes = root.engine.renderNotes({
            version:        root.version,
            tagName:        root.tagName,
            previousTag:    root.lastTag,
            webUrl:         root.webUrl,
            provider:       root.provider,
            commits:        root.includedCommits(),
            includeAuthors: root.includeAuthors,
            linkCommits:    root.linkCommits
        })
        notesArea.text = root.notes
    }

    function resetNotes() {
        root.notesEdited = false
        root.regenerate()
    }

    function copyNotes() {
        clipboardHelper.text = notesArea.text
        clipboardHelper.selectAll()
        clipboardHelper.copy()
        clipboardHelper.deselect()
        root.notificationController?.success("Release notes copied to the clipboard", "Releases", 2500)
    }

    //! Notes without the "## version - date" heading, as used for the tag message and web releases.
    function notesBody() {
        return notesArea.text.split("\n").slice(1).join("\n").trim()
    }

    // ── Release execution ────────────────────────────────────────────────────────────────────
    function startRelease() {
        if (!root.canRelease)
            return

        root.saveSetting("changelogFile", root.changelogFile.trim())
        root.saveSetting("tagPrefix", root.tagPrefix)
        root.notes = notesArea.text
        root.failedIndex = -1

        stepsModel.clear()
        if (root.updateChangelog) {
            stepsModel.append({ key: "changelog", title: "Update " + root.changelogFile.trim(), status: "pending", detail: "" })
            stepsModel.append({ key: "commit", title: "Commit chore(release): " + root.tagName, status: "pending", detail: "" })
        }
        if (root.createTag)
            stepsModel.append({ key: "tag", title: "Create tag " + root.tagName, status: "pending", detail: "" })
        if (root.pushAfter)
            stepsModel.append({ key: "push", title: root.createTag ? "Push branch and tag to origin" : "Push branch to origin", status: "pending", detail: "" })

        root.running = true
        Qt.callLater(root.runStep, 0)
    }

    //! Resumes a failed release from the step that failed; completed steps are not repeated.
    function retryFailed() {
        if (!root.failed)
            return
        const index = root.failedIndex
        for (let i = index; i < stepsModel.count; i++)
            root.setStep(i, "pending", "")
        root.failedIndex = -1
        root.running = true
        Qt.callLater(root.runStep, index)
    }

    function setStep(index, status, detail) {
        stepsModel.setProperty(index, "status", status)
        stepsModel.setProperty(index, "detail", detail || "")
    }

    function failStep(index, message) {
        root.setStep(index, "failed", message)
        for (let i = index + 1; i < stepsModel.count; i++)
            root.setStep(i, "skipped", "")
        root.failedIndex = index
        root.running = false
        root.notificationController?.error(message, "Release failed", 7000)
    }

    function finishRelease() {
        root.running = false
        root.finished = true
        root.notificationController?.success("Released " + root.tagName, "Releases", 4000)
        root.released(root.tagName)
    }

    function runStep(index) {
        if (index >= stepsModel.count) {
            root.finishRelease()
            return
        }

        const step = stepsModel.get(index)
        root.setStep(index, "running", "")

        switch (step.key) {
        case "changelog": {
            const res = root.engine.writeChangelog(root.changelogFile, root.version, root.notes)
            if (!res.success) {
                root.failStep(index, res.errorMessage)
                return
            }
            root._changelogPath = res.relativePath
            root.setStep(index, "done", res.created ? "Created the file" : "Added the " + root.version + " entry")
            break
        }
        case "commit": {
            const staged = root.statusController.stageFile(root._changelogPath)
            if (!staged.success) {
                root.failStep(index, staged.errorMessage || "Could not stage " + root._changelogPath)
                return
            }
            const committed = root.commitController.commit("chore(release): " + root.tagName, false, false)
            if (!committed.success) {
                root.failStep(index, committed.errorMessage || "The release commit failed")
                return
            }
            if (root.pluginManager && typeof root.pluginManager.notifyWorkflowEvent === "function")
                root.pluginManager.notifyWorkflowEvent("post-commit", { amend: false })
            root.setStep(index, "done", "")
            break
        }
        case "tag": {
            const body = root.notes.split("\n").slice(1).join("\n").trim()
            const res = root.tagController.create(root.tagName, "HEAD", "Release " + root.tagName + (body ? "\n\n" + body : ""), false)
            if (!res.success) {
                root.failStep(index, res.errorMessage || "Could not create tag " + root.tagName)
                return
            }
            root.setStep(index, "done", "Annotated tag on HEAD")
            break
        }
        case "push": {
            if (root.remoteController) {
                const rules = root.remoteController.checkPushRules("origin", root.branch, false)
                if (rules && !rules.success) {
                    root.failStep(index, rules.errorMessage || "Push blocked by a rule")
                    return
                }
            }
            root._pushIndex = index
            root.engine.push("origin", root.createTag ? root.tagName : "")
            return
        }
        }

        Qt.callLater(root.runStep, index + 1)
    }

    /* Children
     * ****************************************************************************************/
    ListModel { id: commitsModel }
    ListModel { id: stepsModel }

    Timer {
        id: regenTimer
        interval: 60
        onTriggered: root.regenerate()
    }

    TextEdit {
        id: clipboardHelper
        visible: false
    }

    Connections {
        target: root.engine

        function onPushFinished(success, message) {
            if (root._pushIndex < 0)
                return
            const index = root._pushIndex
            root._pushIndex = -1
            if (!success) {
                root.failStep(index, message)
                return
            }
            root.setStep(index, "done", root.createTag ? "Branch and tag pushed" : "Branch pushed")
            Qt.callLater(root.runStep, index + 1)
        }
    }

    component TextLink: Text {
        id: textLink

        signal clicked()

        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.microPt
        font.weight: Font.Medium
        font.underline: linkHover.hovered
        color: enabled ? Style.colors.accent : Style.colors.mutedText

        HoverHandler {
            id: linkHover
            cursorShape: textLink.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        TapHandler {
            enabled: textLink.enabled
            onTapped: textLink.clicked()
        }
    }

    //! Two-or-more option switch; \a options is a list of { key, label, count? }.
    component Segmented: Rectangle {
        id: segmented

        property var    options: []
        property string current: ""

        signal picked(string key)

        implicitHeight: Style.dp(30)
        implicitWidth: segRow.implicitWidth + Style.dp(6)
        radius: Style.dp(8)
        color: Style.colors.controlBackground
        border.width: 1
        border.color: Style.colors.controlBorder

        Row {
            id: segRow
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: segmented.options

                delegate: Rectangle {
                    id: segment

                    required property var modelData
                    readonly property bool selected: segmented.current === modelData.key

                    width: segContent.implicitWidth + Style.dp(20)
                    height: segmented.height - Style.dp(6)
                    radius: Style.dp(6)
                    color: selected ? Style.colors.pluginCardBackground
                         : segHover.hovered ? Style.colors.controlBackgroundHover : "transparent"
                    border.width: selected ? 1 : 0
                    border.color: Style.colors.pluginCardBorder

                    Row {
                        id: segContent
                        anchors.centerIn: parent
                        spacing: Style.dp(6)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: segment.modelData.label
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.captionPt
                            font.weight: segment.selected ? Font.DemiBold : Font.Medium
                            color: segment.selected ? Style.colors.foreground : Style.colors.secondaryText
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: segment.modelData.count !== undefined
                            text: segment.modelData.count !== undefined ? segment.modelData.count : ""
                            font.family: Style.fontTypes.jetBrainsMono
                            font.pixelSize: Style.appFont.microPt
                            color: segment.selected ? Style.colors.accent : Style.colors.mutedText
                        }
                    }

                    HoverHandler {
                        id: segHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler { onTapped: segmented.picked(segment.modelData.key) }
                }
            }
        }
    }

    //! Publish step as a checklist row with a description (wide summary).
    component StepRow: AbstractButton {
        id: stepRow

        property string iconText:    ""
        property string description: ""

        checkable: true
        hoverEnabled: true
        implicitHeight: stepRowLayout.implicitHeight + Style.dp(16)

        background: Rectangle {
            radius: Style.dp(8)
            color: stepRow.hovered ? Style.colors.controlBackgroundHover : "transparent"
        }

        contentItem: RowLayout {
            id: stepRowLayout
            spacing: Style.dp(10)

            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: Style.dp(1)
                Layout.preferredWidth: Style.dp(18)
                Layout.preferredHeight: Style.dp(18)
                radius: Style.dp(5)
                color: stepRow.checked ? Style.colors.accent : "transparent"
                border.width: stepRow.checked ? 0 : 1
                border.color: Style.colors.controlBorder

                Behavior on color { ColorAnimation { duration: Style.motionFast } }

                Text {
                    anchors.centerIn: parent
                    visible: stepRow.checked
                    text: Style.icons.check
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: Style.appFont.microPt
                    color: Style.colors.onAccentText
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.dp(2)

                RowLayout {
                    spacing: Style.dp(6)

                    Text {
                        text: stepRow.iconText
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: Style.appFont.microPt
                        color: stepRow.checked ? Style.colors.accent : Style.colors.mutedText
                    }

                    Text {
                        text: stepRow.text
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.smallPt
                        font.weight: Font.DemiBold
                        color: stepRow.checked ? Style.colors.foreground : Style.colors.secondaryText
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: stepRow.description
                    wrapMode: Text.WordWrap
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.microPt
                    color: Style.colors.pluginCardMetaText
                }
            }
        }

        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }

    //! Publish step as a compact pill (narrow bar).
    component StepPill: AbstractButton {
        id: stepPill

        property string iconText: ""

        checkable: true
        hoverEnabled: true
        implicitHeight: Style.dp(30)
        implicitWidth: pillRow.implicitWidth + Style.dp(20)

        background: Rectangle {
            radius: height / 2
            color: stepPill.checked ? Style.colors.accentWash
                 : stepPill.hovered ? Style.colors.controlBackgroundHover : Style.colors.controlBackground
            border.width: 1
            border.color: stepPill.checked ? Style.colors.accent : Style.colors.controlBorder

            Behavior on color { ColorAnimation { duration: Style.motionFast } }
        }

        contentItem: Item {
            Row {
                id: pillRow
                anchors.centerIn: parent
                spacing: Style.dp(6)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: stepPill.checked ? Style.icons.check : stepPill.iconText
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: Style.appFont.microPt
                    color: stepPill.checked ? Style.colors.accent : Style.colors.mutedText
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: stepPill.text
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                    font.weight: Font.Medium
                    color: stepPill.checked ? Style.colors.foreground : Style.colors.secondaryText
                }
            }
        }

        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }

    component StatTile: Rectangle {
        id: statTile

        property string label: ""
        property string value: ""
        property color  valueColor: Style.colors.foreground

        implicitHeight: statColumn.implicitHeight + Style.dp(16)
        radius: Style.dp(8)
        color: Style.colors.pluginPanelBackground
        border.width: 1
        border.color: Style.colors.pluginCardBorder

        ColumnLayout {
            id: statColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Style.dp(10)
            anchors.rightMargin: Style.dp(10)
            spacing: 0

            Text {
                text: statTile.value
                font.family: Style.fontTypes.jetBrainsMono
                font.pixelSize: Style.appFont.largePt
                font.weight: Font.Bold
                color: statTile.valueColor
            }

            Text {
                Layout.fillWidth: true
                text: statTile.label
                elide: Text.ElideRight
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.microPt
                color: Style.colors.pluginCardMetaText
            }
        }
    }

    component SettingField: ColumnLayout {
        id: settingField

        property string label:       ""
        property string value:       ""
        property string placeholder: ""
        property var    validator:   null

        signal edited(string text)

        spacing: Style.dp(4)

        ReleaseLabel { text: settingField.label }

        TextField {
            Layout.fillWidth: true
            minHeight: Style.dp(30)
            baseFontSize: Style.appFont.captionPt
            font.family: Style.fontTypes.jetBrainsMono
            backgroundColor: Style.colors.controlBackground
            borderColor: Style.colors.controlBorder
            text: settingField.value
            placeholderText: settingField.placeholder
            validator: settingField.validator
            onTextEdited: settingField.edited(text)
        }
    }

    RegularExpressionValidator {
        id: prefixValidator
        regularExpression: /[A-Za-z_\-\/]{0,12}/
    }

    // ═══ Editing ═══════════════════════════════════════════════════════════════════════════
    GridLayout {
        anchors.fill: parent
        visible: !root.inProgress
        columns: root.wide ? 2 : 1
        columnSpacing: Style.dp(16)
        rowSpacing: Style.dp(12)

        // ── Work area ──────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.dp(12)

            // Version
            ReleaseCard {
                id: versionCard
                Layout.fillWidth: true
                Layout.preferredHeight: versionColumn.implicitHeight + Style.dp(28)

                ColumnLayout {
                    id: versionColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Style.dp(14)
                    spacing: Style.dp(10)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.dp(8)

                        Text {
                            text: "Choose the version"
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.smallPt
                            font.weight: Font.DemiBold
                            color: Style.colors.pluginCardTitle
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: root.lastTag ? "current " + root.lastTag : "no release yet"
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.microPt
                            color: Style.colors.pluginCardMetaText
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: versionCard.width >= Style.dp(620) ? 4 : 2
                        columnSpacing: Style.dp(8)
                        rowSpacing: Style.dp(8)

                        Repeater {
                            model: [
                                { key: "major",  label: "Major",  hint: "Breaking changes" },
                                { key: "minor",  label: "Minor",  hint: "New features" },
                                { key: "patch",  label: "Patch",  hint: "Bug fixes" },
                                { key: "custom", label: "Custom", hint: "Pre-release or any" }
                            ]

                            delegate: Rectangle {
                                id: versionOption

                                required property var modelData

                                readonly property bool selected: root.bumpChoice === modelData.key
                                readonly property bool suggested: root.analysis !== null && modelData.key !== "custom"
                                                                  && root.versionFor(modelData.key) === root.analysis.suggestedVersion

                                Layout.fillWidth: true
                                Layout.preferredHeight: optionColumn.implicitHeight + Style.dp(20)
                                radius: Style.dp(10)
                                color: selected ? Style.colors.accentWash
                                     : optionHover.hovered ? Style.colors.controlBackgroundHover : Style.colors.pluginPanelBackground
                                border.width: selected ? 2 : 1
                                border.color: selected ? Style.colors.accent : Style.colors.pluginCardBorder

                                Behavior on color { ColorAnimation { duration: Style.motionFast } }

                                HoverHandler {
                                    id: optionHover
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    onTapped: {
                                        root.bumpChoice = versionOption.modelData.key
                                        if (versionOption.modelData.key === "custom")
                                            customField.forceActiveFocus()
                                    }
                                }

                                ColumnLayout {
                                    id: optionColumn
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: Style.dp(12)
                                    anchors.rightMargin: Style.dp(10)
                                    spacing: Style.dp(2)

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Style.dp(6)

                                        Text {
                                            Layout.fillWidth: true
                                            text: versionOption.modelData.label
                                            elide: Text.ElideRight
                                            font.family: Style.fontTypes.inter
                                            font.pixelSize: Style.appFont.captionPt
                                            font.weight: Font.DemiBold
                                            color: versionOption.selected ? Style.colors.accent : Style.colors.secondaryText
                                        }

                                        ReleaseBadge {
                                            visible: versionOption.suggested
                                            implicitHeight: Style.dp(16)
                                            label: "Suggested"
                                            strong: true
                                            textColor: Style.colors.onAccentText
                                            fillColor: Style.colors.accent
                                        }
                                    }

                                    Text {
                                        text: versionOption.modelData.key === "custom"
                                              ? (root.bumpChoice === "custom" && root.customVersion.trim() ? root.customVersion.trim() : "x.y.z")
                                              : root.versionFor(versionOption.modelData.key)
                                        font.family: Style.fontTypes.jetBrainsMono
                                        font.pixelSize: Style.appFont.defaultPt
                                        font.weight: Font.Bold
                                        color: Style.colors.foreground
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: versionOption.modelData.hint
                                        elide: Text.ElideRight
                                        font.family: Style.fontTypes.inter
                                        font.pixelSize: Style.appFont.microPt
                                        color: Style.colors.pluginCardMetaText
                                    }
                                }
                            }
                        }
                    }

                    TextField {
                        id: customField
                        Layout.fillWidth: true
                        visible: root.bumpChoice === "custom"
                        minHeight: Style.dp(32)
                        baseFontSize: Style.appFont.captionPt
                        placeholderText: "Version, e.g. 2.0.0-rc.1"
                        text: root.customVersion
                        font.family: Style.fontTypes.jetBrainsMono
                        error: text.length > 0 && !root.versionValid
                        backgroundColor: Style.colors.controlBackground
                        borderColor: Style.colors.controlBorder
                        onTextEdited: root.customVersion = text
                    }
                }
            }

            // Blocking issues, shown here when the summary is not beside the work area
            Repeater {
                model: root.wide ? [] : root.blockingIssues

                delegate: Rectangle {
                    required property string modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: issueRow.implicitHeight + Style.dp(14)
                    radius: Style.dp(8)
                    color: Style.colors.repoItemStatusConflictBg

                    RowLayout {
                        id: issueRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Style.dp(12)
                        anchors.rightMargin: Style.dp(12)
                        spacing: Style.dp(8)

                        Text {
                            text: Style.icons.circleExclamation
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: Style.appFont.captionPt
                            color: Style.colors.repoItemStatusConflictText
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData
                            wrapMode: Text.WordWrap
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.captionPt
                            color: Style.colors.repoItemStatusConflictText
                        }
                    }
                }
            }

            // Changes and notes
            ReleaseCard {
                id: workspaceCard
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Style.dp(260)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Style.dp(14)
                    spacing: Style.dp(10)

                    // Tabs when the panes do not fit side by side
                    Segmented {
                        visible: !root.split
                        options: [
                            { key: "changes", label: "Changes", count: root.includedCount + "/" + root.totalCommits },
                            { key: "notes",   label: "Release notes" }
                        ]
                        current: root.workspaceTab
                        onPicked: function(key) { root.workspaceTab = key }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Style.dp(14)

                        // ── Changes pane ──
                        ColumnLayout {
                            Layout.preferredWidth: root.split ? parent.width * 0.46 : parent.width
                            Layout.fillWidth: !root.split
                            Layout.fillHeight: true
                            visible: root.split || root.workspaceTab === "changes"
                            spacing: Style.dp(8)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.dp(8)

                                Text {
                                    visible: root.split
                                    text: "Changes"
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.smallPt
                                    font.weight: Font.DemiBold
                                    color: Style.colors.pluginCardTitle
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.includedCount + " of " + root.totalCommits + " in the notes"
                                    elide: Text.ElideRight
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.microPt
                                    color: Style.colors.pluginCardMetaText
                                }

                                TextLink {
                                    text: "Suggested"
                                    onClicked: root.setIncluded(row => root.includedByDefault(root._commitsByHash[row.hash] || row))
                                }

                                TextLink {
                                    text: "All"
                                    onClicked: root.setIncluded(() => true)
                                }

                                TextLink {
                                    text: "None"
                                    onClicked: root.setIncluded(() => false)
                                }
                            }

                            TextField {
                                Layout.fillWidth: true
                                visible: root.totalCommits > 6
                                minHeight: Style.dp(30)
                                baseFontSize: Style.appFont.captionPt
                                icon: Style.icons.search
                                iconSize: Style.appFont.captionPt
                                placeholderText: "Filter commits"
                                backgroundColor: Style.colors.controlBackground
                                borderColor: Style.colors.controlBorder
                                text: root.commitFilter
                                onTextEdited: root.commitFilter = text
                            }

                            ListView {
                                id: commitList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 1
                                boundsBehavior: Flickable.StopAtBounds
                                model: commitsModel

                                ScrollBar.vertical: ScrollBar {}

                                section.property: "group"
                                section.delegate: Item {
                                    id: sectionHeader

                                    required property string section

                                    readonly property var stats: { commitsModel.count; root.includedCount; return root.groupCount(section) }

                                    width: ListView.view.width - Style.dp(12)
                                    height: Style.dp(32)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Style.dp(8)
                                        anchors.topMargin: Style.dp(8)
                                        spacing: Style.dp(8)

                                        ReleaseLabel { text: sectionHeader.section.toUpperCase() }

                                        Text {
                                            text: sectionHeader.stats.on + "/" + sectionHeader.stats.total
                                            font.family: Style.fontTypes.jetBrainsMono
                                            font.pixelSize: Style.appFont.microPt
                                            color: Style.colors.mutedText
                                        }

                                        Item { Layout.fillWidth: true }

                                        TextLink {
                                            text: sectionHeader.stats.on === sectionHeader.stats.total ? "Exclude" : "Include all"
                                            onClicked: root.toggleGroup(sectionHeader.section)
                                        }
                                    }
                                }

                                delegate: ReleaseCommitRow {
                                    id: commitRow
                                    width: ListView.view.width - Style.dp(12)
                                    compact: root.compact
                                    onToggled: root.toggleAt(commitRow.index)
                                }

                                Text {
                                    anchors.centerIn: parent
                                    width: parent.width - Style.dp(32)
                                    visible: commitsModel.count === 0
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                    text: root.commitFilter.length > 0 ? "No commits match “" + root.commitFilter + "”"
                                                                       : "No commits since " + (root.lastTag || "the beginning")
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.captionPt
                                    color: Style.colors.mutedText
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: 1
                            visible: root.split
                            color: Style.colors.pluginDivider
                        }

                        // ── Notes pane ──
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.split || root.workspaceTab === "notes"
                            spacing: Style.dp(8)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.dp(8)

                                Text {
                                    visible: root.split
                                    text: "Release notes"
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.smallPt
                                    font.weight: Font.DemiBold
                                    color: Style.colors.pluginCardTitle
                                }

                                ReleaseBadge {
                                    visible: root.notesEdited
                                    label: "edited"
                                    textColor: Style.colors.repoItemStatusDirtyText
                                    fillColor: Style.colors.repoItemStatusDirtyBg
                                }

                                Item { Layout.fillWidth: true }

                                Segmented {
                                    implicitHeight: Style.dp(26)
                                    options: [{ key: "preview", label: "Preview" }, { key: "edit", label: "Markdown" }]
                                    current: root.notesMode
                                    onPicked: function(key) {
                                        root.notesMode = key
                                        if (key === "edit")
                                            notesArea.forceActiveFocus()
                                    }
                                }

                                ReleaseButton {
                                    iconText: Style.icons.copy
                                    tooltip: "Copy the notes as Markdown"
                                    onClicked: root.copyNotes()
                                }
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: Style.dp(14)

                                CheckBox {
                                    text: "Authors"
                                    checked: root.includeAuthors
                                    enabled: !root.notesEdited
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.captionPt
                                    Material.accent: Style.colors.accent
                                    Material.foreground: Style.colors.foreground
                                    padding: 0
                                    onToggled: root.includeAuthors = checked
                                }

                                CheckBox {
                                    text: root.providerName.length > 0 ? root.providerName + " links" : "Links"
                                    checked: root.linkCommits
                                    enabled: !root.notesEdited
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.captionPt
                                    Material.accent: Style.colors.accent
                                    Material.foreground: Style.colors.foreground
                                    padding: 0
                                    onToggled: root.linkCommits = checked
                                }

                                TextLink {
                                    height: Style.dp(30)
                                    verticalAlignment: Text.AlignVCenter
                                    visible: root.notesEdited
                                    text: "Discard edits"
                                    onClicked: root.resetNotes()
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: Style.dp(8)
                                color: Style.colors.controlBackground
                                border.width: notesArea.activeFocus ? 2 : 1
                                border.color: notesArea.activeFocus ? Style.colors.accent : Style.colors.controlBorder

                                StackLayout {
                                    anchors.fill: parent
                                    anchors.margins: Style.dp(2)
                                    currentIndex: root.notesMode === "edit" ? 1 : 0

                                    NotesPreview {
                                        markdown: notesArea.text
                                    }

                                    ScrollView {
                                        clip: true

                                        TextArea {
                                            id: notesArea
                                            wrapMode: TextEdit.Wrap
                                            selectByMouse: true
                                            font.family: Style.fontTypes.jetBrainsMono
                                            font.pixelSize: Style.appFont.captionPt
                                            color: Style.colors.foreground
                                            selectionColor: Style.colors.accent
                                            selectedTextColor: Style.colors.onAccentText
                                            padding: Style.dp(10)
                                            background: Item {}

                                            onTextChanged: {
                                                if (activeFocus && text !== root.notes)
                                                    root.notesEdited = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Summary ────────────────────────────────────────────────────
        ReleaseCard {
            id: summaryCard
            Layout.preferredWidth: root.wide ? Style.dp(320) : -1
            Layout.fillWidth: !root.wide
            Layout.fillHeight: root.wide
            Layout.preferredHeight: root.wide ? -1 : barSummary.implicitHeight + Style.dp(24)

            // Wide: full summary column
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.dp(16)
                visible: root.wide
                spacing: Style.dp(12)

                ReleaseLabel { text: "RELEASE SUMMARY" }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.dp(2)

                    Text {
                        Layout.fillWidth: true
                        text: root.version.length > 0 ? root.tagName : root.tagPrefix + "?"
                        elide: Text.ElideRight
                        font.family: Style.fontTypes.jetBrainsMono
                        font.pixelSize: Style.appFont.h2Pt
                        font.weight: Font.Bold
                        color: root.versionValid ? Style.colors.foreground : Style.colors.error
                    }

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: (root.lastTag ? "from " + root.lastTag : "first release") + "  ·  " + (root.detached ? "detached HEAD" : root.branch)
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.pluginCardMetaText
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Style.dp(8)
                    rowSpacing: Style.dp(8)

                    StatTile {
                        Layout.fillWidth: true
                        label: "commits in notes"
                        value: root.includedCount + "/" + root.totalCommits
                    }

                    StatTile {
                        Layout.fillWidth: true
                        label: "breaking"
                        value: { root.includedCount; return root.includedCountOf("breaking") }
                        valueColor: value !== "0" ? Style.colors.repoItemStatusConflictText : Style.colors.mutedText
                    }

                    StatTile {
                        Layout.fillWidth: true
                        label: "features"
                        value: { root.includedCount; return root.includedCountOf("feat") }
                        valueColor: value !== "0" ? Style.colors.accent : Style.colors.mutedText
                    }

                    StatTile {
                        Layout.fillWidth: true
                        label: "fixes"
                        value: { root.includedCount; return root.includedCountOf("fix") }
                        valueColor: value !== "0" ? Style.colors.repoItemStatusDoneText : Style.colors.mutedText
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: stepsAndChecks.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {}

                    ColumnLayout {
                        id: stepsAndChecks
                        width: parent.width
                        spacing: Style.dp(6)

                        ReleaseLabel {
                            Layout.topMargin: Style.dp(4)
                            text: "PUBLISH STEPS"
                        }

                        StepRow {
                            Layout.fillWidth: true
                            iconText: Style.icons.file
                            text: "Update changelog"
                            description: "Add the notes to " + (root.changelogFile.trim() || "CHANGELOG.md") + " and commit chore(release): " + root.tagName
                            checked: root.updateChangelog
                            onToggled: root.updateChangelog = checked
                        }

                        SettingField {
                            Layout.fillWidth: true
                            Layout.leftMargin: Style.dp(36)
                            visible: root.updateChangelog
                            label: "FILE"
                            value: root.changelogFile
                            onEdited: function(text) { root.changelogFile = text }
                        }

                        StepRow {
                            Layout.fillWidth: true
                            iconText: Style.icons.tag
                            text: "Create tag"
                            description: "Annotated tag " + root.tagName + " with the notes as its message"
                            checked: root.createTag
                            onToggled: root.createTag = checked
                        }

                        SettingField {
                            Layout.fillWidth: true
                            Layout.leftMargin: Style.dp(36)
                            visible: root.createTag
                            label: "TAG PREFIX"
                            value: root.tagPrefix
                            placeholder: "none"
                            validator: prefixValidator
                            onEdited: function(text) { root.tagPrefix = text }
                        }

                        StepRow {
                            Layout.fillWidth: true
                            iconText: Style.icons.upload
                            text: "Push to origin"
                            description: root.createTag ? "Push " + (root.detached ? "HEAD" : root.branch) + " and the tag" : "Push " + (root.detached ? "HEAD" : root.branch)
                            checked: root.pushAfter
                            onToggled: root.pushAfter = checked
                        }

                        ReleaseLabel {
                            Layout.topMargin: Style.dp(10)
                            text: "CHECKS"
                        }

                        Repeater {
                            model: root.checks

                            delegate: RowLayout {
                                required property var modelData

                                Layout.fillWidth: true
                                spacing: Style.dp(8)

                                Text {
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: Style.dp(1)
                                    text: modelData.state === "ok" ? Style.icons.circleCheck
                                        : modelData.state === "warn" ? Style.icons.warning : Style.icons.circleExclamation
                                    font.family: Style.fontTypes.font6Pro
                                    font.pixelSize: Style.appFont.captionPt
                                    color: modelData.state === "ok" ? Style.colors.repoItemStatusDoneText
                                         : modelData.state === "warn" ? Style.colors.repoItemStatusDirtyText : Style.colors.repoItemStatusConflictText
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.text
                                    wrapMode: Text.WordWrap
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.captionPt
                                    color: modelData.state === "ok" ? Style.colors.pluginCardDescription : Style.colors.foreground
                                }
                            }
                        }
                    }
                }

                ReleaseButton {
                    Layout.fillWidth: true
                    variant: "primary"
                    large: true
                    enabled: root.canRelease
                    iconText: Style.icons.rocket
                    text: root.versionValid ? "Release " + root.tagName : "Release"
                    onClicked: root.startRelease()
                }
            }

            // Narrow: compact publish bar
            ColumnLayout {
                id: barSummary
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.dp(14)
                anchors.rightMargin: Style.dp(14)
                visible: !root.wide
                spacing: Style.dp(10)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.dp(10)

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: root.version.length > 0 ? root.tagName : root.tagPrefix + "?"
                            elide: Text.ElideRight
                            font.family: Style.fontTypes.jetBrainsMono
                            font.pixelSize: Style.appFont.largePt
                            font.weight: Font.Bold
                            color: root.versionValid ? Style.colors.foreground : Style.colors.error
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: root.includedCount + " of " + root.totalCommits + " commits  ·  "
                                  + (root.lastTag ? "from " + root.lastTag : "first release")
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.microPt
                            color: Style.colors.pluginCardMetaText
                        }
                    }

                    ReleaseButton {
                        visible: !root.compact
                        variant: "primary"
                        large: true
                        enabled: root.canRelease
                        iconText: Style.icons.rocket
                        text: root.versionValid ? "Release " + root.tagName : "Release"
                        onClicked: root.startRelease()
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Style.dp(6)

                    StepPill {
                        iconText: Style.icons.file
                        text: root.changelogFile.trim() || "CHANGELOG.md"
                        checked: root.updateChangelog
                        onToggled: root.updateChangelog = checked
                    }

                    StepPill {
                        iconText: Style.icons.tag
                        text: "Tag"
                        checked: root.createTag
                        onToggled: root.createTag = checked
                    }

                    StepPill {
                        iconText: Style.icons.upload
                        text: "Push"
                        checked: root.pushAfter
                        onToggled: root.pushAfter = checked
                    }

                    ActionIconButton {
                        width: Style.dp(30)
                        height: Style.dp(30)
                        iconText: Style.icons.gear
                        tooltip: "Changelog file and tag prefix"
                        backgroundColor: "transparent"
                        textColor: Style.colors.secondaryText
                        onClicked: settingsPopup.opened ? settingsPopup.close() : settingsPopup.open()

                        Popup {
                            id: settingsPopup
                            y: -height - Style.dp(8)
                            width: Style.dp(260)
                            padding: Style.dp(14)

                            background: Rectangle {
                                radius: Style.dp(10)
                                color: Style.colors.pluginCardBackground
                                border.width: 1
                                border.color: Style.colors.pluginCardBorder
                            }

                            contentItem: ColumnLayout {
                                spacing: Style.dp(10)

                                SettingField {
                                    Layout.fillWidth: true
                                    label: "CHANGELOG FILE"
                                    value: root.changelogFile
                                    onEdited: function(text) { root.changelogFile = text }
                                }

                                SettingField {
                                    Layout.fillWidth: true
                                    label: "TAG PREFIX"
                                    value: root.tagPrefix
                                    placeholder: "none"
                                    validator: prefixValidator
                                    onEdited: function(text) { root.tagPrefix = text }
                                }
                            }
                        }
                    }
                }

                ReleaseButton {
                    Layout.fillWidth: true
                    visible: root.compact
                    variant: "primary"
                    large: true
                    enabled: root.canRelease
                    iconText: Style.icons.rocket
                    text: root.versionValid ? "Release " + root.tagName : "Release"
                    onClicked: root.startRelease()
                }
            }
        }
    }

    // ═══ Releasing: progress and result ═══════════════════════════════════════════════════
    ReleaseCard {
        anchors.fill: parent
        visible: root.inProgress

        Flickable {
            anchors.fill: parent
            clip: true
            contentWidth: width
            contentHeight: Math.max(height, progressColumn.implicitHeight + Style.dp(48))
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {}

            ColumnLayout {
                id: progressColumn
                anchors.centerIn: parent
                width: Math.min(parent.width - Style.dp(32), Style.dp(560))
                spacing: Style.dp(18)

                // Status
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    spacing: Style.dp(8)

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Style.dp(64)
                        Layout.preferredHeight: Style.dp(64)
                        radius: width / 2
                        color: root.failed ? Style.colors.repoItemStatusConflictBg
                             : root.finished ? Style.colors.repoItemStatusDoneBg : Style.colors.accentWash

                        BusyIndicator {
                            anchors.centerIn: parent
                            width: Style.dp(32)
                            height: Style.dp(32)
                            padding: 0
                            visible: root.running
                            running: visible
                            Material.accent: Style.colors.accent
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !root.running
                            text: root.failed ? Style.icons.circleExclamation : Style.icons.check
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: Style.appFont.h2Pt
                            color: root.failed ? Style.colors.repoItemStatusConflictText : Style.colors.repoItemStatusDoneText
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: root.failed ? "Release stopped"
                            : root.finished ? root.tagName + " is released"
                            : "Releasing " + root.tagName + "..."
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.h3Pt
                        font.weight: Font.DemiBold
                        color: Style.colors.pluginCardTitle
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: root.failed ? "Fix the problem below and try again. Steps that already finished will not run twice."
                            : root.finished ? (root.pushAfter ? "Everything is published to origin."
                                                              : "The release is local. Push the branch" + (root.createTag ? " and tag" : "") + " when you are ready.")
                            : "Keep this page open until every step has finished."
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.pluginCardDescription
                    }
                }

                // Steps timeline
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: stepsColumn.implicitHeight + Style.dp(24)
                    radius: Style.dp(10)
                    color: Style.colors.pluginPanelBackground
                    border.width: 1
                    border.color: Style.colors.pluginCardBorder

                    ColumnLayout {
                        id: stepsColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Style.dp(12)
                        spacing: 0

                        Repeater {
                            model: stepsModel

                            delegate: RowLayout {
                                id: stepItem

                                required property int    index
                                required property string title
                                required property string status
                                required property string detail

                                Layout.fillWidth: true
                                spacing: Style.dp(12)

                                Item {
                                    Layout.preferredWidth: Style.dp(22)
                                    Layout.fillHeight: true
                                    Layout.minimumHeight: Style.dp(40)

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: marker.bottom
                                        anchors.bottom: parent.bottom
                                        width: 2
                                        visible: stepItem.index < stepsModel.count - 1
                                        color: stepItem.status === "done" ? Style.colors.repoItemStatusDoneText : Style.colors.pluginDivider
                                        opacity: 0.6
                                    }

                                    Rectangle {
                                        id: marker
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.top
                                        anchors.topMargin: Style.dp(4)
                                        width: Style.dp(22)
                                        height: Style.dp(22)
                                        radius: width / 2
                                        color: stepItem.status === "done" ? Style.colors.repoItemStatusDoneBg
                                             : stepItem.status === "failed" ? Style.colors.repoItemStatusConflictBg
                                             : stepItem.status === "running" ? Style.colors.accentWash : Style.colors.controlBackground
                                        border.width: stepItem.status === "pending" || stepItem.status === "skipped" ? 1 : 0
                                        border.color: Style.colors.controlBorder

                                        BusyIndicator {
                                            anchors.centerIn: parent
                                            width: Style.dp(16)
                                            height: Style.dp(16)
                                            padding: 0
                                            visible: stepItem.status === "running"
                                            running: visible
                                            Material.accent: Style.colors.accent
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: stepItem.status !== "running"
                                            text: stepItem.status === "done" ? Style.icons.check
                                                : stepItem.status === "failed" ? Style.icons.close
                                                : stepItem.status === "skipped" ? Style.icons.minus : (stepItem.index + 1)
                                            font.family: stepItem.status === "pending" ? Style.fontTypes.inter : Style.fontTypes.font6Pro
                                            font.pixelSize: Style.appFont.microPt
                                            font.weight: Font.DemiBold
                                            color: stepItem.status === "done" ? Style.colors.repoItemStatusDoneText
                                                 : stepItem.status === "failed" ? Style.colors.repoItemStatusConflictText : Style.colors.mutedText
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: Style.dp(6)
                                    Layout.bottomMargin: Style.dp(10)
                                    spacing: Style.dp(2)

                                    Text {
                                        Layout.fillWidth: true
                                        text: stepItem.title
                                        wrapMode: Text.WordWrap
                                        font.family: Style.fontTypes.inter
                                        font.pixelSize: Style.appFont.smallPt
                                        font.weight: stepItem.status === "running" ? Font.DemiBold : Font.Medium
                                        color: stepItem.status === "pending" || stepItem.status === "skipped"
                                               ? Style.colors.mutedText : Style.colors.foreground
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: text.length > 0
                                        text: stepItem.detail
                                        wrapMode: Text.WordWrap
                                        font.family: Style.fontTypes.inter
                                        font.pixelSize: Style.appFont.captionPt
                                        color: stepItem.status === "failed" ? Style.colors.error : Style.colors.pluginCardMetaText
                                    }
                                }
                            }
                        }
                    }
                }

                // Actions; they wrap onto more lines when the page is narrow
                Flow {
                    id: actionsFlow

                    readonly property real naturalWidth: {
                        let w = 0, n = 0
                        for (let i = 0; i < children.length; i++) {
                            const c = children[i]
                            if (c.visible) {
                                w += c.implicitWidth
                                n++
                            }
                        }
                        return w + Math.max(0, n - 1) * spacing
                    }

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.min(progressColumn.width, naturalWidth)
                    visible: !root.running
                    spacing: Style.dp(8)

                    ReleaseButton {
                        visible: root.failed
                        variant: "primary"
                        large: true
                        iconText: Style.icons.refresh
                        text: "Try again"
                        onClicked: root.retryFailed()
                    }

                    ReleaseButton {
                        visible: root.finished && root.createTag && root.pushAfter && root.providerName.length > 0
                        variant: "primary"
                        large: true
                        iconText: Style.icons.globe
                        text: "Publish on " + root.providerName
                        tooltip: "Opens the new-release form prefilled with the notes"
                        onClicked: Qt.openUrlExternally(root.engine.newReleaseLink(root.webUrl, root.provider, root.tagName,
                                                                                   root.tagName, root.notesBody()))
                    }

                    ReleaseButton {
                        visible: root.finished
                        large: true
                        iconText: Style.icons.copy
                        text: "Copy notes"
                        onClicked: root.copyNotes()
                    }

                    ReleaseButton {
                        visible: root.finished && root.pushAfter && root.createTag && root.lastTag.length > 0
                                 && root.engine !== null && root.engine.compareLink(root.webUrl, root.provider, root.lastTag, root.tagName).length > 0
                        large: true
                        iconText: Style.icons.branch
                        text: "Compare"
                        tooltip: "Compare " + root.lastTag + " with " + root.tagName
                        onClicked: Qt.openUrlExternally(root.engine.compareLink(root.webUrl, root.provider, root.lastTag, root.tagName))
                    }

                    ReleaseButton {
                        large: true
                        variant: root.finished ? "ghost" : "secondary"
                        text: root.finished ? "Done" : "Start over"
                        onClicked: root.resetRequested()
                    }
                }
            }
        }
    }
}
