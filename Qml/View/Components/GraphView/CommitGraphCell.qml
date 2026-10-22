import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * CommitGraphCell
 * The graph + branch/tag part of one commit row: lane edges, the commit node and its ref labels.
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    graphRow        : null      // descriptor from CommitGraphRouting.buildRows
    property color  laneColor       : "gray"
    property bool   selected        : false
    property bool   isStash         : false
    property bool   showAvatar      : true

    property real   columnSpacing   : 30
    property real   graphWidth      : 60
    property real   refsWidth       : 80
    property real   nodeSize        : 24

    readonly property int   column      : graphRow ? graphRow.column : 0
    readonly property real  nodeCenterX : columnSpacing * (column + 1)
    readonly property var   refs        : graphRow ? graphRow.refs : []
    readonly property real  refsStartX  : Math.max(graphWidth + 10, nodeCenterX + 20)
    readonly property real  refsEndX    : graphWidth + refsWidth - 4

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth   : graphWidth + refsWidth
    clip            : true

    /* Children
     * ****************************************************************************************/
    CommitLaneEdges {
        anchors.fill: parent
        edges: root.graphRow ? root.graphRow.edges : []
    }

    // Connector between the node and the ref labels
    Rectangle {
        visible: root.refs.length > 0
        x: root.nodeCenterX
        width: Math.max(0, refsRow.x + refsRow.labelsEndX - root.nodeCenterX)
        height: 5
        anchors.verticalCenter: parent.verticalCenter
        color: root.laneColor
        opacity: 0.8
    }

    // Every label is shown in order; each one's text is cut to what is left of the column
    Item {
        id: refsRow

        readonly property real  spacing     : 8
        readonly property real  available   : Math.max(0, root.refsEndX - root.refsStartX)

        property real   labelsEndX  : 0

        visible: root.refs.length > 0
        x: root.refsStartX
        width: available
        height: parent.height

        function refresh() {
            let last = refsRepeater.count > 0 ? refsRepeater.itemAt(refsRepeater.count - 1) : null
            labelsEndX = last ? last.x + last.width : 0
        }

        Repeater {
            id: refsRepeater
            model: root.refs

            delegate: CommitRefLabel {
                id: refLabel

                required property int index
                required property var modelData

                readonly property Item previous: index > 0 ? refsRepeater.itemAt(index - 1) : null

                x: previous ? previous.x + previous.width + refsRow.spacing : 0
                y: (parent.height - height) / 2
                width: Math.max(minimumWidth, Math.min(implicitWidth, refsRow.available - x))

                text: modelData.text
                isTag: modelData.isTag
                color: modelData.isTag ? Style.colors.graphTagLabel : root.laneColor

                onWidthChanged: refsRow.refresh()
                Component.onCompleted: refsRow.refresh()
            }
        }
    }

    CommitGraphNode {
        x: root.nodeCenterX - width / 2
        y: (root.height - height) / 2
        branchColor: root.laneColor
        selected: root.selected
        isStash: root.isStash
        showAvatar: root.showAvatar
        avatarSize: root.nodeSize
    }
}
