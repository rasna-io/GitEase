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
    property bool   isGraphReady    : false
    property string filterText      : ""
    property string filterStartDate : ""
    property string filterEndDate   : ""
    property var    filterModes     : []
    property bool   syncingFilterModes: false
    property var    branchNames     : []
    property string branchFilter    : ""
    property bool   suppressBranchSelectorOpen: false

    readonly property bool  compact         : headerRow.parent ? headerRow.parent.width < 650 : false
    readonly property bool  tight           : headerRow.parent ? headerRow.parent.width < 820 : false
    readonly property bool  crowded         : headerRow.parent ? headerRow.parent.width < 760 : false
    readonly property bool  branchFilterActive: branchFilter.length > 0
    readonly property bool  branchSelectorOpen: !suppressBranchSelectorOpen
                                                 && (branchSelectorArea.hovered || branchCombo.activeFocus || branchCombo.popup.visible)
    readonly property bool  hasStartDate    : filterStartDate.length > 0
    readonly property bool  hasEndDate      : filterEndDate.length > 0
    readonly property bool  hasDateRange    : hasStartDate || hasEndDate
    readonly property real  branchSelectorClosedWidth: branchFilterActive
                                                       ? Math.min(compact ? 96 : (tight ? 118 : 150),
                                                                  Math.max(48, branchChipMetrics.advanceWidth + 42))
                                                       : 26
    readonly property real  branchSelectorOpenWidth: compact ? 118 : (tight ? 142 : 174)
    readonly property real  dateFieldWidth : compact ? 72 : (tight ? 78 : 90)
    readonly property real  columnWidth    : crowded ? 0 : (tight ? 96 : 112)
    readonly property int   controlSize     : 26
    property var            navigationRules : ["Author Email", "Author", "Parent 1", "Branch"]
    property string         navigationRule  : navigationRules[0]

    /* Signals
     * ****************************************************************************************/
    signal filterRequested(string text, string startDate, string endDate, var modes)
    signal branchSelected(string branchName)
    signal nextRequested(string rule)
    signal previousRequested(string rule)
    signal reloadRequested()

    /* Object Properties
     * ****************************************************************************************/
    spacing             : (parent && parent.width < Style.appHeight) ? 6 : 10
    anchors.leftMargin  : (parent && parent.width < Style.appHeight) ? 8 : 20
    anchors.rightMargin : (parent && parent.width < Style.appHeight) ? 4 : 5

    ListModel {
        id: filterOptionsModel
        ListElement { text: "Messages"; checked: false }
        ListElement { text: "Subjects"; checked: false }
        ListElement { text: "Authors";  checked: false }
        ListElement { text: "Emails";   checked: false }
        ListElement { text: "SHA-1";    checked: false }
    }

    TextMetrics {
        id: branchChipMetrics
        text: headerRow.branchFilter
        font.family: Style.fontTypes.roboto
        font.pixelSize: Style.appFont.defaultPt
        font.weight: Font.Medium
    }

    Item {
        id: textFilterArea
        Layout.fillWidth: true
        Layout.minimumWidth: compact ? 42 : (crowded ? 64 : (tight ? 96 : 100))
        Layout.preferredHeight: headerRow.controlSize
        clip: true

        TextField {
            id: textFilterField
            width: textFilterArea.width
            height: textFilterArea.height
            placeholderTextColor: Style.colors.descriptionText
            backgroundColor: hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
            minHeight: headerRow.controlSize
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
            font.pixelSize: Style.appFont.captionPt
            borderRadius: 5
            borderWidth: 0
            focusBorderWidth: 1
            onTextChanged: {
                headerRow.filterText = text
                headerRow.applyFilter()
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    ToolButton {
        id: filterButton
        Layout.preferredWidth: headerRow.controlSize
        Layout.preferredHeight: headerRow.controlSize
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
        x: filterButton.x
        y: filterButton.y + filterButton.height + 6
        model: filterOptionsModel

        onOpened: {
            x = Math.max(0, Math.min(x, parent.width - width))
        }
        onSelectionChanged: function(items) {
            if (headerRow.syncingFilterModes)
                return

            headerRow.applyFilter()
        }
    }

    Label {
        id: fromLabel
        Layout.leftMargin: headerRow.hasDateRange ? (compact ? 4 : (tight ? 8 : 14)) : 0
        color: Style.colors.descriptionText
        text: "From:"
        opacity: headerRow.hasDateRange && !branchSelectorOpen ? 1 : 0
        visible: (headerRow.hasDateRange && !branchSelectorOpen) || opacity > 0
        font.family: Style.fontTypes.roboto
        font.weight: 400
        font.pixelSize: Style.appFont.defaultPt

        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    DateField {
        id: startDateField
        Layout.leftMargin: headerRow.hasDateRange ? 0 : (compact ? 4 : (tight ? 8 : 14))
        Layout.preferredWidth: branchSelectorOpen ? 0 : (headerRow.hasDateRange && headerRow.hasStartDate ? headerRow.dateFieldWidth : headerRow.controlSize)
        Layout.preferredHeight: headerRow.controlSize
        opacity: branchSelectorOpen ? 0 : 1
        compact: compact
        iconOnly: !headerRow.hasStartDate
        placeholder: "2025-08-30"
        dateString: headerRow.filterStartDate

        onClicked: calendarPopup.prepareAndOpen(startDateField, true, headerRow.filterStartDate, headerRow.filterEndDate)

        Behavior on Layout.preferredWidth {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    Label {
        id: toLabel
        color: Style.colors.descriptionText
        text: "To:"
        opacity: headerRow.hasDateRange && !branchSelectorOpen ? 1 : 0
        visible: (headerRow.hasDateRange && !branchSelectorOpen) || opacity > 0
        font.family: Style.fontTypes.roboto
        font.weight: 400
        font.pixelSize: Style.appFont.defaultPt

        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    DateField {
        id: endDateField
        Layout.preferredWidth: branchSelectorOpen || !headerRow.hasDateRange ? 0 : (headerRow.hasEndDate ? headerRow.dateFieldWidth : headerRow.controlSize)
        Layout.preferredHeight: headerRow.controlSize
        opacity: branchSelectorOpen || !headerRow.hasDateRange ? 0 : 1
        visible: headerRow.hasDateRange || opacity > 0
        compact: compact
        iconOnly: !headerRow.hasEndDate
        placeholder: "2025-09-30"
        dateString: headerRow.filterEndDate

        onClicked: calendarPopup.prepareAndOpen(endDateField, false, headerRow.filterEndDate, headerRow.filterStartDate)

        Behavior on Layout.preferredWidth {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    ComboBox {
        id: columnCombo
        model: navigationRules

        Layout.leftMargin: compact || crowded ? 0 : (tight ? 6 : 8)
        Layout.preferredWidth: branchSelectorOpen ? 0 : headerRow.columnWidth
        minHeight: headerRow.controlSize
        visible: !compact && !crowded
        enabled: !branchSelectorOpen
        opacity: branchSelectorOpen ? 0 : 1
        borderWidth: 0
        focusBorderWidth: 1
        font.family: Style.fontTypes.roboto
        font.weight: 400
        font.pixelSize: Style.appFont.smallPt

        Material.background: Style.colors.primaryBackground
        Material.foreground: Style.colors.secondaryText

        background: Rectangle {
            radius: 5
            color: columnCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
        }

        currentIndex: navigationRules.indexOf(navigationRule)
        onActivated: function(index) {
            navigationRule = navigationRules[index]
            headerRow.applyFilter()
        }

        Behavior on Layout.preferredWidth {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    ToolButton {
        id: downButton
        Layout.preferredWidth: headerRow.controlSize
        Layout.preferredHeight: headerRow.controlSize

        visible: !compact && !crowded
        enabled: headerRow.isGraphReady
        hoverEnabled: true

        text: Style.icons.caretDown
        font.family: Style.fontTypes.font6ProSolid
        font.pixelSize: Style.appFont.largerPt

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

        onClicked: headerRow.previousRequested(navigationRule)
    }

    ToolButton {
        id: upButton
        Layout.preferredWidth: headerRow.controlSize
        Layout.preferredHeight: headerRow.controlSize

        visible: !compact && !crowded
        enabled: headerRow.isGraphReady
        hoverEnabled: true

        text: Style.icons.caretUp
        font.family: Style.fontTypes.font6ProSolid
        font.pixelSize: Style.appFont.largerPt

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

        onClicked: headerRow.nextRequested(navigationRule)
    }

    Item {
        id: branchSelectorArea

        property bool hovered: branchSelectorHover.hovered

        Layout.leftMargin: compact ? 3 : (tight ? 5 : 7)
        Layout.preferredWidth: branchSelectorOpen
                               ? headerRow.branchSelectorOpenWidth
                               : headerRow.branchSelectorClosedWidth
        Layout.preferredHeight: headerRow.controlSize
        visible: headerRow.branchNames && headerRow.branchNames.length > 0
        enabled: headerRow.isGraphReady

        HoverHandler {
            id: branchSelectorHover
            onHoveredChanged: {
                if (!hovered)
                    headerRow.suppressBranchSelectorOpen = false
            }
        }

        ToolButton {
            id: branchButton
            anchors.fill: parent
            enabled: branchSelectorArea.enabled
            hoverEnabled: false
            opacity: branchSelectorOpen ? 0 : 1

            text: Style.icons.branch
            font.family: headerRow.branchFilter.length > 0 || branchSelectorOpen
                         ? Style.fontTypes.font6ProSolid
                         : Style.fontTypes.font6Pro
            font.pixelSize: Style.appFont.largePt

            contentItem: Item {
                clip: true

                Row {
                    anchors.centerIn: parent
                    spacing: headerRow.branchFilterActive ? 5 : 0
                    height: parent.height

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: branchButton.text
                        font: branchButton.font
                        color: branchButton.enabled ? Style.colors.foreground : Style.colors.mutedText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: Math.max(0, branchSelectorArea.width - 36)
                        anchors.verticalCenter: parent.verticalCenter
                        visible: headerRow.branchFilterActive
                        text: headerRow.branchFilter
                        font.family: Style.fontTypes.roboto
                        font.weight: Font.Medium
                        font.pixelSize: Style.appFont.defaultPt
                        color: branchButton.enabled ? Style.colors.foreground : Style.colors.mutedText
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            background: Rectangle {
                radius: 5
                color: !branchButton.enabled ? Style.colors.primaryBackground :
                       branchSelectorOpen ? Style.colors.cardBackground : Style.colors.secondaryBackground
            }

            Behavior on opacity {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }

        ComboBox {
            id: branchCombo
            anchors.fill: parent
            model: headerRow.branchFilterModel()

            minHeight: headerRow.controlSize
            enabled: headerRow.isGraphReady && branchSelectorOpen
            opacity: branchSelectorOpen ? 1 : 0
            clip: true
            borderWidth: 0
            focusBorderWidth: 1
            font.family: Style.fontTypes.roboto
            font.weight: 400
            font.pixelSize: Style.appFont.smallPt

            Material.background: Style.colors.primaryBackground
            Material.foreground: Style.colors.secondaryText

            background: Rectangle {
                radius: 5
                color: branchCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
            }

            currentIndex: headerRow.branchFilterIndex()
            onActivated: function(index) {
                var branchName = index > 0 ? headerRow.branchNames[index - 1] : ""
                if (branchName.length > 0) {
                    headerRow.navigationRule = "Branch"
                    headerRow.syncNavigationRule()
                }

                headerRow.branchSelected(branchName)
                branchCombo.popup.close()
                branchCombo.focus = false
                headerRow.suppressBranchSelectorOpen = branchSelectorArea.hovered
            }

            Behavior on opacity {
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
        }

        Behavior on Layout.preferredWidth {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
    }

    ToolButton {
        id: reloadButton
        Layout.preferredWidth: headerRow.controlSize
        Layout.preferredHeight: headerRow.controlSize
        Layout.leftMargin: compact ? 3 : (tight ? 5 : 7)

        enabled: headerRow.isGraphReady
        hoverEnabled: true

        text: Style.icons.refresh
        font.family: Style.fontTypes.font6Pro
        font.pixelSize: Style.appFont.largePt

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

        onClicked: headerRow.reloadRequested()
    }

    CalendarPopup {
        id: calendarPopup

        onDateSelected: function(dateString, isStart) {
            headerRow.handleDateSelected(dateString, isStart)
        }

        onClearRequested: function(isStart) {
            headerRow.handleClearRequested(isStart)
        }
    }

    Component.onCompleted: {
        syncFilterModes()
        syncNavigationRule()
    }

    onFilterModesChanged: syncFilterModes()
    onNavigationRuleChanged: syncNavigationRule()

    /* Functions
     * ****************************************************************************************/
    function applyFilter() {
        var selectedItems = filterOptionsPopup.selectedItems;

        var modes = selectedItems && selectedItems.length > 0
                     ? selectedItems.map(function(it) { return it.text })
                     : [];
        headerRow.filterRequested(headerRow.filterText,
                                  headerRow.filterStartDate,
                                  headerRow.filterEndDate,
                                  modes);

    }

    function syncFilterModes() {
        if (!filterOptionsModel || filterOptionsModel.count === undefined)
            return

        var modes = headerRow.filterModes || []
        headerRow.syncingFilterModes = true
        for (var i = 0; i < filterOptionsModel.count; ++i) {
            var item = filterOptionsModel.get(i)
            filterOptionsModel.setProperty(i, "checked", modes.indexOf(item.text) !== -1)
        }

        filterOptionsPopup.updateSelection()
        headerRow.syncingFilterModes = false
    }

    function syncNavigationRule() {
        var index = headerRow.navigationRules.indexOf(headerRow.navigationRule)
        columnCombo.currentIndex = index >= 0 ? index : 0
    }

    function branchFilterModel() {
        return ["All branches"].concat(headerRow.branchNames || [])
    }

    function branchFilterIndex() {
        var branch = headerRow.branchFilter || ""
        if (branch.length === 0)
            return 0

        var names = headerRow.branchNames || []
        var index = names.indexOf(branch)
        return index >= 0 ? index + 1 : 0
    }

    function handleDateSelected(dateString, isStart) {
        if (isStart)
            headerRow.filterStartDate = dateString;
        else
            headerRow.filterEndDate = dateString;

        headerRow.applyFilter();
    }

    function handleClearRequested(isStart) {
        if (isStart)
            headerRow.filterStartDate = "";
        else
            headerRow.filterEndDate = "";

        headerRow.applyFilter();
    }
}
