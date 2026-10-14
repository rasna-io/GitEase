import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SshKeyNamePopup
 * Prompts for a key name, with a clickable suggestion. Used both when generating a new key and
 * when importing an existing one (see openForGenerate() / openForImport()).
 * ************************************************************************************************/
IPopup {
    id: root
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    width: 400
    height: dialogCol.implicitHeight + 40

    padding: 0

    property SshKeyController sshKeyController: null

    signal generateRequested(string keyName)
    signal importRequested(string source, string keyName)

    property string suggestion: ""
    property string mode: "generate"       // "generate" | "import"
    property string importSource: ""
    readonly property bool importing: mode === "import"
    readonly property string typedName: nameField.text.trim()
    readonly property string nameError:
        typedName.length > 0 ? root.sshKeyController.keyNameError(typedName) : ""
    readonly property bool canGenerate:
        typedName.length > 0 && nameError.length === 0

    onAboutToShow: {
        suggestion = importing
                     ? root.sshKeyController.suggestedImportName(importSource)
                     : root.sshKeyController.suggestedKeyName()
        nameField.text = ""
    }
    onOpened: nameField.forceActiveFocus()

    function openForGenerate() {
        mode = "generate"
        importSource = ""
        open()
    }

    function openForImport(source) {
        mode = "import"
        importSource = source
        open()
    }

    function submit() {
        if (!canGenerate)
            return
        const name = typedName
        const source = importSource
        const isImport = importing
        close()
        if (isImport)
            root.importRequested(source, name)
        else
            root.generateRequested(name)
    }

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
            id: dialogCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 20
            }
            spacing: 12

            Text {
                text: root.importing ? "Name the imported key" : "Name your new SSH key"
                color: Style.colors.foreground
                font.pointSize: Style.appFont.h3Pt
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: root.importing
                      ? "The key will be copied into ~/.ssh under this name. The original file is left untouched."
                      : "A name helps you tell your keys apart, e.g. work-gitlab or personal-github."
                color: Style.colors.mutedText
                font.pointSize: Style.appFont.defaultPt
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            TextField {
                id: nameField
                Layout.fillWidth: true
                placeholderText: "Key name"
                color: Style.colors.foreground
                font.family: Style.fontTypes.jetBrainsMono
                font.pixelSize: Style.appFont.defaultPt
                selectByMouse: true
                maximumLength: 64
                background: Rectangle {
                    implicitHeight: 36
                    radius: 5
                    color: Style.colors.controlBackground
                    border.width: 1
                    border.color: root.nameError.length > 0
                                  ? Style.colors.deletededFile
                                  : (nameField.activeFocus ? Style.colors.accent
                                                           : Style.colors.controlBorder)
                }
                onAccepted: root.submit()
            }

            // Tapping the suggestion fills the field
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.suggestion.length > 0
                         && root.typedName !== root.suggestion

                Text {
                    text: "Suggestion:"
                    font.pointSize: Style.appFont.secondaryPt
                    color: Style.colors.mutedText
                }

                Rectangle {
                    implicitWidth: suggestionText.implicitWidth + 20
                    implicitHeight: suggestionText.implicitHeight + 8
                    radius: height / 2
                    color: suggestionArea.containsMouse
                           ? Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.25)
                           : Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.12)
                    border.width: 1
                    border.color: Style.colors.accent

                    Text {
                        id: suggestionText
                        anchors.centerIn: parent
                        text: root.suggestion
                        font.pointSize: Style.appFont.secondaryPt
                        font.family: Style.fontTypes.jetBrainsMono
                        color: Style.colors.accent
                    }

                    MouseArea {
                        id: suggestionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            nameField.text = root.suggestion
                            nameField.forceActiveFocus()
                            nameField.cursorPosition = nameField.text.length
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Text {
                visible: root.nameError.length > 0
                text: root.nameError
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
                    id: genCancelBtn
                    text: "Cancel"
                    Layout.fillWidth: true
                    flat: true

                    background: Rectangle {
                        implicitHeight: 38
                        color: genCancelBtn.hovered ? Style.colors.controlBackgroundHover : "transparent"
                        border.color: Style.colors.accent
                        border.width: 1
                        radius: 5
                    }

                    contentItem: Text {
                        text: genCancelBtn.text
                        color: Style.colors.foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.mediumPt
                    }

                    onClicked: root.close()
                }

                Button {
                    id: genConfirmBtn
                    text: root.importing ? "Import" : "Generate"
                    Layout.fillWidth: true
                    flat: true
                    enabled: root.canGenerate
                    opacity: enabled ? 1.0 : 0.4

                    background: Rectangle {
                        implicitHeight: 38
                        color: genConfirmBtn.hovered && genConfirmBtn.enabled
                               ? Style.colors.accent
                               : Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.2)
                        border.color: Style.colors.accent
                        border.width: 1
                        radius: 5
                    }

                    contentItem: Text {
                        text: genConfirmBtn.text
                        color: genConfirmBtn.hovered && genConfirmBtn.enabled ? "#ffffff" : Style.colors.accent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.mediumPt
                        font.bold: true
                    }

                    onClicked: root.submit()
                }
            }
        }
    }
}
