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

    /* signals
     * ****************************************************************************************/
    signal amendSuccessful()

    /* Object Properties
     * ****************************************************************************************/
    width: parent.width / 2
    height: 300
    padding: 20

    onOpened:{
        textArea.text = commitController.getLastCommitMessage()
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
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            color: Style.colors.descriptionText
            text: "Edit the message for your amended commit (Optional):"
            font.pixelSize: 12
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
                font.pixelSize: 12
                Material.accent: Style.colors.accent
            }
        }

        Row {
            id: buttonsRow
            spacing: 6
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 10

            Button {
                id: confirmButton
                width: root.width / 4
                height: 40
                hoverEnabled: true
                text: "Amend"

                contentItem: Text {
                    text: confirmButton.text
                    font: confirmButton.font
                    color: Style.colors.secondaryForeground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 3
                    color: confirmButton.down ? Style.colors.accentHover : confirmButton.hovered ? Style.colors.accentHover : Style.colors.accent
                }

                MouseArea{
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        let res = commitController.commit(textArea.text.trim(), true, false)

                        if(res.success){
                            notificationController.success("Commit amended successfully", "Commit Amend", 3000)
                            root.amendSuccessful()
                            root.close()
                        }
                        else
                            notificationController.error(res.errorMessage || "Amend failed", "Commit Amend Error", 5000)
                    }
                }
            }

            Button {
                id: cancelButton
                width: root.width / 4
                height: 40
                hoverEnabled: true
                text: "Cancel"

                contentItem: Text {
                    text: cancelButton.text
                    font: cancelButton.font
                    color: Style.colors.foreground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 3
                    border.width: 1
                    border.color: Style.colors.primaryBorder
                    color: cancelButton.down ? Style.colors.surfaceMuted: cancelButton.hovered ? Style.colors.cardBackground : Style.colors.surfaceLight
                }

                MouseArea{
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.close()
                }
            }
        }
    }
}
