import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

import GitEase_Style

T.TextArea {
    id: control

    property bool floatingPlaceholderEnabled: true

    implicitWidth: Math.max(contentWidth + leftPadding + rightPadding,
                            implicitBackgroundWidth + leftInset + rightInset,
                            placeholder.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(contentHeight + topPadding + bottomPadding,
                             implicitBackgroundHeight + topInset + bottomInset)

    // If we're clipped, or we're in a Flickable that's clipped, set our topInset
    // to half the height of the placeholder text to avoid it being clipped.
    topInset: clip || (parent?.parent as Flickable && parent?.parent.clip) ? placeholder.largestHeight / 2 : 0

    leftPadding: Material.textFieldHorizontalPadding
    rightPadding: Material.textFieldHorizontalPadding
    // Need to account for the placeholder text when it's sitting on top.
    topPadding: Material.textFieldVerticalPadding
    bottomPadding: Material.textFieldVerticalPadding

    color: enabled ? Material.foreground : Material.hintTextColor
    selectionColor: Material.accentColor
    selectedTextColor: Material.primaryHighlightedTextColor
    placeholderTextColor: enabled && activeFocus ? Material.accentColor : Material.hintTextColor

    Material.containerStyle: Material.Outlined

    cursorDelegate: CursorDelegate { }

    FloatingPlaceholderText {
        id: placeholder
        width: control.width - (control.leftPadding + control.rightPadding)
        text: control.placeholderText
        font: control.font
        color: control.placeholderTextColor
        elide: Text.ElideRight
        renderType: control.renderType

        parent: control.background?.parent ?? control

        visible: control.floatingPlaceholderEnabled
                 ? control.placeholderText.length > 0
                 : (control.text.length === 0 && !control.activeFocus && control.placeholderText.length > 0)
        y: control.floatingPlaceholderEnabled ? placeholder.y : control.topPadding
        x: control.floatingPlaceholderEnabled ? placeholder.x : control.leftPadding
        scale: control.floatingPlaceholderEnabled ? placeholder.scale : 1.0

        filled: control.Material.containerStyle === Material.Filled
        verticalPadding: control.Material.textFieldVerticalPadding
        controlHasActiveFocus: control.activeFocus
        controlHasText: control.length > 0
        controlImplicitBackgroundHeight: control.implicitBackgroundHeight
        controlHeight: control.height
        leftPadding: control.leftPadding
        floatingLeftPadding: control.Material.textFieldHorizontalPadding
    }

    background: MaterialTextContainer {
        implicitWidth: 120
        implicitHeight: control.Material.textFieldHeight

        filled: control.Material.containerStyle === Material.Filled
        fillColor: control.Material.textFieldFilledContainerColor
        outlineColor: (enabled && control.hovered) ? control.Material.primaryTextColor : control.Material.hintTextColor
        focusedOutlineColor: control.Material.accentColor
        // When the control's size is set larger than its implicit size, use whatever size is smaller
        // so that the gap isn't too big.
        placeholderTextWidth: Math.min(placeholder.width, placeholder.implicitWidth) * placeholder.scale
        placeholderTextHAlign: control.effectiveHorizontalAlignment
        controlHasActiveFocus: control.activeFocus
        controlHasText: control.length > 0
        placeholderHasText: control.floatingPlaceholderEnabled && placeholder.text.length > 0
        horizontalPadding: control.Material.textFieldHorizontalPadding
    }
}
