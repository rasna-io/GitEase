import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import GitEaseOrganizationRulesPlugin

/*!
 * ModernSwitch
 */

Item {
    id: root
    /* Property Declarations
     * ****************************************************************************************/
    property alias checked: modernSwitch.checked

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: 50

    /* Children
     * ****************************************************************************************/
    Switch {
        id: modernSwitch
        anchors.fill: parent
        Material.accent: Style.colors.accent
        scale: 0.9
    }
}

