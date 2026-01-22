import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

Rectangle{
    id: root

    property alias title: title.text
    property alias details: detailsText.text

    anchors.fill: parent
    color: Style.colors.primaryBackground
    z: 999

    Column {
        id: emptyStateColumn
        anchors.centerIn: parent
        spacing: 10

        // Give the column a concrete width so children using width bindings can render.
        width: Math.min(parent.width, 360)

        Text {
            text: Style.icons.warning
            font.family: Style.fontTypes.font6Pro
            font.pixelSize: 36
            color: Style.colors.mutedText
            horizontalAlignment: Text.AlignHCenter
            width: emptyStateColumn.width
        }

        Text {
            id: title
            font.family: Style.fontTypes.roboto
            font.pixelSize: 16
            font.weight: 500
            color: Style.colors.mutedText
            horizontalAlignment: Text.AlignHCenter
            width: emptyStateColumn.width
            wrapMode: Text.WordWrap
        }

        Text {
            id: detailsText
            font.family: Style.fontTypes.roboto
            font.pixelSize: 12
            font.weight: 400
            color: Style.colors.placeholderText
            horizontalAlignment: Text.AlignHCenter
            width: emptyStateColumn.width
            wrapMode: Text.WordWrap
        }
    }
}
