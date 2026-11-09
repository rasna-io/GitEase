import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * TextFieldItem
 * ************************************************************************************************/
RowLayout {
    id: root

    /* Property Declarations
    * ****************************************************************************************/
    property     string            title:       ""

    property     string            description: ""

    property     alias             text:        txf.text

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: root.title
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.mediumPt
            font.weight: Font.DemiBold
            color: Style.colors.foreground
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.smallPt
            color: Style.colors.mutedText
        }
    }

    TextField {
        id: txf
        Layout.preferredWidth: parent.width * 0.4
    }
}
