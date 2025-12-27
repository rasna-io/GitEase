import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * RecentRepositoriesList
 * Reusable component to display recent repositories list
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property alias model: repositoryRepeater.model

    property int  selectedIndex: -1

    /* Signals
     * ****************************************************************************************/

    signal repositoryClicked(string name, string path)

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 7

        Text {
            text: "Recents"
            font.pixelSize: 12
            font.family: Style.fontTypes.roboto
            font.weight: 400
            font.letterSpacing: 0
            color: Style.colors.foreground
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 7

                Repeater {
                    id: repositoryRepeater

                    delegate: RepositoryListItem {
                        id: item
                        isSelected: root.selectedIndex === item.index

                        onClicked: (index) => {
                            root.selectedIndex = index
                            root.repositoryClicked(item.name, item.path)
                        }
                    }
                }
            }
        }
    }
}

