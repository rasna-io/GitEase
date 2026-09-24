import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RepoForestLogs
 * ************************************************************************************************/
ColumnLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var  operationLogs:        []
    property bool showOperationLogs:    false

    /* Object Properties
     * ****************************************************************************************/
    spacing: 8

    /* Signals
    * ****************************************************************************************/
    signal clearLogsRequested()

    /* Children
    * ****************************************************************************************/
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: "Operation Log"
            font.family: Style.fontTypes.inter
            font.pixelSize: 12
            font.bold: true
            color: Style.colors.foreground
        }

        ToolButton {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            hoverEnabled: true
            contentItem: Text {
                anchors.centerIn: parent
                text: root.showOperationLogs ? Style.icons.caretDown : Style.icons.caretUp
                font.pixelSize: 14
                font.family: Style.fontTypes.font6ProSolid
                color: Style.colors.foreground
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                radius: 5
                color: parent.hovered ? Style.colors.cardBackground : "transparent"
            }
            onClicked: root.showOperationLogs = !root.showOperationLogs
        }

        ToolButton {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            hoverEnabled: true
            contentItem: Text {
                anchors.centerIn: parent
                text: Style.icons.trash
                font.pixelSize: 12
                font.family: Style.fontTypes.font6ProSolid
                color: Style.colors.windowsClose
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                radius: 5
                color: parent.hovered ? Style.colors.cardBackground : "transparent"
            }
            onClicked: {
                root.clearLogsRequested()
                root.showOperationLogs = false
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: root.showOperationLogs ? 150 : 0
        radius: 3
        color: Style.colors.secondaryBackground
        border.color: Style.colors.primaryBorder
        clip: true

        Behavior on Layout.preferredHeight {
            NumberAnimation { duration: 300 }
        }

        ScrollView {
            anchors.fill: parent
            anchors.margins: 4
            clip: true

            ListView {
                width: parent.width
                model: root.operationLogs
                spacing: 4

                highlightMoveDuration: 150

                delegate: RowLayout {
                    width: ListView.width
                    spacing: 6

                    Text {
                        Layout.preferredWidth: 60
                        text: modelData.timestamp
                        font.family: Style.fontTypes.inter
                        font.pixelSize: 11
                        color: Style.colors.mutedText
                    }

                    Text {
                        Layout.preferredWidth: 120
                        text: modelData.repoName
                        font.family: Style.fontTypes.inter
                        font.pixelSize: 11
                        font.bold: true
                        color: Style.colors.foreground
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.preferredWidth: 80
                        text: "[" + modelData.operation.toUpperCase() + "]"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: 11
                        color: modelData.operation === "fetch" ? Style.colors.repoItemStatusFetchingText : Style.colors.repoItemStatusPullingText
                    }

                    Text {
                        Layout.preferredWidth: 80
                        text: modelData.remoteName ? ("@" + modelData.remoteName) : ""
                        font.family: Style.fontTypes.inter
                        font.pixelSize: 11
                        color: Style.colors.mutedText
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.message
                        font.family: Style.fontTypes.inter
                        font.pixelSize: 11
                        color: {
                            if (modelData.status === "Success" || modelData.status === "Done")
                                return Style.colors.repoItemStatusDoneText

                            if (modelData.status === "Failed" || modelData.status === "Canceled")
                                return Style.colors.repoItemStatusCanceledText

                            return Style.colors.foreground
                        }
                        elide: Text.ElideRight
                    }
                }

                onCountChanged: {
                    if (count > 0) {
                        positionViewAtIndex(count - 1, ListView.End)
                    }
                }
            }
        }
    }
}
