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

    /* Signals */
    signal tagCreatedSuccessfully()

    /* Object Properties */
    width: 380
    height: 500
    padding: 12

    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 12
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            spacing: 14
            anchors.fill: parent
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

            // Tag Name
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
                    text: "Type"
                        color: Style.colors.popupSectionLabel
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
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
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                width: 16 
                                height: 16 
                                radius: 8
                                color: "transparent"
                                border.width: 1
                                    border.color: root.isAnnotated === modelData.value
                                                  ? Style.colors.popupRadioBorderChecked
                                                  : Style.colors.popupRadioBorder
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 8
                                    radius: 4
                                        color: Style.colors.popupRadioDot
                                    visible: root.isAnnotated === modelData.value
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
                                    font.pixelSize: smallPt
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
                    text: "Message"
                        color: Style.colors.popupSectionLabel
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                }

                TextField {
                    id: messageInput
                    placeholderText: "Release v1.0.0"
                    Layout.fillWidth: true
                    selectByMouse: true
                    enabled: root.isAnnotated
                    opacity: root.isAnnotated ? 1.0 : 0.5
                    onAccepted: if (root.canAccept) actionBtn.clicked()

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

                Text {
                    text: "Tag Commit"
                        color: Style.colors.popupSectionLabel
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
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
                        text: "Push to remote (origin)"
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
            RowLayout {
                spacing: 12
                Layout.fillWidth: true

                Button {
                    text: "Cancel"
                    Layout.preferredWidth: 100
                    onClicked: root.close()

                    background: Rectangle {
                        implicitHeight: 36
                        color: "transparent"
                        border.color: Style.colors.accent
                        border.width: 1
                        radius: 6
                        opacity: parent.hovered ? 1.0 : 0.7
                    }

                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: Style.colors.accent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.NoButton
                    }
                }

                Button {
                    id: actionBtn
                    text: "Create Tag"
                    Layout.fillWidth: true
                    enabled: root.canAccept

                    background: Rectangle {
                        implicitHeight: 36
                        color: actionBtn.enabled ? (actionBtn.hovered ? Style.colors.accentHover : Style.colors.accent)
                                                 : Style.colors.disabledButton
                        radius: 6
                    }

            }
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

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.NoButton
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
}
