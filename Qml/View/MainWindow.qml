import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * MainWindow
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property UiSession uiSession: null

    /* Object Properties
     * ****************************************************************************************/
    color: "#F9F9F9"

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                spacing: 0

                Rectangle {
                    Layout.preferredWidth: 120

                    Image {
                        anchors.centerIn: parent
                        width: 99
                        height: 28
                        source: "qrc:/GitEase/Resources/Images/Logo.png"
                    }
                }

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onPressed: WindowController.startSystemMove()
                    onDoubleClicked: WindowController.toggleMaxRestore()
                }

                // TODO : main header for each page
                Rectangle {
                    Layout.fillWidth: true

                    Text {
                        anchors.centerIn: parent
                        text: "# main header in docks"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 120
                    color: "#F9F9F9"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        // Minimize Button
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 3
                            color: minimizeButton.containsMouse ? "#4A9EFF" : "#F9F9F9"
                            
                            Rectangle {
                                anchors.centerIn: parent
                                width: 10
                                height: 2
                                radius: 1
                                color: minimizeButton.containsMouse ? "#FFFFFF" : "#808080"
                            }

                            MouseArea {
                                id: minimizeButton
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WindowController.minimize()
                            }
                            
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }

                        // Maximize/Restore Button
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 3
                            color: maximizeButton.containsMouse ? "#FFB84D" : "#F9F9F9"

                            Rectangle {
                                anchors.centerIn: parent
                                width: 10
                                height: 10
                                border.color: maximizeButton.containsMouse ? "#FFFFFF" : "#808080"
                                border.width: 2
                                radius: 2
                            }

                            MouseArea {
                                id: maximizeButton
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WindowController.toggleMaxRestore()
                            }
                            
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }

                        // Close Button
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 3
                            color: closeButton.containsMouse ? "#FF5555" : "#F9F9F9"

                            Item {
                                anchors.centerIn: parent
                                width: 10
                                height: 10
                                
                                Rectangle {
                                    width: 12
                                    height: 2
                                    radius: 1
                                    color: closeButton.containsMouse ? "#FFFFFF" : "#808080"
                                    anchors.centerIn: parent
                                    rotation: 45
                                }
                                
                                Rectangle {
                                    width: 12
                                    height: 2
                                    radius: 1
                                    color: closeButton.containsMouse ? "#FFFFFF" : "#808080"
                                    anchors.centerIn: parent
                                    rotation: -45
                                }
                            }

                            MouseArea {
                                id: closeButton
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WindowController.closeWindow()
                            }
                            
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    Layout.rightMargin: 4
                    Layout.leftMargin: 4

                    color: "#074E96"
                    radius: 3
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            PageTabBar {
                Layout.preferredWidth: 50
                Layout.fillHeight: true

                appModel: root.uiSession?.appModel
                pageController: root.uiSession?.pageController
                repositoryController: root.uiSession?.repositoryController
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 4
                Layout.rightMargin: 4
                Layout.bottomMargin: 4

                color: "#FFFFFF"
                border.color: "#F3F3F3"
                border.width: 1
                radius: 6

                Text {
                    anchors.centerIn: parent
                    text: "Main Content Area"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
