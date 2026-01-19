import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * UserAuthenticationPopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/

    /* Signals
     * ****************************************************************************************/
    signal passwordConfirm(string password)

    /* Object Properties
     * ****************************************************************************************/
    width: parent.width / 2
    height: 180
    padding: 20

    /* Children
     * ****************************************************************************************/
    background: Rectangle {
        radius: 4
        color: Style.colors.primaryBackground
        border.width: 1
        border.color: Style.colors.primaryBorder
    }

    contentItem: Column {
        width: parent.width
        spacing: 10

        Label {
            width: parent.width
            color: Style.colors.descriptionText
            text: "Enter your Account Password (PAT)"
            font.family: Style.fontTypes.roboto
            font.weight: 400
            font.pointSize: Style.appFont.h4Pt
            horizontalAlignment: Text.AlignHCenter
        }

        FormInputField {
            id: textField
            width: parent.width
            label: "Password"
            placeholderText: "Enter your password"
            icon: "\uF023"
            helperText: "This password will be used for authentication"
            echoMode: TextInput.Password
            Layout.fillWidth: true
        }

        Row {
            id: buttonsRow
            spacing: 6
            anchors.horizontalCenter: parent.horizontalCenter

            Button {
                id: confirmButton
                width: root.width / 4
                height: 40
                hoverEnabled: true
                text: "Confirm"

                contentItem: Text {
                    text: confirmButton.text
                    font: confirmButton.font
                    color: Style.colors.secondaryForeground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 3
                    color: confirmButton.down ? Style.colors.accentHover : confirmButton.hovered ? Style.colors.accentHover : Style.colors.accent
                }

                onClicked: {
                    root.passwordConfirm(textField.text)
                    textField.field.text = ""
                    root.close()
                }
            }

            Button {
                id: cancelButton
                width: root.width / 4
                height: 40
                hoverEnabled: true
                text: "Cancel"

                contentItem: Text {
                    text: cancelButton.text
                    font: cancelButton.font
                    color: Style.colors.foreground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 3
                    border.width: 1
                    border.color: Style.colors.primaryBorder
                    color: cancelButton.down ? Style.colors.surfaceMuted: cancelButton.hovered ? Style.colors.cardBackground : Style.colors.surfaceLight
                }

                onClicked: {
                    textField.field.text = ""
                    root.close()
                }
            }
        }
    }
}
