import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style

import GitEasePaletto

/*! ***********************************************************************************************
 * TokenInspector
 * Right side of the page: edits the selected token with the color picker, a hex field and the
 * eyedropper, and compares it with the value of the base theme. The panel slides in when a token
 * is selected and out when it is closed.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! The editor colors and fonts, passed in by PalettoPage.
    required property PalettoChrome chrome

    //! Used to check what is typed in the hex field.
    required property PalettoEngine engine

    //! Whether the panel is shown. The token values below stay valid while it slides closed.
    property bool   open:        false

    property string tokenName:   ""
    property string tokenLabel:  ""
    property string value:       "#000000"
    property string baseValue:   "#000000"

    //! True while the eyedropper overlay is on screen.
    property bool   eyeDropperActive: false

    readonly property real panelWidth: 300

    /* Signals
     * ****************************************************************************************/
    signal valueEdited(string hex)
    signal revertRequested()
    signal closeRequested()
    signal eyeDropperRequested()

    /* Object Properties
     * ****************************************************************************************/
    Layout.preferredWidth: open ? panelWidth : 0
    // Visible while open (a hidden item gets no width from the layout, so it could never grow)
    // and until the closing animation has finished.
    visible: open || width > 0
    opacity: open ? 1 : 0
    color: root.chrome.panel
    clip: true

    Behavior on Layout.preferredWidth {
        NumberAnimation {
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }
    }

    /* Children
     * ****************************************************************************************/
    Rectangle {
        anchors.left: parent.left
        width: 1
        height: parent.height
        color: root.chrome.border
    }

    // Fixed width: the content slides in with the panel instead of being squeezed.
    Flickable {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 16
        width: root.panelWidth - 32
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ScrollBar.vertical: PalettoScrollBar {}

        ColumnLayout {
            id: content

            width: parent.width
            spacing: 14

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: root.tokenLabel
                        elide: Text.ElideRight
                        font.family: root.chrome.fontText
                        font.pixelSize: root.chrome.sizeTitle
                        font.weight: Font.DemiBold
                        color: root.chrome.text
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.tokenName
                        elide: Text.ElideRight
                        font.family: root.chrome.fontMono
                        font.pixelSize: root.chrome.sizeCaption
                        color: root.chrome.textFaint
                    }
                }

                PalettoButton {
                    chrome: root.chrome
                    variant: "ghost"
                    iconText: "" // close
                    onClicked: root.closeRequested()
                }
            }

            ColorPicker {
                chrome: root.chrome
                Layout.fillWidth: true
                hex: root.value
                onEdited: function(hex) {
                    root.valueEdited(hex)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Value"
                    font.family: root.chrome.fontText
                    font.pixelSize: root.chrome.sizeCaption
                    color: root.chrome.textDim
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    PalettoTextField {
                        id: hexField

                        chrome: root.chrome
                        Layout.fillWidth: true
                        mono: true
                        placeholderText: "#rrggbb or #aarrggbb"
                        text: root.value
                        invalid: text.length > 0 && root.engine.normalizeColor(text).length === 0

                        onAccepted: commitHex()
                        onEditingFinished: commitHex()

                        function commitHex() {
                            const hex = root.engine.normalizeColor(text)
                            if(hex.length > 0) {
                                root.valueEdited(hex)
                            }
                            // Typing replaced the binding with plain text; show the real value again.
                            text = Qt.binding(function() {
                                return root.value
                            })
                        }
                    }

                    PalettoButton {
                        chrome: root.chrome
                        iconText: "" // eye-dropper
                        enabled: !root.eyeDropperActive
                        tooltip: "Pick a color from anywhere on the screen"
                        onClicked: root.eyeDropperRequested()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Repeater {
                    model: [
                        {
                            title: "Base",
                            color: root.baseValue
                        },
                        {
                            title: "Current",
                            color: root.value
                        }
                    ]

                    delegate: ColumnLayout {
                        id: comparison

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: comparison.modelData.title
                            font.family: root.chrome.fontText
                            font.pixelSize: root.chrome.sizeMicro
                            color: root.chrome.textFaint
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: 8
                            color: root.chrome.checkerDark
                            border.width: 1
                            border.color: root.chrome.borderStrong

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 7
                                color: comparison.modelData.color
                            }
                        }

                        Text {
                            text: comparison.modelData.color
                            font.family: root.chrome.fontMono
                            font.pixelSize: root.chrome.sizeMicro
                            color: root.chrome.textDim
                        }
                    }
                }
            }

            PalettoButton {
                chrome: root.chrome
                Layout.fillWidth: true
                text: "Back to base value"
                iconText: "" // undo
                enabled: root.value !== root.baseValue
                onClicked: root.revertRequested()
            }
        }
    }
}
