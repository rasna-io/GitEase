import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ConflictConfirmationDialog
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
    property string acceptDescription   : "Discard all changes and exit"

    property string cancelTitle         : "Keep Resolving"
    property string cancelDescription   : "Return to the conflict editor"

    property bool hasAbort              : true

    property bool hasSave               : false

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
    height: 280
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
                    font.pixelSize: Style.appFont.display2xlPt
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
                        font.family: Style.fontTypes.inter
                        font.bold: true
                        font.pixelSize: Style.appFont.xlPt
                    }

                    // Description
                    Text {
                        Layout.fillWidth: true
                        text: dialog.message
                        wrapMode: Text.Wrap
                        color: Style.colors.secondaryText
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.largePt
                    }
                }
            }

            // BUTTON 1: Save
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: saveRow.implicitHeight + 16
                border.color: saveMouseArea.containsMouse ? Style.colors.accent : "transparent"
                radius: 6
                visible: dialog.hasSave
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
                        font.pixelSize: Style.appFont.h2Pt
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: dialog.saveTitle
                            color: Style.colors.secondaryText
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.largePt
                            font.bold: true
                        }
                        Text {
                            text: dialog.saveDescription
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            color: Qt.darker(Style.colors.secondaryText, 1.2)
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.mediumPt
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
                        font.pixelSize: Style.appFont.h2Pt
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: dialog.acceptTitle
                            color: Style.colors.secondaryText
                            font.family: Style.fontTypes.inter
                            font.bold: true
                            font.pixelSize: Style.appFont.largePt
                        }
                        Text {
                            text: dialog.acceptDescription
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            color: Qt.darker(Style.colors.secondaryText, 1.2)
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.mediumPt
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
                        font.pixelSize: Style.appFont.h2Pt
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: dialog.cancelTitle
                            color: Style.colors.secondaryText
                            font.family: Style.fontTypes.inter
                            font.bold: true
                            font.pixelSize: Style.appFont.largePt
                        }
                        Text {
                            text: dialog.cancelDescription
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            color: Qt.darker(Style.colors.secondaryText, 1.2)
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.mediumPt
                        }
                    }
                }
            }
        }
    }
}
