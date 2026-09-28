import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase_Style_Impl
import GitEase_Style
import GitEase
import GitEaseChangelog

/*! ***********************************************************************************************
 * ChangelogPage
 * Header with the "Next release" and "History" tabs. The next release is prepared in
 * ReleaseView; published releases are browsed in ReleaseHistoryView. Both adapt to the width.
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property RepositoryController   repositoryController:   null
    property CommitController       commitController:       null
    property StatusController       statusController:       null
    property TagController          tagController:          null
    property RemoteController       remoteController:       null
    property NotificationController notificationController: null
    property var                    gitStateNotifier:       null
    property var                    pluginManager:          null
    property string                 pluginId:               "com.gitease.changelog-release"

    property var    analysis:      null
    //! The history changed while the notes were being edited; reloading would discard the edits.
    property bool   pendingReload: false
    //! "next" or "history".
    property string tab:           "next"

    readonly property string repoPath: repositoryController?.appModel?.currentRepository?.path ?? ""
    readonly property string repoName: repoPath.length > 0 ? repoPath.replace(/[\\/]+$/, "").split(/[\\/]/).pop() : ""
    readonly property bool   ready:    analysis !== null && analysis.success === true
    readonly property int    pending:  ready ? analysis.counts.total : 0
    readonly property var    releases: ready ? analysis.releases || [] : []

    //! The flow stays visible after a release so its result can be read.
    readonly property bool showFlow: ready && (pending > 0 || releaseView.inProgress)

    // Responsive breakpoints
    readonly property bool narrowHeader: width < Style.dp(720)
    readonly property real pagePadding:  width < Style.dp(700) ? Style.dp(12) : Style.dp(20)

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.pluginPageBackground

    onRepoPathChanged: {
        root.analysis = null
        root.pendingReload = false
        historyView.selectedTag = ""
        if (!releaseView.running) {
            releaseView.analysis = null
            releaseView.finished = false
            releaseView.failedIndex = -1
        }
        refreshTimer.restart()
    }
    Component.onCompleted: refreshTimer.restart()

    /* Functions
     * ****************************************************************************************/
    function onPageActivated() {
        refreshTimer.restart()
    }

    function sameHistory(a, b) {
        return !!a && !!b && a.headHash === b.headHash && (a.lastTag || "") === (b.lastTag || "")
    }

    function applyAnalysis(result) {
        root.analysis = result
        historyView.reloadSelected()

        if (!result.success || releaseView.inProgress)
            return

        if (root.sameHistory(releaseView.analysis, result)) {
            // Same commits: keep the user's choices, only refresh tags, staged files and remotes.
            releaseView.analysis = result
            return
        }

        if (releaseView.analysis && releaseView.notesEdited) {
            root.pendingReload = true
            return
        }

        root.pendingReload = false
        releaseView.load(result)
    }

    function resetFlow() {
        root.pendingReload = false
        if (root.ready)
            releaseView.load(root.analysis)
        refreshTimer.restart()
    }

    function showRelease(tag) {
        historyView.selectedTag = tag
        root.tab = "history"
    }

    /* Children
     * ****************************************************************************************/
    ReleaseEngine {
        id: releaseEngine
        repoPath: root.repoPath

        onAnalyzed: function(result) {
            root.applyAnalysis(result)
        }
    }

    Timer {
        id: refreshTimer
        interval: 300
        onTriggered: {
            if (root.repoPath.length === 0) {
                root.analysis = null
                return
            }
            if (releaseEngine.busy)
                restart()
            else
                releaseEngine.analyze()
        }
    }

    Connections {
        target: root.gitStateNotifier
        ignoreUnknownSignals: true

        function onRepositoryChanged() {
            refreshTimer.restart()
        }
    }

    Connections {
        target: root.tagController
        ignoreUnknownSignals: true

        function onTagsChanged() {
            refreshTimer.restart()
        }
    }

    //! "Next release" / "History" switch; \a stretch makes both tabs share the full width.
    component HeaderTabs: Rectangle {
        id: headerTabs

        property bool stretch: false

        implicitHeight: Style.dp(36)
        implicitWidth: tabsRow.implicitWidth + Style.dp(8)
        radius: Style.dp(10)
        color: Style.colors.controlBackground
        border.width: 1
        border.color: Style.colors.controlBorder

        RowLayout {
            id: tabsRow
            anchors.fill: parent
            anchors.margins: Style.dp(4)
            spacing: Style.dp(4)

            Repeater {
                model: [
                    { key: "next",    label: "Next release", icon: Style.icons.rocket,
                      count: root.pending > 0 ? String(root.pending) : "" },
                    { key: "history", label: "History",      icon: Style.icons.tag,
                      count: root.releases.length > 0 ? String(root.releases.length) : "" }
                ]

                delegate: Rectangle {
                    id: tabItem

                    required property var modelData
                    readonly property bool selected: root.tab === modelData.key

                    Layout.fillWidth: headerTabs.stretch
                    Layout.fillHeight: true
                    Layout.preferredWidth: tabContent.implicitWidth + Style.dp(24)
                    radius: Style.dp(7)
                    color: selected ? Style.colors.pluginCardBackground
                         : tabHover.hovered ? Style.colors.controlBackgroundHover : "transparent"
                    border.width: selected ? 1 : 0
                    border.color: Style.colors.pluginCardBorder

                    Behavior on color { ColorAnimation { duration: Style.motionFast } }

                    HoverHandler {
                        id: tabHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler { onTapped: root.tab = tabItem.modelData.key }

                    Row {
                        id: tabContent
                        anchors.centerIn: parent
                        spacing: Style.dp(7)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tabItem.modelData.icon
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: Style.appFont.microPt
                            color: tabItem.selected ? Style.colors.accent : Style.colors.mutedText
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tabItem.modelData.label
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.captionPt
                            font.weight: tabItem.selected ? Font.DemiBold : Font.Medium
                            color: tabItem.selected ? Style.colors.foreground : Style.colors.secondaryText
                        }

                        ReleaseBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: tabItem.modelData.count.length > 0
                            implicitHeight: Style.dp(17)
                            label: tabItem.modelData.count
                            strong: true
                            textColor: tabItem.selected && tabItem.modelData.key === "next" ? Style.colors.onAccentText : Style.colors.pluginCountPillText
                            fillColor: tabItem.selected && tabItem.modelData.key === "next" ? Style.colors.accent : Style.colors.pluginCountPillBackground
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: headerColumn.implicitHeight + Style.dp(24)
            color: Style.colors.pluginPanelBackground

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Style.colors.pluginPanelBorder
            }

            ColumnLayout {
                id: headerColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: root.pagePadding
                anchors.rightMargin: root.pagePadding
                spacing: Style.dp(10)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.dp(12)

                    Rectangle {
                        Layout.preferredWidth: Style.dp(38)
                        Layout.preferredHeight: Style.dp(38)
                        radius: Style.dp(10)
                        color: Style.colors.accentWash

                        Text {
                            anchors.centerIn: parent
                            text: Style.icons.tag
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: Style.appFont.defaultPt
                            color: Style.colors.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: "Releases"
                            elide: Text.ElideRight
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.largePt
                            font.weight: Font.DemiBold
                            color: Style.colors.pluginCardTitle
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: {
                                if (root.repoName.length === 0)
                                    return "No repository open"
                                if (!root.ready)
                                    return root.repoName
                                const where = root.analysis.branch === "HEAD" ? "detached HEAD" : root.analysis.branch
                                const latest = root.analysis.lastTag ? "latest " + root.analysis.lastTag : "no releases yet"
                                return root.repoName + "  ·  " + where + "  ·  " + latest
                            }
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.captionPt
                            color: Style.colors.pluginSectionMetaText
                        }
                    }

                    HeaderTabs {
                        visible: !root.narrowHeader
                    }

                    Item {
                        Layout.preferredWidth: Style.dp(32)
                        Layout.preferredHeight: Style.dp(32)

                        BusyIndicator {
                            anchors.centerIn: parent
                            width: Style.dp(18)
                            height: Style.dp(18)
                            padding: 0
                            running: releaseEngine.busy
                            visible: running
                            Material.accent: Style.colors.accent
                        }

                        ActionIconButton {
                            anchors.fill: parent
                            visible: !releaseEngine.busy
                            enabled: root.repoPath.length > 0
                            iconText: Style.icons.refresh
                            tooltip: "Refresh"
                            backgroundColor: "transparent"
                            textColor: Style.colors.pluginSectionMetaText
                            onClicked: refreshTimer.restart()
                        }
                    }
                }

                HeaderTabs {
                    Layout.fillWidth: true
                    visible: root.narrowHeader
                    stretch: true
                }
            }
        }

        // ── Content ─────────────────────────────────────────────────────
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: root.pagePadding
            currentIndex: root.tab === "history" ? 1 : 0

            // Next release
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    spacing: Style.dp(12)
                    visible: root.showFlow

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: reloadRow.implicitHeight + Style.dp(16)
                        visible: root.pendingReload && !releaseView.inProgress
                        radius: Style.dp(8)
                        color: Style.colors.repoItemStatusDirtyBg

                        RowLayout {
                            id: reloadRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Style.dp(14)
                            anchors.rightMargin: Style.dp(8)
                            spacing: Style.dp(10)

                            Text {
                                text: Style.icons.warning
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: Style.appFont.captionPt
                                color: Style.colors.repoItemStatusDirtyText
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "New commits arrived while you were editing the notes. Reload to include them; your edits will be replaced."
                                wrapMode: Text.WordWrap
                                font.family: Style.fontTypes.inter
                                font.pixelSize: Style.appFont.captionPt
                                color: Style.colors.repoItemStatusDirtyText
                            }

                            ReleaseButton {
                                iconText: Style.icons.refresh
                                text: "Reload"
                                onClicked: root.resetFlow()
                            }
                        }
                    }

                    ReleaseView {
                        id: releaseView
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        engine: releaseEngine
                        commitController: root.commitController
                        statusController: root.statusController
                        tagController: root.tagController
                        remoteController: root.remoteController
                        notificationController: root.notificationController
                        pluginManager: root.pluginManager
                        pluginId: root.pluginId

                        onResetRequested: root.resetFlow()
                        onReleased: refreshTimer.restart()
                    }
                }

                ReleaseEmptyState {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - Style.dp(32), Style.dp(440))
                    visible: !root.showFlow
                    busy: root.repoPath.length > 0 && !root.analysis
                    iconText: root.repoPath.length === 0 ? Style.icons.folder
                            : root.analysis && !root.analysis.success ? Style.icons.warning : Style.icons.check
                    iconColor: root.analysis && !root.analysis.success ? Style.colors.warning
                             : root.ready ? Style.colors.repoItemStatusDoneText : Style.colors.accent
                    iconFill: root.ready ? Style.colors.repoItemStatusDoneBg : Style.colors.accentWash
                    title: root.repoPath.length === 0 ? "Open a repository"
                         : !root.analysis ? "Reading history..."
                         : !root.analysis.success ? "Can't prepare a release"
                         : "Everything is released"
                    message: root.repoPath.length === 0 ? "Releases are prepared from the repository that is currently open."
                           : !root.analysis ? ""
                           : !root.analysis.success ? root.analysis.errorMessage
                           : "There are no commits since " + root.analysis.lastTag
                             + ". New commits will show up here, ready to become release notes."
                    actionText: root.ready && root.releases.length > 0 ? "View " + root.releases[0].tag : ""
                    actionIcon: Style.icons.tag
                    onActionClicked: root.showRelease(root.releases[0].tag)
                }
            }

            // History
            ReleaseHistoryView {
                id: historyView

                engine: releaseEngine
                notificationController: root.notificationController
                releases: root.releases
                available: root.ready
                releaseCount: root.ready ? root.analysis.releaseCount : 0
                webUrl: root.ready ? root.analysis.webUrl || "" : ""
                provider: root.ready ? root.analysis.provider || "" : ""

                onPrepareRequested: root.tab = "next"
            }
        }
    }
}
