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
    property var controller: null
    property int contentMargins: 24

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
                switch(root.controller ? root.controller.currentPageIndex : 0) {
                    case 0: return ""
                    case 1: return "Set Up Your Profile"
                    case 2: return "Open a Repository"
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
                currentIndex: root.controller ? root.controller.currentPageIndex : 0

                // Step 1: Welcome
                WelcomeContent {
                    controller: root.controller
                }

                // Step 2: Setup Profile
                SetupProfileContent {
                    controller: root.controller
                }

                // Step 3: Open Repository
                OpenRepositoryContent {
                    controller: root.controller
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
                    case 0: return "Get Started" + " " + Style.icons.arrowRight
                    case 1:
                    case 2:
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
                
                if (root.controller.isLastStep) {
                    root.controller.completeWelcomeFlow()
                } else {
                    root.controller.nextPage()
                }
            }
        }
    }
}
