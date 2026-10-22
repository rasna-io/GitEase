import QtQuick
import QtQuick.Controls.Basic

/*! ***********************************************************************************************
 * PalettoTextField
 * Single-line field with the fixed Paletto look. Set `mono` for hex values.
 * ************************************************************************************************/
TextField {
    id: root

    //! The editor colors and fonts, passed in by PalettoPage.
    required property PalettoChrome chrome

    property bool mono: false
    //! Shown in red when true (e.g. an invalid hex value).
    property bool invalid: false

    implicitHeight: 30
    leftPadding: 10
    rightPadding: 10
    topPadding: 0
    bottomPadding: 0
    verticalAlignment: TextInput.AlignVCenter

    font.family: mono ? root.chrome.fontMono : root.chrome.fontText
    font.pixelSize: root.chrome.sizeCaption
    color: root.chrome.text
    placeholderTextColor: root.chrome.textFaint
    selectionColor: root.chrome.accent
    selectedTextColor: root.chrome.accentText
    selectByMouse: true

    background: Rectangle {
        radius: 7
        color: root.chrome.field
        border.width: 1
        border.color: root.invalid ? root.chrome.danger
                    : root.activeFocus ? root.chrome.accent
                    : root.hovered ? root.chrome.borderStrong : root.chrome.border
    }
}
