import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*!
 * ModernSwitch
 */

Item {
    implicitWidth: 50

    Switch {
        anchors.fill: parent
        Material.accent: Style.colors.accent
        scale: 0.9
    }
}

