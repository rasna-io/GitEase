import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SpinBoxItem
 * ************************************************************************************************/
RowLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property     string            title:       ""

    property     string            description: ""

    property     alias             spinBox:     spb

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: root.title
            font.pointSize: Style.appFont.h4Pt
            color: Style.colors.foreground
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            font.pointSize: Style.appFont.secondaryPt
            color: Style.colors.mutedText
        }
    }

    SpinBox {
        id: spb
        Material.accent: Style.colors.accent
        Material.background: Style.colors.surfaceLight
        Material.foreground: Style.colors.foreground
        from: 1
        to: 10
        value: 5
    }
}

