import QtQuick
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * PatternInput
 * One-line field plus an Add button for typing a pattern by hand.
 * ************************************************************************************************/
RowLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string placeholder: "Add a pattern, e.g. *.log or /build/"

    /* Signals
     * ****************************************************************************************/
    signal submitted(string pattern)

    /* Functions
     * ****************************************************************************************/
    function clear() {
        field.text = ""
    }

    function submit() {
        const text = field.text.trim()
        if (text.length > 0)
            root.submitted(text)
    }

    /* Object Properties
     * ****************************************************************************************/
    spacing: Style.dp(8)

    /* Children
     * ****************************************************************************************/
    GitignoreSearchField {
        id: field
        Layout.fillWidth: true
        icon: Style.icons.plus
        placeholderText: root.placeholder
        onAccepted: root.submit()
    }

    GitignoreButton {
        text: "Add"
        enabled: field.text.trim().length > 0
        onClicked: root.submit()
    }
}
