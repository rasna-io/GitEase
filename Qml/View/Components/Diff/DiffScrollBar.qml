import QtQuick
import QtQuick.Controls as QQC

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * DiffScrollBar
 * The scrollbar the diff and conflict editors share: always armed, so it fades in on content change
 * and out again once the view settles, and able to draw a minimap of where the interesting rows sit.
 *
 * Set `markers` to a list of { startRatio, sizeRatio, color } — ratios of the total row count — and a
 * vertical bar paints them over its full width at full opacity, so the map stays readable after the
 * handle itself has faded out.
 * ************************************************************************************************/
ScrollBar {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property real   contentSize:     0
    property real   viewportSize:    0
    property real   viewportRatio:   0.5
    property var    markers:         []
    property color  markerColor:     Style.colors.conflictMarker
    property real   minMarkerHeight: 2

    readonly property bool manualSizing: root.viewportSize > 0
    readonly property real offset: root.position * root.contentSize

    /* Object Properties
     * ****************************************************************************************/
    active: true
    size: root.manualSizing && root.contentSize > 0
          ? (root.viewportSize * root.viewportRatio) / root.contentSize
          : 1

    visible: root.manualSizing ? root.size < 1.0
                               : root.policy !== QQC.ScrollBar.AlwaysOff

    /* Children
     * ****************************************************************************************/
    Item {
        id: markerStrip

        anchors.fill: parent
        z: -1
        clip: true
        visible: root.orientation === Qt.Vertical && root.markers.length > 0 && root.size < 1.0

        Repeater {
            model: root.markers

            delegate: Rectangle {
                required property var modelData

                x: 0
                y: modelData.startRatio * markerStrip.height
                width: markerStrip.width
                height: Math.max(root.minMarkerHeight, modelData.sizeRatio * markerStrip.height)
                color: modelData.color !== undefined ? modelData.color : root.markerColor
            }
        }
    }
}
