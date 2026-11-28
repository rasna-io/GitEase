import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * GitignoreCodeEditor
 * Monospace multi-line editor in a bordered box with a scroll bar and an optional placeholder.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property alias text: edit.text
    property string placeholder: ""

    readonly property bool focused: edit.activeFocus

    /* Signals
     * ****************************************************************************************/
    signal edited()

    /* Functions
     * ****************************************************************************************/
    function focusEditor() {
        edit.forceActiveFocus()
    }

    /* Object Properties
     * ****************************************************************************************/
    radius: Style.dp(8)
    color: Style.colors.controlBackground
    border.width: 1
    border.color: focused ? Style.colors.accent : Style.colors.controlBorder

    /* Children
     * ****************************************************************************************/
    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: Style.dp(2)
        clip: true
        contentWidth: width
        contentHeight: edit.implicitHeight + Style.dp(20)
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        ScrollBar.vertical: ScrollBar {}

        TextEdit {
            id: edit
            x: Style.dp(12)
            y: Style.dp(10)
            width: flick.width - Style.dp(24)
            height: Math.max(implicitHeight, flick.height - Style.dp(20))
            wrapMode: TextEdit.NoWrap
            selectByMouse: true
            persistentSelection: true
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.smallPt
            color: Style.colors.foreground
            selectionColor: Style.colors.accent
            selectedTextColor: Style.colors.onAccentText

            onTextChanged: root.edited()

            // Keep the caret in view while typing.
            onCursorRectangleChanged: {
                const top = cursorRectangle.y + y
                const bottom = top + cursorRectangle.height

                if (top < flick.contentY) {
                    flick.contentY = top
                } else if (bottom > flick.contentY + flick.height) {
                    flick.contentY = bottom - flick.height
                }
            }

            Text {
                visible: edit.text.length === 0 && root.placeholder.length > 0
                text: root.placeholder
                font: edit.font
                color: Style.colors.mutedText
            }
        }
    }
}
