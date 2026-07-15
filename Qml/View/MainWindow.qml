import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * MainWindow
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property UiSession uiSession: null

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.primaryBackground

    /* Functions
     * ****************************************************************************************/
    function switchToPageById(pageId) {
        let pages = pageSwipeView.contentChildren
        let targetIndex = -1
        for (let i = 0; i < pages.length; i++) {
            if (pages[i].pageId === pageId) {
                targetIndex = i
                break
            }
        }
        if (targetIndex < 0)
            return

        let current = pageSwipeView.currentItem
        if (current?.onPageChange) {
            current.onPageChange(accepted => { if (accepted) pageSwipeView.setCurrentIndex(targetIndex) })
        } else {
            pageSwipeView.setCurrentIndex(targetIndex)
        }
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        //Header
        Header {
            Layout.minimumHeight: Style.dp(44)
            Layout.maximumHeight: Style.dp(44)
            Layout.fillWidth: true

            windowController: root.uiSession.windowController
            content: (pageLoader.item && pageLoader.item.hasOwnProperty("headerContent")) ? pageLoader.item.headerContent : null
            pluginManager: root.uiSession?.pluginController?.pluginManager ?? null
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            NavigationRail {
                id: navigationRail
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }

                z: 1

                appModel: root.uiSession?.appModel
                repositoryController: root.uiSession?.repositoryController
                userProfileController: root.uiSession?.userProfileController
                notificationController: root.uiSession?.notificationController
                guideController: root.uiSession?.guideController
                userInfoSelectionPopup: root.uiSession?.popups?.userInfoSelectionPopup

                pages: pageSwipeView.contentChildren
                currentPageId: pageSwipeView.currentItem?.pageId ?? ""

                onPageSelected: function (pageId) {
                    root.switchToPageById(pageId)
                }

                onNewRepositoryRequested: function () {
                    let popup = root.uiSession?.popups?.repositorySelectorPopup
                    popup.repositoryController = Qt.binding(function () {return uiSession.repositoryController})
                    popup.recentRepositories = Qt.binding(function () {return uiSession.appModel.recentRepositories})
                    popup.appModel = Qt.binding(function () {return uiSession.appModel})
                    popup.open()
                }

                onOpenSettingsRequested: {
                    let settingsPopup = root.uiSession?.popups?.settingsPopup
                    settingsPopup.appModel = root.uiSession.appModel
                    settingsPopup.updateController = root.uiSession.updateController
                    settingsPopup.fileIO = root.uiSession.appModel.fileIO
                    settingsPopup.guideController = root.uiSession.guideController
                    settingsPopup.switchToPageById = root.switchToPageById
                    settingsPopup.open()
                }
                
                onOpenNotificationsRequested: {
                    let notificationPopup = root.uiSession?.popups?.notificationCenterPopup
                    if (notificationPopup) {
                        notificationPopup.notificationController = root.uiSession.notificationController
                        notificationPopup.open()
                    }
                }
            }

            SplitView {
                anchors {
                    left: navigationRail.right
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    margins: 4
                }
                width: parent.width - navigationRail.collapsedWidth - (anchors.leftMargin + anchors.rightMargin)
                orientation: Qt.Vertical

                handle: SplitViewHandle {
                    orientation: Qt.Vertical
                }

                Rectangle {
                    id: diffViewRect
                    SplitView.fillWidth: true
                    SplitView.minimumHeight: 500
                    SplitView.fillHeight: true
                    color: Style.colors.primaryBackground
                    radius: 6

                    SwipeView {
                        id: pageSwipeView
                        anchors.fill: parent

                        // Page switching is driven by the NavigationRail only.
                        interactive: false

                        // Switch pages instantly instead of sliding/dragging between them.
                        contentItem: ListView {
                            model: pageSwipeView.contentModel
                            interactive: false
                            currentIndex: pageSwipeView.currentIndex
                            orientation: ListView.Horizontal
                            snapMode: ListView.SnapOneItem
                            boundsBehavior: Flickable.StopAtBounds
                            highlightRangeMode: ListView.StrictlyEnforceRange
                            preferredHighlightBegin: 0
                            preferredHighlightEnd: 0
                            highlightMoveDuration: 0
                            highlightResizeDuration: 0
                        }

                        GraphViewPage {
                            appModel: root.uiSession?.appModel
                            branchController: root.uiSession?.branchController
                            remoteController: root.uiSession?.remoteController
                            userAuthenticationPopup: root.uiSession?.popups?.userAuthenticationPopup
                            commitController: root.uiSession?.commitController
                            statusController: root.uiSession?.statusController
                            repositoryController: root.uiSession?.repositoryController
                            notificationController: root.uiSession?.notificationController
                            uiSessionPopups: root.uiSession?.popups
                            stashController: root.uiSession?.stashController
                            conflictController: root.uiSession?.conflictController
                            mergeController: root.uiSession?.mergeController
                            rebaseController: root.uiSession?.rebaseController
                            cherryPickController: root.uiSession?.cherryPickController
                            tagController: root.uiSession?.tagController
                            resetController: root.uiSession?.resetController
                            terminalController: root.uiSession?.terminalController
                            bundleController: root.uiSession?.bundleController
                            activityController: root.uiSession?.activityController
                            pluginController: root.uiSession?.pluginController
                            guideController: root.uiSession?.guideController
                        }

                        CommittingPage {
                            appModel: root.uiSession?.appModel
                            repositoryController: root.uiSession?.repositoryController
                            statusController: root.uiSession?.statusController
                            branchController: root.uiSession?.branchController
                            commitController: root.uiSession?.commitController
                            remoteController: root.uiSession?.remoteController
                            userProfileController: root.uiSession?.userProfileController
                            stashController: root.uiSession?.stashController
                            notificationController: root.uiSession?.notificationController
                            userAuthenticationPopup: root.uiSession?.popups?.userAuthenticationPopup
                            uiSessionPopups: root.uiSession?.popups
                            pluginController: root.uiSession?.pluginController
                            terminalController: root.uiSession?.terminalController
                            guideController: root.uiSession?.guideController
                        }

                        PluginsPage {
                            appModel: root.uiSession?.appModel
                            pluginController: root.uiSession?.pluginController
                        }

                        //! TODO
                        //! add loader for page plugins

                        Component.onCompleted: {
                            let requestedPageId = root.uiSession?.shellController?.arguments?.["page"]
                            if (requestedPageId)
                                root.switchToPageById(requestedPageId)
                        }
                    }
                }

                Terminal {
                    id: terminalRect
                    minimizable: true
                    layoutController: root.uiSession?.layoutController
                    layoutId: "mainWindow.terminal"
                    SplitView.fillWidth: true
                    SplitView.minimumHeight: 150
                    SplitView.preferredHeight: 250
                    currentRepositoryName: root.uiSession?.appModel?.currentRepository?.name || ""
                    terminalController: root.uiSession?.terminalController
                }
            }
        }

        MinimizedPanels {
            layoutController: root.uiSession?.layoutController
        }
    }

    // Guide overlay — sits above all content; spotlight + tooltip rendered here
    GuideOverlay {
        anchors.fill: parent
        z: 100
        guideController: root.uiSession?.guideController
    }
}
