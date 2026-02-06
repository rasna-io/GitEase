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

    /* Private Properties
     * ****************************************************************************************/
    property var stashes: []

    /* Signals
     * ****************************************************************************************/

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Component Lifecycle
     * ****************************************************************************************/
    Component.onCompleted: {
        loadStashes()
    }

    onStashControllerChanged: {
        loadStashes()
    }

    onVisibleChanged: {
        if (visible) {
            loadStashes()
        }
    }


    /* Functions
     * ****************************************************************************************/
    function loadStashes() {
        if (!stashController)
            return

        let result = stashController.list()
        if (result.success) {
            stashes = result.data
        } else {
            stashes = []
        }
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        visible: stashes.length > 0

        // Stashes List in ScrollView
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            rightPadding: 14

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

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

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

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: modelData.dateTime ? Qt.formatDateTime(modelData.dateTime, "MMM dd, yyyy 'at' hh:mm") : ""
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 7
                                    color: Style.colors.secondaryText
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                RowLayout {
                                    spacing: 10

                                    Text {
                                        text: qsTr("Apply")
                                        color: Style.colors.link || "#3b82f6"
                                        font.family: Style.fontTypes.roboto
                                        font.pixelSize: 7
                                        font.weight: Font.Medium

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor

                                            onClicked: {
                                                let result = stashController.apply(modelData.index, true)
                                                if (result.success) {
                                                    loadStashes()
                                                }
                                            }

                                            onEntered: parent.opacity = 0.7
                                            onExited: parent.opacity = 1.0
                                        }
                                    }


                                    Text {
                                        text: qsTr("Drop")
                                        color: Style.colors.error
                                        font.family: Style.fontTypes.roboto
                                        font.pixelSize: 7
                                        font.weight: Font.Medium

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor

                                            onClicked: {
                                                let result = stashController.remove(modelData.index)
                                                if (result.success) {
                                                    loadStashes()
                                                }
                                            }

                                            onEntered: parent.opacity = 0.7
                                            onExited: parent.opacity = 1.0
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
