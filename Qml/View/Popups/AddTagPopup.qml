import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * AddTagPopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations */
    property TagController tagController: null
    property NotificationController notificationController: null
    property string targetHash: ""
    property bool pushAfterCreate: true

    readonly property bool isNameValid: nameInput.text.trim().length > 0
    readonly property bool canAccept: isNameValid

    /* Signals */
    signal tagCreatedSuccessfully()

    /* Object Properties */
    width: 360
    height: 340
    padding: 12

    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 12
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            spacing: 16
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

            ColumnLayout {
                spacing: 12
                Layout.fillWidth: true

                // Tag Name Input
                TextField {
                    id: nameInput
                    placeholderText: "Tag Name (e.g. v1.0)"
                    Layout.fillWidth: true
                    selectByMouse: true
                    focus: true

                    onAccepted: if(root.canAccept) actionBtn.clicked()

                    background: Rectangle {
                        implicitHeight: 40
                        color: Style.colors.secondaryBackground
                        radius: 5
                        border.color: nameInput.activeFocus ? Style.colors.accent : "transparent"
                    }
                }

                // Tag Message Input
                TextField {
                    id: messageInput
                    placeholderText: "Message (Annotated Tag - Optional)"
                    Layout.fillWidth: true
                    selectByMouse: true
                    onAccepted: if(root.canAccept) actionBtn.clicked()

                    background: Rectangle {
                        implicitHeight: 40
                        color: Style.colors.secondaryBackground
                        radius: 5
                        border.color: messageInput.activeFocus ? Style.colors.accent : "transparent"
                    }
                }
            }

            // Target Info (Visual hint of what we are tagging)
            Text {
                text: root.targetHash !== "" ? "Target: " + root.targetHash.substring(0, 8) : "Target: HEAD"
                color: Style.colors.mutedText
                font.pixelSize: Style.appFont.defaultPt
                Layout.fillWidth: true
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

                        let res = ctrl.create(tagName, commitToTag, messageInput.text.trim());

                        if (res && res.success) {
                            if (root.pushAfterCreate) {
                                if (notif) notif.info("Pushing tag to GitHub...", "Tag", 1500);

                                ctrl.pushTag(tagName);
                            }

                            root.tagCreatedSuccessfully();
                            root.close();
                        } else {
                            if (notif) notif.error(res.errorMessage || "Failed to create tag", "Tag Error", 5000);
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
        pushAfterCreate = true;
    }

    // Auto-focus logic when popup opens
    onOpened: nameInput.forceActiveFocus()
}
