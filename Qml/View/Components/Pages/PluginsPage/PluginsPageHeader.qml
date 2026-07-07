import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * PluginsPageHeader
 * ************************************************************************************************/
RowLayout {
    id: headerRow

    /* Property Declarations
     * ****************************************************************************************/
    property string filterText: ""

    /* Signals
     * ****************************************************************************************/
    signal filterRequested(string text, string mode)

    /* Object Properties
     * ****************************************************************************************/
    ListModel {
        id: filterOptionsModel
        ListElement { text: "Installed"; checked: false }
        ListElement { text: "Enabled"; checked: false }
        ListElement { text: "Available"; checked: false }
    }

    TextField {
        id: textFilterField
        placeholderTextColor: Style.colors.descriptionText
        backgroundColor: hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
        Layout.fillWidth: true
        minHeight: 25
        placeholderText: "Search plugins"
        text: headerRow.filterText
        font.family: Style.fontTypes.roboto
        font.weight: 400
        font.pixelSize: Style.appFont.captionPt
        borderRadius: 5
        borderWidth: 0
        focusBorderWidth: 1
        onTextChanged: {
            headerRow.filterText = text
            headerRow.applyFilter()
        }
    }

    ToolButton {
        id: filterButton
        Layout.preferredWidth: 25
        Layout.preferredHeight: 25
        hoverEnabled: true

        text: Style.icons.filter
        font.family: (filterOptionsPopup.visible || hovered)
                     ? Style.fontTypes.font6ProSolid
                     : Style.fontTypes.font6Pro
        font.pixelSize: Style.appFont.largePt

        contentItem: Text {
            anchors.centerIn: parent
            text: filterButton.text
            font: filterButton.font
            color: filterButton.enabled ? Style.colors.foreground : Style.colors.mutedText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: 5
            color: !filterButton.enabled ? Style.colors.primaryBackground :
                   filterButton.down ? Style.colors.surfaceMuted :
                   filterButton.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
        }

        onClicked: filterOptionsPopup.open()
    }

    ItemSelectorPopup {
        id: filterOptionsPopup
        x: Math.max(0, Math.min(filterButton.x, parent.width - width))
        y: filterButton.y + filterButton.height + 6
        model: filterOptionsModel
        multiSelection: false

        onSelectionChanged: function(items) {
            headerRow.applyFilter()
        }
    }

    /* Functions
     * ****************************************************************************************/
    function applyFilter() {
        var selectedItem = filterOptionsPopup.selectedItems;

        var mode = filterOptionsPopup.selectedItems.length > 0
                     ? filterOptionsPopup.selectedItems[0].text
                     : [];
        headerRow.filterRequested(headerRow.filterText, mode);
    }
}