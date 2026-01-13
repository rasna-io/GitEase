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
    color: "#F9F9F9"

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        //Header
        Header {
            Layout.fillHeight: true
            Layout.fillWidth: true
            content: Rectangle {
                // TODO : main header for each page
                // Text {
                //     anchors.centerIn: parent
                //     text: "# main header in docks"
                //     horizontalAlignment: Text.AlignHCenter
                //     verticalAlignment: Text.AlignVCenter
                // }
            }
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
                    popup.open()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 4
                Layout.rightMargin: 4
                Layout.leftMargin: -2
                Layout.bottomMargin: 4

                color: "#FFFFFF"
                border.color: "#F3F3F3"
                border.width: 1
                radius: 6

                SwipeView {
                    id: pageSwipeView
                    anchors.fill: parent
                    clip: true
                    interactive: false

                    Repeater {
                        model: root.uiSession?.appModel?.pages || []

                        Loader {
                            width: pageSwipeView.width
                            height: pageSwipeView.height

                            active: SwipeView.isCurrentItem || SwipeView.isNextItem || SwipeView.isPreviousItem
                            asynchronous: true

                            source: modelData?.source ?? ""

                            onLoaded: {
                                if (!item)
                                    return

                                // Bind common context properties if the loaded page exposes them.
                                if (item.hasOwnProperty("page")) {
                                    // Bind to the page model represented by this SwipeView index.
                                    item.page = Qt.binding(function() { return modelData })
                                }

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

                    onCurrentIndexChanged: {
                        if (!contentItem)
                            return

                        contentItem.contentX = currentIndex * width
                    }

                    Connections {
                        target: root.uiSession?.appModel ?? null

                        function onCurrentPageChanged() {
                            pageSwipeView.currentIndex = root.uiSession?.appModel?.currentPage.pageIndex ?? 0
                        }
                    }
                }
            }
        }
    }
}
