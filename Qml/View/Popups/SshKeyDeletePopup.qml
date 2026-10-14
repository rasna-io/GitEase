import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SshKeyDeletePopup
 * Confirms deleting an SSH key. Standard OpenSSH key names (id_rsa, id_ed25519, ...) require the
 * name to be typed before Delete is enabled.
 * ************************************************************************************************/
IPopup {
    id: root
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    width: 380
    height: requiresTypedConfirm ? 330 : 240

    padding: 0

    signal deleteConfirmed(string keyName)

    property string targetKeyName: ""

    // OpenSSH default key names (id_rsa, id_ed25519, ...) are likely used
    // elsewhere, so deleting them requires typing the name to confirm.
    readonly property bool requiresTypedConfirm:
        /^id_(rsa|dsa|ecdsa|ed25519)(_sk)?$/.test(targetKeyName)
    readonly property bool confirmed:
        !requiresTypedConfirm || confirmInput.text === targetKeyName

    onAboutToShow: confirmInput.text = ""

    background: Rectangle {
        color: "transparent"
    }

    Overlay.modal: Rectangle {
        color: "#000000"
        opacity: 0.35
    }

    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.primaryBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            Text {
                text: "Delete SSH Key"
                color: Style.colors.foreground
                font.pointSize: Style.appFont.h3Pt
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "Are you sure you want to delete this SSH key?\n\n\"" + root.targetKeyName + "\"\n\nThis action cannot be undone."
                color: Style.colors.mutedText
                font.pointSize: Style.appFont.defaultPt
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                visible: root.requiresTypedConfirm
                text: "This looks like a standard OpenSSH key that other tools may rely on. Type its name to confirm:"
                color: Style.colors.deletededFile
                font.pointSize: Style.appFont.secondaryPt
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            TextField {
                id: confirmInput
                visible: root.requiresTypedConfirm
                Layout.fillWidth: true
                placeholderText: root.targetKeyName
                color: Style.colors.foreground
                font.family: Style.fontTypes.jetBrainsMono
                font.pixelSize: Style.appFont.defaultPt
                background: Rectangle {
                    implicitHeight: 34
                    radius: 5
                    color: Style.colors.controlBackground
                    border.width: 1
                    border.color: confirmInput.activeFocus ? Style.colors.accent : Style.colors.controlBorder
                }
            }

            RowLayout {
                spacing: 8
                Layout.fillWidth: true
                Layout.topMargin: 8

                Button {
                    text: "Cancel"
                    Layout.fillWidth: true
                    flat: true

                    background: Rectangle {
                        implicitHeight: 38
                        color: parent.hovered ? Style.colors.controlBackgroundHover : "transparent"
                        border.color: Style.colors.accent
                        border.width: 1
                        radius: 5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: Style.colors.foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.mediumPt
                    }

                    onClicked: root.close()
                }

                Button {
                    id: deleteConfirmBtn
                    text: "Delete"
                    Layout.fillWidth: true
                    flat: true
                    enabled: root.confirmed
                    opacity: enabled ? 1.0 : 0.4

                    background: Rectangle {
                        implicitHeight: 38
                        color: deleteConfirmBtn.hovered ? Style.colors.deletededFile : Qt.rgba(Style.colors.deletededFile.r, Style.colors.deletededFile.g, Style.colors.deletededFile.b, 0.2)
                        border.color: Style.colors.deletededFile
                        border.width: 1
                        radius: 5
                    }

                    contentItem: Text {
                        text: deleteConfirmBtn.text
                        color: deleteConfirmBtn.hovered ? "#ffffff" : Style.colors.deletededFile
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.mediumPt
                        font.bold: true
                    }

                    onClicked: {
                        root.deleteConfirmed(root.targetKeyName)
                        root.close()
                    }
                }
            }
        }
    }
}
