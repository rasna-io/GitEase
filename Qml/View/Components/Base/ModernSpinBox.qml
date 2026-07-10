// ModernSpinBox.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * ModernSpinBox
 ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int value: 0
    property int from: 0
    property int to: 99
    property int stepSize: 1

    /* Signals
     * ****************************************************************************************/
    signal valueModified()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: 40
    implicitWidth: 80
    color: Style.colors.secondaryBackground
    radius: 5

    /* Children
     * ****************************************************************************************/
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 4
        anchors.bottomMargin: 4

        TextField {
            id: valueField
            Layout.fillHeight: true
            Layout.fillWidth: true

            text: root.value.toString()
            selectByMouse: true
            font.family: Style.fontTypes.roboto
            color: Style.colors.mutedText
            Material.accent: Style.colors.accent
            leftPadding: 0
            rightPadding: 0

            validator: IntValidator {
                bottom: root.from
                top: root.to
            }

            background: Rectangle {
                color: "transparent"
            }

            onTextChanged: {
                const parsed = parseInt(text)
                root.value = isNaN(parsed) ? root.from : root.clamp(parsed)
                root.valueModified()
            }
        }

        Column {
            Layout.preferredWidth: 22
            Layout.fillHeight: true
            spacing: 2

            Rectangle {
                width: parent.width
                height: (parent.height - parent.spacing) / 2
                radius: 3
                color: Style.colors.foreground

                Text {
                    anchors.centerIn: parent
                    text: "▲"
                    font.pixelSize: 8
                    color: Style.colors.placeholderText
                }

                MouseArea {
                    id: upArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.increment()
                }
            }

            Rectangle {
                width: parent.width
                height: (parent.height - parent.spacing) / 2
                radius: 3
                color: Style.colors.foreground

                Text {
                    anchors.centerIn: parent
                    text: "▼"
                    font.pixelSize: 8
                    color: Style.colors.placeholderText
                }

                MouseArea {
                    id: downArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.decrement()
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function clamp(v) {
        return Math.max(root.from, Math.min(root.to, v))
    }

    function increment() {
        root.value = clamp(root.value + root.stepSize)
        root.valueModified()
    }

    function decrement() {
        root.value = clamp(root.value - root.stepSize)
        root.valueModified()
    }
}