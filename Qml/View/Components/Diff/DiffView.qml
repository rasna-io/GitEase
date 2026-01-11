import QtQuick
import QtQuick.Controls

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * DiffView
 * ************************************************************************************************/
SimpleDock {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var diffData: []

    property int minSideBySideWidth: 500

    readonly property bool stacked: width < minSideBySideWidth

    /* Object Properties
     * ****************************************************************************************/
    title: "Diff View Dock"

    /* Children
     * ****************************************************************************************/
    Component {
        id: diagonalHatch
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.strokeStyle = Style.colors.foreground
                ctx.lineWidth = 1
                ctx.beginPath()
                var step = 10
                for (var i = -height; i < width + height; i += step) {
                    ctx.moveTo(i + height, 0)
                    ctx.lineTo(i, height)
                }
                ctx.stroke()
            }
        }
    }

    ListView {
        id: diffList
        anchors.fill: parent
        model: root.diffData
        clip: true

        delegate: Item {
            id: item
            width: diffList.width
            implicitHeight: root.stacked? stackedDiff.implicitHeight : sideBySideDiff.implicitHeight
            required property var modelData


            SideBySideDiff {
                id: sideBySideDiff
                width: diffList.width
                modelData: item.modelData
                hatch: diagonalHatch
                visible: !root.stacked

            }

            StackedDiff {
                id: stackedDiff
                width: diffList.width
                modelData: item.modelData
                hatch: diagonalHatch
                visible: root.stacked
            }
        }

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
    }
}
