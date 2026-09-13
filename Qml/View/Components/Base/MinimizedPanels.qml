import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * MinimizedPanels
 * Footer bar listing currently-minimized DetachablePanel/Terminal instances (see LayoutController).
 * Clicking an icon restores the corresponding panel. Hides itself when nothing is minimized.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property LayoutController layoutController: null
    readonly property bool hasPanels: panelsRepeater.count > 0

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.preferredHeight: root.animHeight
    Layout.margins: root.animHeight > 0 ? 1 : 0
    Layout.bottomMargin: root.animHeight > 0 ? 2 : 0
    clip: true
    color: Style.colors.secondaryBackground
    radius: 5

    property real animHeight: 0

    onHasPanelsChanged: root.animateTo(root.hasPanels ? 27 : 0)

    Component.onCompleted: {
        if (root.hasPanels) {
            if (Style.motionEnabled) {
                root.animHeight = 0
                root.opacity = 0
                root.animateTo(27)
            } else {
                root.animHeight = 27
                root.opacity = 1
            }
        }
    }

    function animateTo(target) {
        if (!Style.motionEnabled) {
            root.animHeight = target
            root.opacity = target > 0 ? 1 : 0
            return
        }

        var hiding = target < root.animHeight
        heightAnim.easing.type = hiding ? Easing.InOutCubic : Easing.OutCubic
        heightAnim.from = root.animHeight
        heightAnim.to = target
        opacityAnim.from = root.opacity
        opacityAnim.to = target > 0 ? 1 : 0
        heightAnim.restart()
        opacityAnim.restart()
    }

    // Height collapse: smooth, no decelerating crawl at the end.
    NumberAnimation {
        id: heightAnim
        target: root
        property: "animHeight"
        duration: Style.motionMedium
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: opacityAnim
        target: root
        property: "opacity"
        duration: Style.motionFast
        easing.type: Easing.OutCubic
    }

    /* Children
     * ****************************************************************************************/
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 6

        Repeater {
            id: panelsRepeater
            model: root.layoutController ? root.layoutController.panels : []

            delegate: ActionIconButton {
                iconText: modelData.icon
                tooltip: modelData.title
                textColor: Style.colors.foreground

                onClicked: modelData.isMinimized = false
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
