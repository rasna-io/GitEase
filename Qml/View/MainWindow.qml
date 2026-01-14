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
            Layout.fillHeight: true
            Layout.fillWidth: true

            content: (pageLoader.item && pageLoader.item.hasOwnProperty("headerContent")) ? pageLoader.item.headerContent : null
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            NavigationRail {
                id: navigationRail
                Layout.fillHeight: true
                Layout.bottomMargin: 4

                appModel: root.uiSession?.appModel
                pageController: root.uiSession?.pageController
                repositoryController: root.uiSession?.repositoryController
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
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 4
                Layout.rightMargin: 4
                Layout.leftMargin: -2
                Layout.bottomMargin: 4

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
