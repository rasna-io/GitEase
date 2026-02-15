import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style_Impl
import GitEase_Style
import GitEase

/*! ***********************************************************************************************
 * RemoteView
 * ************************************************************************************************/

UtilitiesCard {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int currentIndex: 0

    property RemoteController remoteController: null

    property AddEditRemotePopup addEditRemotePopup: null
    
    property NotificationController notificationController: null

    /* Signal Declarations
     * ****************************************************************************************/
    signal fetchSuccess(string remoteName)
    signal fetchError(string remoteName, string errorMessage)

    /* Object Properties
     * ****************************************************************************************/

    title: "Remotes"
    icon: Style.icons.upload

    content: ColumnLayout {
        id: content
        spacing: 10

        Connections {
            target: root
            onRemoteControllerChanged: {
                content.update()
            }
        }

        Connections {
            target: root.remoteController

            function onCurrentRepoChanged() {
                content.update()
            }
        }

        Connections {
            target: root.addEditRemotePopup

            function onAboutToHide() {
                content.update()
            }
        }

        Connections {
            target: root
            
            function onFetchSuccess(remoteName) {
                messageLabel.messageText = "Successfully fetched from " + remoteName
                messageLabel.messageType = "success"
                messageClearTimer.restart()
            }
            
            function onFetchError(remoteName, errorMessage) {
                messageLabel.messageText = "Failed to fetch from " + remoteName + ": " + errorMessage
                messageLabel.messageType = "error"
                messageClearTimer.restart()
            }
        }

        Timer {
            id: messageClearTimer
            interval: 5000
            onTriggered: messageLabel.messageText = ""
        }

        Rectangle {
            id: messageLabel
            property string messageText: ""
            property string messageType: ""
            
            Layout.fillWidth: true
            implicitHeight: messageText !== "" ? 40 : 0
            color: messageType === "error" ? Qt.rgba(Style.colors.error.r, Style.colors.error.g, Style.colors.error.b, 0.15) : Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.15)
            radius: 4
            visible: messageText !== ""
            clip: true
            border.color: messageType === "error" ? Style.colors.error : Style.colors.accent
            border.width: 1
            
            Text {
                anchors.centerIn: parent
                text: messageLabel.messageText
                color: messageType === "error" ? Style.colors.error : Style.colors.accent
                font.family: Style.fontTypes.roboto
                font.pixelSize: 11
                wrapMode: Text.Wrap
                anchors.margins: 8
                width: parent.width - 16
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            clip: true

            delegate: Rectangle {

                property Remote remote: modelData
                property bool isFetching: false

                width: listView.width
                height: 60
                color: Style.colors.secondaryBackground
                radius: 5

                Row {
                    anchors.fill: parent
                    anchors.margins: 10

                    ColumnLayout {
                        width: parent.width * 0.70
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: remote.name
                            color: Style.colors.foreground
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 12
                        }
                        Text {
                            text: remote.url
                            color: Style.colors.mutedText
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    Row {
                        spacing: 4
                        width: parent.width * 0.30
                        anchors.verticalCenter: parent.verticalCenter
                        
                        ActionIconButton {
                            iconText: isFetching ? "↻" : Style.icons.download
                            tooltip: isFetching ? "Fetching..." : "Fetch"
                            textColor: isFetching ? Style.colors.accent : Style.colors.mutedText
                            enabled: !isFetching
                            onClicked: {
                                isFetching = true
                                let res = root.remoteController.fetch(remote.name)
                                isFetching = false
                                
                                if (res.success) {
                                    root.fetchSuccess(remote.name)
                                } else {
                                    root.fetchError(remote.name, res.errorMessage)
                                }
                                content.update()
                            }
                        }
                        
                        ActionIconButton {
                            iconText: Style.icons.edit
                            tooltip: "Edit"
                            textColor: Style.colors.mutedText
                            onClicked: {
                                addEditRemotePopup.oldRemote = remote
                                openAddEditPopup()
                            }
                        }
                        ActionIconButton {
                            iconText: Style.icons.trash
                            tooltip: "Remove"
                            textColor: Style.colors.deletededFile
                            onClicked: {
                                let res = root.remoteController.removeRemote(remote.name)
                                if (res.success) {
                                    if (root.notificationController) {
                                        root.notificationController.success("Remote '" + remote.name + "' removed successfully", "Remote", 3000)
                                    }
                                } else {
                                    if (root.notificationController) {
                                        root.notificationController.error(res.errorMessage || "Failed to remove remote", "Remote Error", 5000)
                                    }
                                }
                                content.update()
                            }
                        }
                    }
                }
            }
        }

        Button {
            Layout.fillWidth: true
            implicitHeight: 44

            background: Rectangle {
                radius: 8
                color: enabled ? Style.colors.accent : Style.colors.disabledButton
            }

            contentItem: Item {
                anchors.fill: parent

                Row {
                    spacing: 10
                    anchors.centerIn: parent

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Style.icons.plus
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: 12
                        color: Style.colors.secondaryForeground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add New Remote"
                        color: Style.colors.secondaryForeground
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            onClicked: {
                openAddEditPopup()
            }
        }

        function update() {
            if (remoteController) {
                let res = remoteController.getRemotes();
                if (res.success) {
                    listView.model = res.data
                }
            }
        }
    }


    /* Functions
     * ****************************************************************************************/

    function openAddEditPopup() {
        addEditRemotePopup.remoteController = root.remoteController
        addEditRemotePopup.open()
    }


}
