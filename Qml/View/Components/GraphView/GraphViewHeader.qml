import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * GraphViewHeader
 * ************************************************************************************************/
RowLayout {
    id: headerRow

    /* Property Declarations
     * ****************************************************************************************/
    property var    commitGraph     : null
    property string filterText      : ""
    property string filterStartDate : ""
    property string filterEndDate   : ""

    readonly property bool  compact         : headerRow.parent ? headerRow.parent.width < 650 : false
    property var            navigationRules : ["Author Email", "Author", "Parent 1", "Branch"]
    property string         navigationRule  : navigationRules[0]

    spacing: (parent && parent.width < Style.appHeight) ? 6 : 10
    anchors.leftMargin: (parent && parent.width < Style.appHeight) ? 8 : 20
    anchors.rightMargin: (parent && parent.width < Style.appHeight) ? 4 : 5

    TextField {
        id: textFilterField
        placeholderTextColor: Style.colors.descriptionText
        backgroundColor: hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
        Layout.fillWidth: true
        minHeight: 25
        placeholderText: {
            var selected = filterOptionsPopup.selectedItems
            var display = selected && selected.length > 0
                          ? selected.map(function(it) { return it.text }).join(", ")
                          : ""
            return display.length > 0 ? "Write Filter By " + display : "Write Filter By"
        }
        text: headerRow.filterText
        font.family: Style.fontTypes.roboto
        font.weight: 400
        font.pixelSize: 9
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
        font.pixelSize: 14

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
        x: filterButton.x
        y: filterButton.y + filterButton.height + 6
        model: filterOptionsModel

        onOpened: {
            x = Math.max(0, Math.min(x, parent.width - width))
        }
        onSelectionChanged: function(items) {
            headerRow.applyFilter()
        }
    }

    ListModel {
        id: filterOptionsModel
        ListElement { text: "Messages"; checked: false }
        ListElement { text: "Subjects"; checked: false }
        ListElement { text: "Authors";  checked: false }
        ListElement { text: "Emails";   checked: false }
        ListElement { text: "SHA-1";    checked: false }
    }

    CalendarPopup {
        id: calendarPopup
    }

    Label {
        Layout.leftMargin: compact ? 8 : 40
        color: Style.colors.descriptionText
        text: "From:"
        font.family: Style.fontTypes.roboto
        font.weight: 400
        font.pixelSize: 12
    }

    DateField {
        id: startDateField
        Layout.preferredWidth: compact ? 22 : 90
        Layout.preferredHeight: 25
        compact: compact
        placeholder: "2025-08-30"
        dateString: headerRow.filterStartDate

        onClicked: calendarPopup.openForField(startDateField, headerRow, true)
    }

    Label {
        color: Style.colors.descriptionText
        text: "To:"
        font.family: Style.fontTypes.roboto
        font.weight: 400
        font.pixelSize: 12
    }

    DateField {
        id: endDateField
        Layout.preferredWidth: compact ? 22 : 90
        Layout.preferredHeight: 25
        compact: compact
        placeholder: "2025-09-30"
        dateString: headerRow.filterEndDate

        onClicked: calendarPopup.openForField(endDateField, headerRow, false)
    }

    ComboBox {
        id: columnCombo
        model: navigationRules

        Layout.leftMargin: compact ? 6 : 20
        minHeight: 26
        visible: !compact
        borderWidth: 0
        focusBorderWidth: 1
        font.family: Style.fontTypes.roboto
        font.weight: 400
        font.pixelSize: 10

        Material.background: Style.colors.primaryBackground
        Material.foreground: Style.colors.secondaryText

        background: Rectangle {
            radius: 5
            color: columnCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
        }

        Layout.preferredWidth: 90
        currentIndex: navigationRules.indexOf(navigationRule)
        onActivated: function(index) {
            navigationRule = navigationRules[index]
            headerRow.applyFilter()
        }
    }

    ToolButton {
        id: downButton
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26

        visible: !compact
        enabled: !!headerRow.commitGraph
        hoverEnabled: true

        text: Style.icons.caretDown
        font.family: Style.fontTypes.font6ProSolid
        font.pixelSize: 15

        contentItem: Text {
            anchors.centerIn: parent
            text: downButton.text
            font: downButton.font
            color: downButton.enabled ? Style.colors.foreground : Style.colors.mutedText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: 5
            color: !downButton.enabled ? Style.colors.primaryBackground :
                   downButton.down ? Style.colors.surfaceMuted :
                   downButton.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
        }

        onClicked: headerRow.commitGraph.selectNext(navigationRule)
    }

    ToolButton {
        id: upButton
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26

        visible: !compact
        enabled: !!headerRow.commitGraph
        hoverEnabled: true

        text: Style.icons.caretUp
        font.family: Style.fontTypes.font6ProSolid
        font.pixelSize: 15

        contentItem: Text {
            anchors.centerIn: parent
            text: upButton.text
            font: upButton.font
            color: upButton.enabled ? Style.colors.foreground : Style.colors.mutedText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: 5
            color: !upButton.enabled ? Style.colors.primaryBackground :
                   upButton.down ? Style.colors.surfaceMuted :
                   upButton.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
        }

        onClicked: headerRow.commitGraph.selectPrevious(navigationRule)
    }

    ToolButton {
        id: reloadButton
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
        Layout.leftMargin: 10

        enabled: !!headerRow.commitGraph
        hoverEnabled: true

        text: Style.icons.refresh
        font.family: Style.fontTypes.font6Pro
        font.pixelSize: 14

        contentItem: Text {
            anchors.centerIn: parent
            text: reloadButton.text
            font: reloadButton.font
            color: reloadButton.enabled ? Style.colors.foreground : Style.colors.mutedText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: 5
            color: !reloadButton.enabled ? Style.colors.primaryBackground :
                   reloadButton.down ? Style.colors.surfaceMuted :
                   reloadButton.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
        }

        onClicked: headerRow.commitGraph.reloadAll()
    }

    function applyFilter() {
        if (!headerRow.commitGraph)
            return;

        var selectedItems = filterOptionsPopup.selectedItems;
        var modes = selectedItems && selectedItems.length > 0
                     ? selectedItems.map(function(it) { return it.text })
                     : [];
        headerRow.commitGraph.applyFilter(headerRow.filterText,
                                          headerRow.filterStartDate,
                                          headerRow.filterEndDate,
                                          modes);

    }
}
