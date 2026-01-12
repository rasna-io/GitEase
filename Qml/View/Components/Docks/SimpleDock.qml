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
    readonly property string dockId: title + " " + Date.now()
    required property string title
    property bool isDragging: false
    property int position: -1
    default property alias contentData: contentArea.data

    /* Signals
     * ****************************************************************************************/
    signal dockPositionChanged()

    /* Object Properties
     * ****************************************************************************************/
    z: isDragging ? 999 : 1
    
    /* Children
     * ****************************************************************************************/
    Rectangle {
        id: dockBackground
        anchors.fill: parent
        color: Style.colors.primaryBackground
        radius: 6
        border.color: "#c9c9c9"
        border.width: root.isDragging ? 1.8 : 1

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
            anchors.margins: 1
            z: 1

            // Header
            Rectangle {
                id: headerRect
                width: parent.width
                height: 30
                z: 2
                color: dragArea.containsMouse ? Qt.darker("#F9F9F9", 1.1) : "#F9F9F9"
                radius: 6

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
                        color: "#000000"
                        font.bold: true
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        color: closeMouseArea.containsMouse ? "#e81123" : "transparent"
                        radius: 3
                        
                        Rectangle {
                            width: 12
                            height: 2
                            radius: 1
                            color:  dragArea.containsMouse ? "#000000" :
                                                             closeMouseArea.containsMouse ? "#FFFFFF" : "#808080"
                            anchors.centerIn: parent
                            rotation: 45
                        }

                        Rectangle {
                            width: 12
                            height: 2
                            radius: 1
                            color:  dragArea.containsMouse ? "#000000" :
                                                             closeMouseArea.containsMouse ? "#FFFFFF" : "#808080"
                            anchors.centerIn: parent
                            rotation: -45
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
                                root.position = -1
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
                            root.dockPositionChanged()
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

