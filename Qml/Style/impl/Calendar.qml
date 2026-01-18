import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

import GitEase_Style

/*! ***********************************************************************************************
 * Calendar
 * Styled Calendar control (Material-like) for date picking.
 * ************************************************************************************************/

T.Control {
    id: control

    /* Property Declarations
     * ****************************************************************************************/
    property date selectedDate: new Date()
    property int month: selectedDate.getMonth()
    property int year: selectedDate.getFullYear()
    property string errorMessage: ""

    /* Signals
     * ****************************************************************************************/
    signal dateSelected(date date)

    signal clearRequested()

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: 280
    implicitHeight: 230 + (errorMessage !== "" ? 28 : 0)

    /* Children
     * ****************************************************************************************/
    background: Rectangle {
        radius: 8
        color: Style.colors.primaryBackground
        border.width: 1
        border.color: Style.colors.primaryBorder
    }

    contentItem: Column {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 2

        // Header: month/year + nav
        Row {
            width: parent.width
            height: 26
            spacing: 6

            ToolButton {
                width: 24; height: 24
                text: "<"
                Material.foreground: Style.colors.secondaryText
                onClicked: {
                    if (control.month === 0) {
                        control.month = 11
                        control.year -= 1
                    } else {
                        control.month -= 1
                    }
                }
            }

            Item {
                width: Math.max(0, parent.width - (24 + 8) - (24 + 8))
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDate(new Date(control.year, control.month, 1), "MMMM yyyy")
                    color: Style.colors.foreground
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            ToolButton {
                width: 24; height: 24
                text: ">"
                Material.foreground: Style.colors.secondaryText
                onClicked: {
                    if (control.month === 11) {
                        control.month = 0
                        control.year += 1
                    } else {
                        control.month += 1
                    }
                }
            }
        }

        // Weekday header
        Row {
            width: parent.width
            spacing: 0
            Repeater {
                model: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
                delegate: Text {
                    width: (parent.width / 7)
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Style.colors.descriptionText
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 10
                }
            }
        }

        // Day grid
        Grid {
            width: parent.width
            columns: 7
            rowSpacing: 2
            columnSpacing: 3

            Repeater {
                model: 42
                delegate: Rectangle {
                    required property int index

                    readonly property date _date: control.cellDate(index)
                    readonly property bool inMonth: _date.getMonth() === control.month
                    readonly property bool isSelected: control.isSameDay(_date, control.selectedDate)
                    readonly property bool isToday: control.isToday(_date)

                    width: (parent.width - ((parent.columns - 1) * parent.columnSpacing)) / parent.columns
                    height: 23
                    radius: 6

                    color: isSelected ? Style.colors.accent : (hovered ? Style.colors.cardBackground : "transparent")
                    border.width: isToday ? 1 : 0
                    border.color: isToday ? Style.colors.accent : "transparent"

                    property bool hovered: false

                    Text {
                        anchors.centerIn: parent
                        text: _date.getDate()
                        color: isSelected ? Style.colors.secondaryForeground
                                         : (inMonth ? Style.colors.foreground : Style.colors.mutedText)
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 11
                    }

                    HoverHandler {
                        onHoveredChanged: parent.hovered = hovered
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton;
                        onTapped: control.commitDate(_date)
                    }
                }
            }
        }

        // Error message display (above footer buttons)
        Rectangle {
            width: parent.width
            height: control.errorMessage !== "" ? 28 : 0
            visible: control.errorMessage !== ""
            color: Qt.rgba(239/255, 83/255, 80/255, 0.1) // Light red background
            radius: 4
            border.width: 1
            border.color: Style.colors.error || "#ef5350"

            Text {
                id: errorText
                anchors.centerIn: parent
                width: parent.width - 16
                text: control.errorMessage
                color: Style.colors.error || "#ef5350"
                font.family: Style.fontTypes.roboto
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
        }

        // Footer actions (part of Calendar feature)
        Row {
            id: footerRow
            spacing: 6
            anchors.horizontalCenter: parent.horizontalCenter

            readonly property int actionButtonHeight: 32
            readonly property int actionButtonWidth: Math.max(todayButton.implicitWidth, clearButton.implicitWidth)

            Button {
                id: todayButton
                width: footerRow.actionButtonWidth
                height: footerRow.actionButtonHeight
                hoverEnabled: true
                text: "Today"

                contentItem: Text {
                    text: todayButton.text
                    font: todayButton.font
                    color: Style.colors.secondaryForeground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 3
                    color: todayButton.down ? Style.colors.accentHover : todayButton.hovered ? Style.colors.accentHover : Style.colors.accent
                }

                onClicked: {
                    var now = new Date()
                    control.commitDate(now)
                }
            }

            Button {
                id: clearButton
                width: footerRow.actionButtonWidth
                height: footerRow.actionButtonHeight
                hoverEnabled: true
                text: "Clear"

                contentItem: Text {
                    text: clearButton.text
                    font: clearButton.font
                    color: Style.colors.foreground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 3
                    border.width: 1
                    border.color: Style.colors.primaryBorder
                    color: clearButton.down ? Style.colors.surfaceMuted: clearButton.hovered ? Style.colors.cardBackground : Style.colors.surfaceLight
                }

                onClicked: {
                    control.errorMessage = ""
                    control.clearRequested()
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function dayOfWeekMon(_date) {
        // JS: 0=Sun..6=Sat  -> 0=Mon..6=Sun
        return (_date.getDay() + 6) % 7
    }

    function startOffset() {
        return dayOfWeekMon(new Date(year, month, 1))
    }

    function cellDate(index) {
        // index: 0..41
        var offset = startOffset()
        return new Date(year, month, 1 + (index - offset))
    }

    function isSameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
    }

    function isToday(_date) {
        var t = new Date()
        return isSameDay(_date, t)
    }

    function dateToString(d) {
        // Converts a JS Date to "YYYY-MM-DD".
        // Returns empty string when input is invalid.
        if (!d || typeof d.getFullYear !== "function")
            return ""

        function pad2(n) { return (n < 10) ? ("0" + n) : ("" + n) }
        return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate())
    }

    function dateFromString(s) {
        // Parses "YYYY-MM-DD" into a JS Date.
        // Returns null when input is invalid.
        if (!s || typeof s !== "string")
            return null

        var parts = s.split("-")
        if (parts.length !== 3)
            return null

        var y = parseInt(parts[0], 10)
        var m = parseInt(parts[1], 10)
        var d = parseInt(parts[2], 10)
        if (!isFinite(y) || !isFinite(m) || !isFinite(d))
            return null

        // JS Date month is 0-based
        var dt = new Date(y, m - 1, d)

        // Validate (avoid rollover like 2025-13-40)
        if (dt.getFullYear() !== y || dt.getMonth() !== (m - 1) || dt.getDate() !== d)
            return null

        return dt
    }

    function setDate(value) {
        // Convenience setter. Accepts Date or "YYYY-MM-DD".
        // Does NOT emit dateSelected.
        // Returns true on success.
        var dt = null

        if (value && typeof value.getFullYear === "function") {
            dt = value
        } else if (typeof value === "string") {
            dt = dateFromString(value)
        }

        if (!dt)
            return false

        selectedDate = dt
        month = dt.getMonth()
        year = dt.getFullYear()
        return true
    }

    function commitDate(_date) {
        setDate(_date)
        control.dateSelected(_date)
    }
}
