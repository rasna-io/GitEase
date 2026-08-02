import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * GraphViewHeader
 * ************************************************************************************************/
RowLayout {
    id: headerRow

    /* Property Declarations
     * ****************************************************************************************/
    property GuideController guideController : null
    property RemoteController remoteController : null

    property bool   isGraphReady    : false
    property bool   isFetching      : false
    property string filterText      : ""
    property string filterStartDate : ""
    property string filterEndDate   : ""
    property var    filterModes     : []
    property var    filterFieldOptions: ["Messages", "Subjects", "Authors", "Emails", "SHA-1"]
    property var    branchNames     : []
    property string branchFilter    : ""
    property bool   panelOpen        : false

    readonly property bool  compact         : headerRow.parent ? headerRow.parent.width < 650 : false
    readonly property bool  tight           : headerRow.parent ? headerRow.parent.width < 820 : false
    readonly property bool  crowded         : headerRow.parent ? headerRow.parent.width < 600 : false
    readonly property int   controlSize     : 26
    property var            navigationRules : ["Author Email", "Author", "Parent 1", "Branch"]
    property string         navigationRule  : navigationRules[0]

    /* Signals
     * ****************************************************************************************/
    signal filterRequested(string text, string startDate, string endDate, var modes)
    signal branchSelected(string branchName)
    signal nextRequested(string rule)
    signal previousRequested(string rule)
    signal reloadRequested()
    signal panelToggleRequested()
    signal pullRequested()
    signal pushRequested(bool force)
    signal fetchRequested()

    /* Object Properties
     * ****************************************************************************************/
    spacing             : (parent && parent.width < Style.appHeight) ? 6 : 10
    anchors.leftMargin  : (parent && parent.width < Style.appHeight) ? 8 : 20
    anchors.rightMargin : (parent && parent.width < Style.appHeight) ? 4 : 5

    Item {
        id: textFilterArea
        Layout.fillWidth: true
        Layout.minimumWidth: compact ? 42 : (crowded ? 64 : (tight ? 96 : 100))
        Layout.maximumWidth: 240
        Layout.preferredHeight: headerRow.controlSize
        clip: true

        TextField {
            id: textFilterField
            width: textFilterArea.width
            height: textFilterArea.height
            placeholderTextColor: Style.colors.descriptionText
            backgroundColor: hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
            minHeight: headerRow.controlSize
            placeholderText: {
                var modes = headerRow.filterModes || []
                var display = modes.length > 0 ? modes.join(", ") : ""
                return display.length > 0 ? "Write Filter By " + display : "Write Filter By"
            }
            text: headerRow.filterText
            font.family: Style.fontTypes.inter
            font.weight: 400
            font.pixelSize: Style.appFont.captionPt
            borderRadius: 5
            borderWidth: 0
            focusBorderWidth: 1
            onTextChanged: {
                headerRow.filterText = text
                headerRow.applyFilter()
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    IconButton {
        id: filterButton
        Layout.preferredHeight: headerRow.controlSize

        text: "Filters"
        font.family: Style.fontTypes.inter
        font.weight: Font.Medium
        font.pixelSize: Style.appFont.smallPt
        leftPadding: 12
        rightPadding: 12
        topPadding: 4
        bottomPadding: 4
        spacing: 6

        contentItem: Row {
            spacing: filterButton.spacing

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Style.icons.filter
                font.family: Style.fontTypes.font6ProSolid
                font.pixelSize: Style.appFont.smallPt
                color: Style.colors.foreground
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: filterButton.text
                font: filterButton.font
                color: Style.colors.foreground
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Style.icons.caretDown
                font.family: Style.fontTypes.font6ProSolid
                font.pixelSize: Style.appFont.smallPt
                color: Style.colors.foreground
            }
        }

        onClicked: {
            filterPopup.filterField = headerRow.filterModes && headerRow.filterModes.length > 0 ? headerRow.filterModes[0] : ""
            filterPopup.startDate = headerRow.filterStartDate
            filterPopup.endDate = headerRow.filterEndDate
            filterPopup.branchFilter = headerRow.branchFilter
            filterPopup.open()
        }
    }

    GraphFilterPopup {
        id: filterPopup
        x: filterButton.x - filterPopup.width + filterButton.width
        y: filterButton.y + filterButton.height + 6
        filterFieldOptions: headerRow.filterFieldOptions
        branchNames: headerRow.branchNames
        navigationRules: headerRow.navigationRules
        navigationRule: headerRow.navigationRule

        onApplyRequested: function(field, startDate, endDate, branch) {
            headerRow.filterModes = field === "" ? [] : [field]
            headerRow.filterStartDate = startDate
            headerRow.filterEndDate = endDate
            headerRow.applyFilter()

            if (branch.length > 0)
                headerRow.navigationRule = "Branch"
            headerRow.branchSelected(branch)
        }

        onClearRequested: {
            headerRow.filterModes = []
            headerRow.filterStartDate = ""
            headerRow.filterEndDate = ""
            headerRow.applyFilter()
            headerRow.branchSelected("")
        }

        onStartDateFieldClicked: function(field) {
            calendarPopup.prepareAndOpen(field, true, filterPopup.startDate, filterPopup.endDate)
        }

        onEndDateFieldClicked: function(field) {
            calendarPopup.prepareAndOpen(field, false, filterPopup.endDate, filterPopup.startDate)
        }

        onNavigationRuleSelected: function(rule) {
            headerRow.navigationRule = rule
            headerRow.applyFilter()
        }
    }

    IconButton {
        id: downButton
        Layout.preferredHeight: headerRow.controlSize
        Layout.preferredWidth: upDownRowLayout.implicitWidth

        visible: !compact && !crowded
        enabled: headerRow.isGraphReady

        display: IconButton.IconOnly
        icon.name: Style.icons.caretDown
        icon.width: Style.appFont.largerPt
        icon.height: Style.appFont.largerPt
        solidIcon: true

        onClicked: headerRow.previousRequested(navigationRule)
    }

    IconButton {
        id: upButton
        Layout.preferredWidth: headerRow.controlSize
        Layout.preferredHeight: headerRow.controlSize

        visible: !compact && !crowded
        enabled: headerRow.isGraphReady

        display: IconButton.IconOnly
        icon.name: Style.icons.caretUp
        icon.width: Style.appFont.largerPt
        icon.height: Style.appFont.largerPt
        solidIcon: true

        onClicked: headerRow.nextRequested(navigationRule)
    }

    Item {
        Layout.fillWidth: true
    }

    IconButton {
        id: pullBtn
        Layout.preferredHeight: headerRow.controlSize

        solidIcon: true
        icon.name: Style.icons.arrowDown
        icon.width: Style.appFont.h3Pt
        icon.height: Style.appFont.h3Pt
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.defaultPt
        font.weight: Font.Medium
        text: "Pull"
        tooltip: "Pull from origin"
        display: headerRow.compact ? IconButton.IconOnly : IconButton.TextBesideIcon

        onClicked: headerRow.pullRequested()
    }

    IconButton {
        id: pushBtnHeader
        Layout.preferredHeight: headerRow.controlSize
        Layout.minimumWidth: 30
        Material.accent: Style.colors.accent

        property bool isBusy: headerRow.remoteController?.pushInProgress && !headerRow.remoteController?.forcePush

        background: Rectangle {
            radius: 5
            color: pushBtnHeader.down ? Style.colors.surfaceMuted :
                   pushBtnHeader.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
        }

        BusyIndicator {
            id: pushBusyIndicator
            anchors.centerIn: parent
            width: 30
            height: 30
            running: pushBtnHeader.isBusy
            visible: pushBtnHeader.isBusy
        }

        enabled: !headerRow.remoteController?.pushInProgress
        solidIcon: true
        icon.name: !isBusy ? Style.icons.arrowUp : ""
        icon.width: Style.appFont.h3Pt
        icon.height: Style.appFont.h3Pt
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.defaultPt
        font.weight: Font.Medium
        text: !isBusy ? "Push" : ""
        tooltip: !isBusy ? "Push to origin" : "Pushing..."
        display: headerRow.compact ? IconButton.IconOnly : IconButton.TextBesideIcon

        onClicked: headerRow.pushRequested(false)
    }

    IconButton {
        id: fetchBtnHeader
        Layout.preferredHeight: headerRow.controlSize

        enabled: !headerRow.isFetching

        solidIcon: true
        icon.name: Style.icons.download
        icon.width: Style.appFont.h3Pt
        icon.height: Style.appFont.h3Pt
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.defaultPt
        font.weight: Font.Medium
        text: "Fetch"
        tooltip: headerRow.isFetching ? "Fetching…" : "Fetch all remotes"
        display: headerRow.compact ? IconButton.IconOnly : IconButton.TextBesideIcon

        onClicked: headerRow.fetchRequested()
    }

    IconButton {
        id: reloadButton
        Layout.preferredWidth: headerRow.controlSize
        Layout.preferredHeight: headerRow.controlSize
        Layout.leftMargin: compact ? 3 : (tight ? 5 : 7)

        enabled: headerRow.isGraphReady

        display: IconButton.IconOnly
        icon.name: Style.icons.refresh
        icon.width: Style.appFont.largePt
        icon.height: Style.appFont.largePt
        solidIcon: false

        onClicked: headerRow.reloadRequested()
    }

    IconButton {
        id: panelToggleButton
        Layout.preferredWidth: headerRow.controlSize
        Layout.preferredHeight: headerRow.controlSize
        Layout.leftMargin: compact ? 3 : (tight ? 5 : 7)

        display: IconButton.IconOnly
        icon.source: Style.icons.togglePanel
        icon.width: 14
        icon.height: 14
        icon.color: headerRow.panelOpen ? Style.colors.accent : Style.colors.foreground

        background: Rectangle {
            radius: 5
            color: panelToggleButton.down ? Style.colors.surfaceMuted :
                   panelToggleButton.hovered ? Style.colors.cardBackground :
                   headerRow.panelOpen ? Style.colors.subtleAzureGlow : "transparent"
        }

        onClicked: headerRow.panelToggleRequested()
    }

    CalendarPopup {
        id: calendarPopup

        onDateSelected: function(dateString, isStart) {
            if (isStart)
                filterPopup.startDate = dateString
            else
                filterPopup.endDate = dateString
        }

        onClearRequested: function(isStart) {
            if (isStart)
                filterPopup.startDate = ""
            else
                filterPopup.endDate = ""
        }
    }

    /* Guide
     * ****************************************************************************************/
    GuideHoverTrigger {
        guideController: headerRow.guideController
        guideId: "graph_header_tutorial"
        guideName: "Graph Search & Filters"
        guideIcon: Style.icons.filter
        guidePage: "graph"
        stepsFactory: function() {
            return [
                {
                    targetProvider: function() { return textFilterField },
                    icon: Style.icons.filter,
                    title: "Search Commits",
                    description: "Type to filter commits in real time. Results update as you type across the whole graph."
                },
                {
                    targetProvider: function() { return filterButton },
                    icon: Style.icons.filter,
                    title: "Filters",
                    description: "Narrow the search field, date range, and branch, and choose the field used to navigate between matches: Author Email, Author, Parent commit, or Branch."
                },
                {
                    targetProvider: function() { return downButton.visible ? downButton : null },
                    icon: Style.icons.arrowDown,
                    title: "Previous Result",
                    description: "Jump to the previous commit that matches your current search or navigation rule."
                },
                {
                    targetProvider: function() { return upButton.visible ? upButton : null },
                    icon: Style.icons.arrowUp,
                    title: "Next Result",
                    description: "Jump to the next commit that matches your current search or navigation rule."
                },
                {
                    targetProvider: function() { return pullBtn },
                    icon: Style.icons.arrowDown,
                    title: "Pull",
                    description: "Downloads commits from the remote and merges them into your current branch. Run this before starting work to stay in sync with your team.",
                    commands: [{ command: "git pull" }]
                },
                {
                    targetProvider: function() { return pushBtnHeader },
                    icon: Style.icons.arrowUp,
                    title: "Push",
                    description: "Uploads your local commits to the remote so teammates can fetch or pull them. Only commits that are already saved locally will be sent.",
                    commands: [{ command: "git push" }]
                },
                {
                    targetProvider: function() { return fetchBtnHeader },
                    icon: Style.icons.download,
                    title: "Fetch",
                    description: "Downloads all remote changes and updates your remote-tracking branches without touching your working tree or current branch. Always safe to run.",
                    commands: [{ command: "git fetch --all" }]
                },
                {
                    targetProvider: function() { return reloadButton },
                    icon: Style.icons.refresh,
                    title: "Reload Graph",
                    description: "Reload the entire commit graph from the repository. Use this after external changes."
                }
            ]
        }
    }

    /* Functions
     * ****************************************************************************************/
    function applyFilter() {
        headerRow.filterRequested(headerRow.filterText,
                                  headerRow.filterStartDate,
                                  headerRow.filterEndDate,
                                  headerRow.filterModes);
    }
}
