import QtQuick
import QtQuick.Controls

import GitEase_Style

/*! ***********************************************************************************************
 * SplitViewHandle
 * Shared draggable handle for all SplitViews: an always-visible rounded bar that thickens with
 * an animation while hovered or pressed.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    // Set to match the containing SplitView's own orientation.
    property int orientation: Qt.Horizontal

    readonly property bool active: SplitHandle.pressed || SplitHandle.hovered
    readonly property int  idleThickness: 1
    readonly property int  activeThickness: 4
    readonly property int  thickness: root.active ? root.activeThickness : root.idleThickness

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: 4
    implicitHeight: 4

    /* Children
     * ****************************************************************************************/
    Rectangle {
        anchors.centerIn: parent
        width: root.orientation === Qt.Horizontal ? root.thickness : parent.width / 4
        height: root.orientation === Qt.Horizontal ? parent.height / 4 : root.thickness
        radius: root.thickness / 2
        color: SplitHandle.pressed ? Style.colors.accent
             : SplitHandle.hovered ? Style.colors.resizeHandlePressed
             : Style.colors.resizeHandle

        Behavior on width {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }
}
