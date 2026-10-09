import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SshKeyExportPopup
 * Asks what to export for an SSH key (public key only, or the key pair) before a folder is chosen.
 * ************************************************************************************************/
IPopup {
    id: root
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    width: 400
    height: exportCol.implicitHeight + 40

    padding: 0

    /*! Emitted after the dialog closes; the owner opens a folder chooser and then
            reads targetKeyName / includePrivate from this popup. */
    signal chooseFolderRequested()

    property string targetKeyName: ""
    property bool   includePrivate: false

    onAboutToShow: includePrivate = false

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
            id: exportCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 20
            }
            spacing: 12

            Text {
                text: "Export SSH key"
                color: Style.colors.foreground
                font.pointSize: Style.appFont.h3Pt
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "\"" + root.targetKeyName + "\" — the public key (.pub) will be saved to the folder you choose. It is safe to share."
                color: Style.colors.mutedText
                font.pointSize: Style.appFont.defaultPt
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            CheckBox {
                id: includePrivateBox
                text: "Also export the private key"
                checked: root.includePrivate
                onToggled: root.includePrivate = checked
                contentItem: Text {
                    leftPadding: includePrivateBox.indicator.width + 8
                    text: includePrivateBox.text
                    color: Style.colors.foreground
                    font.pointSize: Style.appFont.defaultPt
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Text {
                visible: root.includePrivate
                text: "Warning: anyone with the private key can sign in as you on every host it is registered with. Only export it to a place you trust, such as a backup drive or your own new machine."
                color: Style.colors.deletededFile
                font.pointSize: Style.appFont.secondaryPt
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 8
                Layout.fillWidth: true
                Layout.topMargin: 4

                Button {
                    id: exportCancelBtn
                    text: "Cancel"
                    Layout.fillWidth: true
                    flat: true

                    background: Rectangle {
                        implicitHeight: 38
                        color: exportCancelBtn.hovered ? Style.colors.controlBackgroundHover : "transparent"
                        border.color: Style.colors.accent
                        border.width: 1
                        radius: 5
                    }

                    contentItem: Text {
                        text: exportCancelBtn.text
                        color: Style.colors.foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.mediumPt
                    }

                    onClicked: root.close()
                }

                Button {
                    id: exportChooseBtn
                    text: "Choose folder …"
                    Layout.fillWidth: true
                    flat: true

                    background: Rectangle {
                        implicitHeight: 38
                        color: exportChooseBtn.hovered
                               ? Style.colors.accent
                               : Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.2)
                        border.color: Style.colors.accent
                        border.width: 1
                        radius: 5
                    }

                    contentItem: Text {
                        text: exportChooseBtn.text
                        color: exportChooseBtn.hovered ? "#ffffff" : Style.colors.accent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.mediumPt
                        font.bold: true
                    }

                    onClicked: {
                        root.close()
                        root.chooseFolderRequested()
                    }
                }
            }
        }
    }
}
