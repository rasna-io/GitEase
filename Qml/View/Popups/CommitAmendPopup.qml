import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * CommitAmendPopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property NotificationController notificationController  : null
    property CommitController       commitController        : null
    property bool                   changeCommitMessage     : false

    readonly property bool          canAccept               : messageInput.text.trim().length > 0

    /* signals
     * ****************************************************************************************/
    signal amendSuccessful()

    /* Object Properties
     * ****************************************************************************************/
    width: 480
    height: contentItem.implicitHeight
    padding: 0

    closePolicy: Popup.CloseOnEscape

    onOpened: {
        messageInput.text = commitController.getLastCommitMessage().replace(/\s+$/, "")
        messageInput.focusAtEnd()
    }

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        implicitHeight: layout.implicitHeight
        color: Style.colors.popupBackground
        radius: 8
        clip: true
        border.color: Style.colors.popupBorder
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                spacing: 8

                Text {
                    text: root.changeCommitMessage ? "Change Commit Message" : "Amend Commit"
                    color: Style.colors.popupTitleText
                    font.family: Style.fontTypes.inter
                    font.weight: Font.DemiBold
                    font.pixelSize: Style.appFont.mediumPt
                    Layout.fillWidth: true
                }

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
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                Layout.topMargin: 16
                Layout.bottomMargin: 12
                spacing: 6

                Text {
                    text: "COMMIT MESSAGE"
                    color: Style.colors.popupSectionLabel
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.defaultPt
                }

                // Same box as the commit message on the Committing page
                ModernInputArea {
                    id: messageInput
                    Layout.fillWidth: true
                    placeholder: "Commit message (required)"
                }

                CommandPreview {
                    Layout.fillWidth: true
                    Layout.topMargin: 4

                    placeholder: qsTr("Write a message to see the command")
                    command: messageInput.text.trim() === ""
                             ? ""
                             : GitCommandText.commit(messageInput.text, true)
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
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                Layout.topMargin: 12
                Layout.bottomMargin: 12
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
                    text: root.changeCommitMessage ? "Save" : "Amend Commit"
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
                        onClicked: root.amend()
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function amend() {
        let res = commitController.commit(messageInput.text.trim(), true, false)

        if (res.success) {
            notificationController.success(root.changeCommitMessage ? "Commit message changed successfully" : "Commit amended successfully", "Amend Commit", 3000)
            root.amendSuccessful()
            root.close()
        } else {
            notificationController.error(res.errorMessage || "Amend failed", "Amend Commit Error", 5000)
        }
    }
}
