import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * RepoRadio
 * Compact radio button whose circle and label share one vertical center.
 * ************************************************************************************************/
RadioButton {
    id: rb

    implicitHeight: 24
    padding: 0
    spacing: 0
    font.family: Style.fontTypes.inter
    font.pixelSize: 12

    indicator: Item {}   // drawn inside contentItem instead, for reliable centering

    contentItem: RowLayout {
        spacing: 8

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 15
            implicitHeight: 15
            radius: width / 2
            color: "transparent"
            border.width: 1.5
            border.color: rb.checked ? Style.colors.accent : Style.colors.controlBorder
            Behavior on border.color {
                ColorAnimation {
                    duration: 120
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 7
                height: 7
                radius: width / 2
                color: Style.colors.accent
                visible: rb.checked
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: rb.text
            verticalAlignment: Text.AlignVCenter
            font: rb.font
            color: Style.colors.foreground
        }
    }
}
