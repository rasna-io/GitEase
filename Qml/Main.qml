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
    width: 523
    height: 475
    visible: true
    color: "transparent"
    title: qsTr("GitEase")


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
        anchors.fill: parent

        sourceComponent: {
            // Check flag before creating components
            if (AppSettings.hasCompletedWelcome) {
                window.width = Qt.binding(function() {return Style.appWidth})
                window.height = Qt.binding(function() {return Style.appHeight})
                window.x = (Screen.width - width) / 2
                window.y = (Screen.height - height) / 2
                return mainApplicationComponent
            } else {
                return welcomeFlowComponent
            }
        }

        // sourceComponent:
    }
    // TODO: Move position bindings from the component to the Loader.
    //       Check all uses of 'parent' inside the root element of the component.

    // Welcome Flow Component
    Component {
        id: welcomeFlowComponent

        Item {
            anchors.fill: parent

            WelcomeController {
                id: welcomeController

                onWelcomeFlowCompleted: {
                    AppSettings.hasCompletedWelcome = true
                }
            }

            Loader {
                id: welcomePageLoader
                anchors.fill: parent
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
