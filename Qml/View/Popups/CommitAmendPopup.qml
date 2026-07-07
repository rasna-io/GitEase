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
    width: parent.width / 2
    height: 300
    padding: 20

    modal           : true
    closePolicy     : Popup.NoAutoClose

    onOpened:{
        textArea.text = commitController.getLastCommitMessage()

        textArea.forceActiveFocus()
        textArea.cursorPosition = textArea.length
    }

    /* Children
     * ****************************************************************************************/
    background: Rectangle {
        radius: 4
        color: Style.colors.primaryBackground
        border.width: 1
        border.color: Style.colors.primaryBorder
    }

    contentItem: Column {
        width: parent.width
        spacing: 10

        Label {
            width: parent.width
            color: Style.colors.descriptionText
            text: "Amend Commit Message"
            font.family: Style.fontTypes.roboto
            font.pixelSize: Style.appFont.largePt
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            color: Style.colors.descriptionText
            text: "Edit the message for your amended commit (Optional):"
            font.pixelSize: Style.appFont.mediumPt
        }

        ScrollView {
            width: parent.width
            height: 150
            anchors.margins: 5
            TextArea {
                id: textArea
                color: Style.colors.foreground
                font.family: Style.fontTypes.roboto
                wrapMode: TextArea.Wrap
                font.pixelSize: Style.appFont.mediumPt
                Material.accent: Style.colors.accent
            }
        }

        RowLayout  {
            id: buttonsRow
            width: parent.width
            spacing: 10

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
                        text: "Amend"
                        color: Style.colors.secondaryForeground
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: Style.appFont.mediumPt
                    }

                    onClicked: {
                        let res = commitController.commit(textArea.text.trim(), true, false)

                        if(res.success){
                            notificationController.success(root.changeCommitMessage ? "Commit Message Changes successfully" : "Commit amended successfully", "Commit Amend", 3000)
                            root.amendSuccessful()
                            root.close()
                        }
                        else
                            notificationController.error(res.errorMessage || "Amend failed", "Commit Amend Error", 5000)
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
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: Style.appFont.mediumPt
                    }

                    onClicked: root.close();
                }
            }
        }
    }
}
