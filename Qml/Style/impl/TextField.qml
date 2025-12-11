import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

import GitEase_Style

T.TextField {
    id: control

    /* Property Declarations
     * ****************************************************************************************/
    property  bool error

    implicitWidth: implicitBackgroundWidth + leftInset + rightInset
                   || Math.max(contentWidth, placeholder.implicitWidth) + leftPadding + rightPadding
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    // If we're clipped, set topInset to half the height of the placeholder text to avoid it being clipped.
    topInset: clip ? placeholder.largestHeight / 2 : 0

    leftPadding: Material.textFieldHorizontalPadding
    rightPadding: Material.textFieldHorizontalPadding
    // Need to account for the placeholder text when it's sitting on top.
    topPadding: Material.containerStyle === Material.Filled
        ? placeholderText.length > 0 && (activeFocus || length > 0)
            ? Material.textFieldVerticalPadding + placeholder.largestHeight
            : Material.textFieldVerticalPadding
        // Account for any topInset (used to avoid floating placeholder text being clipped),
        // otherwise the text will be too close to the background.
        : Material.textFieldVerticalPadding + topInset
    bottomPadding: Material.textFieldVerticalPadding

    color: enabled ? Material.foreground : Material.hintTextColor
    selectionColor: Material.accentColor
    selectedTextColor: Material.primaryHighlightedTextColor
    placeholderTextColor: Material.accentColor
    verticalAlignment: TextInput.AlignVCenter

    Material.containerStyle: Material.Outlined
    Material.accent: Style.colors.foreground

    cursorDelegate: CursorDelegate { }

    PlaceholderText {
        id: placeholder
        x: control.leftPadding
        y: control.topPadding
        width: control.width - (control.leftPadding + control.rightPadding)
        height: control.height - (control.topPadding + control.bottomPadding)

        text: control.placeholderText
        font: control.font
        color: control.error ? Style.colors.error
                             : control.placeholderTextColor
        verticalAlignment: control.verticalAlignment
        visible: !control.length && !control.preeditText && (!control.activeFocus || control.horizontalAlignment !== Qt.AlignHCenter)
        elide: Text.ElideRight
        renderType: control.renderType
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 40
        radius: 5
        border.width: control.activeFocus ? 2 : 1
        color: control.palette.base
        border.color: control.error ? Style.colors.error
                        : control.activeFocus ? Style.colors.accent : Style.colors.primaryBorder
    }
}
