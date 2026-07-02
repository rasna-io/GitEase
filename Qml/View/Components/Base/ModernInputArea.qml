import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style_Impl
import GitEase_Style
import GitEase

/*! ***********************************************************************************************
 * ModernInputArea
 * Modern Input Area, shown text character count and ...
 * ************************************************************************************************/
Rectangle {

    /* Property Declarations
     * ****************************************************************************************/
    property alias text:        commitTextArea.text
    property alias placeholder: commitTextArea.placeholderText

    property int    minLines            : 3
    property int    maxLines            : 10
    property real   lineHeightMultiplier: 1.2

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.primaryBackground
    radius: 4
    border.width: 1
    border.color: commitTextArea.activeFocus ? Style.colors.accent : Style.colors.primaryBorder

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: commitTextArea
                placeholderTextColor: Style.colors.placeholderText
                color: Style.colors.foreground
                font.family: Style.fontTypes.roboto
                font.pixelSize: 14
                wrapMode: TextEdit.Wrap
                leftPadding: 12;
                topPadding: 12;
                rightPadding: 12
                selectByMouse: true
                background: null
                selectionColor: Style.colors.accent
                selectedTextColor: Style.colors.secondaryForeground
                Material.accent: Style.colors.accent
            }
        }

        // Character Count & Branch Hint
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12; anchors.rightMargin: 12
                Item { Layout.fillWidth: true }
                Text {
                    text: commitTextArea.text.length + " characters"
                    font.pixelSize: 10
                    color: Style.colors.placeholderText
                }
            }
        }
    }
}
