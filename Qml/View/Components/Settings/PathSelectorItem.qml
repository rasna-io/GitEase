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
ColumnLayout {
    id: root
    
    /* Property Declarations
    * ****************************************************************************************/
    required     property          FileIO       fileIO

    property     string            title:       ""
    
    property     string            description: ""
    
    property     alias             text:        txf.text
    
    spacing: 8

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: root.title
            font.family: Style.fontTypes.inter
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Style.colors.foreground
        }
        
        Text {
            Layout.fillWidth: true
            text: root.description
            font.family: Style.fontTypes.inter
            font.pixelSize: 10
            color: Style.colors.mutedText
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        TextField {
            id: txf
            Layout.fillWidth: true
            minHeight: 30
            borderRadius: 6
            baseFontSize: 12
            backgroundColor: Style.colors.controlBackground
            borderColor: Style.colors.controlBorder
            focusBorderColor: Style.colors.accent
        }

        Button {
            id: buttonItem
            Layout.preferredHeight: txf.implicitHeight
            topInset: 0
            bottomInset: 0
            text: "Browse"
            flat: true
            font.pixelSize: Style.appFont.mediumPt
            font.weight: 400
            font.family: Style.fontTypes.inter

            background: Rectangle {
                radius: 6
                implicitHeight: 30
                color: buttonItem.hovered ? Style.colors.controlBackgroundHover
                                          : Style.colors.controlBackground
                border.width: 1
                border.color: buttonItem.hovered ? Style.colors.accent
                                                 : Style.colors.controlBorder
                Behavior on color        {
                    ColorAnimation {
                        duration: 150
                    }
                }
                Behavior on border.color {
                    ColorAnimation {
                        duration: 150
                    }
                }
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
