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
    spacing: 15

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

    Label {
        text: "Plugins"
        font.family: Style.fontTypes.roboto
        font.pixelSize: Style.appFont.h2Pt
        font.bold: true
        color: Style.colors.placeholderText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Rectangle {
        Layout.preferredWidth: 100
        Layout.preferredHeight: 30
        Layout.alignment: Qt.AlignVCenter
        color: "#1F3B82"
        border.color: "#60A5FA"
        border.width: 1
        radius: 10

        Label {
            anchors.fill: parent
            text: "4 installed"
            font.family: Style.fontTypes.roboto
            font.pixelSize: Style.appFont.largerPt
            font.bold: true
            color: "#60A5FA"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Item {
        Layout.fillWidth: true
    }

    TextField {
        id: textFilterField
        placeholderTextColor: Style.colors.descriptionText
        backgroundColor: hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
        Layout.preferredWidth: 300
        minHeight: 25
        placeholderText: "Search plugins"
        text: headerRow.filterText
        font.family: Style.fontTypes.inter
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
        font.family: Style.fontTypes.font6Pro
        font.styleName: (filterOptionsPopup.visible || hovered) ? "Solid" : "Regular"
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
                   filterButton.hovered ? Style.colors.headerButtonBackgroundHover : Style.colors.headerButtonBackground
            border.width: 1
            border.color: Style.colors.headerButtonBorder
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