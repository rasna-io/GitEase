import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * AddEditRemotePopup
 * ************************************************************************************************/

IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property RemoteController       remoteController
    property NotificationController notificationController: null

    property var              oldRemote:    null

    property bool             isEdit:       oldRemote !== null

    readonly property bool    isNameValid: nameInput.text.trim().length > 0

    readonly property bool    isUrlValid:  urlInput.text.match(/^(https?|git|ssh):\/\/|^(git@)/)

    readonly property bool    canAccept:   isNameValid && isUrlValid

    /* Object Properties
     * ****************************************************************************************/

    width: 360
    height: 320
    padding: 20

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
                text: root.isEdit ? "Edit Remote" : "Add Remote"
                color: Style.colors.foreground
                font.family: Style.fontTypes.roboto
                font.bold: true
                font.pixelSize: Style.appFont.h2Pt
                Layout.alignment: Qt.AlignHCenter
            }

            ColumnLayout {
                spacing: 12
                Layout.fillWidth: true

                // Name Input
                TextField {
                    id: nameInput
                    placeholderText: "Remote Name (e.g. origin)"
                    Layout.fillWidth: true
                    selectByMouse: true

                    background: Rectangle {
                        implicitHeight: 40
                        color: Style.colors.secondaryBackground
                        radius: 5
                        border.color: nameInput.activeFocus ? Style.colors.accent : "transparent"
                    }
                }

                // URL Input with visual validation feedback
                TextField {
                    id: urlInput
                    placeholderText: "Remote URL (HTTPS or SSH)"
                    Layout.fillWidth: true
                    selectByMouse: true

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
                    text: root.isEdit ? "Update" : "Add"
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

    onAboutToHide: {
        nameInput.text = "";
        urlInput.text = "";
        root.oldRemote = null;
    }
}
