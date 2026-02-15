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
    property string title:       ""
    property string description: ""
    property alias  from:        spinBox.from
    property alias  to:          spinBox.to
    property alias  value:       spinBox.value

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
        id: spinBox
        from: 1
        to: 10
        value: 5
        editable: false
    }
}

