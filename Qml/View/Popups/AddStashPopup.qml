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
    property StashController        stashController:        null
    property NotificationController notificationController: null
    property StatusController       statusController:       null

    readonly property bool    isNameValid: true

    readonly property bool    canAccept:   isNameValid

    /* Object Properties
     * ****************************************************************************************/
    width: 800
    height: 650
    padding: 12

    property var stashFiles: []
    property string selectedFilePath: ""
    property var stashDiffData: []

    onOpened: {
        loadFiles()
    }

    /* Children
     * ****************************************************************************************/

    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            spacing: 8
            anchors.fill: parent
            anchors.margins: 20

            RowLayout{
                Text {
                    text: "Stash Message (Optional)"
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 13
                    font.bold: true
                    color: Style.colors.foreground
                }

                TextField {
                    id: stashMessageField
                    Layout.preferredWidth: 200
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

                Item {
                    Layout.fillWidth: true
                }

                // Close Button
                WindowsButton {
                    id: closeButton

                    Material.accent: Style.colors.windowsClose
                    content: Item {
                        anchors.centerIn: parent
                        width: 10
                        height: 10

                        Rectangle {
                            width: 12
                            height: 2
                            radius: 1
                            color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                            anchors.centerIn: parent
                            rotation: 45
                        }

                        Rectangle {
                            width: 12
                            height: 2
                            radius: 1
                            color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                            anchors.centerIn: parent
                            rotation: -45
                        }
                    }
                    onClicked: root.close()
                }
            }

            RowLayout{
                Layout.fillWidth: true
                spacing: 8

                CheckBox {
                    id: keepIndexCheckBox
                    Layout.fillWidth: false
                    text: "Keep staged changes in index"
                    checked: true

                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 12

                    Material.accent: Style.colors.accent

                    palette {
                        text: Style.colors.foreground
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                ActionIconButton {
                    iconText: Style.icons.plus
                    tooltip: "Create"
                    textColor: Style.colors.accent

                    onClicked: {
                        let message = stashMessageField.text.trim()
                        let keepIndex = keepIndexCheckBox.checked
                        let result = stashController.save(message, keepIndex)
                        if (result.success) {
                            stashMessageField.text = ""
                            keepIndexCheckBox.checked = false
                            selectedFilePath = ""
                            stashDiffData = []
                            stashFiles = []
                            root.close()

                        }

                    }
                }

            }

            Rectangle {
                Layout.topMargin: 10
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 6
                color: Style.colors.secondaryBackground
                border.width: 1
                border.color: Style.colors.primaryBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    ListView {
                        id: fileList
                        Layout.preferredWidth: 240
                        Layout.fillHeight: true
                        clip: true
                        model: stashFiles

                        delegate: Rectangle {
                            width: parent.width
                            height: 24
                            radius: 3
                            color: (selectedFilePath === modelData.path) ? Style.colors.hoverTitle : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 6

                                Text {
                                    text: statusLabel(modelData)
                                    color: Style.colors.mutedText
                                    font.pixelSize: 8
                                    Layout.preferredWidth: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    font.bold: true
                                }

                                Text {
                                    text: modelData.path || ""
                                    color: Style.colors.foreground
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                    elide: Text.ElideMiddle
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: selectFile(modelData)
                            }
                        }
                    }

                    DiffView {
                        id: diffView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        readOnly: true
                        diffData: root.stashDiffData
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/

    function loadFiles() {
        stashFiles = []
        stashDiffData = []
        selectedFilePath = ""

        if (!statusController)
            return

        let res = statusController.status()
        if (!res.success)
            return

        let filtered = []
        res.data.forEach((file) => {
            if (file.isStaged || file.isUnstaged || file.isUntracked) {
                filtered.push(file)
            }
        })
        stashFiles = filtered

        if (stashFiles.length > 0) {
            selectFile(stashFiles[0])
        }
    }

    function selectFile(file) {
        selectedFilePath = file.path
        stashDiffData = []

        if (!statusController || !selectedFilePath)
            return

        let res = statusController.getDiffView(selectedFilePath, !!file.isStaged)

        if (res.success) {
            stashDiffData = res.data.lines  // Use the lines for DiffView
        }
    }


    function statusLabel(fileOrDelta) {
        if (fileOrDelta.isStaged)
            return "S"
        if (fileOrDelta.isUntracked)
            return "U"
        return "M"
    }
}
