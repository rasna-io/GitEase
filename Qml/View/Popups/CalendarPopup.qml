import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * CalendarPopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    headerRef   : null
    property bool   isStart     : true
    property point  fieldOrigin : Qt.point(0, 0)

    /* Object Properties
     * ****************************************************************************************/
    width: 280
    height: 260
    padding: 8

    x: Math.min(fieldOrigin.x, window.width - width - 10)
    y: fieldOrigin.y

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 8
        border.width: 1
        border.color: Style.colors.primaryBorder

        Calendar {
            id: cal
            anchors.fill: parent
            anchors.margins: 4

            onDateSelected: function(date) {root.handleDateSelected(date)}

            onClearRequested: root.handleClearRequested()
        }
    }

    /* Functions
     * ****************************************************************************************/
    function openForField(field, header, isStartMode) {
        root.headerRef  = header;
        root.isStart    = isStartMode;

        cal.errorMessage = "";

        var dateStr = isStartMode ? header.filterStartDate : header.filterEndDate;
        if (dateStr && dateStr.length === 10) {
            cal.setDate(dateStr);
        } else {
            cal.selectedDate = new Date();
        }

        root.fieldOrigin = field.mapToItem(null, 0, field.height);
        root.open();
    }

    function handleDateSelected(date) {
        if (!root.headerRef)
            return;

        var formatted = cal.dateToString(date);
        cal.errorMessage = "";

        if (root.isStart) {
            if (root.headerRef.filterEndDate && formatted > root.headerRef.filterEndDate) {
                cal.errorMessage = "Start date cannot be greater than end date";
                return;
            }
            root.headerRef.filterStartDate = formatted;
        }
        else {
            if (root.headerRef.filterStartDate && formatted < root.headerRef.filterStartDate) {
                cal.errorMessage = "End date cannot be less than start date";
                return;
            }
            root.headerRef.filterEndDate = formatted;
        }
        root.headerRef.applyFilter();
        root.close();
    }

    function handleClearRequested() {
        if (!root.headerRef)
            return;

        if (root.isStart)
            root.headerRef.filterStartDate = "";
        else
            root.headerRef.filterEndDate = "";

        root.headerRef.applyFilter();
        root.close();
    }
}
