import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * CreateStashView
 * View for creating new stashes
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property StashController stashController: null

    /* Signals
     * ****************************************************************************************/

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Text {
            text: "Create a new stash to save your current changes"
            font.family: Style.fontTypes.roboto
            font.pixelSize: 12
            color: Style.colors.secondaryText
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }


        Text {
            text: "Stash Message (Optional)"
            font.family: Style.fontTypes.roboto
            font.pixelSize: 11
            font.bold: true
            color: Style.colors.foreground
        }

        TextField {
            id: stashMessageField
            Layout.fillWidth: true
            placeholderText: "Enter a description for this stash..."
            font.family: Style.fontTypes.roboto
            font.pixelSize: 12

            background: Rectangle {
                radius: 4
                color: Style.colors.secondaryBackground
                border.width: parent.activeFocus ? 2 : 1
                border.color: parent.activeFocus ? Style.colors.accent : Style.colors.primaryBorder
            }
        }

        Button {
            Layout.fillWidth: true
            implicitHeight: 44

            background: Rectangle {
                radius: 8
                color: enabled ? Style.colors.accent : Style.colors.disabledButton
            }

            contentItem: Item {
                anchors.fill: parent

                Row {
                    spacing: 10
                    anchors.centerIn: parent

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Style.icons.plus
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: 12
                        color: Style.colors.secondaryForeground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Stash"
                        color: Style.colors.secondaryForeground
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            onClicked: {
                let message = stashMessageField.text.trim()
                let result = stashController.save(message)
                if (result.success) {
                    stashMessageField.text = ""
                }
            }
        }
    }
}
