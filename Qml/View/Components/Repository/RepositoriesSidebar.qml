import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

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
    property var                     recentRepositories:   []

    property bool                    expanded:             false

    /* Signals
     * ****************************************************************************************/
    signal newRepositoryRequested()

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

            height: Math.min(repositoryColumn.height, parent.height - addButton.height - 12)
            contentHeight: repositoryColumn.height
            clip: true

            Column {
                id: repositoryColumn
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                spacing: 2

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
                                color: (modelData.id === (currentRepository?.id ?? -1)) ? "#074E96" : "transparent"
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
            height: 33
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            anchors.topMargin: 3
            anchors.bottomMargin: 3
            radius: 6
            color: "#F3F3F3"

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
                        text: Style.icons.plus
                        font.family: Style.fontTypes.font6Pro
                        font.weight: 400
                        font.pixelSize: 14
                        color: Style.colors.foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Text {
                    visible: root.expanded
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: "Add new"
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
                id: addRepoMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: root.newRepositoryRequested()
                onEntered: parent.color = Qt.darker("#F3F3F3", 1.3)
                onExited: parent.color = "#F3F3F3"
            }
        }
    }
}
