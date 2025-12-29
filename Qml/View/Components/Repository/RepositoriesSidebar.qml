import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * RepositoriesSidebar
 * Sidebar component with + button and repository squares showing first letter
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property RepositoryController    repositoryController: null
    property var                     repositories:         []
    property Repository              currentRepository:    null

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/
    Item {
        anchors.fill: parent

        // Repository list - anchored to bottom with flexible height
        Flickable {
            id: flickable
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: addButton.top
            anchors.bottomMargin: 12

            height: Math.min(repositoryColumn.height, parent.height - addButton.height - 12)
            contentHeight: repositoryColumn.height
            clip: true

            Column {
                id: repositoryColumn
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.repositories

                    Row {
                        spacing: 2
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: modelData.id === currentRepository?.id ?? false
                            color: "#074E96"
                            width: 3
                            height: 28
                            radius: 2
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 33
                            height: 33
                            radius: 6
                            color: "#B9FAB9"

                            Text {
                                anchors.centerIn: parent
                                text: modelData && modelData.name ? modelData.name.charAt(0).toUpperCase() + modelData.name.charAt(1).toUpperCase() : "?"
                                font.pixelSize: 24
                                font.family: Style.fontTypes.roboto
                                font.weight: 400
                                color: Qt.darker(parent.color, 1.5)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: root.repositoryController.openRepository(modelData.path)
                                onEntered: parent.color = Qt.darker(parent.color, 1.3)
                                onExited: parent.color = Qt.lighter(parent.color, 1.3)
                            }
                        }
                    }
                }
            }
        }

        // Add button - anchored at bottom
        Rectangle {
            id: addButton
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            width: 33
            height: 33
            radius: 6
            color: "#F3F3F3"

            Text {
                anchors.centerIn: parent
                text: "+"
                font.pixelSize: 22
                font.family: Style.fontTypes.roboto
                font.weight: 400
                color: "#C9C9C9"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                // TODO :: onClicked, show RepositorySelector
                onEntered: parent.color = Qt.darker("#F3F3F3", 2)
                onExited: parent.color = "#F3F3F3"
            }
        }
    }
}
