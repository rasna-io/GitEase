import QtQuick
import QtQuick.Templates as T

import GitEase_Style

/*! ***********************************************************************************************
 * RuleScrollBar
 * Slim vertical scrollbar with a rounded track that stays visible while content is scrollable.
 * Parents reserve a right gutter wider than the bar so it never overlaps content.
 * ************************************************************************************************/
T.ScrollBar {
    id: control

    /* Property Declarations
     * ****************************************************************************************/
    readonly property bool scrollable: control.size < 1.0
    readonly property bool highlighted: control.hovered || control.pressed

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: 10
    implicitHeight: 10
    padding: 2
    topPadding: 4
    bottomPadding: 4
    hoverEnabled: true
    minimumSize: 0.08
    policy: T.ScrollBar.AsNeeded
    visible: control.scrollable
    opacity: control.scrollable ? 1.0 : 0.0

    Behavior on opacity { NumberAnimation { duration: Style.motionFast } }

    /* Children
     * ****************************************************************************************/
    contentItem: Item {
        implicitWidth: 6

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: control.highlighted ? 6 : 4
            radius: width / 2
            color: control.pressed     ? Style.colors.accent
                 : control.highlighted ? Style.colors.pluginSectionLabel
                                       : Style.colors.pluginSectionMetaText
            opacity: control.highlighted ? 1.0 : 0.7

            Behavior on width { NumberAnimation { duration: Style.motionFast; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Style.motionFast } }
            Behavior on opacity { NumberAnimation { duration: Style.motionFast } }
        }
    }

    background: Rectangle {
        implicitWidth: 10
        radius: width / 2
        color: Style.colors.pluginCountPillBackground
        opacity: control.highlighted ? 1.0 : 0.6

        Behavior on opacity { NumberAnimation { duration: Style.motionFast } }
    }
}
