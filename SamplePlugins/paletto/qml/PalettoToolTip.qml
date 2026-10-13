import QtQuick
import QtQuick.Controls

import GitEase_Style

/*! ***********************************************************************************************
 * PalettoToolTip
 * Tooltip with the same look as the application's own (see ActionIconButton): dark rounded
 * bubble above the item, light Inter text. Declare it inside the item it describes:
 *
 *   PalettoToolTip {
 *       visible: someButton.hovered
 *       text: "Explain the item"
 *   }
 * ************************************************************************************************/
ToolTip {
    id: root

    delay: 100
    timeout: 2000
    padding: 6

    x: parent ? (parent.width - width) / 2 : 0
    y: -height - 6

    contentItem: Text {
        text: root.text
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.defaultPt
        color: "#ffffff"
    }

    background: Rectangle {
        radius: 6
        color: Qt.rgba(0, 0, 0, 0.85)
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
    }
}
