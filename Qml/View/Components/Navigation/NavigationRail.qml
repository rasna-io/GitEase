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

    /* Signals
     * ****************************************************************************************/
    signal newRepositoryRequested()



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
            onNewRepositoryRequested: function () {
                root.newRepositoryRequested()
            }
        }

        // Settings button (Bottom section)
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.topMargin: 3
            Layout.bottomMargin: 3
            Layout.preferredHeight: 33
            radius: 6
            color: "transparent"

            Behavior on color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                spacing: 8

                Item {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    Layout.preferredWidth: 20
                    Layout.minimumWidth: 20
                    Layout.maximumWidth: 20
                    Layout.preferredHeight: 20

                    Text {
                        anchors.centerIn: parent
                        text: Style.icons.gear
                        font.family: settingButtonMouse.containsMouse ? Style.fontTypes.font6ProSolid : Style.fontTypes.font6Pro
                        font.weight: 400
                        font.pixelSize: 14
                        color: Style.colors.foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: "Settings"
                    visible: root.expanded
                    font.family: Style.fontTypes.roboto
                    font.weight: 400
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    color: Style.colors.foreground
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    visible: root.expanded
                }
            }

            // Make the whole row clickable
            MouseArea {
                id: settingButtonMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                // onClicked: // TODO
                onEntered: parent.color = Qt.darker("#F3F3F3", 1.3)
                onExited: parent.color = "transparent"
            }
        }

        // Profile button
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.topMargin: 3
            Layout.bottomMargin: 3
            Layout.preferredHeight: 33
            radius: 6
            color: "transparent"

            Behavior on color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                spacing: 8

                Image {
                    source: "qrc:/GitEase/Resources/Images/defaultUserIcon.svg"
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    width: 42
                    height: 42
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: "username"
                    visible: root.expanded
                    font.family: Style.fontTypes.roboto
                    font.weight: 400
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    color: Style.colors.foreground
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    visible: root.expanded
                }
            }

            // Make the whole row clickable
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                // onClicked: // TODO
                onEntered: parent.color = Qt.darker("#F3F3F3", 1.3)
                onExited: parent.color = "transparent"
            }
        }
    }
}


