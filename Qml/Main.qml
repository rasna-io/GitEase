import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls

import GitEase
import GitEase_Style
import GitEase.Resources
import GitEase_Style_Impl




/*! ***********************************************************************************************
 * This is the highest level graphical object, i.e., the main application window. The state
 * of each instance is stored in the UiSession, which needs to be passed to its children.
 * Multiple instances can be created.
 * ************************************************************************************************/
ApplicationWindow {
    id: window

    /* Property Declarations
     * ****************************************************************************************/


    /* Object Properties
     * ****************************************************************************************/
    width: AppSettings.hasCompletedWelcome ? Style.appWidth : 523
    height: AppSettings.hasCompletedWelcome ? Style.appHeight : 475
    x: (Screen.width - width) / 2
    y: (Screen.height - height) / 2
    visible: true
    color: "transparent"
    title: qsTr("GitEase")
    flags: Qt.Window | Qt.FramelessWindowHint


    /* Fonts
     * ****************************************************************************************/
    FontLoader { source: "qrc:/GitEase/Resources/Fonts/Font Awesome 6 Pro-Thin-100.otf" }
    FontLoader { source: "qrc:/GitEase/Resources/Fonts/Font Awesome 6 Pro-Solid-900.otf" }
    FontLoader { source: "qrc:/GitEase/Resources/Fonts/Font Awesome 6 Pro-Regular-400.otf" }
    FontLoader { source: "qrc:/GitEase/Resources/Fonts/Font Awesome 6 Pro-Light-300.otf" }


    /* Children
     * ****************************************************************************************/
    UiSession {
        id: uiSession
    }

    UiSessionPopups {
        id: uiSessionPopups
        width: window.width
        height: window.height
    }

    // Main content loader - switches between welcome flow and main application
    // Check flag BEFORE creating any components
    Loader {
        id: mainContentLoader
        anchors.centerIn: parent
        width: AppSettings.hasCompletedWelcome ? parent.width : undefined
        height: AppSettings.hasCompletedWelcome ? parent.height : undefined
        
        sourceComponent: {
            // Check flag before creating components
            if (AppSettings.hasCompletedWelcome) {
                return mainApplicationComponent
            } else {
                return welcomeFlowComponent
            }
        }
    }

    // Welcome Flow Component
    Component {
        id: welcomeFlowComponent

        Item {
            width: 523
            height: 475

            WelcomeController {
                id: welcomeController

                onWelcomeFlowCompleted: {
                    AppSettings.hasCompletedWelcome = true
                }
            }

            Loader {
                id: welcomePageLoader
                anchors.centerIn: parent
                source: "qrc:/GitEase/Qml/Pages/WelcomePage.qml"

                // Pass controller to loaded page
                onLoaded: {
                    if (item && item.hasOwnProperty("controller")) {
                        item.controller = welcomeController
                        item.repositoryController = uiSession.repositoryController
                    }
                }
            }
        }
    }

    // Main Application Component
    Component {
        id: mainApplicationComponent

        Item {
            anchors.fill: parent

            // Main application content goes here
            Rectangle {
                anchors.fill: parent
                color: Style.colors.primaryBackground
                radius: 16

                Text {
                    anchors.centerIn: parent
                    text: "Main Application Window"
                    font.pixelSize: 24
                    color: Style.colors.foreground
                }
            }
        }
    }
}
