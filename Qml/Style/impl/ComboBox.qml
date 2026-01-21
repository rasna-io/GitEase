
import QtQuick
import QtQuick.Window
import QtQuick.Controls.impl
import QtQuick.Templates as T
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

import GitEase_Style

T.ComboBox {
    id: control

    /* Property Declarations
     * ****************************************************************************************/
    property  bool error

    property int minHeight: 40
    property int maxPopupHeight: 200
    property int borderWidth: 1
    property int focusBorderWidth: 2
    property string placeholderText: ""

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(minHeight,
                             implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    leftPadding: padding + (!control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
    rightPadding: padding + (control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)

    delegate: ItemDelegate {
        required property var model
        required property int index

        width: control.width
        height: control.minHeight
        contentItem: Text {
            text:  model[control.textRole]
            font: control.font
            color: control.Material.foreground
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        highlighted: control.highlightedIndex === index
    }

    indicator: ColorImage {
        x: control.mirrored ? control.padding : control.width - width - control.padding
        y: control.topPadding + (control.availableHeight - height) / 2
        color: control.enabled ? control.Material.foreground : Style.colors.placeholderText
        source: "qrc:/qt-project.org/imports/QtQuick/Controls/Material/images/drop-indicator.png"
    }

    contentItem: T.TextField {
        leftPadding: Material.textFieldHorizontalPadding
        topPadding: Material.textFieldVerticalPadding
        bottomPadding: Material.textFieldVerticalPadding

        text: control.currentIndex >= 0 ? control.displayText : control.placeholderText
        color: control.currentIndex >= 0 ? control.Material.foreground : Style.colors.placeholderText

        enabled: control.editable
        autoScroll: control.editable
        readOnly: control.down
        inputMethodHints: control.inputMethodHints
        validator: control.validator
        selectByMouse: control.selectTextByMouse

        selectionColor: control.Material.accentColor
        selectedTextColor: control.Material.primaryHighlightedTextColor
        verticalAlignment: Text.AlignVCenter

        cursorDelegate: CursorDelegate { }
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: control.minHeight
        radius: 5
        border.width: control.activeFocus ? control.focusBorderWidth : control.borderWidth
        color: Material.background
        border.color: control.error ? Style.colors.error
                                    : control.activeFocus ? Style.colors.accent : Style.colors.primaryBorder
    }

    popup: Popup {
        y: control.height - 1
        width: control.width
        padding: 1

        implicitHeight: Math.min(contentItem.implicitHeight, control.maxPopupHeight)
        contentItem: ListView {
            clip: true
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0

            implicitHeight: contentHeight
            boundsBehavior: Flickable.StopAtBounds

            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            color: Style.colors.primaryBackground
            radius: 2
            border.color: Style.colors.primaryBorder
        }
    }

    onModelChanged: {
        control.currentIndex = placeholderText === "" ? 0 : -1
    }
}
