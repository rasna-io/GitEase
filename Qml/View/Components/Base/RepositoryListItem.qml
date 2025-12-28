import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RepositoryListItem
 * Reusable repository list item component displaying name and path
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property int index

    required property var modelData

    property string name:   modelData.name

    property string path:   modelData.name

    property bool   isSelected:     false

    /* Signals
     * ****************************************************************************************/
    signal clicked(index : int)

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.preferredHeight: 50
    color: {
        if (msa.containsMouse) {
            if (isSelected)
                return Style.colors.accentHover
            else
                return Qt.darker(Style.colors.surfaceLight, 1.05)
        } else {
            if (isSelected)
                return Style.colors.accent
            else
                return Style.colors.surfaceLight
        }
    }

    radius: 3

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 2

        // Project name
        Text {
            text: root.name
            font.pixelSize: 12
            font.family: Style.fontTypes.roboto
            font.weight: 400
            font.letterSpacing: 0
            color: root.isSelected ? Style.colors.secondaryForeground : Style.colors.foreground
        }

        // Path row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Folder icon
            Text {
                text: Style.icons.folder
                font.family: Style.fontTypes.font6Pro
                font.pixelSize: 14
                color: root.isSelected ? Style.colors.secondaryForeground : Style.colors.foreground
            }

            // Path
            Text {
                text: root.path
                font.pixelSize: 12
                font.family: Style.fontTypes.roboto
                color: root.isSelected ? Style.colors.secondaryForeground : Style.colors.mutedText
                elide: Text.ElideMiddle
                font.weight: 400
                font.letterSpacing: 0
                Layout.fillWidth: true
            }
        }
    }

    // Mouse area for interaction
    MouseArea {
        id: msa
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: {
            root.clicked(root.index)
        }
    }
}

