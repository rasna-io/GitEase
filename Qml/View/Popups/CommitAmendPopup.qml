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


    /* signals
     * ****************************************************************************************/
    signal amendSuccessful()

    /* Object Properties
     * ****************************************************************************************/
    width: 480
    height: contentItem.implicitHeight
    padding: 0

    closePolicy: Popup.CloseOnEscape

    onOpened:{
        textArea.text = commitController.getLastCommitMessage()

        textArea.forceActiveFocus()
        textArea.cursorPosition = textArea.length
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
            Rectangle {
                id: amendBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 30

                radius: 4

                readonly property bool canAmend: textArea.text.trim().length > 0
                color: canAmend ? Style.colors.accent : Style.colors.disabledButton

                MouseArea {
                    id: amendBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: parent.canAmend ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: parent.canAmend

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: amendBtnMouse.containsMouse ? Qt.rgba(0,0,0,0.12) : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.changeCommitMessage ? "Save" : "Amend Commit"
                        color: Style.colors.secondaryForeground
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.mediumPt
                    }

                    onClicked: {
                        let res = commitController.commit(textArea.text.trim(), true, false)

                        if(res.success){
                            notificationController.success(root.changeCommitMessage ? "Commit message changed successfully" : "Commit amended successfully", "Amend Commit", 3000)
                            root.amendSuccessful()
                            root.close()
                        }
                        else
                            notificationController.error(res.errorMessage || "Amend failed", "Amend Commit Error", 5000)
                    }
                }
            }

            Rectangle {
                id: cancelBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 4
                color: "transparent"

                MouseArea {
                    id: cancelBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: cancelBtnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : Qt.rgba(255, 255, 255, 0.12)
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Style.colors.secondaryForeground
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
