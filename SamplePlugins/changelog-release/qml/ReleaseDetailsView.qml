import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl
import GitEaseChangelog

/*! ***********************************************************************************************
 * ReleaseDetailsView
 * A published release: its tag, the commits since the previous release and its notes.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property ReleaseEngine          engine:                 null
    property NotificationController notificationController: null
    //! Entry of the analysis "releases" list.
    property var                    release:                null
    property string                 previousTag:            ""
    property bool                   latest:                 false
    property string                 webUrl:                 ""
    property string                 provider:               ""
    property bool                   showBack:               false

    property var    details: null
    //! "notes" or "commits".
    property string tab:     "notes"

    readonly property bool   compact:      width < Style.dp(560)
    readonly property string tag:          release ? release.tag : ""
    readonly property bool   ready:        details !== null && details.success === true
    readonly property var    counts:       ready ? details.counts : null
    readonly property string providerName: provider === "github" ? "GitHub" : provider === "gitlab" ? "GitLab" : ""
    readonly property string pageLink:     engine && tag ? engine.releaseLink(webUrl, provider, tag) : ""
    readonly property string diffLink:     engine && tag ? engine.compareLink(webUrl, provider, previousTag, tag) : ""
    readonly property bool   fromMessage:  ready && details.message.length > 0

    //! Notes as shown and copied: the tag message when it has one, otherwise generated from the commits.
    readonly property string notes: {
        if (!ready || !engine)
            return ""
        if (fromMessage)
            return details.message
        const rendered = engine.renderNotes({
            version:     release.version,
            tagName:     tag,
            previousTag: previousTag,
            date:        details.date,
            webUrl:      webUrl,
            provider:    provider,
            commits:     details.commits,
            linkCommits: true
        })
        return rendered.split("\n").slice(1).join("\n").trim()
    }

    /* Signals
     * ****************************************************************************************/
    signal backRequested()

    /* Object Properties
     * ****************************************************************************************/
    onTagChanged:         reloadTimer.restart()
    onPreviousTagChanged: reloadTimer.restart()

    /* Functions
     * ****************************************************************************************/
    function reload() {
        root.details = root.engine && root.tag ? root.engine.releaseDetails(root.tag, root.previousTag) : null
    }

    function copyNotes() {
        clipboardHelper.text = "## " + root.tag + (root.ready && root.details.date ? " - " + root.details.date : "") + "\n\n" + root.notes + "\n"
        clipboardHelper.selectAll()
        clipboardHelper.copy()
        clipboardHelper.deselect()
        root.notificationController?.success("Notes for " + root.tag + " copied to the clipboard", "Releases", 2500)
    }

    /* Children
     * ****************************************************************************************/
    Timer {
        id: reloadTimer
        interval: 0
        onTriggered: root.reload()
    }

    TextEdit {
        id: clipboardHelper
        visible: false
    }

    component Meta: Row {
        id: meta

        property string iconText: ""
        property string label: ""

        spacing: Style.dp(6)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: meta.iconText
            font.family: Style.fontTypes.font6Pro
            font.pixelSize: Style.appFont.microPt
            color: Style.colors.pluginCardMetaText
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: meta.label
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.captionPt
            color: Style.colors.pluginCardMetaText
        }
    }

    //! Badge vertically centered in a Flow row of \a rowHeight.
    component RowBadge: Item {
        id: rowBadge

        property alias label:     badge.label
        property alias textColor: badge.textColor
        property alias fillColor: badge.fillColor
        property real  rowHeight: Style.dp(34)

        width: badge.implicitWidth
        height: rowHeight

        ReleaseBadge {
            id: badge
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    component TabButton: AbstractButton {
        id: tabButton

        property string key: ""
        property string count: ""
        readonly property bool selected: root.tab === key

        implicitHeight: Style.dp(34)
        implicitWidth: tabRow.implicitWidth + Style.dp(8)
        hoverEnabled: true
        onClicked: root.tab = key

        background: Item {
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 2
                radius: 1
                color: tabButton.selected ? Style.colors.accent : "transparent"
            }
        }

        contentItem: Item {
            Row {
                id: tabRow
                anchors.centerIn: parent
                spacing: Style.dp(6)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: tabButton.text
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt
                    font.weight: tabButton.selected ? Font.DemiBold : Font.Medium
                    color: tabButton.selected ? Style.colors.foreground
                         : tabButton.hovered ? Style.colors.secondaryText : Style.colors.mutedText
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: tabButton.count.length > 0
                    text: tabButton.count
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.microPt
                    color: tabButton.selected ? Style.colors.accent : Style.colors.mutedText
                }
            }
        }

        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Style.dp(12)

        // ── Hero ───────────────────────────────────────────────────────
        ReleaseCard {
            Layout.fillWidth: true
            Layout.preferredHeight: heroColumn.implicitHeight + Style.dp(32)

            ColumnLayout {
                id: heroColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.dp(16)
                spacing: Style.dp(10)

                ReleaseButton {
                    visible: root.showBack
                    variant: "ghost"
                    iconText: Style.icons.arrowLeft
                    text: "All releases"
                    onClicked: root.backRequested()
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.dp(14)

                    Rectangle {
                        visible: !root.compact
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: Style.dp(46)
                        Layout.preferredHeight: Style.dp(46)
                        radius: Style.dp(12)
                        color: Style.colors.accentWash

                        Text {
                            anchors.centerIn: parent
                            text: Style.icons.tag
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: Style.appFont.largePt
                            color: Style.colors.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.dp(6)

                        Flow {
                            Layout.fillWidth: true
                            spacing: Style.dp(8)

                            Text {
                                height: Style.dp(34)
                                verticalAlignment: Text.AlignVCenter
                                text: root.tag
                                font.family: Style.fontTypes.jetBrainsMono
                                font.pixelSize: root.compact ? Style.appFont.largePt : Style.appFont.h2Pt
                                font.weight: Font.Bold
                                color: Style.colors.foreground
                            }

                            RowBadge {
                                visible: root.latest
                                label: "Latest"
                                textColor: Style.colors.accent
                                fillColor: Style.colors.accentWash
                            }

                            RowBadge {
                                visible: root.release !== null && root.release.prerelease === true
                                label: "Pre-release"
                                textColor: Style.colors.repoItemStatusDirtyText
                                fillColor: Style.colors.repoItemStatusDirtyBg
                            }

                            RowBadge {
                                visible: root.ready && !root.details.annotated
                                label: "Lightweight tag"
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: Style.dp(16)

                            Meta {
                                visible: root.ready && root.details.date.length > 0
                                iconText: Style.icons.calendar
                                label: root.ready ? root.details.date : ""
                            }

                            Meta {
                                visible: root.ready && root.details.tagger.length > 0
                                iconText: Style.icons.user
                                label: root.ready ? root.details.tagger : ""
                            }

                            Meta {
                                visible: root.ready
                                iconText: Style.icons.branch
                                label: !root.ready ? ""
                                     : root.counts.total + " commit" + (root.counts.total === 1 ? "" : "s")
                                       + (root.previousTag ? " since " + root.previousTag : " (first release)")
                            }
                        }
                    }
                }

                // Summary chips and actions
                Flow {
                    Layout.fillWidth: true
                    spacing: Style.dp(8)

                    Repeater {
                        model: {
                            if (!root.counts)
                                return []
                            let chips = []
                            if (root.counts.breaking > 0)
                                chips.push({ label: root.counts.breaking + " breaking", fg: Style.colors.repoItemStatusConflictText, bg: Style.colors.repoItemStatusConflictBg })
                            if (root.counts.features > 0)
                                chips.push({ label: root.counts.features + " feat", fg: Style.colors.accent, bg: Style.colors.accentWash })
                            if (root.counts.fixes > 0)
                                chips.push({ label: root.counts.fixes + " fix", fg: Style.colors.repoItemStatusDoneText, bg: Style.colors.repoItemStatusDoneBg })
                            if (root.counts.other > 0)
                                chips.push({ label: root.counts.other + " other", fg: Style.colors.pluginBadgeText, bg: Style.colors.pluginBadgeBackground })
                            return chips
                        }

                        delegate: RowBadge {
                            required property var modelData
                            rowHeight: Style.dp(28)
                            label: modelData.label
                            textColor: modelData.fg
                            fillColor: modelData.bg
                        }
                    }

                    Item {
                        width: Style.dp(4)
                        height: Style.dp(28)
                        visible: root.counts !== null && root.counts.total > 0
                    }

                    ReleaseButton {
                        iconText: Style.icons.copy
                        text: "Copy notes"
                        enabled: root.ready
                        onClicked: root.copyNotes()
                    }

                    ReleaseButton {
                        visible: root.diffLink.length > 0
                        iconText: Style.icons.branch
                        text: "Compare"
                        tooltip: "Compare " + root.previousTag + " with " + root.tag + " on " + root.providerName
                        onClicked: Qt.openUrlExternally(root.diffLink)
                    }

                    ReleaseButton {
                        visible: root.pageLink.length > 0
                        iconText: Style.icons.globe
                        text: "Open on " + root.providerName
                        onClicked: Qt.openUrlExternally(root.pageLink)
                    }
                }
            }
        }

        // ── Notes and commits ─────────────────────────────────────────
        ReleaseCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Style.dp(200)

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.dp(14)
                anchors.rightMargin: Style.dp(14)
                anchors.bottomMargin: Style.dp(14)
                anchors.topMargin: Style.dp(4)
                spacing: Style.dp(10)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.dp(16)

                    TabButton {
                        key: "notes"
                        text: "Release notes"
                    }

                    TabButton {
                        key: "commits"
                        text: "Commits"
                        count: root.counts ? String(root.counts.total) : ""
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: root.ready && root.tab === "notes" && !root.compact
                        text: root.fromMessage ? "from the tag message" : "generated from the commits"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.microPt
                        color: Style.colors.pluginCardMetaText
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: -Style.dp(10)
                    Layout.preferredHeight: 1
                    color: Style.colors.pluginDivider
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.tab === "commits" ? 1 : 0

                    NotesPreview {
                        padding: Style.dp(6)
                        markdown: root.notes
                    }

                    ListView {
                        clip: true
                        spacing: 1
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.ready ? root.details.commits : []

                        ScrollBar.vertical: ScrollBar {}

                        delegate: ReleaseCommitRow {
                            required property var modelData

                            width: ListView.view.width - Style.dp(12)
                            shortHash: modelData.shortHash
                            author: modelData.author
                            date: modelData.date
                            type: modelData.type
                            scope: modelData.scope
                            subject: modelData.subject
                            breaking: modelData.breaking
                            included: true
                            showToggle: false
                            enabledForEdit: false
                            compact: root.compact
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.details !== null && !root.ready
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: root.details ? root.details.errorMessage || "" : ""
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                    color: Style.colors.warning
                }
            }
        }
    }
}
