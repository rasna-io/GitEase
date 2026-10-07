import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * AddEditRemotePopup
 * ************************************************************************************************/

PopupDialog {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property RemoteController       remoteController
    property NotificationController notificationController: null

    property var              oldRemote:    null

    property bool             isEdit:       oldRemote !== null

    property bool             fetchAfterAdd: true

    //! How the remote authenticates. Unused until the Auth section can be shown, see its TODO.
    property string           authMethod:   "none"

    readonly property var     remoteNameSuggestions: ["origin", "upstream", "fork"]

    readonly property bool    isNameValid: nameInput.text.trim().length > 0

    readonly property bool    isUrlValid:  urlInput.text.match(/^(https?|git|ssh):\/\/|^(git@)/)

    readonly property bool    canAccept:   isNameValid && isUrlValid

    /* Object Properties
     * ****************************************************************************************/
    width: 380
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    title: root.isEdit ? "Edit Remote" : "Add Remote"
    iconText: Style.icons.cloud
    iconColor: Style.colors.accent

    onAboutToShow: {
        if (isEdit) {
            nameInput.text = oldRemote.name
            urlInput.text = oldRemote.url
        }
    }

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
            text: "NAME"
            color: Style.colors.popupSectionLabel
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.defaultPt
        }

        TextField {
            id: nameInput
            placeholderText: "origin"
            Layout.fillWidth: true
            selectByMouse: true
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.defaultPt
            color: Style.colors.popupInputText
            leftPadding: 10
            rightPadding: 10
            topPadding: 7
            bottomPadding: 7
            Layout.bottomMargin: 6

            background: Rectangle {
                implicitHeight: 26
                color: Style.colors.popupInputBackground
                radius: 5
                border.color: nameInput.activeFocus ? Style.colors.popupInputBorderFocus
                                                    : Style.colors.popupInputBorder
                border.width: 1
            }
        }

        RowLayout {
            spacing: 5
            Layout.fillWidth: true

            Repeater {
                model: root.remoteNameSuggestions

                Rectangle {
                    id: chip
                    required property string modelData
                    radius: 4
                    color: Style.colors.popupChipBackground
                    border.color: Style.colors.popupChipBorder
                    border.width: 1
                    implicitWidth: chipText.implicitWidth + 12
                    implicitHeight: 22

                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: chip.modelData
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.popupChipText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: nameInput.text = chip.modelData
                    }
                }
            }
        }
    }

                    background: Rectangle {
                        implicitHeight: 40
                        color: Style.colors.secondaryBackground
                        radius: 5
                        // Turns Red if user has typed something invalid
                        border.color: (urlInput.text.length > 0 && !root.isUrlValid)
                                      ? Style.colors.error
                                      : (urlInput.activeFocus ? Style.colors.accent : "transparent")
                    }
                }

                Text {
                    text: "Invalid URL format"
                    color: Style.colors.error
                    font.pixelSize: Style.appFont.smallPt
                    visible: urlInput.text.length > 0 && !root.isUrlValid
                    Layout.leftMargin: 5
                }

                CommandPreview {
                    Layout.fillWidth: true
                    Layout.topMargin: 4

                    placeholder: root.isEdit ? qsTr("Change the name or URL to see the command")
                                             : qsTr("Fill in the name and URL to see the command")
                    command: root.previewCommand()
                }
            }

            RowLayout {
                spacing: 8
                Layout.fillWidth: true

                Button {
                    text: "Cancel"
                    Layout.preferredWidth: 100
                    onClicked: root.close()
                    Material.foreground: Style.colors.foreground

                    background: Rectangle {
                        implicitHeight: 35
                        color: parent.hovered ? "#33ffffff" : "transparent"
                        border.color: Style.colors.accent
                        radius: 5
                    }
                }

                Button {
                    id: actionBtn
                    text: root.isEdit ? "Save" : "Add Remote"
                    Layout.fillWidth: true
                    enabled: root.canAccept

                    opacity: enabled ? 1.0 : 0.5
                    Material.foreground: Style.colors.textButton

                    background: Rectangle {
                        implicitHeight: 35
                        color: actionBtn.enabled ? (actionBtn.hovered) ? Style.colors.accentHover : Style.colors.accent
                                                    : (Style.colors.disabledButton)
                        border.color: Style.colors.accent
                        radius: 5
                    }

                    onClicked: {
                        let res;
                        if (root.isEdit) {
                            res = root.remoteController.editRemote(root.oldRemote.name, nameInput.text.trim(), urlInput.text.trim());
                        } else {
                            res = root.remoteController.addRemote(nameInput.text.trim(), urlInput.text.trim());
                        }

                        if (res.success) {
                            if (notificationController) {
                                let action = root.isEdit ? "updated" : "added"
                                notificationController.success("Remote '" + nameInput.text + "' " + action + " successfully", "Remote", 3000)
                            }
                            root.close();
                        } else {
                            if (notificationController) {
                                let action = root.isEdit ? "update" : "add"
                                notificationController.error(res.errorMessage || "Failed to " + action + " remote", "Remote Error", 5000)
                            }
                        }
                    }
                }
            }
        }
    }

    function previewCommand() {
        let name = nameInput.text.trim()
        let url  = urlInput.text.trim()

        if (!root.isEdit)
            return (name === "" || url === "") ? "" : GitCommandText.addRemote(name, url)

        let steps = []

        if (name !== "" && name !== root.oldRemote.name)
            steps.push(GitCommandText.renameRemote(root.oldRemote.name, name))

        if (url !== "" && url !== root.oldRemote.url)
            steps.push(GitCommandText.setRemoteUrl(name !== "" ? name : root.oldRemote.name, url))

        return steps.join(" && ")
    }

    onAboutToHide: {
        nameInput.text = "";
        urlInput.text = "";
        root.oldRemote = null;
    }
}
