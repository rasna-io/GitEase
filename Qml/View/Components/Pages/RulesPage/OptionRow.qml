import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*!
 * OptionRow
 *
 * A reusable row component for displaying a configurable option.
 * Contains a title, optional subtitle, and a customizable control area
 * for inserting UI elements such as switches, buttons, or input fields.
 */

RowLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string title: ""
    property string subtitle: ""
    property int rowHeight: 40
    property alias control: controlSlot.data

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.preferredHeight: root.rowHeight


    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        Layout.preferredWidth: 200

        Text {
            text: root.title
            font.family: Style.fontTypes.roboto
            color: Style.colors.placeholderText
            font.pixelSize: 12
        }

        Text {
            text: root.subtitle
            font.family: Style.fontTypes.roboto
            color: Style.colors.mutedText
            font.pixelSize: 11
            visible: root.subtitle !== ""
        }
    }

    Item {
        id: controlSlot
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}