import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * AddBranchPopup
 * ************************************************************************************************/
PopupDialog {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property BranchController       branchController
    property NotificationController notificationController: null
    property string                 targetHash: ""
    property string                 baseBranchType: "remote"
    property string                 baseBranch: "main"

    readonly property var branchNameSuggestions: ["feature/", "fix/", "chore/"]

    readonly property bool    isNameValid: nameInput.text.trim().length > 0

    readonly property bool    canAccept:   isNameValid

    property RemoteOperationsSession remoteOperationsSession: typeof uiSession !== "undefined" && uiSession
                                                              ? uiSession.remoteOperationsSession : null

    readonly property var  remoteNames: (root.remoteOperationsSession?.remotes ?? []).map(remote => remote.name)
    readonly property bool canPublish:  root.remoteNames.length > 0

    //! Also create the branch on a remote and track it (git push -u). Kept between openings.
    property bool   publish:       false
    //! The remote to publish to; preselected from the default remote each time the popup opens.
    property string publishRemote: ""

    readonly property bool publishes: root.canPublish && root.publish && root.publishRemote !== ""

    signal branchCreatedSuccessfully()

    /* Object Properties
     * ****************************************************************************************/
    title: "Create Branch"
    iconText: Style.icons.gitBranch
    initialFocusItem: nameInput

    onAboutToShow: {
        root.remoteOperationsSession?.refreshTarget()
        let preferred = root.remoteOperationsSession?.preferredRemote() ?? ""
        root.publishRemote = preferred !== "" ? preferred : (root.remoteNames[0] ?? "")
    }

    onAboutToHide: {
        nameInput.text  = ""
        targetHash      = ""
        baseBranch      = "main"
        baseBranchType  = "remote"
    }

    /* Children
     * ****************************************************************************************/
    // Branch name
    ColumnLayout {
        spacing: root.elementSpacing
        Layout.fillWidth: true

        Text {
            text: "BRANCH NAME"
            color: Style.colors.popupSectionLabel
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.defaultPt
        }

        TextField {
            id: nameInput
            placeholderText: "feature/new-work"
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
                model: root.branchNameSuggestions

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

    // Based on
    ColumnLayout {
        spacing: root.elementSpacing
        Layout.fillWidth: true

        visible: false
        // TODO: Implement "Based on" feature – currently the baseBranch and
        //       baseBranchType are not used. Need GitBranch::createBranchFromBase()
        //       that creates a branch from a given base branch (local or remote).
        //       Until then, creation always happens from HEAD or the explicit targetHash.

        Text {
            text: "BASED ON"
            color: Style.colors.popupSectionLabel
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.defaultPt
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 26
            radius: 5
            color: Style.colors.popupBaseBranchBackground
            border.color: Style.colors.popupBaseBranchBorder
            border.width: 1
            Layout.bottomMargin: 7

            RowLayout {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.baseBranch
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.defaultPt
                    color: Style.colors.popupBaseBranchText
                }

                Text {
                    text: Style.icons.caretDown
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.appFont.extraSmallPt
                    color: Style.colors.popupRadioBorder
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
            }
        }

        RowLayout {
            spacing: 14
            Layout.fillWidth: true

            Repeater {
                model: [
                    { label: "Local branch", value: "local" },
                    { label: "Remote branch", value: "remote" }
                ]

                RowLayout {
                    id: baseTypeOption
                    readonly property bool checked: root.baseBranchType === modelData.value
                    spacing: 6
                    Layout.fillWidth: true

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: baseTypeOption.checked ? Style.colors.popupRadioBorderChecked : "transparent"
                        border.width: 1
                        border.color: baseTypeOption.checked ? Style.colors.popupRadioBorderChecked
                                                             : Style.colors.popupRadioBorder
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            anchors.centerIn: parent
                            width: 8
                            height: 8
                            radius: 4
                            color: Style.colors.popupRadioDot
                            visible: baseTypeOption.checked
                        }
                    }

                    Text {
                        text: modelData.label
                        color: Style.colors.popupCheckboxLabelText
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.defaultPt
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            root.baseBranchType = modelData.value
                        }
                    }
                }
            }
        }
    }

    // Checkboxes
    ColumnLayout {
        spacing: 8
        Layout.fillWidth: true

        // Checkout after creating
        RowLayout {
            id: checkoutCheckbox
            property bool checked: true

            spacing: 8
            Layout.fillWidth: true

            Rectangle {
                width: 16; height: 16
                radius: 3
                color: checkoutCheckbox.checked ? Style.colors.popupCheckboxBackgroundChecked : "transparent"
                border.color: checkoutCheckbox.checked ? Style.colors.popupCheckboxBackgroundChecked
                                                        : Style.colors.popupCheckboxBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: Style.icons.check
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    color: Style.colors.popupCheckboxCheckmark
                    font.pixelSize: Style.appFont.smallPt
                    visible: checkoutCheckbox.checked
                }
            }

            Text {
                text: "Checkout after creating"
                color: Style.colors.popupCheckboxLabelText
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.defaultPt
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: {
                    checkoutCheckbox.checked = !checkoutCheckbox.checked
                }
            }
        }

        // Publish: create the branch on a remote too, and track it there
        RowLayout {
            id: publishCheckbox
            readonly property bool checked: root.publish

            spacing: 8
            Layout.fillWidth: true
            visible: root.canPublish

            Rectangle {
                width: 16; height: 16
                radius: 3
                color: publishCheckbox.checked ? Style.colors.popupCheckboxBackgroundChecked : "transparent"
                border.color: publishCheckbox.checked ? Style.colors.popupCheckboxBackgroundChecked
                                                      : Style.colors.popupCheckboxBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: Style.icons.check
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    color: Style.colors.popupCheckboxCheckmark
                    font.pixelSize: Style.appFont.smallPt
                    visible: publishCheckbox.checked
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.remoteNames.length === 1 ? "Publish to " + root.remoteNames[0]
                                                    : "Publish to a remote"
                color: Style.colors.popupCheckboxLabelText
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.defaultPt
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.publish = !root.publish
            }
        }

        // Which remote, when there is more than one
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            spacing: 5
            visible: root.canPublish && root.publish && root.remoteNames.length > 1

            Repeater {
                model: root.remoteNames

                Rectangle {
                    id: remoteChip
                    required property string modelData
                    readonly property bool selected: root.publishRemote === remoteChip.modelData

                    radius: 4
                    color: remoteChip.selected ? Style.colors.popupCheckboxBackgroundChecked
                                               : Style.colors.popupChipBackground
                    border.color: remoteChip.selected ? Style.colors.popupCheckboxBackgroundChecked
                                                      : Style.colors.popupChipBorder
                    border.width: 1
                    implicitWidth: remoteChipRow.implicitWidth + 16
                    implicitHeight: 22

                    Row {
                        id: remoteChipRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Style.icons.cloud
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: Style.appFont.extraSmallPt
                            color: remoteChipName.color
                        }

                        Text {
                            id: remoteChipName
                            anchors.verticalCenter: parent.verticalCenter
                            text: remoteChip.modelData
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.captionPt
                            color: remoteChip.selected ? Style.colors.popupCheckboxCheckmark
                                                       : Style.colors.popupChipText
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.publishRemote = remoteChip.modelData
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            visible: root.canPublish && root.publish
            text: root.isNameValid && root.publishRemote !== ""
                  ? "Creates " + root.publishRemote + "/" + nameInput.text.trim()
                    + " and tracks it, so Pull and Push work without asking."
                  : "Creates the branch on the remote too and tracks it, so Pull and Push work without asking."
            color: Style.colors.placeholderText
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.captionPt
            wrapMode: Text.Wrap
        }
    }

    // Git command preview
    CommandPreview {
        Layout.fillWidth: true

        placeholder: qsTr("Name the branch to see the command")
        command: root.previewCommand()
    }

    actions: [
        PopupButton {
            tone: PopupButton.Primary
            text: root.publishes ? "Create & Publish" : "Create Branch"
            enabled: root.canAccept
            onClicked: root.createBranch()
        }
    ]

    /* Functions
     * ****************************************************************************************/
    function previewCommand() {
        let branchName = nameInput.text.trim()
        if (branchName === "")
            return ""

        let command = GitCommandText.createBranch(branchName, root.targetHash)

        if (checkoutCheckbox.checked)
            command += " && " + GitCommandText.checkoutBranch(branchName)

        if (root.publishes)
            command += " && " + GitCommandText.push(root.publishRemote, branchName, branchName, false, true)

        return command
    }

    function createBranch(){

        let branchName  = nameInput.text.trim()
        let checkout    = checkoutCheckbox.checked
        let publishTo   = root.publishes ? root.publishRemote : ""

        // TODO: Implement "Based on" feature – currently the baseBranch and
        //       baseBranchType are not used. Need GitBranch::createBranchFromBase()
        //       that creates a branch from a given base branch (local or remote).
        //       Until then, creation always happens from HEAD or the explicit targetHash.

        let res
        if (root.targetHash === "") {
            res = root.branchController.createBranch(branchName)
        } else {
            res = root.branchController.createBranch(root.targetHash, branchName)
        }

        if (res && res.success) {
            if (checkout)
                root.branchController.checkoutBranch(branchName)

            root.branchCreatedSuccessfully()
            notificationController.success("Branch '" + branchName + "' created successfully", "Branch", 3000)
            root.close()

            // Runs in the background; its own notifications report how it went.
            if (publishTo !== "")
                root.remoteOperationsSession.publishBranch(branchName, publishTo)
        } else {
            notificationController.error(res.errorMessage || "Failed to create branch", "Branch Error", 5000)
        }
    }
}
