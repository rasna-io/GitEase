import QtQuick
import QtQuick.Controls

import GitEase_Style

/*! ***********************************************************************************************
 * AppToolTip is the tooltip used all over the application.
 * ************************************************************************************************/
ToolTip {
    id: control

    /* Property Declarations
     * ****************************************************************************************/
    //! Longer texts wrap instead of growing wider than this
    property real maximumWidth: 420

    /* Object Properties
     * ****************************************************************************************/
    x: parent ? (parent.width - width) / 2 : 0
    y: -height - 6

    padding: 6
    implicitWidth: Math.min(control.maximumWidth,
                            implicitContentWidth + leftPadding + rightPadding)

    /* Children
     * ****************************************************************************************/
    contentItem: Text {
        text: control.text
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.defaultPt
        color: Style.colors.onColorText
        wrapMode: Text.Wrap
    }

    background: Rectangle {
        radius: 6
        color: Qt.rgba(0, 0, 0, 0.85)
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
    }
}
