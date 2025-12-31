import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * WindowsButton
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/

    required property Component content

    property alias containsMouse: msa.containsMouse

    /* Signals
     * ****************************************************************************************/
    signal clicked();


    /* Object Properties
     * ****************************************************************************************/
    width: 28
    height: 28
    radius: 3
    color: msa.containsMouse ? Material.accent : Material.background

    Material.background: "#F9F9F9"
    

    /* Children
     * ****************************************************************************************/
    Loader {
        anchors.centerIn: parent
        sourceComponent: root.content
    }

    MouseArea {
        id: msa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
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
