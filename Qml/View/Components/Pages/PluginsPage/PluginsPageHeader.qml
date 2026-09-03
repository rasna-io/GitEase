import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
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
    property var pluginsData: []

    /* Signals
     * ****************************************************************************************/
    signal filterRequested(string text, string mode)
    signal installGepRequested(string gepPath)

    /* Object Properties
     * ****************************************************************************************/
    ListModel {
        id: filterOptionsModel
        ListElement { text: "Installed"; checked: false }
        ListElement { text: "Enabled"; checked: false }
        ListElement { text: "Available"; checked: false }
    }

    FileDialog {
        id: gepFileDialog
        title: "Install plugin from .gep"
        fileMode: FileDialog.OpenFile
        nameFilters: ["GitEase Package (*.gep)"]

        onAccepted: {
            let path = selectedFile.toString().replace(new RegExp("^file://+"), "")
            headerRow.installGepRequested(path)
        }
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
        id: installed
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: Style.dp(6)
        color: Style.colors.pluginBadgeBackground
        border.color: Style.colors.pluginBadgeBorder
        border.width: 1
        radius: Style.dp(10)
        Layout.preferredHeight: installedLabel.implicitHeight + Style.dp(4)
        Layout.preferredWidth: installedLabel.implicitWidth + Style.dp(20)

        Label {
            id: installedLabel
            anchors.centerIn: parent
            text: (headerRow.pluginsData ? headerRow.pluginsData.filter(function(p) { return p.isInstalled }).length : 0) + " installed"
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.h4Pt
            font.bold: true
            color: Style.colors.pluginBadgeText
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
        minHeight: 27
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

    IconButton {
        id: filterButton
        backgroundColor: Style.colors.headerButtonBackground
        hoverBackgroundColor: Style.colors.headerButtonBackgroundHover
        borderColor: Style.colors.headerButtonBorder
        borderWidth: 1
        Layout.preferredHeight: 25

        text: "Filters"
        font.family: Style.fontTypes.inter
        font.weight: Font.Medium
        font.pixelSize: Style.appFont.smallPt
        leftPadding: 12
        rightPadding: 12
        topPadding: 4
        bottomPadding: 4
        spacing: 6

        contentItem: Row {
            spacing: filterButton.spacing

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Style.icons.filter
                font.family: Style.fontTypes.font6Pro
                font.styleName: "Solid"
                font.pixelSize: Style.appFont.smallPt
                color: Style.colors.foreground
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: filterButton.text
                font: filterButton.font
                color: Style.colors.foreground
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Style.icons.caretDown
                font.family: Style.fontTypes.font6Pro
                font.styleName: "Solid"
                font.pixelSize: Style.appFont.smallPt
                color: Style.colors.foreground
            }
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

    IconButton {
        id: installGepButton
        Layout.preferredWidth: 30
        Layout.preferredHeight: 25
        hoverEnabled: true

        icon.color: headerRow.panelOpen ? Style.colors.accent : Style.colors.foreground

        backgroundColor: Style.colors.headerButtonBackground
        hoverBackgroundColor: Style.colors.headerButtonBackgroundHover
        borderColor: Style.colors.headerButtonBorder
        borderWidth: 1

        display: IconButton.IconOnly
        icon.name: Style.icons.upload
        icon.width: Style.appFont.largePt
        icon.height: Style.appFont.largePt
        solidIcon: false

        background: Rectangle {
            radius: 5
            color: !installGepButton.enabled ? Style.colors.primaryBackground :
                   installGepButton.down ? Style.colors.surfaceMuted :
                   installGepButton.hovered ? Style.colors.headerButtonBackgroundHover : Style.colors.headerButtonBackground
            border.width: 1
            border.color: Style.colors.headerButtonBorder
        }

        onClicked: gepFileDialog.open()
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