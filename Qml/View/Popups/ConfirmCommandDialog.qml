import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ConfirmCommandDialog
 * Asks before an action that cannot be undone from inside the app, and shows the exact command it
 * is about to run. Open it with ask(); the caller handles confirmed().
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string title:       ""
    property string message:     ""
    property string command:     ""
    property string confirmText: qsTr("Delete")

    //! Anything the caller needs back in confirmed(), e.g. which stash index was being dropped.
    property var context: null

    /* Signals
     * ****************************************************************************************/
    signal confirmed(var context)

    /* Object Properties
     * ****************************************************************************************/
    width: 460
    height: contentItem.implicitHeight
    padding: 0

    closePolicy: Popup.CloseOnEscape

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        implicitHeight: layout.implicitHeight
        color: Style.colors.popupBackground
        radius: 8
        clip: true
        border.color: Style.colors.popupBorder
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                spacing: 8

                Text {
                    text: Style.icons.warning
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.appFont.mediumPt
                    color: Style.colors.error
                }

                Text {
                    text: root.title
                    color: Style.colors.popupTitleText
                    font.family: Style.fontTypes.inter
                    font.weight: Font.DemiBold
                    font.pixelSize: Style.appFont.mediumPt
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: "×"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                    color: closeMouse.containsMouse ? Style.colors.popupCloseButtonHover
                                                    : Style.colors.popupCloseButton
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Style.colors.popupHeaderSeparator
            }

            // Body
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                Layout.topMargin: 16
                Layout.bottomMargin: 12
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: root.message
                    color: Style.colors.popupCheckboxLabelText
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.defaultPt
                    wrapMode: Text.WordWrap
                }

                CommandPreview {
                    Layout.fillWidth: true
                    command: root.command
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Style.colors.popupHeaderSeparator
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                Layout.topMargin: 12
                Layout.bottomMargin: 12
                spacing: 8

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: qsTr("Cancel")
                    Layout.preferredWidth: 100
                    Layout.alignment: Qt.AlignVCenter
                    topPadding: 6
                    bottomPadding: 6
                    leftPadding: 14
                    rightPadding: 14

                    background: Rectangle {
                        implicitHeight: 32
                        color: "transparent"
                        border.color: Style.colors.popupCancelButtonBorder
                        border.width: 1
                        radius: 5
                        opacity: parent.hovered ? 1.0 : 0.7
                    }

                    contentItem: Text {
                        text: parent.text
                        color: Style.colors.popupCancelButtonText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }

                Button {
                    id: confirmButton
                    text: root.confirmText
                    Layout.preferredWidth: 130
                    Layout.alignment: Qt.AlignVCenter
                    topPadding: 6
                    bottomPadding: 6
                    leftPadding: 16
                    rightPadding: 16

                    background: Rectangle {
                        implicitHeight: 32
                        color: confirmButton.hovered ? Qt.darker(Style.colors.error, 1.15)
                                                     : Style.colors.error
                        radius: 5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let callerContext = root.context
                            root.close()
                            root.confirmed(callerContext)
                        }
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function ask(dialogTitle, dialogMessage, dialogCommand, buttonText, callerContext) {
        root.title       = dialogTitle
        root.message     = dialogMessage
        root.command     = dialogCommand
        root.confirmText = buttonText
        root.context     = callerContext ?? null
        root.open()
    }
}
