import QtQuick
import QtQuick.Shapes

/*! ***********************************************************************************************
 * CommitLaneEdges
 * Draws the slice of the graph edges that crosses one row. Paths are row-relative SVG strings
 * produced by CommitGraphRouting.js; neighbouring rows continue the same edges seamlessly.
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    edges       : []
    property real   edgeWidth   : 2.5
    property real   dashLength  : 4
    property real   dashGap     : 8

    /* Children
     * ****************************************************************************************/
    Repeater {
        model: root.edges

        delegate: Shape {
            id: edgeShape

            required property var modelData

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor       : "transparent"
                strokeColor     : edgeShape.modelData.color
                strokeWidth     : root.edgeWidth
                capStyle        : ShapePath.FlatCap
                strokeStyle     : edgeShape.modelData.dashed ? ShapePath.DashLine : ShapePath.SolidLine
                dashPattern     : [root.dashLength / root.edgeWidth, root.dashGap / root.edgeWidth]
                dashOffset      : edgeShape.modelData.dashOffset

                PathSvg {
                    path: edgeShape.modelData.path
                }
            }
        }
    }
}
