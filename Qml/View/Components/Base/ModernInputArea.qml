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
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property alias text:        commitTextArea.text
    property alias placeholder: commitTextArea.placeholderText

    property int    minLines            : 3
    property int    maxLines            : 10
    property real   lineHeightMultiplier: 1.3

    readonly property real  effectiveLineHeight : commitTextArea.font.pixelSize * lineHeightMultiplier

    readonly property int   counterHeight       : 24
    readonly property int   verticalPadding     : 24

    readonly property int   horizontalTextPadding: 10
    readonly property int   verticalTextPadding  : 8

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.actionPillBg
    radius: 5
    border.width: 1
    border.color: commitTextArea.activeFocus ? Style.colors.accent : Style.colors.chipBorder

    implicitHeight: {
        var lines = commitTextArea.lineCount
        var desiredLines = Math.min(maxLines, Math.max(minLines, lines))
        return desiredLines * effectiveLineHeight + verticalPadding + counterHeight
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: commitTextArea
                floatingPlaceholderEnabled: false

                width: parent.width

                placeholderTextColor: Style.colors.placeholderText
                color: Style.colors.foreground

                font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                font.weight: Font.Normal

                wrapMode: TextEdit.Wrap
                    leftPadding: root.horizontalTextPadding
                    topPadding: root.verticalTextPadding
                    rightPadding: root.horizontalTextPadding
                    bottomPadding: root.verticalTextPadding

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
                anchors.leftMargin: 10
                anchors.rightMargin: 10

                Item { Layout.fillWidth: true }

                Text {
                    text: commitTextArea.text.length + " characters"
                    font.pixelSize: Style.appFont.smallPt
                    color: Style.colors.placeholderText
                }
            }
        }
    }
}
