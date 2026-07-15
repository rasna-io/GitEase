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

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.preferredHeight: 27
    Layout.margins: 1
    Layout.bottomMargin: 2
    visible: panelsRepeater.count > 0
    color: Style.colors.secondaryBackground
    radius: 5

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
