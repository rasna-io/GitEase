import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * AddBranchPopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property BranchController       branchController
    property NotificationController notificationController: null
property string                 targetHash: ""
    property string                 baseBranchType: "remote"
    property string                 baseBranch: "main"

    property string targetHash: ""

    readonly property var branchNameSuggestions: ["feature/", "fix/", "chore/"]

    readonly property bool    isNameValid: nameInput.text.trim().length > 0

    readonly property bool    canAccept:   isNameValid

    readonly property int sectionSpacing: 12
    readonly property int elementSpacing: 2

    signal branchCreatedSuccessfully()

    width: 300
    height: 400
    padding: 0

    contentItem: Rectangle {
        color: Style.colors.popupBackground
        radius: 8
        clip: true
        border.color: Style.colors.popupBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                spacing: 8

                // Title
            Text {
                text: "Create Branch"
                    color: Style.colors.popupTitleText
                    font.family: Style.fontTypes.inter
                    font.weight: Font.DemiBold
                    font.pixelSize: Style.appFont.mediumPt
                    Layout.fillWidth: true
                }

                // Close Button
                Text {
                    text: "\u00d7"
                font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                    color: closeMouse.containsMouse ? Style.colors.popupCloseButtonHover
                                                    : Style.colors.popupCloseButton
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            // Header separator
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Style.colors.popupHeaderSeparator
            }

            // Body
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                Layout.topMargin: 16
                spacing: 0

                // Branch name
                ColumnLayout {
                    spacing: root.elementSpacing
                    Layout.fillWidth: true
                    Layout.bottomMargin: root.sectionSpacing

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
                        font.family: Style.fontTypes.mono
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
                    Layout.bottomMargin: root.sectionSpacing

                    Text {
                        text: "BASED ON"
                        color: Style.colors.popupSectionLabel
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
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
                                font.family: Style.fontTypes.mono
                                font.pixelSize: Style.appFont.defaultPt
                                color: Style.colors.popupBaseBranchText
                            }

                            Text {
                                text: "▾"
                                font.family: Style.fontTypes.inter
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
                                spacing: 6
                                Layout.fillWidth: true

                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Style.colors.popupRadioDot
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: Style.colors.popupRadioBorderChecked
                                        visible: root.baseBranchType === modelData.value
                                    }
                                }

                                Text {
                                    text: modelData.label
                                    color: Style.colors.popupCheckboxLabelText
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.defaultPt
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.baseBranchType = modelData.value
                                }
                            }
                        }
                    }
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Style.colors.popupHeaderSeparator
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                }

                // Checkboxes
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Layout.bottomMargin: root.sectionSpacing

                    // Checkout after creating
                    RowLayout {
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
                                text: "\u2713"
                                color: Style.colors.popupCheckboxCheckmark
                                font.pixelSize: 10
                                visible: checkoutCheckbox.checked
                }
            }

                        Text {
                            text: "Checkout after creating"
                            color: Style.colors.popupCheckboxLabelText
                            font.family: Style.fontTypes.inter
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: checkoutCheckbox.checked = !checkoutCheckbox.checked
                        }
                    }

                    // Push to remote immediately
            RowLayout {
                spacing: 8
                Layout.fillWidth: true
                        visible: false  // TODO: Implement GitBranch::pushBranch(branchName) to push the newly created
                                        // branch to the remote (origin). Until then, the push checkbox has no effect.


                        Rectangle {
                            width: 16; height: 16
                            radius: 3
                            color: pushCheckbox.checked ? Style.colors.popupCheckboxBackgroundChecked : "transparent"
                            border.color: pushCheckbox.checked ? Style.colors.popupCheckboxBackgroundChecked
                                                                : Style.colors.popupCheckboxBorder
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "\u2713"
                                color: Style.colors.popupCheckboxCheckmark
                                font.pixelSize: 10
                                visible: pushCheckbox.checked
                            }
                        }

                        Text {
                            text: "Push to remote immediately"
                            color: Style.colors.popupCheckboxLabelText
                            font.family: Style.fontTypes.inter
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: pushCheckbox.checked = !pushCheckbox.checked
                        }
                    }
                }

                // Git command preview
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 25
                    radius: 5
                    color: Style.colors.popupCommandPreviewBackground

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        textFormat: Text.RichText

                        text:
                            "git checkout -b " +
                            "<span style=\"color:" + Style.colors.accent + "\">" +
                            (nameInput.text || "feature/new-work") +
                            "</span> " +
                              root.baseBranch

                        font.family: Style.fontTypes.mono
                        font.pixelSize: Style.appFont.defaultPt
                        color: Style.colors.popupCommandPreviewText
                    }
                }
}

            // Footer separator
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Style.colors.popupHeaderSeparator
            }

            // Footer
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                color: Style.colors.popupFooterBackground

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 8

                    Item {
                        Layout.fillWidth: true
                    }


                    Button {
                        text: "Cancel"
                        Layout.preferredWidth: 100
                        Layout.alignment: Qt.AlignVCenter
                        topPadding: 6
                        bottomPadding: 6
                        leftPadding: 14
                        rightPadding: 14

                    background: Rectangle {
                            implicitHeight: 32
                            color: "transparent"
                            border.color: Style.colors.popupCancelButtonBorder
                            border.width: 1
                        radius: 5
                    }

                        contentItem: Text {
                            text: parent.text
                            color: Style.colors.secondaryForeground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        onClicked: root.close()
                    }

                    Button {
                        text: "Create Branch"
                        Layout.preferredWidth: 130
                        Layout.alignment: Qt.AlignVCenter
                        enabled: root.canAccept
                        topPadding: 6
                        bottomPadding: 6
                        leftPadding: 16
                        rightPadding: 16

                        background: Rectangle {
                            implicitHeight: 32
                            color: parent.enabled ? Style.colors.accent : "#222228"
                            radius: 5
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Style.colors.secondaryForeground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        onClicked: root.createBranch()
                    }
                }
            }
        }
    }

    onAboutToHide: {
        nameInput.text  = ""
        targetHash      = ""
        baseBranch      = "main"
        baseBranchType  = "remote"
    }

    function createBranch(){

        let branchName  = nameInput.text.trim()
        let checkout    = checkoutCheckbox.checked
        let push        = pushCheckbox.checked

        let res
        if (root.targetHash === "") {
            res = root.branchController.createBranch(branchName)
        } else {
            res = root.branchController.createBranch(root.targetHash, branchName)
        }

        if (res && res.success) {
            if (checkout)
                root.branchController.checkoutBranch(branchName)

            // TODO: Implement GitBranch::pushBranch(branchName) to push the newly created
            //       branch to the remote (origin). Until then, the push checkbox has no effect.
            // if (push)
            //     root.branchController.pushBranch(branchName)

            root.branchCreatedSuccessfully()
            notificationController.success("Branch '" + branchName + "' created successfully", "Branch", 3000)
            root.close()
        } else {
            notificationController.error(res.errorMessage || "Failed to create branch", "Branch Error", 5000)
        }
    }
}