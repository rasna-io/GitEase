import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*!
 * UtilitiesPage
 * Responsive utilities page with auto-wrapping layout
 */

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var page: null

    property BranchController           branchController            : null
    property BundleController           bundleController            : null
    property RemoteController           remoteController            : null
    property CommitController           commitController            : null
    property StatusController           statusController            : null
    property RepositoryController       repositoryController        : null
    property UserAuthenticationPopup    userAuthenticationPopup     : null
    property UiSessionPopups            uiSessionPopups             : null
    property StashController            stashController             : null
    property TagController              tagController               : null
    property TerminalController         terminalController          : null

    
    property NotificationController     notificationController      : null

    property ActivityController         activityController          : null

    property RebaseController           rebaseController            : null
    property ConflictController         conflictController          : null

    property var                        pluginController            : null

    property LayoutController           layoutController            : null
    
    property GuideController            guideController             : null

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    readonly property int hSpacing: 8
    readonly property int vSpacing: 8

    Connections {
        target: root.terminalController

        function onGitStateChanged() {
            root.reload()
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true

        interactive: !flow.dockHovered
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        contentWidth: flow.width
        contentHeight: flow.implicitHeight

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        Flow {
            id: flow
            width: flick.width
            spacing: hSpacing

            property bool dockHovered: false

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
                        flow.dockHovered = true
                        return
                    }
                }

                flow.dockHovered = false
            }

            function setupPluginDock(item) {
                if (!item)
                    return

                if (item.hasOwnProperty("pageScrollBlocking")
                        && item.pageScrollBlocking === true
                        && item.hasOwnProperty("onHoveredChanged"))
                    {
                    item.onHoveredChanged = flow.updateDockHovered
                }

                updateDockHovered()
            }

            ImportExportBundleDock {
                width: 330
                height: 390
                branchController: root.branchController
                bundleController: root.bundleController
                notificationController: root.notificationController
                guideController: root.guideController
            }

            RemoteView {
                width: 330
                height: 390
                remoteController: root.remoteController
                repositoryController: root.repositoryController
                userAuthenticationPopup: root.userAuthenticationPopup
                uiSessionPopups: root.uiSessionPopups
                addEditRemotePopup: uiSessionPopups.addEditRemotePopup
                notificationController: root.notificationController

                onHoveredChanged: flow.updateDockHovered()
                guideController: root.guideController
            }


            BranchManagementView {
                id: branchManagementView
                width: 330
                height: 390
                branchController: root.branchController
                addBranchPopup: uiSessionPopups.addBranchPopup
                notificationController: root.notificationController

                onHoveredChanged: flow.updateDockHovered()
                guideController: root.guideController
            }


            StashManagerDock {
                id: stashManagerDock
                width: 330
                height: 390
                stashController: root.stashController
                commitController: root.commitController
                statusController: root.statusController
                addStashPopup: uiSessionPopups.addStashPopup
                manageStashPopup: uiSessionPopups.manageStashPopup

                notificationController: root.notificationController

                onHoveredChanged: flow.updateDockHovered()
                guideController: root.guideController
            }

            TagManagementView {
                id: tagManagementView
                width: 330
                height: 390
                tagController: root.tagController
                addTagPopup: uiSessionPopups.addTagPopup
                notificationController: root.notificationController

                onHoveredChanged: flow.updateDockHovered()
                guideController: root.guideController
            }

            RecentActivityDock {
                width: 330
                height: 390
                activityController: root.activityController

                onHoveredChanged: flow.updateDockHovered()
                guideController: root.guideController
            }

            RepositoriesHistoryDock {
                width: 330
                height: 390
                repositoryController: root.repositoryController

                onHoveredChanged: flow.updateDockHovered()
                guideController: root.guideController
            }

            RebaseDock {
                id: rebaseDock
                width: 330
                height: 390
                branchController        : root.branchController
                rebaseController        : root.rebaseController
                commitController        : root.commitController
                statusController        : root.statusController
                notificationController  : root.notificationController
                conflictController      : root.conflictController
                layoutController        : root.layoutController
                guideController         : root.guideController
            }

            // ── Plugin docks ─────────────────────────────────────────────────
            Repeater {
                model: root.pluginController?.pluginManager?.registeredDocks ?? []

                delegate: Loader {
                    width:  330
                    height: 390

                    source: modelData.url

                    onLoaded: {
                        if (!item) return
                        if (item.hasOwnProperty("pluginManager"))
                            item.pluginManager = Qt.binding(function() { return root.pluginController?.pluginManager })
                        if (item.hasOwnProperty("pluginId"))
                            item.pluginId = modelData.id
                        flow.setupPluginDock(item)
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
                    }

                    onStatusChanged: {
                        if (status === Loader.Error)
                            console.error("[PluginDock] Failed to load:", source)
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function reload() {
        branchManagementView.update()
        stashManagerDock.updateStashes()
        tagManagementView.update()
        rebaseDock.refreshBranches()
    }
}
