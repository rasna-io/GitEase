import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PathSelectorItem
 * ************************************************************************************************/
RowLayout {
    id: root
    
    /* Property Declarations
    * ****************************************************************************************/
    required     property          FileIO       fileIO

    property     string            title:       ""
    
    property     string            description: ""
    
    property     alias             text:        txf.text
    
    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        Layout.fillWidth: true
        
        Text {
            Layout.fillWidth: true
            text: root.title
            font.pointSize: Style.appFont.h4Pt
            color: Style.colors.foreground
        }
        
        Text {
            Layout.fillWidth: true
            text: root.description
            font.pointSize: Style.appFont.secondaryPt
            color: Style.colors.mutedText
        }
    }
    
    TextField {
        id: txf
        Layout.preferredWidth: parent.width * 0.4
    }
    
    Button {
        id: buttonItem
        Layout.preferredHeight: txf.implicitHeight
        topInset: 0
        bottomInset: 0
        text: "Browse"
        flat: true
        font.pixelSize: 12
        font.weight: 400
        font.family: Style.fontTypes.roboto
        
        background: Rectangle {
            radius: 5
            implicitHeight: 40
            color: Style.colors.surfaceLight
            border.width: 1
            border.color: buttonItem.hovered ? Style.colors.accent : Style.colors.primaryBorder
            Behavior on border.width { NumberAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }
        
        contentItem: Text {
            text: buttonItem.text
            font: buttonItem.font
            color: Style.colors.foreground
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        
        onClicked:  folderDialog.open()
    }
    
    FolderDialog {
        id: folderDialog
        title: "Select Path"
        
        onAccepted: {
            var selectedFolder = folderDialog.selectedFolder
            if (selectedFolder) {
                var folderPath = selectedFolder.toString()
                let path = root.fileIO.pathNormalizer(folderPath);
                txf.text = path
            }
        }
    }
}
