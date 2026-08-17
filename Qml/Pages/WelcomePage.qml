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
    property WindowController       windowController

    property WelcomeController      controller

    property RepositoryController   repositoryController

    property NotificationController notificationController

    property UserProfileController  userProfileController

    property AppModel               appModel

    property int                    contentMargins:  24


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
            windowController: root.windowController
            pageTitle: {
                switch(root.controller ? root.controller.currentPageIndex : Enums.WelcomePages.WelcomeBanner) {
                    case Enums.WelcomePages.WelcomeBanner: return ""
                    case Enums.WelcomePages.SetupProfle: return "Set Up Your Profile"
                    case Enums.WelcomePages.OpenRepository: return "Open a Repository"
                    default: return ""
                }
            }
            showBackButton: root.controller ? root.controller.canGoBack : false
            backButtonText: root.appModel?.appSettings?.hasCompletedWelcome ? Style.icons.close : Style.icons.angleLeft
            onBackClicked: {
                if(root.appModel?.appSettings?.hasCompletedWelcome)
                {
                    Qt.quit()
                }
                else if (root.controller) {
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
                    id: setupProfileForm
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
                    onCloneFinished: function (res) {
                        if (res.success) {
                            root.repositoryController.openRepository(res.path)
                            root.controller.completeWelcomeFlow()
                        }
                    }
                    fileIO: root.appModel.fileIO
                    repositoryController: root.repositoryController
                    notificationController: root.notificationController
                    defaultPath: appModel.appSettings.generalSettings.defaultPath
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.preferredHeight: 1
            color: Style.colors.primaryBorder
            opacity: 0.5
        }

        Item {
            id: continueButtonContainer

            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.preferredHeight: 40

            ProgressButton {
                id: continueButton
                anchors.right: parent.right
                width: 140
                height: 40
                progress: repositorySelector.progress
                busy: repositorySelector.busy

                idleText:  {
                    if (repositorySelector.busy) {
                        return (repositorySelector.progress) + " %"
                    }
                    if (!root.controller) {
                        return "Continue  " + Style.icons.arrowRight
                    }
                    switch(root.controller.currentPageIndex) {
                        case Enums.WelcomePages.WelcomeBanner: return "Get Started  " + Style.icons.arrowRight
                        default: return "Continue  " + Style.icons.arrowRight
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

                background: Rectangle {
                    radius: 8
                    color: continueButton.enabled
                           ? (continueButton.hovered ? Style.colors.accentHover : Style.colors.accent)
                           : Style.colors.disabledButton

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1
                        radius: parent.radius + 1
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(0, 0, 0, 0.06)
                        z: -1
                    }

                    // Progress overlay
                    Rectangle {
                        anchors.fill: parent
                        visible: continueButton.busy
                        radius: 8
                        color: "#CCCCCC"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * (continueButton.progress / 100.0)
                            radius: 8
                            color: Style.colors.accent

                            Behavior on width {
                                NumberAnimation {
                                    duration: 100
                                }
                            }
                        }
                    }
                }

                contentItem: Text {
                    text: continueButton.text
                    font: continueButton.font
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    if (!root.controller) return

                    switch(root.controller.currentPageIndex) {
                        case Enums.WelcomePages.WelcomeBanner:
                            root.controller.nextPage()
                            break
                        case Enums.WelcomePages.SetupProfle:
                            if(setupProfileForm.fullName.length === 0
                                    && setupProfileForm.email.length === 0)
                                root.controller.nextPage()
                            else{
                                if(setupProfileForm.fullName.length === 0){
                                    setupProfileForm.errorMessage = "full name can't empty"
                                    break
                                }

                                if(setupProfileForm.email.length === 0){
                                    setupProfileForm.errorMessage = "email can't empty"
                                    break
                                }

                                let userProfile = userProfileController.createUserProfile(
                                                    setupProfileForm.fullName,
                                                    "", // Password
                                                    setupProfileForm.email)

                                if(userProfile) {
                                    root.controller.nextPage()
                                    setupProfileForm.errorMessage = ""
                                }else
                                    setupProfileForm.errorMessage = "can't register profile"
                            }

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