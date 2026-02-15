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
                    font.pixelSize: 13
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
            }

            Rectangle {
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
                        Layout.preferredWidth: 200
                        Layout.fillHeight: true
                        clip: true
                        model: stashFiles

                        delegate: Rectangle {
                            width: parent.width
                            height: 22
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
                                    font.pixelSize: 11
                                    Layout.preferredWidth: 18
                                }

                                Text {
                                    text: modelData.path || ""
                                    color: Style.colors.foreground
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 15
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

            CheckboxItem {
                id: keepIndexCheckBox
                Layout.fillWidth: false
                title: "Keep staged changes in index"
                description: "Preserves staged changes and stashes only working directory modifications."
                checked: false
            }

            RowLayout {
                spacing: 8
                Layout.fillWidth: true



                Button {
                    Layout.fillWidth: true
                    implicitHeight: 38

                    background: Rectangle {
                        radius: 8
                        color: Style.colors.accent
                    }

                    contentItem: Item {
                        anchors.fill: parent
                        Row {
                            spacing: 10
                            anchors.centerIn: parent

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Cancel"
                                color: Style.colors.secondaryForeground
                                font.pixelSize: 13
                            }
                        }
                    }

                    onClicked: root.close()
                }

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 38

                    background: Rectangle {
                        radius: 8
                        color: Style.colors.accent
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
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Stash"
                                color: Style.colors.secondaryForeground
                                font.pixelSize: 13
                            }
                        }
                    }

                    onClicked: {
                        let message = stashMessageField.text.trim()
                        let keepIndex = keepIndexCheckBox.checked
                        let result = stashController.save(message, keepIndex)
                        if (result.success) {
                            if (notificationController) {
                                notificationController.success("Changes stashed successfully", "Stash", 3000)
                            }
                            stashMessageField.text = ""
                            keepIndexCheckBox.checked = false
                            selectedFilePath = ""
                            stashDiffData = []
                            stashFiles = []
                            root.close()

                        } else {
                            if (notificationController) {
                                notificationController.error(result.errorMessage || "Failed to stash changes", "Stash Error", 5000)
                            }
                        }

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
