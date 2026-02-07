import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style_Impl
import GitEase_Style
import GitEase

/*! ***********************************************************************************************
 * StashManagerDock
 * ************************************************************************************************/

UtilitiesCard {
    id: root


    /* Property Declarations
     * ****************************************************************************************/
    property StashController stashController: null

    property AddStashPopup   addStashPopup: null

    /* Object Properties
     * ****************************************************************************************/
    title: "Stash Manager"
    icon: Style.icons.archive


    content: ColumnLayout {
        id: content

        anchors.fill: parent
        spacing: 16

        Connections {
            target: root
            onStashControllerChanged: {
                content.update()
            }
        }

        Connections {
            target: root.addStashPopup

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
                width: listView.width
                height: 60
                color: Style.colors.secondaryBackground
                radius: 5

                Row {
                    anchors.fill: parent
                    anchors.margins: 10

                    ColumnLayout {
                        width: parent.width * 0.8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: modelData.message || qsTr("WIP on %1").arg(modelData.author || "unknown")
                            color: Style.colors.foreground
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 12
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.dateTime ? Qt.formatDateTime(modelData.dateTime, "MMM dd, yyyy 'at' hh:mm") : ""
                            color: Style.colors.mutedText
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 10
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Row {
                        spacing: 4
                        width: parent.width * 0.2
                        anchors.verticalCenter: parent.verticalCenter
                        ActionIconButton {
                            iconText: Style.icons.undo
                            tooltip: "Pop"
                            textColor: Style.colors.mutedText
                            onClicked: {
                                let result = stashController.pop(modelData.index, true)
                                if (result.success) {
                                    content.update()
                                }
                            }
                        }
                        ActionIconButton {
                            iconText: Style.icons.check
                            tooltip: "Apply"
                            textColor: Style.colors.mutedText
                            onClicked: {
                                let result = stashController.apply(modelData.index, true)
                                if (result.success) {
                                    content.update()
                                }
                            }
                        }
                        ActionIconButton {
                            iconText: Style.icons.trash
                            tooltip: "Remove"
                            textColor: Style.colors.deletededFile
                            onClicked: {
                                let result = stashController.remove(modelData.index)
                                if (result.success) {
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
                        text: "Stash"
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
            if (!stashController)
                return

            let result = stashController.list()
            if (result.success) {
                listView.model = result.data
            } else {
                listView.model = []
            }
        }

    }

    /* Functions
     * ****************************************************************************************/

    function openAddEditPopup() {
        addStashPopup.stashController = root.stashController
        addStashPopup.open()
    }

}



