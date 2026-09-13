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
            anchors.margins: 24

            Text {
                text: "Create New Tag"
                color: Style.colors.foreground
                font.family: Style.fontTypes.inter
                font.bold: true
                font.pixelSize: Style.appFont.xlPt
                Layout.alignment: Qt.AlignLeft
            }

            // Tag Name
            ColumnLayout {
                spacing: 6
                Layout.fillWidth: true

                Text {
                    text: "Tag Name"
                    color: Style.colors.mutedText
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                }

                TextField {
                    id: nameInput
                    placeholderText: "v1.0.0"
                    Layout.fillWidth: true
                    selectByMouse: true
                    focus: true

                    onAccepted: if (root.canAccept) actionBtn.clicked()

                    background: Rectangle {
                        implicitHeight: 40
                        color: Style.colors.secondaryBackground
                        radius: 5
                        border.color: nameInput.activeFocus ? Style.colors.accent : "transparent"
                    }
                }

                RowLayout {
                    spacing: 6
                    Layout.fillWidth: true

                    Repeater {
                        model: root.versionSuggestions

                        Rectangle {
                            id: chip
                            required property string modelData

                            radius: 4
                            color: Style.colors.secondaryBackground
                            border.color: Style.colors.mutedText
                            border.width: 1
                            implicitWidth: chipLabel.implicitWidth + 16
                            implicitHeight: 20

                            Text {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: chip.modelData
                                font.family: Style.fontTypes.inter
                                font.pixelSize: Style.appFont.captionPt
                                color: Style.colors.mutedText
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

            // Tag Type
            ColumnLayout {
                spacing: 6
                Layout.fillWidth: true

                Text {
                    text: "Type"
                    color: Style.colors.mutedText
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                }

                ColumnLayout {
                    spacing: 6
                    Layout.fillWidth: true

                    Repeater {
                        model: [
                            { label: "Annotated tag",   hint: "(recommended — includes message)",   value: true },
                            { label: "Lightweight tag", hint: "",                                   value: false }
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
                                border.color: root.isAnnotated === modelData.value ? Style.colors.accent : Style.colors.mutedText
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: Style.colors.accent
                                    visible: root.isAnnotated === modelData.value
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.isAnnotated = modelData.value
                                }
                            }

                            Text {
                                text: modelData.label
                                color: Style.colors.foreground
                                font.family: Style.fontTypes.inter
                                font.pixelSize: Style.appFont.smallPt
                            }

                            Text {
                                text: modelData.hint
                                color: Style.colors.mutedText
                                font.family: Style.fontTypes.inter
                                font.pixelSize: Style.appFont.captionPt
                                visible: modelData.hint.length > 0
                            }
                        }
                    }
                }
            }

            // Tag Message
            ColumnLayout {
                spacing: 6
                Layout.fillWidth: true

                Text {
                    text: "Message"
                    color: Style.colors.mutedText
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
                        implicitHeight: 40
                        color: Style.colors.secondaryBackground
                        radius: 5
                        border.color: messageInput.activeFocus ? Style.colors.accent : "transparent"
                    }
                }
            }

            // Target Commit
            ColumnLayout {
                spacing: 6
                Layout.fillWidth: true

                Text {
                    text: "Tag Commit"
                    color: Style.colors.mutedText
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: 5
                    color: Style.colors.secondaryBackground
                    border.color: "transparent"

                    RowLayout {
                        anchors.fill: parent
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
                            color: Style.colors.mutedText
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.defaultPt
                        }
                    }
                }
            }

            CheckBox {
                id: pushCheckBox
                text: "Push to remote (origin)"
                checked: root.pushAfterCreate
                Layout.fillWidth: true
                implicitHeight: 32
                spacing: 1

                indicator: Rectangle {
                    implicitWidth: 20
                    implicitHeight: 20
                    y: parent.height / 2 - height / 2
                    radius: 6
                    color: pushCheckBox.checked ? Style.colors.accent : Style.colors.secondaryBackground
                    border.color: pushCheckBox.checked ? Style.colors.accent : Qt.lighter(Style.colors.secondaryBackground, 1.5)
                    border.width: 1

                    Text {
                        text: "\uf00c"
                        font.family: Style.fontTypes.font6Pro
                        font.styleName: "Solid"
                        font.pixelSize: Style.appFont.mediumPt
                        color: "white"
                        anchors.centerIn: parent
                        visible: pushCheckBox.checked
                    }
                }

                contentItem: Text {
                    text: pushCheckBox.text
                    font: pushCheckBox.font
                    color: Style.colors.foreground
                    leftPadding: pushCheckBox.indicator.width + pushCheckBox.spacing
                    verticalAlignment: Text.AlignVCenter
                }

                onCheckedChanged: root.pushAfterCreate = checked
            }

            Item { Layout.fillHeight: true }

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

                    onClicked: {
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
