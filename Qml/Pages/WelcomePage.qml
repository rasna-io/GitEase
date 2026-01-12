import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * WelcomePage
 * Main welcome page with shared header and different content steps
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property WelcomeController    controller

    property RepositoryController repositoryController

    property AppModel             appModel

    property int                  contentMargins:  24


    /* Object Properties
     * ****************************************************************************************/
    width: 523
    height: 475
    color: Style.colors.primaryBackground
    radius: 16
    clip: true

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: contentMargins
        spacing: 0

        // Shared PageHeader for all steps
        PageHeader {
            id: pageHeader
            pageTitle: {
                switch(root.controller ? root.controller.currentPageIndex : Enums.WelcomePages.WelcomeBanner) {
                    case Enums.WelcomePages.WelcomeBanner: return ""
                    case Enums.WelcomePages.SetupProfle: return "Set Up Your Profile"
                    case Enums.WelcomePages.OpenRepository: return "Open a Repository"
                    default: return ""
                }
            }
            showBackButton: root.controller ? root.controller.canGoBack : false
            onBackClicked: {
                if (root.controller) {
                    root.controller.previousPage()
                }
            }
        }

        // Content area - changes based on current step
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            StackLayout {
                anchors.fill: parent
                currentIndex: root.controller ? root.controller.currentPageIndex : Enums.WelcomePages.WelcomeBanner

                // Step 1: Welcome
                WelcomeContent {
                    controller: root.controller
                }

                SetupProfileForm {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    showHint: true
                }

                RepositorySelector {
                    id: repositorySelector
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    showDescription: true
                    descriptionText: "Choose how you want to get started with your Git repository"
                    recentRepositories: appModel.recentRepositories
                    onCloneFinished:  root.controller.completeWelcomeFlow()
                    repositoryController: root.repositoryController
                    defaultPath: appModel.appSettings.generalSettings.defaultPath
                }
            }
        }


        Item {
            id: continueButtonContainer

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            Layout.preferredWidth: 320
            Layout.preferredHeight: 43

            ProgressButton {
                anchors.fill: parent
                progress: repositorySelector.progress
                busy: repositorySelector.busy

                idleText:  {
                    if (repositorySelector.busy) {
                        return (repositorySelector.progress) + " %"
                    }
                    if (!root.controller) {
                        return "Continue " + Style.icons.arrowRight
                    }
                    switch(root.controller.currentPageIndex) {
                        case Enums.WelcomePages.WelcomeBanner: return "Get Started " + Style.icons.arrowRight
                        default: return "Continue " + Style.icons.arrowRight
                    }
                }

                enabled: {
                    if (repositorySelector.busy)
                        return false;

                    if (root.controller.currentPageIndex !== Enums.WelcomePages.OpenRepository)
                        return true;

                    switch(repositorySelector.currentTabIndex) {
                        case Enums.RepositorySelectorTab.Recents:
                        case Enums.RepositorySelectorTab.Open:
                            return repositorySelector.selectedPath !== ""

                        case Enums.RepositorySelectorTab.Clone:
                            return repositorySelector.selectedPath !== ""

                        default:
                            return false;
                    }
                }


                onClicked: {
                    if (!root.controller) return

                    switch(root.controller.currentPageIndex) {
                        case Enums.WelcomePages.WelcomeBanner:
                            root.controller.nextPage()
                            break
                        case Enums.WelcomePages.SetupProfle:
                            root.controller.nextPage()
                            break
                        case Enums.WelcomePages.OpenRepository:
                            if(repositorySelector.submit())
                                root.controller.completeWelcomeFlow()
                            break
                        default:
                            break
                    }
                }
            }
        }
    }
}
