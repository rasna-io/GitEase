import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * FormInputField
 * Reusable input field component with label, icon, text field, and helper text
 * ************************************************************************************************/
ColumnLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string label: ""
    property string placeholderText: ""
    property string helperText: ""
    property string icon: ""
    property string text: field.text
    property bool hasError: false
    property alias field: field
    property string button: ""

    /* Signals
     * ****************************************************************************************/
    signal buttonClicked()

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    spacing: 4

    /* Children
     * ****************************************************************************************/
    // Label
    Text {
        visible: root.label !== ""
        text: root.label
        font.pixelSize: 14
        color: Style.colors.foreground
        font.family: Style.fontTypes.roboto
        font.weight: 400
    }

    // Input with icon
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: field.implicitHeight
        Layout.alignment: Qt.AlignVCenter

        TextField {
            id: field
            anchors.left: parent.left
            anchors.right: buttonItem.visible ? buttonItem.left : parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: buttonItem.visible ? 8 : 0
            placeholderText: root.placeholderText
            icon: root.icon
            error: root.hasError
        }

        // Button
        Button {
            id: buttonItem
            visible: root.button !== ""
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: field.baseFontSize * 7.5
            height: field.implicitHeight * 1.3
            text: root.button
            flat: true
            font.pixelSize: field.baseFontSize
            font.weight: 400
            font.family: Style.fontTypes.roboto

            background: Rectangle {
                implicitWidth: field.baseFontSize * 7.5
                implicitHeight: field.implicitHeight
                radius: field.borderRadius
                color: field.backgroundColor
                border.width: buttonItem.hovered ? 1 : 0
                border.color: Style.colors.accent
                Behavior on border.width { NumberAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }

            contentItem: Text {
                text: buttonItem.text
                font: buttonItem.font
                color: Style.colors.foreground
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: root.buttonClicked()
        }
    }

    // Helper text
    Text {
        visible: helperText !== ""
        text: root.helperText
        color: Style.colors.mutedText
        font.pixelSize: 8
        font.family: Style.fontTypes.roboto
        font.weight: 100
        font.styleName: "Thin"
    }
}

