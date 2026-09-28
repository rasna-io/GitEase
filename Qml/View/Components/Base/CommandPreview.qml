import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * CommandPreview
 * Shows the git command a form is about to run. The text comes from GitCommandText, the same
 * builder the controllers use when they report what they ran, so the preview cannot promise
 * something different from what happens.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string command: ""

    property string placeholder: ""

    property bool copyable: true

    readonly property bool hasCommand: root.command.trim().length > 0

    /* Signals
     * ****************************************************************************************/
    signal copied()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: Math.max(28, commandText.implicitHeight + 10)
    radius: 5
    color: Style.colors.popupCommandPreviewBackground
    border.width: 1
    border.color: Style.colors.popupCommandPreviewBorder

    /* Children
     * ****************************************************************************************/
    TextEdit {
        id: clipboardHelper
        visible: false
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: root.copyable ? 4 : 10
        spacing: 6

        Text {
            id: commandText
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            text: root.hasCommand ? root.command : root.placeholder
            color: root.hasCommand ? Style.colors.popupCommandPreviewText
                                   : Style.colors.placeholderText

            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.defaultPt

            wrapMode: Text.WrapAnywhere
            maximumLineCount: 2
            elide: Text.ElideRight

            ToolTip.visible: hoverArea.containsMouse && commandText.truncated
            ToolTip.text: root.command
            ToolTip.delay: 400

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }

        ActionIconButton {
            visible: root.copyable && root.hasCommand
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            Layout.alignment: Qt.AlignVCenter

            iconText: Style.icons.copy
            tooltip: qsTr("Copy command")
            textColor: Style.colors.popupCommandPreviewText

            onClicked: {
                clipboardHelper.text = root.command
                clipboardHelper.selectAll()
                clipboardHelper.copy()
                root.copied()
            }
        }
    }
}
