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


    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        //Header
        Header {
            Layout.minimumHeight: 50
            Layout.maximumHeight: 50
            Layout.fillWidth: true

            windowController: root.uiSession.windowController
            content: (pageLoader.item && pageLoader.item.hasOwnProperty("headerContent")) ? pageLoader.item.headerContent : null
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
                    margins: 1
                }

                z: 1

                appModel: root.uiSession?.appModel
                pageController: root.uiSession?.pageController
                repositoryController: root.uiSession?.repositoryController
                userProfileController: root.uiSession?.userProfileController
                notificationController: root.uiSession?.notificationController
                
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
                    settingsPopup.fileIO = root.uiSession.appModel.fileIO
                    settingsPopup.open()
                }

                onOpenUserSelectionRequested: {
                    let userInfoSelectionPopup = root.uiSession?.popups?.userInfoSelectionPopup
                    userInfoSelectionPopup.userProfileController = root.uiSession.userProfileController
                    userInfoSelectionPopup.open()
                }
                
                onOpenNotificationsRequested: {
                    let notificationPopup = root.uiSession?.popups?.notificationCenterPopup
                    if (notificationPopup) {
                        notificationPopup.notificationController = root.uiSession.notificationController
                        notificationPopup.open()
                    }
                }
            }

            Rectangle {
                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    margins: 4
                }

                width: parent.width - navigationRail.collapsedWidth - (anchors.leftMargin + anchors.rightMargin)

                color: Style.colors.primaryBackground
                radius: 6

                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    anchors.margins: 0

                    source: root.uiSession?.appModel?.currentPage?.source ?? ""

                    onLoaded: {
                        // Bind common context properties if the loaded page exposes them.
                        if (!item)
                            return

                        // If the loaded page exposes a `page` property, bind it to the current page model.
                        if (item && item.hasOwnProperty("page")) {
                            item.page = Qt.binding(function() { return root.uiSession?.appModel?.currentPage })
                        }

                        // Repository controller (for pages that need repository context)
                        if (item.hasOwnProperty("appModel")) {
                            item.appModel = Qt.binding(function() { return root.uiSession?.appModel })
                        }
                        if (item.hasOwnProperty("branchController")) {
                            item.branchController = Qt.binding(function() { return root.uiSession?.branchController })
                        }
                        if (item.hasOwnProperty("commitController")) {
                            item.commitController = Qt.binding(function() { return root.uiSession?.commitController })
                        }
                        if (item.hasOwnProperty("statusController")) {
                            item.statusController = Qt.binding(function() { return root.uiSession?.statusController })
                        }
                        if (item.hasOwnProperty("repositoryController")) {
                            item.repositoryController = Qt.binding(function() { return root.uiSession?.repositoryController })
                        }
                        if (item.hasOwnProperty("remoteController")) {
                            item.remoteController = Qt.binding(function() { return root.uiSession?.remoteController })
                        }
                        if (item.hasOwnProperty("userProfileController")) {
                            item.userProfileController = Qt.binding(function() { return root.uiSession?.userProfileController })
                        }
                        if (item.hasOwnProperty("bundleController")) {
                            item.bundleController = Qt.binding(function() { return root.uiSession?.bundleController })
                        }
                        if (item.hasOwnProperty("stashController")) {
                            item.stashController = Qt.binding(function() { return root.uiSession?.stashController })
                        }
                        if (item.hasOwnProperty("tagController")) {
                            item.tagController = Qt.binding(function() { return root.uiSession?.tagController })
                        }
                        if (item.hasOwnProperty("notificationController")) {
                            item.notificationController = Qt.binding(function() { return root.uiSession?.notificationController })
                        }
                        if (item.hasOwnProperty("userAuthenticationPopup")) {
                            item.userAuthenticationPopup = Qt.binding(function() { return root.uiSession?.popups?.userAuthenticationPopup })
                        }
                        if (item.hasOwnProperty("uiSessionPopups")) {
                            item.uiSessionPopups = Qt.binding(function() { return root.uiSession?.popups })
                        }
                        if (item.hasOwnProperty("activityController")) {
                            item.activityController = Qt.binding(function() { return root.uiSession?.activityController })
                        }
                        if (item.hasOwnProperty("mergeController")) {
                            item.mergeController = Qt.binding(function() { return root.uiSession?.mergeController })
						}
                        if (item.hasOwnProperty("repoForestPopup")) {
                            item.repoForestPopup = Qt.binding(function() { return root.uiSession?.popups?.repoForestPopup })
                        }
                        if (item.hasOwnProperty("conflictController")) {
                            item.conflictController = Qt.binding(function() { return root.uiSession?.conflictController })
                        }
                        if (item.hasOwnProperty("rebaseController")) {
                            item.rebaseController = Qt.binding(function() { return root.uiSession?.rebaseController })
                        }
                        if (item.hasOwnProperty("cherryPickController")) {
                            item.cherryPickController = Qt.binding(function() { return root.uiSession?.cherryPickController })
                        }
                        if (item.hasOwnProperty("conflictController")) {
                            item.conflictController = Qt.binding(function() { return root.uiSession?.conflictController })
                        }
                        if (item.hasOwnProperty("windowController")) {
                            item.windowController = Qt.binding(function() {return root.uiSession?.windowController})
                        }
                    }

                    onStatusChanged: {
                        if (status === Loader.Error)
                            console.error("[MainWindow] Failed to load page:", source)
                    }
                }
            }
        }
    }
}
