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
    property bool isFloating: true
    property int position: -1

    readonly property int resizeHandleSize: 10
    readonly property int minFloatingWidth: 220
    readonly property int minFloatingHeight: 140
    property bool isResizing: false

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
        border.width: root.isDragging ? 1.8 : 1

        // Resize handles (only when floating)
        Item {
            id: resizeOverlay
            anchors.fill: parent
            z: 10
            visible: root.isFloating && !root.isDragging

            // Right edge
            MouseArea {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: root.resizeHandleSize
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                enabled: resizeOverlay.visible

                property real startW
                property real startX
                property real startMouseX

                onPressed: function(m) {
                    root.isResizing = true

                    startW = root.width
                    startMouseX = m.x
                }

                onPositionChanged: function(m) {
                    if (!pressed)
                        return

                    let delatX = m.x - startMouseX
                    root.width = Math.max(startW + delatX, root.minFloatingWidth)
                }

                onReleased: root.isResizing = false

                onCanceled: root.isResizing = false
            }

            // Bottom edge
            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: root.resizeHandleSize
                hoverEnabled: true
                cursorShape: Qt.SizeVerCursor
                enabled: resizeOverlay.visible

                property real startH
                property real startMouseY

                onPressed: function(m) {
                    root.isResizing = true

                    startH = root.height
                    startMouseY = m.y
                }

                onPositionChanged: function(m) {
                    if (!pressed)
                        return

                    let deltaY = m.y - startMouseY
                    root.height = Math.max(startH + deltaY, root.minFloatingHeight)
                }

                onReleased: root.isResizing = false

                onCanceled: root.isResizing = false
            }

            // Bottom-right corner
            MouseArea {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: root.resizeHandleSize
                height: root.resizeHandleSize
                hoverEnabled: true
                cursorShape: Qt.SizeFDiagCursor
                enabled: resizeOverlay.visible

                property real startW
                property real startH
                property real startMouseX
                property real startMouseY

                onPressed: function(m) {
                    root.isResizing = true

                    startW = root.width
                    startH = root.height
                    startMouseX = m.x
                    startMouseY = m.y
                }

                onPositionChanged: function(m) {
                    if (!pressed)
                        return

                    let deltaX = m.x - startMouseX
                    let deltaY = m.y - startMouseY
                    root.width = Math.max(startW + deltaX, root.minFloatingWidth)
                    root.height = Math.max(startH + deltaY, root.minFloatingHeight)
                }

                onReleased: root.isResizing = false

                onCanceled: root.isResizing = false
            }

            // Left edge
            MouseArea {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: root.resizeHandleSize
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                enabled: resizeOverlay.visible

                property real startW
                property real startX
                property real startMouseX

                onPressed: function(m) {
                    root.isResizing = true

                    startW = root.width
                    startX = root.x
                    startMouseX = m.x
                }

                onPositionChanged: function(m) {
                    if (!pressed)
                        return

                    let deltaX = m.x - startMouseX
                    let newW = Math.max(startW - deltaX, root.minFloatingWidth)
                    root.x = startX + (startW - newW)
                    root.width = newW
                }

                onReleased: root.isResizing = false

                onCanceled: root.isResizing = false
            }

            // Top edge
            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: root.resizeHandleSize
                hoverEnabled: true
                cursorShape: Qt.SizeVerCursor
                enabled: resizeOverlay.visible

                property real startH
                property real startY
                property real startMouseY

                onPressed: function(m) {
                    root.isResizing = true

                    startH = root.height
                    startY = root.y
                    startMouseY = m.y
                }

                onPositionChanged: function(m) {
                    if (!pressed)
                        return

                    let deltaY = m.y - startMouseY
                    let newH = Math.max(startH - deltaY, root.minFloatingHeight)
                    root.y = startY + (startH - newH)
                    root.height = newH
                }

                onReleased: root.isResizing = false

                onCanceled: root.isResizing = false
            }

            // Top-left corner
            MouseArea {
                anchors.left: parent.left
                anchors.top: parent.top
                width: root.resizeHandleSize
                height: root.resizeHandleSize
                hoverEnabled: true
                cursorShape: Qt.SizeFDiagCursor
                enabled: resizeOverlay.visible

                property real startW
                property real startH
                property real startX
                property real startY
                property real startMouseX
                property real startMouseY

                onPressed: function(m) {
                    root.isResizing = true

                    startW = root.width
                    startH = root.height
                    startX = root.x
                    startY = root.y
                    startMouseX = m.x
                    startMouseY = m.y
                }

                onPositionChanged: function(m) {
                    if (!pressed)
                        return

                    let deltaX = m.x - startMouseX
                    let deltaY = m.y - startMouseY
                    let newW = Math.max(startW - deltaX, root.minFloatingWidth)
                    let newH = Math.max(startH - deltaY, root.minFloatingHeight)
                    root.x = startX + (startW - newW)
                    root.y = startY + (startH - newH)
                    root.width = newW
                    root.height = newH
                }

                onReleased: root.isResizing = false

                onCanceled: root.isResizing = false
            }

            // Top-right corner
            MouseArea {
                anchors.right: parent.right
                anchors.top: parent.top
                width: root.resizeHandleSize
                height: root.resizeHandleSize
                hoverEnabled: true
                cursorShape: Qt.SizeBDiagCursor
                enabled: resizeOverlay.visible

                property real startW
                property real startH
                property real startY
                property real startMouseX
                property real startMouseY

                onPressed: function(m) {
                    root.isResizing = true

                    startW = root.width
                    startH = root.height
                    startY = root.y
                    startMouseX = m.x
                    startMouseY = m.y
                }

                onPositionChanged: function(m) {
                    if (!pressed)
                        return

                    let deltaX = m.x - startMouseX
                    let deltaY = m.y - startMouseY
                    root.width = Math.max(startW + deltaX, root.minFloatingWidth)
                    let newH = Math.max(startH - deltaY, root.minFloatingHeight)
                    root.y = startY + (startH - newH)
                    root.height = newH
                }

                onReleased: root.isResizing = false

                onCanceled: root.isResizing = false
            }

            // Bottom-left corner
            MouseArea {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: root.resizeHandleSize
                height: root.resizeHandleSize
                hoverEnabled: true
                cursorShape: Qt.SizeBDiagCursor
                enabled: resizeOverlay.visible

                property real startW
                property real startH
                property real startX
                property real startMouseX
                property real startMouseY

                onPressed: function(m) {
                    root.isResizing = true

                    startW = root.width
                    startH = root.height
                    startX = root.x
                    startMouseX = m.x
                    startMouseY = m.y
                }

                onPositionChanged: function(m) {
                    if (!pressed)
                        return

                    let deltaX = m.x - startMouseX
                    let deltaY = m.y - startMouseY
                    let newW = Math.max(startW - deltaX, root.minFloatingWidth)
                    root.x = startX + (startW - newW)
                    root.width = newW
                    root.height = Math.max(startH + deltaY, root.minFloatingHeight)
                }

                onReleased: root.isResizing = false

                onCanceled: root.isResizing = false
            }
        }

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

                            onClicked: root.closeRequested()
                        }
                    }
                }
                
                // Drag area on header
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    anchors.rightMargin: 25
                    hoverEnabled: true
                    cursorShape: (root.isDragging || root.isResizing) ? Qt.ClosedHandCursor :
                                                   dragArea.containsMouse? Qt.SizeAllCursor : Qt.ArrowCursor
                    acceptedButtons: Qt.LeftButton
                    
                    property point pressPoint: Qt.point(0, 0)
                                        
                    onPressed: function(mouse) {
                        pressPoint = Qt.point(mouse.x, mouse.y)
                    }
                    
                    onPositionChanged: function(mouse) {
                        if (root.isResizing)
                            return

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

