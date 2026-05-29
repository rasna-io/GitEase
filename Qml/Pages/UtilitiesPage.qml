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

    property RepoForestPopup            repoForestPopup             : null
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

    
    property NotificationController     notificationController      : null

    property ActivityController         activityController          : null

    property RebaseController           rebaseController            : null
    property ConflictController         conflictController          : null

    property var                        pluginController            : null

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    readonly property int hSpacing: 8
    readonly property int vSpacing: 8

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true

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

            ImportExportBundleDock {
                width: 330
                height: 390
                branchController: root.branchController
                bundleController: root.bundleController
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
            }


            BranchManagementView {
                width: 330
                height: 390
                branchController: root.branchController
                addBranchPopup: uiSessionPopups.addBranchPopup
                notificationController: root.notificationController
            }


            StashManagerDock {
                width: 330
                height: 390
                stashController: root.stashController
                commitController: root.commitController
                statusController: root.statusController
                addStashPopup: uiSessionPopups.addStashPopup
                manageStashPopup: uiSessionPopups.manageStashPopup

                notificationController: root.notificationController
            }

            TagManagementView {
                width: 330
                height: 390
                tagController: root.tagController
                addTagPopup: uiSessionPopups.addTagPopup
                notificationController: root.notificationController
            }

            RecentActivityDock {
                width: 330
                height: 390
                activityController: root.activityController
            }

            RepositoriesHistoryDock {
                width: 330
                height: 390
                repositoryController: root.repositoryController
            }

            RepoForestDock {
                width: 330
                height: 390
                repositoryController: root.repositoryController
                branchController: root.branchController
                remoteController: root.remoteController
                repoForestPopup: root.repoForestPopup
            }
            
            RebaseDock {
                width: 330
                height: 390
                branchController        : root.branchController
                rebaseController        : root.rebaseController
                notificationController  : root.notificationController

                conflictPopup: ConflictPopup {
                    currentOperation: ConflictPopup.OperationType.Rebase

                    rebaseController        : root.rebaseController
                    conflictController      : root.conflictController
                    notificationController  : root.notificationController
                    statusController        : root.statusController
                }
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
                            item.pluginManager = root.pluginController?.pluginManager
                        if (item.hasOwnProperty("pluginId"))
                            item.pluginId = modelData.id
                    }

                    onStatusChanged: {
                        if (status === Loader.Error)
                            console.error("[PluginDock] Failed to load:", source)
                    }
                }
            }
        }
    }
}
