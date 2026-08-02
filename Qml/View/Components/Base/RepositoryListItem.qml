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

    property string path:   modelData.path

    property bool   isSelected:     false

    property bool   isExists:       false

    /* Signals
     * ****************************************************************************************/
    signal clicked(index : int)

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.preferredHeight: Style.dp(35)
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
                return Style.colors.secondaryBackground
        }
    }

    radius: 3

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.topMargin: 2
        anchors.rightMargin: 6
        anchors.bottomMargin: 2
        spacing: 2

        // Project name
        Text {
            text: root.name
            font.pixelSize: Style.appFont.smallPt
            font.family: Style.fontTypes.inter
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
                font.pixelSize: Style.appFont.smallPt
                color: root.isSelected ? Style.colors.secondaryForeground : Style.colors.foreground
            }

            // Path
            ScrollingText {
                text: root.path
                font.pixelSize: Style.appFont.smallPt
                font.family: Style.fontTypes.inter
                color: root.isSelected ? Style.colors.secondaryForeground : root.isExists ? Style.colors.mutedText : Style.colors.error
                font.weight: 400
                font.strikeout: !root.isExists
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
            if(isExists)
                root.clicked(root.index)
        }
    }
}

