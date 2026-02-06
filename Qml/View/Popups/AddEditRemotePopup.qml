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
    property RemoteController remoteController

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
                font.pixelSize: 16
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
                    font.pixelSize: 10
                    visible: urlInput.text.length > 0 && !root.isUrlValid
                    Layout.leftMargin: 5
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
                    text: root.isEdit ? "Update" : "Add"
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
                        let res;
                        if (root.isEdit) {
                            res = root.remoteController.editRemote(root.oldRemote.name, nameInput.text.trim(), urlInput.text.trim());
                        } else {
                            res = root.remoteController.addRemote(nameInput.text.trim(), urlInput.text.trim());
                        }

                        if (res.success) {
                            root.close();
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
