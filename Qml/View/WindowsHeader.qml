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

    /* Property Declarations
     * ****************************************************************************************/
    property WindowController windowController

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.primaryBackground
    
    /* Children
     * ****************************************************************************************/
    RowLayout {
        anchors.centerIn: parent
        spacing: 4
        
        // Minimize Button
        WindowsButton {
            id: minimizeButton
            onClicked: windowController.minimize()
            Material.accent: Style.colors.windowsMinimize
            content: Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 2
                radius: 1
                color: minimizeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
            }
        }
        
        // Maximize/Restore Button
        WindowsButton {
            id: maximizeButton
            onClicked: windowController.toggleMaxRestore()
            Material.accent: Style.colors.windowsMaximize
            content: Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                color: "transparent"
                border.color: maximizeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                border.width: 2
                radius: 2
            }
        }
        
        // Close Button
        WindowsButton {
            id: closeButton
            onClicked: windowController.closeWindow()
            Material.accent: Style.colors.windowsClose
            content: Item {
                anchors.centerIn: parent
                width: 10
                height: 10

                Rectangle {
                    width: 12
                    height: 2
                    radius: 1
                    color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                    anchors.centerIn: parent
                    rotation: 45
                }

                Rectangle {
                    width: 12
                    height: 2
                    radius: 1
                    color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                    anchors.centerIn: parent
                    rotation: -45
                }
            }
        }
    }
}
