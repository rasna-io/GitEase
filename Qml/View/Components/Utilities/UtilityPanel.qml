import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * UtilityPanel
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property          bool open: true
    readonly property real borderWidth: 1
    readonly property real contentWidth: Style.dp(279)
    readonly property real expandedWidth: contentWidth + borderWidth

    property BranchController        branchController        : null
    property RemoteController        remoteController        : null
    property RepositoryController    repositoryController    : null
    property CommitController        commitController        : null
    property StatusController        statusController        : null
    property StashController         stashController         : null
    property TagController           tagController           : null
    property RebaseController        rebaseController        : null
    property ConflictController      conflictController      : null
    property BundleController        bundleController        : null
    property ActivityController      activityController      : null
    property NotificationController  notificationController  : null
    property GuideController         guideController         : null
    property UserAuthenticationPopup userAuthenticationPopup : null
    property UiSessionPopups         uiSessionPopups         : null
    property var                     pluginController        : null
    property real                    animatedWidth           : root.open ? expandedWidth : 0

    /* Object Properties
     * ****************************************************************************************/
    visible: animatedWidth > 0
    clip: true
    Layout.fillHeight: true
    Layout.preferredWidth: animatedWidth

    color: Style.colors.utilitiesPanelBackground
    border.width: 0

    Behavior on animatedWidth {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    /* Children
     * ****************************************************************************************/
    GuideHoverTrigger {
        guideController: root.guideController
        guideId: "utility_panel_tutorial"
        guideName: "Utility Panel"
        guideIcon: Style.icons.panelRight
        guidePage: "utilities"
        stepsFactory: function() {
            return [
                {
                    targetProvider: function() { return filterField },
                    icon: Style.icons.search,
                    title: "Filter Docks",
                    description: "Type to filter the list of utility docks — only matching titles remain visible.",
                    isInPopup: false,
                    activationDelay: 300,
                },
                {
                    targetProvider: function() { return dockFlick },
                    icon: Style.icons.panelRight,
                    title: "Utility Docks",
                    description: "Each card is a specialized dock (Branches, Remotes, Stashes, Tags, etc.). Click the header to expand/collapse. The panel remembers which docks you leave open.",
                }
            ]
        }
    }

    Rectangle {
        id: leftBorder
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.borderWidth
        color: Style.colors.utilitiesPanelBorder
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.contentWidth
        spacing: 0

        TextField {
            id: filterField
            Layout.fillWidth: true
            Layout.margins: Style.dp(8)
            Layout.preferredHeight: Style.dp(28)
            placeholderText: qsTr("Filter...")
            backgroundColor: Style.colors.utilitiesFilterBackground
            borderWidth: 1
            borderColor: Style.colors.utilitiesFilterBorder
            focusBorderWidth: 1
            focusBorderColor: Style.colors.utilitiesFilterBorderFocus
            color: Style.colors.utilitiesFilterText
            placeholderTextColor: Style.colors.utilitiesFilterPlaceholder
            font.family: Style.fontTypes.inter
            font.weight: 400
            font.pixelSize: Style.appFont.smallPt

            onTextChanged: dockFlow.filterText = text
        }

        Flickable {
            id: dockFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Style.dp(1)
            clip: true

            interactive: !dockFlow.dockHovered
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds

            contentWidth: dockFlow.width
            contentHeight: dockFlow.implicitHeight

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            Flow {
                id: dockFlow
                width: dockFlick.width

                property bool dockHovered: false
                property string filterText: ""

                function matchesFilter(sectionTitle) {
                    var needle = dockFlow.filterText.trim().toLowerCase()
                    if (needle.length === 0)
                        return true
                    return sectionTitle.toLowerCase().indexOf(needle) !== -1
                }

                function scrollBlockingHovered(item) {
                    return item
                        && item.visible !== false
                        && item.hasOwnProperty("pageScrollBlocking")
                        && item.pageScrollBlocking === true
                        && item.hasOwnProperty("hovered")
                        && item.hovered === true
                }

                function updateDockHovered() {
                    for (let i = 0; i < children.length; ++i) {
                        const child = children[i]
                        if (scrollBlockingHovered(child) || scrollBlockingHovered(child.item)) {
                            dockFlow.dockHovered = true
                            return
                        }
                    }

                    dockFlow.dockHovered = false
                }

                function setupPluginDock(item) {
                    if (!item)
                        return

                    if (item.hasOwnProperty("pageScrollBlocking")
                            && item.pageScrollBlocking === true
                            && item.hoveredChanged)
                    {
                        item.hoveredChanged.connect(dockFlow.updateDockHovered)
                    }

                    updateDockHovered()
                }

                ImportExportBundleDock {
                    visible: dockFlow.matchesFilter("Export / Import Project")
                    branchController: root.branchController
                    bundleController: root.bundleController
                    notificationController: root.notificationController
                    guideController: root.guideController
                }

                RemoteView {
                    visible: dockFlow.matchesFilter("Remotes")
                    remoteController: root.remoteController
                    repositoryController: root.repositoryController
                    userAuthenticationPopup: root.userAuthenticationPopup
                    uiSessionPopups: root.uiSessionPopups
                    addEditRemotePopup: root.uiSessionPopups ? root.uiSessionPopups.addEditRemotePopup : null
                    notificationController: root.notificationController
                    guideController: root.guideController

                    onHoveredChanged: dockFlow.updateDockHovered()
                }

                BranchManagementView {
                    id: branchManagementView
                    visible: dockFlow.matchesFilter("Branch Management")
                    branchController: root.branchController
                    addBranchPopup: root.uiSessionPopups ? root.uiSessionPopups.addBranchPopup : null
                    notificationController: root.notificationController
                    guideController: root.guideController

                    onHoveredChanged: dockFlow.updateDockHovered()
                }

                StashManagerDock {
                    id: stashManagerDock
                    visible: dockFlow.matchesFilter("Stash Manager")
                    stashController: root.stashController
                    commitController: root.commitController
                    statusController: root.statusController
                    addStashPopup: root.uiSessionPopups ? root.uiSessionPopups.addStashPopup : null
                    manageStashPopup: root.uiSessionPopups ? root.uiSessionPopups.manageStashPopup : null
                    guideController: root.guideController

                    notificationController: root.notificationController

                    onHoveredChanged: dockFlow.updateDockHovered()
                }

                TagManagementView {
                    id: tagManagementView
                    visible: dockFlow.matchesFilter("Tag Management")
                    tagController: root.tagController
                    addTagPopup: root.uiSessionPopups ? root.uiSessionPopups.addTagPopup : null
                    guideController: root.guideController
                    notificationController: root.notificationController

                    onHoveredChanged: dockFlow.updateDockHovered()
                }

                RecentActivityDock {
                    visible: dockFlow.matchesFilter("Recent Activity")
                    activityController: root.activityController
                    guideController: root.guideController

                    onHoveredChanged: dockFlow.updateDockHovered()
                }

                RepositoriesHistoryDock {
                    visible: dockFlow.matchesFilter("Repositories History")
                    repositoryController: root.repositoryController
                    guideController: root.guideController

                    onHoveredChanged: dockFlow.updateDockHovered()
                }

                RebaseDock {
                    id: rebaseDock
                    visible: dockFlow.matchesFilter("Rebase")
                    branchController        : root.branchController
                    rebaseController        : root.rebaseController
                    commitController        : root.commitController
                    statusController        : root.statusController
                    notificationController  : root.notificationController
                    conflictController      : root.conflictController
                    guideController         : root.guideController
                }

                // ── Plugin docks ─────────────────────────────────────────────────
                Repeater {
                    model: root.pluginController?.pluginManager?.registeredDocks ?? []

                    delegate: Loader {
                        width:  root.contentWidth
                        height: 390
                        visible: dockFlow.matchesFilter(modelData.title ?? "")

                        source: modelData.url

                        onLoaded: {
                            if (!item)
                                return

                            if (item.hasOwnProperty("pluginManager"))
                                item.pluginManager = Qt.binding(function() { return root.pluginController?.pluginManager })
                            if (item.hasOwnProperty("pluginId"))
                                item.pluginId = modelData.id
                            if (item.hasOwnProperty("repositoryController"))
                                item.repositoryController = Qt.binding(function() { return root.repositoryController })
                            if (item.hasOwnProperty("branchController"))
                                item.branchController = Qt.binding(function() { return root.branchController })
                            if (item.hasOwnProperty("remoteController"))
                                item.remoteController = Qt.binding(function() { return root.remoteController })
                            if (item.hasOwnProperty("userAuthenticationPopup"))
                                item.userAuthenticationPopup = Qt.binding(function() { return root.userAuthenticationPopup })
                            if (item.hasOwnProperty("uiSessionPopups"))
                                item.uiSessionPopups = Qt.binding(function() { return root.uiSessionPopups })
                            if (item.hasOwnProperty("notificationController"))
                                item.notificationController = Qt.binding(function() { return root.notificationController })
                            if (item.hasOwnProperty("guideController"))
                                item.guideController = Qt.binding(function() { return root.guideController })
                            if (item.hasOwnProperty("commitController"))
                                item.commitController = Qt.binding(function() { return root.commitController })
                            if (item.hasOwnProperty("statusController"))
                                item.statusController = Qt.binding(function() { return root.statusController })
                            if (item.hasOwnProperty("stashController"))
                                item.stashController = Qt.binding(function() { return root.stashController })
                            if (item.hasOwnProperty("tagController"))
                                item.tagController = Qt.binding(function() { return root.tagController })
                            if (item.hasOwnProperty("eventBus"))
                                item.eventBus = Qt.binding(function() { return root.pluginController?.pluginManager })

                            dockFlow.setupPluginDock(item)
                        }

                        onStatusChanged: {
                            if (status === Loader.Error)
                                console.error("[UtilityPanel] Failed to load plugin dock:", source)
                        }
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    //! Re-reads every dock that caches repository state.
    function reload() {
        branchManagementView.update()
        stashManagerDock.updateStashes()
        tagManagementView.update()
        rebaseDock.refreshBranches()
    }
}
