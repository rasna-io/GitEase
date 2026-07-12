import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RuleImportPopup
 * Warns the user that importing will replace all existing rules for this repository.
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property url pendingFile

    /* Signals
     * ****************************************************************************************/
    signal confirmed(url fileUrl)

    /* Object Properties
     * ****************************************************************************************/
    width: 420
    height: 230
    padding: 20

    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Import Rules"
                    Layout.fillWidth: true
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 13
                    color: "white"
                    font.bold: true
                }

                Button {
                    implicitHeight: 30
                    Layout.preferredWidth: 20

                    background: Rectangle {
                        radius: 8
                        color: "transparent"
                    }

                    contentItem: Item {
                        anchors.fill: parent

                        Text {
                            anchors.centerIn: parent
                            text: "X"
                            color: Style.colors.textButton
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }

                    onClicked: root.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.secondaryBackground
            }

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "This will replace all existing rules for this repository with the ones from the imported file. This cannot be undone."
                font.family: Style.fontTypes.roboto
                font.pixelSize: 12
                color: Style.colors.mutedText
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignTop
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item { Layout.fillWidth: true }

                Button {
                    Layout.preferredWidth: 90
                    implicitHeight: 38

                    background: Rectangle {
                        anchors.fill: parent
                        radius: 5
                        color: "transparent"
                        border.width: 1
                        border.color: "#888"
                    }

                    contentItem: Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Style.colors.textButton
                        font.pixelSize: 12
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: root.close()
                }

                Button {
                    Layout.preferredWidth: 90
                    implicitHeight: 38

                    background: Rectangle {
                        anchors.fill: parent
                        radius: 5
                        color: "#f85149"
                    }

                    contentItem: Text {
                        anchors.centerIn: parent
                        text: "Continue"
                        color: Style.colors.textButton
                        font.pixelSize: 12
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        root.confirmed(root.pendingFile)
                        root.close()
                    }
                }
            }
        }
    }
}