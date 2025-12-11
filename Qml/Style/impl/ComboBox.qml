
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


    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    leftPadding: padding + (!control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
    rightPadding: padding + (control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)

    Material.background: flat ? "transparent" : undefined
    Material.foreground: flat ? undefined : Material.primaryTextColor

    delegate: ItemDelegate {
        required property var model
        required property int index

        width: control.width
        height: control.height
        contentItem: Text {
            text:  model[control.textRole]
            font: control.font
            color: Material.foreground
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        highlighted: control.highlightedIndex === index
    }

    indicator: ColorImage {
        x: control.mirrored ? control.padding : control.width - width - control.padding
        y: control.topPadding + (control.availableHeight - height) / 2
        color: control.enabled ? control.Material.foreground : control.Material.hintTextColor
        source: "qrc:/qt-project.org/imports/QtQuick/Controls/Material/images/drop-indicator.png"
    }

    contentItem: T.TextField {
        leftPadding: Material.textFieldHorizontalPadding
        topPadding: Material.textFieldVerticalPadding
        bottomPadding: Material.textFieldVerticalPadding

        text: control.editable ? control.editText : control.displayText

        enabled: control.editable
        autoScroll: control.editable
        readOnly: control.down
        inputMethodHints: control.inputMethodHints
        validator: control.validator
        selectByMouse: control.selectTextByMouse

        color: control.enabled ? control.Material.foreground : control.Material.hintTextColor
        selectionColor: control.Material.accentColor
        selectedTextColor: control.Material.primaryHighlightedTextColor
        verticalAlignment: Text.AlignVCenter

        cursorDelegate: CursorDelegate { }
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

    popup: Popup {
        y: control.height - 1
        width: control.width
        implicitHeight: contentItem.implicitHeight
        padding: 1

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0
            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            color: Style.colors.primaryBackground
            radius: 2
            border.color: Style.colors.primaryBorder
        }
    }
}
