import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

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
    property bool isFloating: true
    property int position: -1

    readonly property int resizeHandleSize: 10
    readonly property int minFloatingWidth: 220
    readonly property int minFloatingHeight: 140

    default property alias contentData: contentArea.data

    /* Signals
     * ****************************************************************************************/
    signal dockPositionChanged()
    signal closeRequested()

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
        border.color: root.isFloating ? "#c9c9c9" : "transparent"
        border.width: root.enabled ? (root.isDragging ? 1.8 : 1) : 0
        opacity: root.isDragging ? 0.8 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: 100
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
                visible: root.enabled

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

                            onClicked: root.closeRequested()
                        }
                    }
                }
                
                // Drag area on header
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    anchors.rightMargin: 25
                    hoverEnabled: root.enabled
                    enabled: root.enabled
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
                                root.isFloating = true
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

    // Right edge
    ResizeHandle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        thickness: root.resizeHandleSize
        handle: ResizeHandle.Right
        minWidth: root.minFloatingWidth
        enabled: root.isFloating && !root.isDragging && root.enabled
    }

    // Bottom edge
    ResizeHandle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        thickness: root.resizeHandleSize
        handle: ResizeHandle.Bottom
        minHeight: root.minFloatingHeight
        enabled: root.isFloating && !root.isDragging && root.enabled
    }

    // Bottom-right corner
    ResizeHandle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        thickness: root.resizeHandleSize
        handle: ResizeHandle.BottomRight
        minWidth: root.minFloatingWidth
        minHeight: root.minFloatingHeight
        enabled: root.isFloating && !root.isDragging && root.enabled
    }

    // Left edge
    ResizeHandle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        thickness: root.resizeHandleSize
        handle: ResizeHandle.Left
        minWidth: root.minFloatingWidth
        enabled: root.isFloating && !root.isDragging && root.enabled
    }

    // Top edge
    ResizeHandle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        thickness: root.resizeHandleSize
        handle: ResizeHandle.Top
        minHeight: root.minFloatingHeight
        enabled: root.isFloating && !root.isDragging && root.enabled
    }

    // Top-left corner
    ResizeHandle {
        anchors.left: parent.left
        anchors.top: parent.top

        thickness: root.resizeHandleSize
        handle: ResizeHandle.TopLeft
        minWidth: root.minFloatingWidth
        minHeight: root.minFloatingHeight
        enabled: root.isFloating && !root.isDragging && root.enabled
    }

    // Top-right corner
    ResizeHandle {
        anchors.right: parent.right
        anchors.top: parent.top

        thickness: root.resizeHandleSize
        handle: ResizeHandle.TopRight
        minWidth: root.minFloatingWidth
        minHeight: root.minFloatingHeight
        enabled: root.isFloating && !root.isDragging && root.enabled
    }

    // Bottom-left corner
    ResizeHandle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom

        thickness: root.resizeHandleSize
        handle: ResizeHandle.BottomLeft
        minWidth: root.minFloatingWidth
        minHeight: root.minFloatingHeight
        enabled: root.isFloating && !root.isDragging && root.enabled
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

