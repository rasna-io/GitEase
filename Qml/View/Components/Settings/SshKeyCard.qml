import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SshKeyCard
 * SSH key-management panel used inside the Settings → SSH tab.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property SshKeyController       sshKeyController

    property          NotificationController notificationController:   null

    property          UserProfile            currentUserProfile:       null


    /* Object Properties
     * ****************************************************************************************/

    implicitHeight: content.implicitHeight

    // Hidden TextEdit used solely for clipboard copy
    TextEdit {
        id: clipboardHelper
        visible: false
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 4


        ButtonItem {
            id: generateBtn
            Layout.fillWidth: true
            title: "SSH Key"
            description: "Generate and manage your SSH key pair for authenticating with remote Git hosts."
            enabled: !root.sshKeyController.isGenerating
            buttonTitle: {
                if (root.sshKeyController.isGenerating)
                    return "Generating…"
                return "Generate New Key"
            }
            busy: root.sshKeyController.isGenerating
            onClicked:  {
                let keyComment = root.currentUserProfile?.email ?? ""

                doGenerateKey(keyComment)
            }

        }

        Text {
            visible: root.sshKeyController.allKeys.length > 0
            Layout.fillWidth: true
            Layout.topMargin: 10
            text: "Available Keys"
            font.pointSize: Style.appFont.h4Pt
            color: Style.colors.foreground
        }
        Item {
            Layout.fillHeight: listView.count > 0 ? false : true
        }

        ListView {
            id: listView
            visible: root.sshKeyController.allKeys.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.sshKeyController.allKeys
            spacing: 8
            clip: true
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            delegate: Rectangle {
                width: ListView.view.width - 16
                implicitHeight: keyItemCol.implicitHeight + 16
                radius: 6
                color: Style.colors.surfaceLight
                border.color: Style.colors.primaryBorder
                border.width: 1

                ColumnLayout {
                    id: keyItemCol
                    width: parent.width - 16
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 8
                    }
                    spacing: 4

                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true

                        Text {
                            text: modelData.name
                            font.pointSize: Style.appFont.h4Pt
                            font.bold: true
                            color: Style.colors.foreground
                            Layout.fillWidth: true
                        }

                        ActionIconButton {
                            id: copyKeyBtn
                            iconText: copyKeyBtn._copied ? "✓" : Style.icons.copy
                            tooltip: copyKeyBtn._copied ? "Copied!" : "Copy Public Key"
                            textColor: copyKeyBtn._copied ? "#4caf50" : Style.colors.accent
                            width: 24
                            height: 24

                            property bool _copied: false

                            Timer {
                                id: copyKeyResetTimer
                                interval: 2000
                                onTriggered: copyKeyBtn._copied = false
                            }

                            onClicked: {
                                clipboardHelper.text = modelData.publicKeyContent
                                clipboardHelper.selectAll()
                                clipboardHelper.copy()
                                copyKeyBtn._copied = true
                                copyKeyResetTimer.restart()
                                if (root.notificationController) {
                                    root.notificationController.success(
                                        "Public key copied to clipboard", "SSH Key", 2500)
                                }
                            }
                        }

                        ActionIconButton {
                            iconText: Style.icons.trash
                            tooltip: "Delete SSH Key"
                            textColor: Style.colors.deletededFile
                            width: 24
                            height: 24

                            onClicked: {
                                deleteKeyDialog.targetKeyName = modelData.name
                                deleteKeyDialog.open()
                            }
                        }
                    }

                    RowLayout {
                        spacing: 6
                        Layout.fillWidth: true
                        visible: modelData.fingerprint.length > 0

                        Text {
                            text: "Fingerprint:"
                            font.pointSize: Style.appFont.secondaryPt
                            color: Style.colors.mutedText
                            Layout.preferredWidth: 70
                        }

                        Text {
                            text: modelData.fingerprint
                            font.pointSize: Style.appFont.secondaryPt
                            font.family: "Courier New"
                            color: Style.colors.foreground
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        spacing: 6
                        Layout.fillWidth: true

                        Text {
                            text: "Path:"
                            font.pointSize: Style.appFont.secondaryPt
                            color: Style.colors.mutedText
                            Layout.preferredWidth: 70
                        }

                        Text {
                            text: modelData.privateKeyPath
                            font.pointSize: Style.appFont.secondaryPt
                            font.family: "Courier New"
                            color: Style.colors.secondaryText
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    IPopup {
        id: deleteKeyDialog
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        width: 380
        height: 240

        parent: Overlay.overlay
        x: Overlay.overlay ? Math.round((Overlay.overlay.width - width) / 2) : 0
        y: Overlay.overlay ? Math.round((Overlay.overlay.height - height) / 2) : 0

        padding: 0

        property string targetKeyName: ""

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
                    text: "Are you sure you want to delete this SSH key?\n\n\"" + deleteKeyDialog.targetKeyName + "\"\n\nThis action cannot be undone."
                    color: Style.colors.mutedText
                    font.pointSize: Style.appFont.defaultPt
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
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
                            color: parent.hovered ? "#33ffffff" : "transparent"
                            border.color: Style.colors.accent
                            border.width: 1
                            radius: 5
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Style.colors.foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 12
                        }

                        onClicked: deleteKeyDialog.close()
                    }

                    Button {
                        id: deleteConfirmBtn
                        text: "Delete"
                        Layout.fillWidth: true
                        flat: true

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
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 12
                            font.bold: true
                        }

                        onClicked: {
                            doDeleteKey(deleteKeyDialog.targetKeyName)
                            deleteKeyDialog.close()
                        }
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function doGenerateKey(keyComment) {
        const result = root.sshKeyController.generateKey(keyComment)
        if (result.success) {
            if (root.notificationController)
                root.notificationController.success(
                    "SSH key generated. Copy the public key and add it to your remote host.",
                    "SSH Key", 5000)
        } else {
            if (root.notificationController)
                root.notificationController.error(
                    result.errorMessage || "Failed to generate SSH key",
                    "SSH Key Error", 6000)
        }
    }

    function doDeleteKey(keyName) {
        const result = root.sshKeyController.deleteKeyByName(keyName)
        if (result.success) {
            if (root.notificationController)
                root.notificationController.success("SSH key deleted.", "SSH Key", 3000)
        } else {
            if (root.notificationController)
                root.notificationController.error(
                    result.errorMessage || "Failed to delete SSH key",
                    "SSH Key Error", 5000)
        }
    }
}
