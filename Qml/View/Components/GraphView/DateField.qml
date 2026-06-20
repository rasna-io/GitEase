import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * DateField
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string dateString  : ""
    property string placeholder : "YYYY-MM-DD"
    property bool   compact     : false
    property bool   iconOnly    : false

    /* Signals
     * ****************************************************************************************/
    signal clicked()

    /* Children
     * ****************************************************************************************/
    implicitWidth: root.iconOnly ? 26 : (root.compact ? 82 : 90)
    implicitHeight: 26

    TextField {
        id: textField
        anchors.fill: parent
        minHeight: 26
        rightPadding: root.iconOnly ? 6 : caret.width + 5
        placeholderTextColor: Style.colors.descriptionText
        backgroundColor: mouseArea.containsMouse ? Style.colors.cardBackground : Style.colors.secondaryBackground
        placeholderText: root.iconOnly ? "" : root.placeholder
        text: root.iconOnly ? "" : root.dateString
        font.family: Style.fontTypes.roboto
        font.weight: 400
        font.pixelSize: 10
        borderRadius: 5
        borderWidth: 0
        focusBorderWidth: 1
        readOnly: true
        enabled: text.trim().length > 0
    }

    RTextIcon {
        id: calendarIcon
        anchors.centerIn: parent
        width: 14
        height: 14
        visible: root.iconOnly
        text: Style.icons.calendar
        font.pixelSize: 13
        color: Style.colors.descriptionText
    }

    RTextIcon {
        id: caret
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 12;
        height: 12
        visible: !root.iconOnly
        text: Style.icons.caretDown
        font.pixelSize: 15
        color: Style.colors.descriptionText
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
