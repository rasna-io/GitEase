import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * RepositorySelectorPopup
 * ************************************************************************************************/
IPopup {
    id: root
    

    /* Property Declarations
     * ****************************************************************************************/
    property bool                   busy: false

    property real                   progress: 0

    property RepositoryController   repositoryController

    property var                    recentRepositories



    /* Object Properties
     * ****************************************************************************************/

    onClosed: {
        repositorySelector.reset()
    }
    
    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 0

            PageHeader {
                pageTitle: "Open a Repository"
                showBackButton: true
                onBackClicked: {
                   root.close()
                }
            }

            RepositorySelector {
                id: repositorySelector
                Layout.fillWidth: true
                Layout.fillHeight: true
                showDescription: true
                descriptionText: "Choose how you want to get started with your Git repository"
                recentRepositories: root.recentRepositories
                repositoryController: root.repositoryController
                onCloneFinished: root.close()
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
                Layout.preferredWidth: 320
                Layout.preferredHeight: 43

                ProgressButton {
                    id: submitButton
                    anchors.fill: parent
                    flat: false
                    Material.background: Style.colors.accent
                    Material.foreground: "white"
                    progress: repositorySelector.progress
                    busy: repositorySelector.busy

                    idleText:  {
                        if (repositorySelector.busy) {
                            return (repositorySelector.progress) + " %"
                        } else {
                            return "Continue " + Style.icons.arrowRight
                        }
                    }



                    enabled: {
                        if (repositorySelector.busy)
                            return false

                        switch(repositorySelector.currentTabIndex) {
                        case Enums.RepositorySelectorTab.Recents:
                        case Enums.RepositorySelectorTab.Open:
                            return repositorySelector.selectedPath !== ""

                        case Enums.RepositorySelectorTab.Clone:
                            return repositorySelector.selectedPath !== "" && repositorySelector.selectedUrl !== ""

                        default:
                            return false
                        }
                    }


                    onClicked: {
                        if(repositorySelector.submit())
                            root.close()
                    }
                }
            }
        }
    }
}
