import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * AddStashPopup
 * ************************************************************************************************/

IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property StashController stashController: null

    readonly property bool    isNameValid: true

    readonly property bool    canAccept:   isNameValid

    /* Object Properties
     * ****************************************************************************************/
    width: 360
    height: 300
    padding: 20

    /* Children
     * ****************************************************************************************/

    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            spacing: 20
            anchors.fill: parent
            anchors.margins: 20

            Text {
                text: "Stash"
                color: Style.colors.foreground
                font.family: Style.fontTypes.roboto
                font.bold: true
                font.pixelSize: 16
                Layout.alignment: Qt.AlignHCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

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

                CheckBox {
                    id: keepIndexCheckBox
                    Layout.fillWidth: true
                    text: "Keep staged changes in index"
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 12
                    checked: false

                    indicator: Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        x: keepIndexCheckBox.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 3
                        border.color: keepIndexCheckBox.down ? Style.colors.accent : Style.colors.primaryBorder

                        Rectangle {
                            width: 8
                            height: 8
                            x: 4
                            y: 4
                            radius: 2
                            color: Style.colors.accent
                            visible: keepIndexCheckBox.checked
                        }
                    }

                    contentItem: Text {
                        text: keepIndexCheckBox.text
                        font: keepIndexCheckBox.font
                        color: Style.colors.foreground
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: keepIndexCheckBox.indicator.width + keepIndexCheckBox.spacing
                    }
                }
            }



            RowLayout {
                spacing: 8
                Layout.fillWidth: true

                Button {
                    text: "Cancel"
                    Layout.preferredWidth: parent.width * 0.3
                    onClicked: root.close()

                    background: Rectangle {
                        implicitHeight: 35
                        color: parent.hovered ? "#33ffffff" : "transparent"
                        border.color: Style.colors.accent
                        radius: 5
                    }
                }

                Button {
                    id: actionBtn
                    text: "Stash"
                    Layout.fillWidth: true
                    enabled: root.canAccept

                    opacity: enabled ? 1.0 : 0.5

                    background: Rectangle {
                        implicitHeight: 35
                        color: (actionBtn.hovered && actionBtn.enabled) ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                    }

                    onClicked: {
                        let message = stashMessageField.text.trim()
                        let keepIndex = keepIndexCheckBox.checked
                        let result = stashController.save(message, keepIndex)
                        if (result.success) {
                            stashMessageField.text = ""
                            keepIndexCheckBox.checked = false
                            root.close()

                        }

                    }
                }
            }
        }
    }

}
