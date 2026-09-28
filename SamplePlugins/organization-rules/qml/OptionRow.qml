import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import GitEaseOrganizationRulesPlugin

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
    spacing: 20


    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        Layout.preferredWidth: 200
        Layout.maximumWidth: 200
        Layout.alignment: Qt.AlignVCenter
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: root.title
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.defaultPt
            font.weight: Font.Medium
            color: Style.colors.pluginCardTitle
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: root.subtitle
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.captionPt
            color: Style.colors.pluginCardMetaText
            elide: Text.ElideRight
            visible: root.subtitle !== ""
        }
    }

    Item {
        id: controlSlot
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}
