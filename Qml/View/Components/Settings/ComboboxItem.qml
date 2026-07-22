import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * ComboboxItem
 * ************************************************************************************************/
ColumnLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property     string            title:       ""

    property     string            description: ""

    property     alias             cmb:         cmb

    spacing: 8

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: root.title
            font.family: Style.fontTypes.inter
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Style.colors.foreground
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            font.family: Style.fontTypes.inter
            font.pixelSize: 10
            color: Style.colors.mutedText
        }
    }

    ComboBox {
        id: cmb
        Layout.fillWidth: true
        Material.accent: Style.colors.accent
        Material.foreground: Style.colors.foreground
        font.family: Style.fontTypes.inter
        font.pixelSize: 12

        implicitHeight: 30
        minHeight: 30
        topPadding: 0
        bottomPadding: 0
        leftPadding: 12
        rightPadding: indicator ? indicator.width + 16 : 12

        readonly property bool isOpen: activeFocus || popup.visible

        contentItem: Text {
            text: cmb.displayText
            font: cmb.font
            color: cmb.currentIndex >= 0 ? Style.colors.foreground
                                         : Style.colors.placeholderText
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            implicitHeight: 30
            radius: 6
            color: cmb.hovered ? Style.colors.controlBackgroundHover
                               : Style.colors.controlBackground
            border.width: cmb.isOpen ? 2 : 1
            border.color: cmb.isOpen ? Style.colors.accent
                          : cmb.hovered ? Style.colors.controlBorderHover
                                        : Style.colors.controlBorder

            Behavior on color        {
                ColorAnimation {
                    duration: 150
                }
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: 150
                }
            }
        }
    }
}
