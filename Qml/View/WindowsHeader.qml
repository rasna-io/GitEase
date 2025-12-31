import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * WindowsHeader
 * ************************************************************************************************/
Rectangle {
    color: "#F9F9F9"
    
    RowLayout {
        anchors.centerIn: parent
        spacing: 4
        
        // Minimize Button
        WindowsButton {
            id: minimizeButton
            onClicked: WindowController.minimize()
            Material.accent: "#4A9EFF"
            content: Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 2
                radius: 1
                color: minimizeButton.containsMouse ? "#FFFFFF" : "#808080"
            }
        }
        
        // Maximize/Restore Button
        WindowsButton {
            id: maximizeButton
            onClicked: WindowController.toggleMaxRestore()
            Material.accent: "#FFB84D"
            content: Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                border.color: maximizeButton.containsMouse ? "#FFFFFF" : "#808080"
                border.width: 2
                radius: 2
            }
        }
        
        // Close Button
        WindowsButton {
            id: closeButton
            onClicked: WindowController.closeWindow()
            Material.accent: "#FF5555"
            content: Item {
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
        }
    }
}
