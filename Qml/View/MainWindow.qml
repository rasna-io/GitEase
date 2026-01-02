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
