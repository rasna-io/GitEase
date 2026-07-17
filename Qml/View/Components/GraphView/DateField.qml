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
        leftPadding: root.iconOnly ? 6 : calendarIcon.width + 14
        rightPadding: 8
        placeholderTextColor: Style.colors.descriptionText
        backgroundColor: mouseArea.containsMouse ? Style.colors.cardBackground : Style.colors.secondaryBackground
        placeholderText: root.iconOnly ? "" : root.placeholder
        text: root.iconOnly ? "" : root.dateString
        font.family: Style.fontTypes.roboto
        font.weight: 400
        font.pixelSize: Style.appFont.smallPt
        borderRadius: 5
        borderWidth: 0
        focusBorderWidth: 1
        readOnly: true
        enabled: text.trim().length > 0
    }

    RTextIcon {
        id: calendarIcon
        anchors.left: root.iconOnly ? undefined : parent.left
        anchors.leftMargin: root.iconOnly ? 0 : 8
        anchors.horizontalCenter: root.iconOnly ? parent.horizontalCenter : undefined
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        text: Style.icons.calendar
        font.pixelSize: Style.appFont.h3Pt
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
