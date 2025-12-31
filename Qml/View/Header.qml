import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * Header
 * ************************************************************************************************/
ColumnLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property Component content


    /* Object Properties
     * ****************************************************************************************/
    spacing: 0


    /* Children
     * ****************************************************************************************/
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 35
        spacing: 0
        
        Item {
            Layout.preferredWidth: 120
            
            Image {
                anchors.centerIn: parent
                width: 99
                height: 28
                fillMode: Image.PreserveAspectFit
                source: "qrc:/GitEase/Resources/Images/Logo.svg"
            }
        }
        
        MouseArea {
            id: dragArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: WindowController.startSystemMove()
            onDoubleClicked: WindowController.toggleMaxRestore()
        }


        Loader {
            Layout.fillWidth: true
            sourceComponent: root.content
        }

        
        // Windows Header
        WindowsHeader {
            Layout.preferredWidth: 120
        }
    }
    
    //Line Seperator
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 2
        Layout.rightMargin: 4
        Layout.leftMargin: 4
        
        color: "#074E96"
        radius: 3
    }
}
