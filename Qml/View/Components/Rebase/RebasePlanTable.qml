import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RebasePlanTable
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property ListModel  model:          null
    property int        currentIndex:   -1
    property bool       showStatus:     false
    property bool       editable:       true

    property var        statusColorOf:  function(status) {
        return Style.colors.rebaseStatusPending
    }

    property var        statusIsDone:   function(status) {
        return false
    }

    property int contentInset: Style.dp(16)

    readonly property int gripWidth:    Style.dp(20)
    readonly property int actionWidth:  Style.dp(80)
    readonly property int shaWidth:     Style.dp(78)
    readonly property int authorWidth:  Style.dp(80)
    readonly property int dateWidth:    Style.dp(62)
    readonly property int statusWidth:  root.showStatus ? Style.dp(80) : 0
    readonly property int reorderWidth: Style.dp(26)

    readonly property int _leftEdge:  root.contentInset
    readonly property int _rightEdge: root.width - root.contentInset

    readonly property var columns: ({
        gripX:         root._leftEdge,
        actionX:       root._leftEdge + root.gripWidth,
        actionWidth:   root.actionWidth,
        shaX:          root._leftEdge + root.gripWidth + root.actionWidth,
        shaWidth:      root.shaWidth,
        messageX:      root._leftEdge + root.gripWidth + root.actionWidth + root.shaWidth,
        messageWidth:  Math.max(Style.dp(120),
                                root._rightEdge - root._leftEdge
                                - root.gripWidth - root.actionWidth - root.shaWidth
                                - root.authorWidth - root.dateWidth - root.statusWidth
                                - root.reorderWidth),
        authorX:       root._rightEdge - root.reorderWidth - root.statusWidth - root.dateWidth
                       - root.authorWidth,
        authorWidth:   root.authorWidth,
        dateX:         root._rightEdge - root.reorderWidth - root.statusWidth - root.dateWidth,
        dateWidth:     root.dateWidth,
        statusX:       root._rightEdge - root.reorderWidth - root.statusWidth,
        statusWidth:   root.statusWidth,
        reorderX:      root._rightEdge - root.reorderWidth
    })

    /* Signals
     * ****************************************************************************************/
    signal rowClicked(int index)
    signal actionPicked(int index, string action)
    signal moveRequested(int fromIndex, int toIndex)

    /* Functions
     * ****************************************************************************************/
    function positionViewAtIndex(index, mode) {
        rowList.positionViewAtIndex(index, mode)
    }

    /* Children
     * ****************************************************************************************/
    Column {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: headerRow
            width: parent.width
            height: Style.dp(30)
            color: Style.colors.secondaryBackground

            Repeater {
                model: [
                    { title: "ACTION",  x: root.columns.actionX,  width: root.columns.actionWidth },
                    { title: "SHA",     x: root.columns.shaX,     width: root.columns.shaWidth },
                    { title: "MESSAGE", x: root.columns.messageX, width: root.columns.messageWidth },
                    { title: "AUTHOR",  x: root.columns.authorX,  width: root.columns.authorWidth },
                    { title: "DATE",    x: root.columns.dateX,    width: root.columns.dateWidth },
                    { title: root.showStatus ? "STATUS" : "",
                      x: root.columns.statusX, width: root.columns.statusWidth }
                ]

                delegate: Text {
                    required property var modelData

                    x: modelData.x
                    width: modelData.width
                    anchors.verticalCenter: parent.verticalCenter

                    text: modelData.title
                    color: Style.colors.conflictSectionLabel
                    font.family: Style.fontTypes.inter
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.1
                    font.pixelSize: Style.appFont.microPt
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Style.colors.primaryBorder
        }

        ListView {
            id: rowList

            width: parent.width
            height: parent.height - headerRow.height - 1
            clip: true
            model: root.model
            currentIndex: root.currentIndex
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar { active: true }

            delegate: RebasePlanRow {
                id: planRow

                required property int index
                required property var model

                width: rowList.width
                columns: root.columns

                action:     planRow.model.action
                shortHash:  planRow.model.shortHash
                summary:    planRow.model.summary
                author:     planRow.model.author
                authorDate: planRow.model.authorDate
                status:     planRow.model.status

                isCurrent: planRow.index === root.currentIndex
                showStatus: root.showStatus
                actionEnabled: root.editable
                canMoveUp: planRow.index > 0
                canMoveDown: planRow.index < (root.model ? root.model.count - 1 : 0)
                statusColor: root.statusColorOf(planRow.status)
                isDone: root.statusIsDone(planRow.status)

                onClicked: root.rowClicked(planRow.index)
                onActionPicked: (picked) => root.actionPicked(planRow.index, picked)
                onMoveUpRequested: root.moveRequested(planRow.index, planRow.index - 1)
                onMoveDownRequested: root.moveRequested(planRow.index, planRow.index + 1)

                onDragMoveRequested: (deltaRows) => {
                    let target = planRow.index + deltaRows
                    if (target >= 0 && target < root.model.count)
                        root.moveRequested(planRow.index, target)
                }
            }
        }
    }
}
