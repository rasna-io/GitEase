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

    property bool                    expanded:             false

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

                    Item {
                        width: parent.width
                        height: repositoryRow.implicitHeight + 8

                        Row {
                            id: repositoryRow
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: (modelData.id === (currentRepository?.id ?? -1))
                                color: "#074E96"
                                width: 3
                                height: 28
                                radius: 2
                            }

                            Rectangle {
                                id: repositoryAvatar
                                anchors.verticalCenter: parent.verticalCenter
                                height: 33
                                radius: 6
                                clip: true

                                width: root.expanded ? repositoryRow.width - (repositoryRow.spacing + 2 + repositoryRow.anchors.margins) : 33
                                color: repoMouseArea.containsMouse ?  Qt.darker("#B9FAB9", 1.25) : "#B9FAB9"

                                Text {
                                    property string initials: {
                                        const n = (modelData && modelData.name) ? modelData.name : "";
                                        if (n.length >= 2) return (n.charAt(0) + n.charAt(1)).toUpperCase();
                                        if (n.length === 1) return n.charAt(0).toUpperCase();
                                        return "?";
                                    }

                                    text: root.expanded ? modelData.name : initials
                                    font.family: Style.fontTypes.roboto
                                    font.weight: 400
                                    font.pixelSize:root.expanded ? 16 : 24
                                    Behavior on font.pixelSize {
                                        NumberAnimation {
                                            duration: 10;
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    color: Qt.darker(parent.color, 2.0)
                                    elide: Text.ElideRight

                                    x: root.expanded ? 5 : ((repositoryAvatar.width - width) / 2)
                                    y: (repositoryAvatar.height - height) / 2

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 10;
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                MouseArea {
                                    id: repoMouseArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: root.repositoryController.openRepository(modelData.path)
                                }
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
