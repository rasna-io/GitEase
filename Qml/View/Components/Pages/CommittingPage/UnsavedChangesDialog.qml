import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * UnsavedChangesDialog
 * ************************************************************************************************/

IPopup {
    id: dialog

    /* Property Declarations
     * ****************************************************************************************/
    property string title               : "Save modifications"
    property string message             : "There are unsaved modifications!\nDo you want to save your changes?"

    property string saveTitle           : "Save"
    property string saveDescription     : "The modifications will be saved"

    property string acceptTitle         : "Abort Operation"
    property string acceptDescription   : "Discard all changes and continue"

    property string cancelTitle         : "Cancel"
    property string cancelDescription   : "Return to the editor"

    property bool hasAbort              : true

    /* Signals
     * ****************************************************************************************/
    signal saved()
    signal aborted()
    signal cancelled()

    /* Object Properties
     * ****************************************************************************************/
    modal: true
    focus: true
    width: 580
    height: 350
    closePolicy: Popup.NoAutoClose

    onClosed: destroy()

    contentItem: Rectangle {
        anchors.fill: parent
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Main Icon
                Text {
                    Layout.alignment: Qt.AlignTop
                    text: Style.icons.warning
                    font.family: Style.fontTypes.font6Pro
                    color: Style.colors.warning
                    font.pixelSize: 50
                }

                // Title + Description
                ColumnLayout{
                    Layout.fillWidth: true
                    spacing: 12

                    // Title
                    Text {
                        Layout.fillWidth: true
                        text: dialog.title
                        color: Style.colors.secondaryText
                        font.family: Style.fontTypes.roboto
                        font.bold: true
                        font.pixelSize: 18
                    }

                    // Description
                    Text {
                        Layout.fillWidth: true
                        text: dialog.message
                        wrapMode: Text.Wrap
                        color: Style.colors.secondaryText
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 14
                    }
                }
            }

            // BUTTON 1: Save
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: saveRow.implicitHeight + 16
                border.color: saveMouseArea.containsMouse ? Style.colors.accent : "transparent"
                radius: 6
                visible: true
                color: Style.colors.primaryBackground

                MouseArea {
                    id: saveMouseArea
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        dialog.saved()
                        dialog.close()
                    }
                }

                RowLayout {
                    id: saveRow
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text {
                        text: Style.icons.arrowRight
                        Layout.alignment: Qt.AlignTop
                        color: Style.colors.accent
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: 16
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: dialog.saveTitle
                            color: Style.colors.secondaryText
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Text {
                            text: dialog.saveDescription
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            color: Qt.darker(Style.colors.secondaryText, 1.2)
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 12
                        }
                    }
                }
            }

            // BUTTON 2: Abort
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: abortRow.implicitHeight + 16
                border.color: abortMouseArea.containsMouse ? Style.colors.accent : "transparent"
                radius: 6
                visible: dialog.hasAbort
                color: Style.colors.primaryBackground

                MouseArea {
                    id: abortMouseArea
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        dialog.aborted()
                        dialog.close()
                    }
                }

                RowLayout {
                    id: abortRow
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text {
                        text: Style.icons.arrowRight
                        Layout.alignment: Qt.AlignTop
                        color: Style.colors.accent
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: 16
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: dialog.acceptTitle
                            color: Style.colors.secondaryText
                            font.family: Style.fontTypes.roboto
                            font.bold: true
                            font.pixelSize: 14
                        }
                        Text {
                            text: dialog.acceptDescription
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            color: Qt.darker(Style.colors.secondaryText, 1.2)
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 12
                        }
                    }
                }
            }

            // BUTTON 3: Cancel
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: cancelRow.implicitHeight + 16
                border.color: cancelMouseArea.containsMouse ? Style.colors.accent : "transparent"
                radius: 6
                color: Style.colors.primaryBackground


                MouseArea {
                    id: cancelMouseArea
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        dialog.cancelled()
                        dialog.close()
                    }
                }

                RowLayout {
                    id: cancelRow
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text {
                        text: Style.icons.arrowRight
                        Layout.alignment: Qt.AlignTop
                        color: Style.colors.accent
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: 16
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: dialog.cancelTitle
                            color: Style.colors.secondaryText
                            font.family: Style.fontTypes.roboto
                            font.bold: true
                            font.pixelSize: 14
                        }
                        Text {
                            text: dialog.cancelDescription
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            color: Qt.darker(Style.colors.secondaryText, 1.2)
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
