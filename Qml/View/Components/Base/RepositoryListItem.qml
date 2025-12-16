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
    property string repositoryName: ""
    property string repositoryPath: ""

    /* Signals
     * ****************************************************************************************/
    signal clicked()

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.preferredHeight: 50
    color: Style.colors.surfaceLight
    radius: 3

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 2

        // Project name
        Text {
            text: root.repositoryName
            font.pixelSize: 12
            font.family: Style.fontTypes.roboto
            font.weight: 400
            font.letterSpacing: 0
            color: Style.colors.foreground
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
                color: Style.colors.foreground
            }

            // Path
            Text {
                text: root.repositoryPath
                font.pixelSize: 12
                font.family: Style.fontTypes.roboto
                color: Style.colors.mutedText
                elide: Text.ElideMiddle
                font.weight: 400
                font.letterSpacing: 0
                Layout.fillWidth: true
            }
        }
    }

    // Mouse area for interaction
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onEntered: {
            root.color = Qt.darker(Style.colors.surfaceLight, 1.05)
        }

        onExited: {
            root.color = Style.colors.surfaceLight
        }

        onClicked: {
            root.clicked()
        }
    }
}

