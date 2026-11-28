import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * GitignoreDialog
 * Modal card used by every popup of the plugin: centered over the window, grows in and fades out.
 * Children declared inside it are stacked in a column.
 *
 *   GitignoreDialog {
 *       maxWidth: Style.dp(520)
 *       Text { text: "Title" }
 *       ...
 *   }
 * ************************************************************************************************/
Popup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property real maxWidth:  Style.dp(520)
    //! 0 sizes the dialog to its content.
    property real maxHeight: 0

    property alias contentSpacing: body.spacing
    default property alias content: body.data

    /* Object Properties
     * ****************************************************************************************/
    parent: Overlay.overlay
    anchors.centerIn: Overlay.overlay
    modal: true
    dim: true
    padding: Style.dp(18)
    closePolicy: Popup.CloseOnEscape
    transformOrigin: Item.Center

    width: Math.min(Overlay.overlay ? Overlay.overlay.width - Style.dp(32) : maxWidth, maxWidth)
    height: maxHeight > 0 ? Math.min(Overlay.overlay ? Overlay.overlay.height - Style.dp(48) : maxHeight, maxHeight)
                          : implicitHeight

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.96
                to: 1
                duration: 240
                easing.type: Easing.OutCubic
            }
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    background: Rectangle {
        radius: Style.dp(12)
        color: Style.colors.pluginCardBackground
        border.width: 1
        border.color: Style.colors.pluginCardBorder
    }

    contentItem: ColumnLayout {
        id: body
        spacing: Style.dp(10)
    }
}
