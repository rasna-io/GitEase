import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import GitEase
import GitEase_Style
import GitEase_Style_Impl

import "qrc:/GitEase/Qml/Core/Scripts/AsyncGit.js" as AsyncGit

/*! ***********************************************************************************************
 * AddTagPopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations */
    property TagController tagController: null
    property NotificationController notificationController: null
    property string targetHash: ""
    property string targetLabel: ""
    property bool pushAfterCreate: true
    property bool isAnnotated: true

    readonly property bool isNameValid: nameInput.text.trim().length > 0
    readonly property bool isMessageValid: !root.isAnnotated || messageInput.text.trim().length > 0
    readonly property bool canAccept: isNameValid && isMessageValid

    readonly property var versionSuggestions: ["v1.0.1", "v1.1.0", "v2.0.0"]

    readonly property int sectionSpacing: 12
    readonly property int elementSpacing: 2

    /* Signals */
    signal tagCreatedSuccessfully()

    /* Object Properties */
    width: 380
    height: 380
    padding: 0

    contentItem: Rectangle {
        color: Style.colors.primaryBackground
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
                    text: "Create Tag"
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

                // TAG name
                ColumnLayout {
                    spacing: root.elementSpacing
                    Layout.fillWidth: true
                    Layout.bottomMargin: root.sectionSpacing

                    Text {
                        text: "TAG NAME"
                        color: Style.colors.popupSectionLabel
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.defaultPt
                    }

                    TextField {
                        id: nameInput
                        placeholderText: "v1.0.0"
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
                            model: root.versionSuggestions

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

                // Tag Type section
                ColumnLayout {
                    spacing: root.elementSpacing
                    Layout.fillWidth: true
                    Layout.bottomMargin: root.sectionSpacing

                    Text {
                        text: "TYPE"
                        color: Style.colors.popupSectionLabel
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.defaultPt
                    }

                    ColumnLayout {
                        spacing: 6
                        Layout.fillWidth: true

                        Repeater {
                            model: [
                                { label: "Annotated tag",       hint: "(recommended — includes message)",   value: true },
                                { label: "Lightweight tag",     hint: "",                                   value: false }
                            ]

                            RowLayout {
                                id: typeOption
                                required property var modelData
                                readonly property bool checked: root.isAnnotated === modelData.value
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: typeOption.checked ? Style.colors.popupRadioBorderChecked : "transparent"
                                    border.width: 1
                                    border.color: typeOption.checked ? Style.colors.popupRadioBorderChecked
                                                                     : Style.colors.popupRadioBorder
                                    Layout.alignment: Qt.AlignVCenter

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: Style.colors.popupRadioDot
                                        visible: typeOption.checked
                                    }
                                }

                                // Label
                                Text {
                                    text: modelData.label
                                    color: Style.colors.popupCheckboxLabelText
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.defaultPt
                                }

                                // Hint
                                Text {
                                    text: modelData.hint
                                    color: Style.colors.popupCheckboxLabelText
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.smallPt
                                    visible: modelData.hint.length > 0
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.isAnnotated = modelData.value
                                }
                            }
                        }
                    }
                }

                // Tag Message
                ColumnLayout {
                    spacing: 5
                    Layout.fillWidth: true
                    Layout.bottomMargin: root.sectionSpacing

                    Text {
                        text: "MESSAGE"
                        color: Style.colors.popupSectionLabel
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.defaultPt
                    }

                    TextField {
                        id: messageInput
                        placeholderText: "Release v1.0.0"
                        Layout.fillWidth: true
                        selectByMouse: true
                        enabled: root.isAnnotated
                        opacity: root.isAnnotated ? 1.0 : 0.5

                        background: Rectangle {
                            implicitHeight: 26
                            color: Style.colors.popupInputBackground
                            radius: 5
                            border.color: messageInput.activeFocus ? Style.colors.popupInputBorderFocus
                                                                    : Style.colors.popupInputBorder
                            border.width: 1
                        }
                    }
                }

                // Target Commit
                ColumnLayout {
                    spacing: 5
                    Layout.fillWidth: true
                    Layout.bottomMargin: root.sectionSpacing
                    visible: false
                    // TODO: Implement commit picker to change the target commit.
                    //       Currently the popup receives targetHash from the caller;
                    //       a future dialog could let the user browse commits and set it.

                    Text {
                        text: "TARGET COMMIT"
                        color: Style.colors.popupSectionLabel
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.defaultPt
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 26
                        radius: 5
                        color: Style.colors.popupInputBackground
                        border.color: Style.colors.popupInputBorder
                        border.width: 1

                        RowLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: Style.icons.tag
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: Style.appFont.smallPt
                                color: Style.colors.mutedText
                            }

                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: root.targetHash !== ""
                                      ? (
                                            root.targetLabel !== ""
                                            ? root.targetHash.substring(0, 8) + " — " + root.targetLabel
                                            : root.targetHash.substring(0, 8)
                                        )
                                      : (
                                            "HEAD" + (root.targetLabel !== "" ? " — " + root.targetLabel : "")
                                        )
                                color: Style.colors.popupInputText
                                font.family: Style.fontTypes.mono
                                font.pixelSize: Style.appFont.defaultPt
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                // TODO: open commit picker to change target
                            }
                        }
                    }
                }

                // Push checkbox
                RowLayout {
                    id: pushCheckBox
                    property bool checked: true
                    Layout.bottomMargin: root.sectionSpacing

                    spacing: 8
                    Layout.fillWidth: true

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 3
                        color: pushCheckBox.checked ? Style.colors.popupCheckboxBackgroundChecked : "transparent"
                        border.color: pushCheckBox.checked ? Style.colors.popupCheckboxBackgroundChecked
                                                                : Style.colors.popupCheckboxBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "\u2713"
                            color: Style.colors.popupCheckboxCheckmark
                            font.pixelSize: Style.appFont.smallPt
                            visible: pushCheckBox.checked
                        }
                    }

                    Text {
                        text: "Push to origin after creating"
                        color: Style.colors.popupCheckboxLabelText
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.defaultPt
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pushCheckBox.checked = !pushCheckBox.checked
                    }
                }

                // Footer separator
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Style.colors.popupHeaderSeparator
                }

                // Footer
                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.elementSpacing

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
                            opacity: parent.hovered ? 1.0 : 0.7
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Style.colors.popupCancelButtonText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }

                    Button {
                        id: actionBtn
                        text: "Create Tag"
                        Layout.preferredWidth: 130
                        Layout.alignment: Qt.AlignVCenter
                        enabled: root.canAccept
                        topPadding: 6
                        bottomPadding: 6
                        leftPadding: 16
                        rightPadding: 16

                        background: Rectangle {
                            implicitHeight: 32
                            color: parent.enabled ? (actionBtn.hovered ? Style.colors.accentHover : Style.colors.accent)
                                                  : Style.colors.disabledButton
                            radius: 5
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Style.colors.secondaryForeground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.createTag()
                        }
                    }
                }
            }
        }
    }

    // Reset state on close
    onAboutToHide: {
        nameInput.text = "";
        messageInput.text = "";
        targetHash = "";
        targetLabel = "";
        pushAfterCreate = true;
        isAnnotated = true;
    }

    // Auto-focus logic when popup opens
    onOpened: nameInput.forceActiveFocus()

    function createTag(){
        let ctrl = root.tagController || (typeof uiSession !== "undefined" ? uiSession.tagController : null);
        let notif = root.notificationController || (typeof uiSession !== "undefined" ? uiSession.notifications : null);

        if (!ctrl) return;

        let tagName = nameInput.text.trim();
        let commitToTag = root.targetHash === "" ? "HEAD" : root.targetHash;
        let tagMessage = root.isAnnotated ? messageInput.text.trim() : "";

        let res = ctrl.create(tagName, commitToTag, tagMessage);

        if (res && res.success) {
            if (root.pushAfterCreate) {
                if (notif) notif.info("Pushing tag to GitHub...", "Tag", 1500);

                                AsyncGit.call(ctrl, "pushTag", [tagName],
                                    function(pushResult) {
                                        if (pushResult.success) {
                                            if (notif) notif.success("Tag created and pushed", "Success", 3000);
                                        } else {
                                            if (notif) notif.warning("Tag created locally but failed to push", "Sync Warning", 5000);
                                        }
                                    },
                                    function(error) {
                                        if (notif) notif.warning("Tag created locally but failed to push", "Sync Warning", 5000);
                                    }
                                );
                            }

            root.tagCreatedSuccessfully();
            root.close();
        } else {
            if (notif) notif.error(res.errorMessage || "Failed to create tag", "Tag Error", 5000);
        }
    }
}
