import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * SimpleDock
 * SimpleDock Contain Dock Header and function
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string title: "Simple Dock"
    property bool isDragging: false
    default property alias contentData: contentArea.data
    
    /* Children
     * ****************************************************************************************/
    Rectangle {
        id: dockBackground
        anchors.fill: parent
        z: -1
        color: Style.colors.primaryBackground
        border.color: "#4a90ff"
        border.width: root.isDragging ? 4 : 0
        opacity: root.isDragging ? 0.3 : 1.0
        radius: root.isDragging ? 6 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
        
        Behavior on border.color {
            ColorAnimation {
                duration: 200
            }
        }
        
        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }

        Column {
            anchors.fill: parent
            z: 1

            // Header
            Rectangle {
                id: headerRect
                width: parent.width
                height: 30
                z: 2
                color: dragArea.containsMouse ? Qt.darker("#F9F9F9", 1.9) : "#F9F9F9"

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    anchors.rightMargin: 5
                    spacing: 5

                    Label {
                        text: root.title
                        color: dragArea.containsMouse ? "#ffffff" : "#000000"
                        font.bold: true
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        color: closeMouseArea.containsMouse ? "#e81123" : "transparent"
                        radius: 3
                        
                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: "#ffffff"
                            font.pixelSize: 16
                            font.bold: true
                        }
                        
                        MouseArea {
                            id: closeMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
                
                // Drag area on header
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    anchors.rightMargin: 25
                    hoverEnabled: true
                    cursorShape: root.isDragging ? Qt.ClosedHandCursor :
                                                   dragArea.containsMouse? Qt.SizeAllCursor : Qt.ArrowCursor
                    acceptedButtons: Qt.LeftButton
                    
                    property point pressPoint: Qt.point(0, 0)
                                        
                    onPressed: function(mouse) {
                        pressPoint = Qt.point(mouse.x, mouse.y)
                    }
                    
                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            var distance = Math.sqrt(
                                Math.pow(mouse.x - pressPoint.x, 2) +
                                Math.pow(mouse.y - pressPoint.y, 2)
                            )
                            
                            if (distance > 10 && !root.isDragging) {
                                root.isDragging = true
                                root.clearAnchors()
                            }
                            
                            if (root.isDragging) {
                                root.x += mouse.x - pressPoint.x
                                root.y += mouse.y - pressPoint.y
                            }
                        }
                    }
                    
                    onReleased: function(mouse) {                       
                        if (root.isDragging) {                          
                            root.isDragging = false
                            root.clearAnchors()
                        }
                    }
                }
            }

            // Content
            Item {
                id: contentArea
                width: parent.width
                height: parent.height - headerRect.height
                z: 1
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    // Helper function to clear all anchors
    function clearAnchors() {
        root.anchors.fill = undefined
        root.anchors.left = undefined
        root.anchors.right = undefined
        root.anchors.top = undefined
        root.anchors.bottom = undefined
        root.anchors.centerIn = undefined
        root.anchors.horizontalCenter = undefined
        root.anchors.verticalCenter = undefined
    }
}

