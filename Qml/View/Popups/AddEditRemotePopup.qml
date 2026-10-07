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

    readonly property bool    showUrlError: urlInput.text.length > 0 && !root.isUrlValid

    readonly property var     urlParts:    root.isUrlValid ? root.parseRemoteUrl(urlInput.text.trim()) : null

    readonly property int     elementSpacing: 2

    /* Signals
     * ****************************************************************************************/
    signal remoteAdded(string name, bool fetchNow)

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

    onOpened: nameInput.forceActiveFocus()

    onAboutToHide: {
        nameInput.text = "";
        urlInput.text = "";
        root.oldRemote = null;
        root.fetchAfterAdd = true;
        root.authMethod = "none";
    }

    /* Children
     * ****************************************************************************************/
    // Remote name
    ColumnLayout {
        spacing: root.elementSpacing
        Layout.fillWidth: true

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

    // Remote URL
    ColumnLayout {
        spacing: root.elementSpacing
        Layout.fillWidth: true

        Text {
            text: "URL"
            color: Style.colors.popupSectionLabel
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.defaultPt
        }

        TextField {
            id: urlInput
            placeholderText: "https://github.com/owner/repo.git"
            Layout.fillWidth: true
            selectByMouse: true
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.defaultPt
            color: Style.colors.popupInputText
            leftPadding: 10
            rightPadding: 10
            topPadding: 7
            bottomPadding: 7

            background: Rectangle {
                implicitHeight: 26
                color: Style.colors.popupInputBackground
                radius: 5
                // Red for something that is not a URL, green once Git can use it
                border.color: root.showUrlError     ? Style.colors.error
                            : root.isUrlValid       ? Style.colors.popupInputBorderValid
                            : urlInput.activeFocus  ? Style.colors.popupInputBorderFocus
                                                    : Style.colors.popupInputBorder
                border.width: 1
            }
        }

        // What a valid URL points at, or how to fix an invalid one
        RowLayout {
            Layout.topMargin: 3
            Layout.fillWidth: true
            visible: root.showUrlError || root.urlParts !== null
            spacing: 5

            Text {
                text: root.showUrlError ? Style.icons.circleExclamation : Style.icons.check
                font.family: Style.fontTypes.font6Pro
                font.styleName: "Solid"
                font.pixelSize: Style.appFont.captionPt
                color: root.showUrlError ? Style.colors.error : Style.colors.popupValidText
            }

            Text {
                Layout.fillWidth: true
                text: root.showUrlError ? "Use an http(s)://, ssh://, git:// or git@ URL"
                                        : root.urlSummary()
                color: root.showUrlError ? Style.colors.error : Style.colors.popupValidText
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.smallPt
                elide: Text.ElideMiddle
            }
        }
    }

    // Auth
    ColumnLayout {
        spacing: root.elementSpacing
        Layout.fillWidth: true

        visible: false
        // TODO: Let the user choose how this remote authenticates. Today GitEase picks the method
        //       from the URL when it fetches or pushes (SSH keys for ssh:// and git@ URLs, a token
        //       for https://) and nothing stores a choice per remote, so authMethod is unused.
        //       Show this section once the backend can keep and apply that choice.

        Text {
            text: "AUTH"
            color: Style.colors.popupSectionLabel
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.defaultPt
        }

        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true

            Repeater {
                model: [
                    { label: "None (public / SSH key in URL)",  value: "none" },
                    { label: "SSH Key",                         value: "ssh" },
                    { label: "Token",                           value: "token" }
                ]

                RowLayout {
                    id: authOption
                    required property var modelData
                    readonly property bool checked: root.authMethod === modelData.value
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: authOption.checked ? Style.colors.popupRadioBorderChecked : "transparent"
                        border.width: 1
                        border.color: authOption.checked ? Style.colors.popupRadioBorderChecked
                                                         : Style.colors.popupRadioBorder
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            anchors.centerIn: parent
                            width: 8
                            height: 8
                            radius: 4
                            color: Style.colors.popupRadioDot
                            visible: authOption.checked
                        }
                    }

                    Text {
                        text: authOption.modelData.label
                        color: Style.colors.popupCheckboxLabelText
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.defaultPt
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.authMethod = authOption.modelData.value
                    }
                }
            }
        }
    }

    // Separator
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        visible: !root.isEdit
        color: Style.colors.popupHeaderSeparator
    }

    // Fetch after adding
    RowLayout {
        id: fetchCheckBox
        readonly property bool checked: root.fetchAfterAdd

        visible: !root.isEdit
        spacing: 8
        Layout.fillWidth: true

        Rectangle {
            width: 16
            height: 16
            radius: 3
            color: fetchCheckBox.checked ? Style.colors.popupCheckboxBackgroundChecked : "transparent"
            border.color: fetchCheckBox.checked ? Style.colors.popupCheckboxBackgroundChecked
                                                : Style.colors.popupCheckboxBorder
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "\u2713"
                color: Style.colors.popupCheckboxCheckmark
                font.pixelSize: Style.appFont.smallPt
                visible: fetchCheckBox.checked
            }
        }

        Text {
            text: "Fetch immediately after adding"
            color: Style.colors.popupCheckboxLabelText
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.defaultPt
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.fetchAfterAdd = !root.fetchAfterAdd
        }
    }

    CommandPreview {
        Layout.fillWidth: true

        placeholder: root.isEdit ? qsTr("Change the name or URL to see the command")
                                 : qsTr("Fill in the name and URL to see the command")
        command: root.previewCommand()
    }

    actions: [
        PopupButton {
            text: "Cancel"
            onClicked: root.close()
        },

        PopupButton {
            tone: PopupButton.Primary
            text: root.isEdit ? "Save" : "Add Remote"
            enabled: root.canAccept
            onClicked: root.saveRemote()
        }
    ]

    /* Functions
     * ****************************************************************************************/
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

    function parseRemoteUrl(url) {
        let scheme = /^(https?|ssh|git):\/\/(?:[^@\/]+@)?([^\/:]+)(?::\d+)?\/?(.*)$/i.exec(url)
        let scp    = /^[^@\/\s]+@([^:\/\s]+):\/?(.*)$/.exec(url)

        let parts = scheme ? { host: scheme[2], path: scheme[3],
                               protocol: scheme[1].toLowerCase() === "git" ? "Git" : scheme[1].toUpperCase() }
                  : scp    ? { host: scp[1], path: scp[2], protocol: "SSH" }
                           : null

        if (!parts || parts.host === "")
            return null

        parts.path = parts.path.replace(/\/+$/, "").replace(/\.git$/i, "")
        return parts
    }

    //! "github.com · HTTPS · owner/repo" for the line under the URL field.
    function urlSummary() {
        if (!root.urlParts)
            return ""

        return [root.urlParts.host, root.urlParts.protocol, root.urlParts.path]
                .filter(part => part !== "")
                .join(" \u00b7 ")
    }

    function saveRemote() {
        let res;
        if (root.isEdit) {
            res = root.remoteController.editRemote(root.oldRemote.name, nameInput.text.trim(), urlInput.text.trim());
        } else {
            res = root.remoteController.addRemote(nameInput.text.trim(), urlInput.text.trim());
        }

        if (res.success) {
            if (root.notificationController) {
                let action = root.isEdit ? "updated" : "added"
                root.notificationController.success("Remote '" + nameInput.text + "' " + action + " successfully", "Remote", 3000)
            }

            // Closing resets the form, so keep what remoteAdded() needs first
            let addedName = root.isEdit ? "" : nameInput.text.trim()
            let fetchNow  = root.fetchAfterAdd

            root.close();

            if (addedName !== "")
                root.remoteAdded(addedName, fetchNow)
        } else {
            if (root.notificationController) {
                let action = root.isEdit ? "update" : "add"
                root.notificationController.error(res.errorMessage || "Failed to " + action + " remote", "Remote Error", 5000)
            }
        }
    }
}
