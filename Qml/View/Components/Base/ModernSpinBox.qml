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
    property alias value:   valueField.text
    property int  from:     0
    property int  to:       99
    property int  stepSize: 1

    /* Signals
     * ****************************************************************************************/
    signal valueModified()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: 34
    implicitWidth: 96
    color: spinHover.hovered && !valueField.activeFocus ? Style.colors.controlBackgroundHover
                                                        : Style.colors.controlBackground
    radius: 7
    border.width: 1
    border.color: valueField.activeFocus ? Style.colors.accent
                : spinHover.hovered      ? Style.colors.controlBorderHover
                                         : Style.colors.controlBorder

    Behavior on color { ColorAnimation { duration: Style.motionFast } }
    Behavior on border.color { ColorAnimation { duration: Style.motionFast } }

    HoverHandler { id: spinHover }

    /* Children
     * ****************************************************************************************/
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 3
        anchors.topMargin: 3
        anchors.bottomMargin: 3
        spacing: 4

        TextField {
            id: valueField
            Layout.fillHeight: true
            Layout.fillWidth: true

            selectByMouse: true
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.defaultPt
            color: Style.colors.foreground
            selectionColor: Style.colors.accent
            selectedTextColor: Style.colors.onAccentText
            Material.accent: Style.colors.accent
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            bottomPadding: 0
            verticalAlignment: TextInput.AlignVCenter

            validator: IntValidator {
                bottom: root.from
                top: root.to
            }

            background: Item {}

            onTextChanged: {
                const parsed = parseInt(text)
                root.value = isNaN(parsed) ? root.from : root.clamp(parsed)
                root.valueModified()
            }
        }

        Column {
            Layout.preferredWidth: 20
            Layout.fillHeight: true
            spacing: 1

            Repeater {
                model: [
                    { glyph: "\u25B2", step: 1 },
                    { glyph: "\u25BC", step: -1 }
                ]

                delegate: Rectangle {
                    width: parent.width
                    height: (parent.height - parent.spacing) / 2
                    radius: 4
                    color: stepArea.pressed      ? Style.colors.controlBorder
                         : stepArea.containsMouse ? Style.colors.controlBackgroundHover
                                                  : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.glyph
                        font.pixelSize: Style.appFont.microPt
                        color: stepArea.containsMouse ? Style.colors.accent : Style.colors.placeholderText
                    }

                    MouseArea {
                        id: stepArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.step > 0 ? root.increment() : root.decrement()
                    }
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
        root.value = clamp(parseInt(root.value) + root.stepSize)
        root.valueModified()
    }

    function decrement() {
        root.value = clamp(parseInt(root.value) - root.stepSize)
        root.valueModified()
    }
}
