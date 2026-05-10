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
    property bool   isStart     : true
    property point  fieldOrigin : Qt.point(0, 0)
    property string otherDateStr: ""

    /* Signals
     * ****************************************************************************************/
    signal dateSelected(string dateString, bool isStart)
    signal clearRequested(bool isStart)

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
    function prepareAndOpen(field, isStartMode, currentDateStr, oppositeDateStr) {
        root.isStart      = isStartMode;
        root.otherDateStr = oppositeDateStr;

        cal.errorMessage = "";

        if (currentDateStr && currentDateStr.length === 10) {
            cal.setDate(currentDateStr);
        } else {
            cal.selectedDate = new Date();
        }

        root.fieldOrigin = field.mapToItem(null, 0, field.height);
        root.open();
    }

    function handleDateSelected(date) {
        var formatted = cal.dateToString(date);

        cal.errorMessage = "";

        if (root.isStart) {
            if (root.otherDateStr && formatted > root.otherDateStr) {
                cal.errorMessage = "Start date cannot be greater than end date";
                return;
            }
        }
        else {
            if (root.otherDateStr && formatted < root.otherDateStr) {
                cal.errorMessage = "End date cannot be less than start date";
                return;
            }
        }

        root.dateSelected(formatted, root.isStart);
        root.close();
    }

    function handleClearRequested() {
        root.clearRequested(root.isStart);
        root.close();
    }
}
