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

    property int                  contentMargins:  24


    /* Object Properties
     * ****************************************************************************************/
    width: 523
    height: 475
    color: Style.colors.primaryBackground
    radius: 16
    clip: true
    border.color: Style.colors.accent
    border.width: 1

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
                    onSelectedPathChanged : {
                        if(repositorySelector.currentTabIndex === Enums.RepositorySelectorTab.Recents){
                            if(submit() && root.controller) {
                                root.controller.completeWelcomeFlow()
                            }
                        }
                    }
                }
            }
        }

        // Shared Continue/Finish button for all steps
        Button {
            id: continueButton
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            Layout.preferredWidth: 320
            Layout.preferredHeight: 43
            flat: false
            Material.background: Style.colors.accent
            Material.foreground: "white"
            text: {
                if (!root.controller) {
                    return "Continue" + " " + Style.icons.arrowRight
                }
                switch(root.controller.currentPageIndex) {
                    case Enums.WelcomePages.WelcomeBanner: return "Get Started" + " " + Style.icons.arrowRight
                    case Enums.WelcomePages.SetupProfle:
                    case Enums.WelcomePages.OpenRepository:
                    default: return "Continue" + " " + Style.icons.arrowRight
                }
            }
            font.family: Style.fontTypes.roboto
            font.weight: 400
            font.pixelSize: 15
            font.letterSpacing: 0

            background: Rectangle {
                radius: 3
                color: continueButton.hovered ? Style.colors.accentHover : Style.colors.accent
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            onClicked: {
                if (!root.controller) {
                    return
                }

                switch(root.controller.currentPageIndex) {
                    case Enums.WelcomePages.WelcomeBanner:
                        root.controller.nextPage()
                        break

                    case Enums.WelcomePages.SetupProfle:
                        //TODO : set user info
                        root.controller.nextPage()
                        break

                    case Enums.WelcomePages.OpenRepository:
                        if(submit()) {
                            root.controller.completeWelcomeFlow()
                        }
                        break

                    default:
                        break
                }
            }
        }
    }

    function submit() {
        switch(repositorySelector.currentTabIndex) {
            case Enums.RepositorySelectorTab.Recents:
            case Enums.RepositorySelectorTab.Open:
                return root.repositoryController.openRepository(repositorySelector.selectedPath)

            case Enums.RepositorySelectorTab.Clone:
                return root.repositoryController.cloneRepository(repositorySelector.selectedPath, repositorySelector.selectedUrl)

            default:
                return false;
        }
    }
}
