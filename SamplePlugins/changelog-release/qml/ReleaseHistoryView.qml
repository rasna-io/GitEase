import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl
import GitEaseChangelog

/*! ***********************************************************************************************
 * ReleaseHistoryView
 * Published releases as a timeline. Wide screens show the list and the selected release side by
 * side; narrow screens show one at a time with a way back to the list.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property ReleaseEngine          engine:                 null
    property NotificationController notificationController: null
    //! The analysis "releases" list, newest first.
    property var                    releases:               []
    property int                    releaseCount:           0
    property string                 webUrl:                 ""
    property string                 provider:               ""
    property string                 selectedTag:            ""
    property string                 filter:                 ""
    //! False while there is no readable repository.
    property bool                   available:              true

    readonly property bool split:         width >= Style.dp(900)
    readonly property int  selectedIndex: selectedTag.length > 0 ? releases.findIndex(r => r.tag === selectedTag) : -1

    /* Signals
     * ****************************************************************************************/
    signal prepareRequested()

    /* Object Properties
     * ****************************************************************************************/
    onSplitChanged:    Qt.callLater(ensureSelection)
    onReleasesChanged: { rebuild(); Qt.callLater(ensureSelection) }
    onFilterChanged:   rebuild()

    /* Functions
     * ****************************************************************************************/
    //! On wide screens something is always selected so the detail pane is never empty.
    function ensureSelection() {
        if (root.selectedTag.length > 0 && root.selectedIndex < 0)
            root.selectedTag = ""
        if (root.split && root.selectedIndex < 0 && root.releases.length > 0)
            root.selectedTag = root.releases[0].tag
    }

    //! Stable releases are compared with the previous stable one so their notes cover the pre-releases too.
    function previousTagFor(index) {
        const list = root.releases
        const current = list[index]
        if (!current)
            return ""
        for (let i = index + 1; i < list.length; i++) {
            if (current.prerelease || !list[i].prerelease)
                return list[i].tag
        }
        return ""
    }

    //! Re-reads the selected release, e.g. after the repository changed.
    function reloadSelected() {
        if (root.selectedIndex >= 0)
            detailsView.reload()
    }

    function rebuild() {
        releaseModel.clear()
        const f = root.filter.trim().toLowerCase()
        root.releases.forEach((r, i) => {
            if (f.length > 0 && (r.tag + " " + (r.subject || "")).toLowerCase().indexOf(f) === -1)
                return
            releaseModel.append({
                tag: r.tag, date: r.date || "", subject: r.subject || "",
                prerelease: r.prerelease === true, year: (r.date || "").substring(0, 4) || "Undated",
                sourceIndex: i
            })
        })
    }

    /* Children
     * ****************************************************************************************/
    ListModel { id: releaseModel }

    ReleaseEmptyState {
        anchors.centerIn: parent
        width: Math.min(parent.width - Style.dp(32), Style.dp(440))
        visible: root.releases.length === 0
        iconText: Style.icons.tag
        title: root.available ? "No releases yet" : "No history to show"
        message: root.available ? "Version tags reachable from HEAD appear here as a timeline with their notes."
                                : "Open a repository to browse its releases."
        actionText: root.available ? "Prepare the first release" : ""
        actionIcon: Style.icons.rocket
        onActionClicked: root.prepareRequested()
    }

    RowLayout {
        anchors.fill: parent
        visible: root.releases.length > 0
        spacing: Style.dp(16)

        // ── Timeline ───────────────────────────────────────────────────
        ReleaseCard {
            Layout.preferredWidth: root.split ? Style.dp(330) : -1
            Layout.fillWidth: !root.split
            Layout.fillHeight: true
            visible: root.split || root.selectedIndex < 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.dp(14)
                spacing: Style.dp(10)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.dp(8)

                    Text {
                        text: "All releases"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.smallPt
                        font.weight: Font.DemiBold
                        color: Style.colors.pluginCardTitle
                    }

                    ReleaseBadge {
                        label: root.releaseCount > root.releases.length ? root.releases.length + "+" : String(root.releases.length)
                        textColor: Style.colors.pluginCountPillText
                        fillColor: Style.colors.pluginCountPillBackground
                        strong: true
                    }

                    Item { Layout.fillWidth: true }
                }

                TextField {
                    Layout.fillWidth: true
                    visible: root.releases.length > 8
                    minHeight: Style.dp(30)
                    baseFontSize: Style.appFont.captionPt
                    icon: Style.icons.search
                    iconSize: Style.appFont.captionPt
                    placeholderText: "Filter releases"
                    backgroundColor: Style.colors.controlBackground
                    borderColor: Style.colors.controlBorder
                    text: root.filter
                    onTextEdited: root.filter = text
                }

                ListView {
                    id: timeline
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: releaseModel

                    ScrollBar.vertical: ScrollBar {}

                    section.property: "year"
                    section.delegate: Item {
                        required property string section

                        width: ListView.view.width - Style.dp(12)
                        height: Style.dp(30)

                        ReleaseLabel {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: Style.dp(6)
                            anchors.bottomMargin: Style.dp(6)
                            text: parent.section
                        }
                    }

                    delegate: Rectangle {
                        id: releaseRow

                        required property int    index
                        required property string tag
                        required property string date
                        required property string subject
                        required property bool   prerelease
                        required property int    sourceIndex

                        readonly property bool latest:   sourceIndex === 0
                        readonly property bool selected: root.selectedTag === tag
                        readonly property bool last:     index === releaseModel.count - 1

                        width: ListView.view.width - Style.dp(12)
                        height: Style.dp(56)
                        radius: Style.dp(8)
                        color: selected ? Style.colors.pluginSidebarRowActiveBg
                             : rowHover.hovered ? Style.colors.pluginSidebarRowHoverBg : "transparent"

                        Behavior on color { ColorAnimation { duration: Style.motionFast } }

                        HoverHandler {
                            id: rowHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler { onTapped: root.selectedTag = releaseRow.tag }

                        // Timeline rail
                        Rectangle {
                            x: Style.dp(16)
                            y: parent.height / 2
                            width: 2
                            height: parent.height / 2 + 1
                            visible: !releaseRow.last
                            color: Style.colors.pluginDivider
                        }

                        Rectangle {
                            x: Style.dp(16)
                            y: 0
                            width: 2
                            height: parent.height / 2
                            visible: releaseRow.index > 0
                            color: Style.colors.pluginDivider
                        }

                        Rectangle {
                            x: Style.dp(17) - width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: releaseRow.latest ? Style.dp(12) : Style.dp(10)
                            height: width
                            radius: width / 2
                            color: releaseRow.latest || releaseRow.selected ? Style.colors.accent
                                 : releaseRow.prerelease ? Style.colors.repoItemStatusDirtyText : Style.colors.pluginCardBackground
                            border.width: releaseRow.latest || releaseRow.selected || releaseRow.prerelease ? 0 : 2
                            border.color: Style.colors.pluginCardMetaText
                        }

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Style.dp(34)
                            anchors.rightMargin: Style.dp(10)
                            spacing: Style.dp(2)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.dp(6)

                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: releaseRow.tag
                                    font.family: Style.fontTypes.jetBrainsMono
                                    font.pixelSize: Style.appFont.captionPt
                                    font.weight: Font.DemiBold
                                    color: releaseRow.selected ? Style.colors.pluginSidebarRowActiveText : Style.colors.pluginSidebarRowText
                                }

                                ReleaseBadge {
                                    visible: releaseRow.latest || releaseRow.prerelease
                                    implicitHeight: Style.dp(16)
                                    label: releaseRow.latest ? "Latest" : "Pre"
                                    textColor: releaseRow.latest ? Style.colors.accent : Style.colors.repoItemStatusDirtyText
                                    fillColor: releaseRow.latest ? Style.colors.accentWash : Style.colors.repoItemStatusDirtyBg
                                }

                                Text {
                                    text: releaseRow.date
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.microPt
                                    color: Style.colors.pluginCardMetaText
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: text.length > 0
                                elide: Text.ElideRight
                                text: releaseRow.subject
                                font.family: Style.fontTypes.inter
                                font.pixelSize: Style.appFont.microPt
                                color: Style.colors.pluginCardDescription
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: Style.dp(10)
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !root.split
                            text: Style.icons.arrowRight
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: Style.appFont.microPt
                            color: Style.colors.mutedText
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: releaseModel.count === 0 && root.filter.length > 0
                        text: "No releases match “" + root.filter + "”"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.mutedText
                    }
                }
            }
        }

        // ── Selected release ───────────────────────────────────────────
        ReleaseDetailsView {
            id: detailsView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.split || root.selectedIndex >= 0

            engine: root.engine
            notificationController: root.notificationController
            release: root.selectedIndex >= 0 ? root.releases[root.selectedIndex] : null
            previousTag: root.selectedIndex >= 0 ? root.previousTagFor(root.selectedIndex) : ""
            latest: root.selectedIndex === 0
            webUrl: root.webUrl
            provider: root.provider
            showBack: !root.split

            onBackRequested: root.selectedTag = ""
        }
    }
}
