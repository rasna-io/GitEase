import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ManageStashesView
 * View for managing existing stashes
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property StashController stashController: null
    property var stashes: []

    /* Signals
     * ****************************************************************************************/
    signal refreshRequested()
    signal stashApplied()
    signal stashPopped()
    signal stashRemoved()

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Refresh button
        Button {
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32

            contentItem: Text {
                anchors.centerIn: parent
                text: Style.icons.refresh
                font.family: Style.fontTypes.font6Pro
                font.pixelSize: 14
                color: Style.colors.secondaryForeground
            }

            background: Rectangle {
                radius: 4
                color: Style.colors.primaryBackground
                border.width: 1
                border.color: Style.colors.primaryBorder
            }

            onClicked: {
                root.refreshRequested()
            }
        }

        // Stashes List in ScrollView
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 8

                Repeater {
                    model: stashes

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        color: Style.colors.primaryBackground
                        radius: 4
                        border.width: 1
                        border.color: Style.colors.primaryBorder

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            // Stash info (left side)
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 4

                                // Message on top
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.message || qsTr("WIP on %1").arg(modelData.author || "unknown")
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 8
                                    font.weight: Font.Medium
                                    color: Style.colors.foreground
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.WordWrap
                                }

                                // Time created below message
                                Text {
                                    text: modelData.dateTime ? Qt.formatDateTime(modelData.dateTime, "MMM dd, yyyy 'at' hh:mm") : ""
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 6
                                    color: Style.colors.secondaryText
                                }
                            }

                            // Action buttons (right side)
                            RowLayout {
                                Layout.preferredWidth: 140
                                Layout.fillHeight: true
                                spacing: 8

                                Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: qsTr("Apply")

                                    background: Rectangle {
                                        radius: 4
                                        color: Style.colors.accent
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: Style.colors.secondaryForeground
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    onClicked: {
                                        let result = stashController.apply(modelData.index, true)
                                        if (result.success) {
                                            root.refreshRequested()
                                            root.stashApplied()
                                        } else {
                                            console.error("Failed to apply stash:", result.errorMessage)
                                        }
                                    }
                                }

                                Button {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: qsTr("Drop")

                                    background: Rectangle {
                                        radius: 4
                                        color: Style.colors.error
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: Style.colors.secondaryForeground
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    onClicked: {
                                        let result = stashController.remove(modelData.index)
                                        if (result.success) {
                                            root.refreshRequested()
                                            root.stashRemoved()
                                        } else {
                                            console.error("Failed to drop stash:", result.errorMessage)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Empty state when no stashes
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    color: "transparent"
                    visible: stashes.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 16

                        Text {
                            text: Style.icons.archive
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: 48
                            color: Style.colors.placeholderText
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: qsTr("No stashes found")
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 14
                            color: Style.colors.placeholderText
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: qsTr("Switch to 'Create Stash' tab to save your current changes")
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 12
                            color: Style.colors.secondaryText
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            Layout.maximumWidth: parent.width * 0.8
                        }
                    }
                }
            }
        }

        // Empty state
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            visible: stashesList.count === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    text: Style.icons.archive
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: 48
                    color: Style.colors.placeholderText
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: qsTr("No stashes found")
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 14
                    color: Style.colors.placeholderText
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: qsTr("Switch to 'Create Stash' tab to save your current changes")
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 12
                    color: Style.colors.secondaryText
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.maximumWidth: parent.width * 0.8
                }
            }
        }
    }
}
