import QtQuick
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * ConflictProgressBar
 * Footer progress readout: an uppercase caption on the left, "done / total" on the right, and a
 * filled track between them.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string caption:    ""
    property int    value:      0
    property int    total:      0
    property color  fillColor:  Style.colors.accent

    readonly property real ratio: root.total > 0 ? Math.min(1, root.value / root.total) : 0

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: captionLabel.implicitHeight + track.height + 5

    /* Children
     * ****************************************************************************************/
    Text {
        id: captionLabel
        anchors.left: parent.left
        anchors.top: parent.top
        text: root.caption
        color: Style.colors.conflictSectionLabel
        font.family: Style.fontTypes.inter
        font.weight: Font.DemiBold
        font.letterSpacing: 1.2
        font.pixelSize: Style.appFont.microPt
    }

    Text {
        anchors.right: parent.right
        anchors.baseline: captionLabel.baseline
        text: `${root.value} / ${root.total}`
        color: Style.colors.conflictSectionLabel
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.microPt
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 3
        radius: 1.5
        color: Style.colors.conflictProgressTrack

        Rectangle {
            width: parent.width * root.ratio
            height: parent.height
            radius: parent.radius
            color: root.fillColor

            Behavior on width {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
