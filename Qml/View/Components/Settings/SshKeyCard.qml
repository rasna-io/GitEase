import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SshKeyCard
 * One SSH key in the key list: name (renameable), type, copy / export / delete actions, the
 * "Use for" host chips and the key's comment, fingerprint and path.
 *
 * The card only reports what the user asked for through its signals; SshSection performs the
 * actions and shows the notifications.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property var keyData

    /* Signals
     * ****************************************************************************************/
    signal renameRequested(string oldName, string newName)
    signal copyRequested(string publicKey)
    signal exportRequested(string keyName)
    signal deleteRequested(string keyName)
    signal assignRequested(string provider, string label, string keyName, bool currentlyAssigned)

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: keyItemCol.implicitHeight + 28
    radius: 10
    color: keyHover.hovered ? Style.colors.controlBackgroundHover
                            : Style.colors.controlBackground
    border.color: keyHover.hovered ? Style.colors.controlBorderHover
                                   : Style.colors.controlBorder
    border.width: 1

    property bool editing: false
    readonly property var parts: (root.keyData.publicKeyContent || "").split(" ")
    readonly property string keyType: {
        const t = parts[0] || ""
        if (t.startsWith("ssh-"))
            return t.substring(4).toUpperCase()
        if (t.startsWith("ecdsa-"))
            return "ECDSA"
        if (t.startsWith("sk-"))
            return "SECURITY KEY"
        return t.toUpperCase()
    }
    readonly property var providers: root.keyData.providers || []
    readonly property bool isDefault: root.keyData.isActive
    readonly property Item copyButtonItem: copyKeyBtn
    readonly property Item chipsItem: chipsRow
    readonly property string keyComment: parts.length > 2 ? parts.slice(2).join(" ") : ""

    function startEdit() {
        nameInput.text = root.keyData.name
        editing = true
        nameInput.forceActiveFocus()
        nameInput.selectAll()
    }

    function commitEdit() {
        if (!editing)
            return
        editing = false
        if (nameInput.text.trim() !== root.keyData.name)
            root.renameRequested(root.keyData.name, nameInput.text)
    }

    Behavior on color        {
        ColorAnimation {
            duration: 150
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration: 150
        }
    }

    HoverHandler { id: keyHover }

    ColumnLayout {
        id: keyItemCol

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 14
        }
        spacing: 8

        RowLayout {
            spacing: 8
            Layout.fillWidth: true

            Text {
                visible: !root.editing
                text: root.keyData.name
                font.pointSize: Style.appFont.h4Pt
                font.bold: true
                color: Style.colors.foreground
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            TextField {
                id: nameInput
                visible: root.editing
                Layout.fillWidth: true
                color: Style.colors.foreground
                font.pixelSize: Style.appFont.defaultPt
                font.family: Style.fontTypes.jetBrainsMono
                selectByMouse: true
                maximumLength: 64
                background: Rectangle {
                    implicitHeight: 30
                    radius: 5
                    color: Style.colors.secondaryBackground
                    border.width: 1
                    border.color: Style.colors.accent
                }
                onAccepted: root.commitEdit()
                Keys.onEscapePressed: root.editing = false
            }

            Rectangle {
                visible: !root.editing && root.keyType.length > 0
                implicitWidth: typeText.implicitWidth + 12
                implicitHeight: typeText.implicitHeight + 4
                radius: 4
                color: Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.15)

                Text {
                    id: typeText
                    anchors.centerIn: parent
                    text: root.keyType
                    font.pointSize: Style.appFont.secondaryPt
                    font.bold: true
                    color: Style.colors.accent
                }
            }

            ActionIconButton {
                iconText: root.editing ? Style.icons.check : Style.icons.edit
                tooltip: root.editing ? "Save name" : "Rename Key"
                textColor: Style.colors.accent
                width: 24
                height: 24
                onClicked: root.editing ? root.commitEdit() : root.startEdit()
            }

            ActionIconButton {
                id: copyKeyBtn
                iconText: copyKeyBtn._copied ? "✓" : Style.icons.copy
                tooltip: copyKeyBtn._copied ? "Copied!" : "Copy Public Key"
                textColor: copyKeyBtn._copied ? Style.colors.notificationSuccessIcon : Style.colors.accent
                width: 24
                height: 24

                property bool _copied: false

                Timer {
                    id: copyKeyResetTimer
                    interval: 2000
                    onTriggered: copyKeyBtn._copied = false
                }

                onClicked: {
                    copyKeyBtn._copied = true
                        copyKeyResetTimer.restart()
                        root.copyRequested(root.keyData.publicKeyContent)
                }
            }

            ActionIconButton {
                iconText: Style.icons.upload
                tooltip: "Export Key"
                textColor: Style.colors.accent
                width: 24
                height: 24

                onClicked: {
                    root.exportRequested(root.keyData.name)
                }
            }

            ActionIconButton {
                iconText: Style.icons.trash
                tooltip: "Delete SSH Key"
                textColor: Style.colors.deletededFile
                width: 24
                height: 24

                onClicked: {
                    root.deleteRequested(root.keyData.name)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Style.colors.controlBorder
            opacity: 0.6
        }

        // Per-host assignment: remotes on GitHub / GitLab use the key assigned to them
        RowLayout {
            id: chipsRow
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Use for"
                font.pointSize: Style.appFont.secondaryPt
                color: Style.colors.mutedText
                Layout.preferredWidth: 80
            }

            Repeater {
                model: [
                    { provider: "github", label: "GitHub" },
                    { provider: "gitlab", label: "GitLab" },
                    { provider: "",       label: "Other hosts" }
                ]

                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    // "" = every host without its own key (the default key)
                    readonly property bool assigned: modelData.provider === ""
                        ? root.isDefault
                        : root.providers.indexOf(modelData.provider) >= 0

                    implicitWidth: chipText.implicitWidth + 20
                    implicitHeight: chipText.implicitHeight + 8
                    radius: height / 2
                    color: assigned
                           ? Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.2)
                           : (chipArea.containsMouse ? Style.colors.controlBackgroundHover : "transparent")
                    border.width: 1
                    border.color: assigned ? Style.colors.accent : Style.colors.controlBorder

                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: (chip.assigned ? "✓ " : "") + chip.modelData.label
                        font.pointSize: Style.appFont.secondaryPt
                        font.bold: chip.assigned
                        color: chip.assigned ? Style.colors.accent : Style.colors.mutedText
                    }

                    MouseArea {
                        id: chipArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        ToolTip.visible: containsMouse && chip.modelData.provider === ""
                        ToolTip.delay: 400
                        ToolTip.text: "Used for every remote that has no key of its own"
                        onClicked: root.assignRequested(chip.modelData.provider,
                                                         chip.modelData.label,
                                                         root.keyData.name,
                                                         chip.assigned)
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 4

            Text {
                visible: root.keyComment.length > 0
                text: "Comment"
                font.pointSize: Style.appFont.secondaryPt
                color: Style.colors.mutedText
                Layout.preferredWidth: 80
            }
            Text {
                visible: root.keyComment.length > 0
                text: root.keyComment
                font.pointSize: Style.appFont.secondaryPt
                color: Style.colors.foreground
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: root.keyData.fingerprint.length > 0
                text: "Fingerprint"
                font.pointSize: Style.appFont.secondaryPt
                color: Style.colors.mutedText
                Layout.preferredWidth: 80
            }
            Text {
                visible: root.keyData.fingerprint.length > 0
                text: root.keyData.fingerprint
                font.pointSize: Style.appFont.secondaryPt
                font.family: Style.fontTypes.jetBrainsMono
                color: Style.colors.foreground
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }

            Text {
                text: "Path"
                font.pointSize: Style.appFont.secondaryPt
                color: Style.colors.mutedText
                Layout.preferredWidth: 80
            }
            Text {
                text: root.keyData.privateKeyPath
                font.pointSize: Style.appFont.secondaryPt
                font.family: Style.fontTypes.jetBrainsMono
                color: Style.colors.secondaryText
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
        }
    }
}
