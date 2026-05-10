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

    /* Signals
     * ****************************************************************************************/
    signal clicked()

    /* Children
     * ****************************************************************************************/
    implicitWidth: compact ? 22 : 90
    implicitHeight: 25

    TextField {
        id: textField
        anchors.fill: parent
        minHeight: 25
        rightPadding: caret.width + 5
        placeholderTextColor: Style.colors.descriptionText
        backgroundColor: mouseArea.containsMouse ? Style.colors.cardBackground : Style.colors.secondaryBackground
        placeholderText: root.compact ? "" : root.placeholder
        text: root.compact ? "" : root.dateString
        font.family: Style.fontTypes.roboto
        font.weight: 400
        font.pixelSize: 10
        borderRadius: 5
        borderWidth: 0
        focusBorderWidth: 1
        readOnly: true
        enabled: text.trim().length > 0
    }

    RoniaTextIcon {
        id: caret
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 12;
        height: 12
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
