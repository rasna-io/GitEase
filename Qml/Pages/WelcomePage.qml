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

        Connections {
            target: GitService

            function onCloneFinished() {
                continueButtonContainer.busy = false
                continueButtonContainer.progress = 0
                root.controller.completeWelcomeFlow()
            }

            function onCloneProgress (progress){
                continueButtonContainer.progress = progress
            }
        }

        // Shared Continue/Finish button for all steps
        Item {
            id: continueButtonContainer

            property bool busy: false
            property real progress: 0

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            Layout.preferredWidth: 320
            Layout.preferredHeight: 43

            Button {
                id: continueButton
                anchors.fill: parent
                flat: false
                Material.background: Style.colors.accent
                Material.foreground: "white"
                text: {
                    if (continueButtonContainer.busy) {
                        return (continueButtonContainer.progress) + " %"
                    }
                    if (!root.controller) {
                        return "Continue " + Style.icons.arrowRight
                    }
                    switch(root.controller.currentPageIndex) {
                        case Enums.WelcomePages.WelcomeBanner: return "Get Started " + Style.icons.arrowRight
                        default: return "Continue " + Style.icons.arrowRight
                    }
                }
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 15
                font.letterSpacing: 0

                background: Rectangle {
                    radius: 3
                    color: continueButton.enabled ?
                              (continueButton.hovered ? Style.colors.accentHover : Style.colors.accent) :
                              Style.colors.disabledButton
                    Behavior on color { ColorAnimation { duration: 150 } }

                    // Gray background bar
                    Rectangle {
                        anchors.fill: parent
                        color: "#CCCCCC"
                        radius: 3
                        visible: continueButtonContainer.busy

                        // Blue progress bar
                        Rectangle {
                            width: continueButtonContainer.busy ? parent.width * continueButtonContainer.progress / 100 : 0
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            color: Style.colors.accent
                            radius: 3
                            Behavior on width { NumberAnimation { duration: 100 } }
                        }
                    }
                }

                enabled: {
                    if (continueButtonContainer.busy)
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
                            if(submit())
                                root.controller.completeWelcomeFlow()
                            break
                        default:
                            break
                    }
                }
            }
        }

    }

    function submit() {
        switch(repositorySelector.currentTabIndex) {
            case Enums.RepositorySelectorTab.Recents:
            case Enums.RepositorySelectorTab.Open:
                return root.repositoryController.openRepository(repositorySelector.selectedPath)

            case Enums.RepositorySelectorTab.Clone: {
                let res = root.repositoryController.cloneRepository(repositorySelector.selectedPath, repositorySelector.selectedUrl)
                continueButtonContainer.busy = res.success

                if (!res.success) {
                    repositorySelector.errorMessage = res.error
                }

                return false;
            }

            default:
                return false;
        }
    }
}
