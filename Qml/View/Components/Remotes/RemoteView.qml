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

    property RepositoryController repositoryController: null

    property UserAuthenticationPopup userAuthenticationPopup: null

    property AddEditRemotePopup addEditRemotePopup: null

    property NotificationController notificationController: null

    property bool isFetching: false

    property Remote remote: null

    /* Signal Declarations
     * ****************************************************************************************/
    signal fetchSuccess(string remoteName)
    signal fetchError(string remoteName, string errorMessage)

    /* Object Properties
     * ****************************************************************************************/

    title: "Remotes"
    icon: Style.icons.upload

    Connections {
        target: userAuthenticationPopup

        function onPasswordConfirm(password){
            root.isFetching = true
            let res = root.remoteController.fetchWithToken(remote.name, password)
            if (res.success)
                root.fetchSuccess(remote.name)
            else
                root.fetchError(remote.name, res.errorMessage)
            root.isFetching = false
        }
        function onRejected() {
            root.isFetching = false
        }
    }

    content: ColumnLayout {
        id: content
        spacing: 10

        Connections {
            target: root
            function onRemoteControllerChanged() {
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
                if (notificationController) {
                    notificationController.success("Successfully fetched from " + remoteName, "Fetch", 5000)
                }
            }
            
            function onFetchError(remoteName, errorMessage) {
                if (notificationController) {
                    notificationController.error("Failed to fetch from " + remoteName + ": " + errorMessage, "Fetch Error", 7000)
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: listView
                anchors.fill: parent
                spacing: 8
                clip: true

                delegate: Rectangle {

                    property Remote currentRemote: modelData

                    width: listView.width
                    height: 60
                    color: Style.colors.secondaryBackground
                    radius: 5

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.maximumWidth: parent.width * 0.70 - parent.spacing
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2
                            clip: true

                            Text {
                                Layout.fillWidth: true
                                text: currentRemote.name
                                color: Style.colors.foreground
                                font.family: Style.fontTypes.roboto
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: currentRemote.url
                                color: Style.colors.mutedText
                                font.family: Style.fontTypes.roboto
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        Row {
                            spacing: 4
                            Layout.preferredWidth: parent.width * 0.30
                            Layout.minimumWidth: 1
                            Layout.alignment: Qt.AlignVCenter

                            ActionIconButton {
                                iconText: Style.icons.download
                                tooltip: root.isFetching ? "Fetching..." : "Fetch"
                                textColor: root.isFetching ? Style.colors.accent : Style.colors.mutedText
                                enabled: !root.isFetching
                                onClicked: {
                                    root.remote = currentRemote
                                    let res = remoteController.getRemoteUrl(currentRemote.name)

                                    if (!res.success) {
                                        return
                                    }

                                    let url = res.data.url
                                    let protocol = repositoryController.detectGitProtocol(url)
                                    switch(protocol) {
                                    case RepositoryController.GitProtocol.SSH:
                                        root.isFetching = true
                                        res = root.remoteController.fetch(currentRemote.name)
                                        if (res.success) {
                                            root.fetchSuccess(currentRemote.name)
                                        } else {
                                            root.fetchError(currentRemote.name, res.errorMessage)
                                        }
                                        root.isFetching = false
                                        content.update()
                                        break;
                                    case RepositoryController.GitProtocol.HTTPS:
                                    case RepositoryController.GitProtocol.HTTP:
                                        userAuthenticationPopup.open()
                                        break;
                                    }
                                }
                            }
                            ActionIconButton {
                                iconText: Style.icons.edit
                                tooltip: "Edit"
                                textColor: Style.colors.mutedText
                                onClicked: {
                                    addEditRemotePopup.oldRemote = currentRemote
                                    openAddEditPopup()
                                }
                            }
                            ActionIconButton {
                                iconText: Style.icons.trash
                                tooltip: "Remove"
                                textColor: Style.colors.deletededFile
                                onClicked: {
                                    root.remoteController.removeRemote(currentRemote.name)
                                    content.update()
                                }
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
