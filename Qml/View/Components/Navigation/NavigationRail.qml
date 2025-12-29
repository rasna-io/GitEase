import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * NavigationRail
 * Vertical sidebar component for page and repository navigation.
 * Displays list of open pages and available repositories.
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property AppModel             appModel: null
    property PageController       pageController: null
    property RepositoryController repositoryController: null

    /* Object Properties
     * ****************************************************************************************/
    color: "#F9F9F9"

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        anchors.bottomMargin: 4

        // Pages Sidebar (Top section)
        PagesRail {
            Layout.preferredWidth: 50
            Layout.fillHeight: true

            color: "#F9F9F9"

            pageController: root.pageController
        }

        // Repositories Sidebar (Middle section)
        RepositoriesSidebar {
            Layout.preferredWidth: 50
            Layout.fillHeight: true
            color: "#F9F9F9"

            repositoryController: root.repositoryController
            repositories: root.appModel.repositories
            currentRepository: root.appModel.currentRepository
        }

        // Settings button (Bottom section)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "transparent"

            RoundButton {
                id: settingsButton
                anchors.centerIn: parent
                text: Style.icons.gear
                font.pixelSize: 20
                width: 31
                height: 31
                flat: true
                hoverEnabled: true

                font.family: settingsButton.hovered ? Style.fontTypes.font6ProSolid : Style.fontTypes.font6Pro

                background: Rectangle {
                    implicitWidth: 31
                    implicitHeight: 31
                    radius: width / 2
                    color: settingsButton.hovered ? "#E5E5E5" : "transparent"
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                onClicked: {
                    console.log("NavigationRail - Settings clicked")
                    // TODO: Open settings dialog
                }
            }
        }

        // Profile Icon(Bottom profile)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 35
            color: "transparent"

            RoundButton {
                anchors.centerIn: parent
                width: 42
                height: 42
                flat: true

                background: Rectangle {
                    width: 42
                    height: 42
                    radius: width / 2
                    color: "#D9D9D9"
                }

                contentItem: Image {
                    source: "qrc:/GitEase/Resources/Images/defaultUserIcon.svg"
                    anchors.centerIn: parent
                    width: 42
                    height: 42
                }

                onClicked: {
                    console.log("NavigationRail - Profile clicked")
                    // TODO:
                }
            }
        }
    }

}


