import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import GitEaseOrganizationRulesPlugin

/*!
 * ModernSwitch
 * Compact toggle using the GitEase plugin toggle palette.
 */

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property bool checked: false

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: 36
    implicitHeight: 20
    opacity: enabled ? 1.0 : 0.5

    /* Children
     * ****************************************************************************************/
    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 20
        radius: height / 2
        color: root.checked ? (toggleArea.containsMouse ? Style.colors.accentHover : Style.colors.accent)
                            : Style.colors.pluginToggleTrackOff
        border.width: root.checked ? 0 : 1
        border.color: Style.colors.pluginToggleTrackOffBorder

        Behavior on color { ColorAnimation { duration: Style.motionFast; easing.type: Easing.OutCubic } }

        Rectangle {
            id: thumb
            width: 14
            height: 14
            radius: 7
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? track.width - width - 3 : 3
            color: root.checked ? Style.colors.switchHandle : Style.colors.pluginToggleThumbOff
            border.width: root.checked ? 0 : 1
            border.color: Style.colors.pluginToggleTrackOffBorder

            Behavior on x { NumberAnimation { duration: Style.motionFast; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: toggleArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.enabled) root.checked = !root.checked
        }
    }
}
