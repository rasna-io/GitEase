import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style_Impl
import GitEase_Style
import GitEase

/*! ***********************************************************************************************
 * RemoteView
 * Import and Export git bundle
 * ************************************************************************************************/

UtilitiesCard {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int currentIndex: 0

    property RemoteController remoteController: null

    property AddEditRemotePopup addEditRemotePopup: null


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
            target: root.addEditRemotePopup

            function onAboutToHide() {
                content.update()
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

                width: listView.width
                height: 60
                color: "#f8f8f8"
                border.color: "#eeeeee"
                radius: 8

                Row {
                    anchors.fill: parent
                    anchors.margins: 10

                    ColumnLayout {
                        width: parent.width * 0.85
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: remote.name
                            font.bold: true
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
                        width: parent.width * 0.15
                        anchors.verticalCenter: parent.verticalCenter
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
                                root.remoteController.removeRemote(remote.name)
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
