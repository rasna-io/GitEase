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
    required property AppModel             appModel
    required property PageController       pageController
    required property RepositoryController repositoryController

    property real                          collapsedWidth:       50
    property real                          expandedWidth:        125
    property bool                          expanded:             hoverHandler.hovered
    property real                          animatedWidth:        collapsedWidth

    // HoverHandler reliably tracks hover even with complex children.
    HoverHandler {
        id: hoverHandler
        margin: 6
    }

    states: [
        State {
            name: "expanded"
            when: root.expanded
            PropertyChanges {
                target: root;
                animatedWidth: root.expandedWidth
            }
        },
        State {
            name: "collapsed"
            when: !root.expanded
            PropertyChanges {
                target: root;
                animatedWidth: root.collapsedWidth
            }
        }
    ]

    transitions: [
        Transition {
            NumberAnimation {
                properties: "animatedWidth"
                duration: 100
                easing.type: Easing.InOutCubic
            }
        }
    ]

    implicitWidth: animatedWidth
    width: animatedWidth

    Layout.preferredWidth: animatedWidth
    Layout.minimumWidth: collapsedWidth
    Layout.maximumWidth: expandedWidth

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
            Layout.fillWidth: true
            Layout.fillHeight: true

            color: "#F9F9F9"

            pageController: root.pageController
            expanded: root.expanded
        }

        // Repositories Sidebar (Middle section)
        RepositoriesSidebar {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#F9F9F9"

            expanded: root.expanded
            repositoryController: root.repositoryController
            repositories: root.appModel.repositories
            currentRepository: root.appModel.currentRepository
            recentRepositories: root.appModel.recentRepositories
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


