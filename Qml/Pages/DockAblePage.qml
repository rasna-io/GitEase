import QtQuick
import QtQuick.Controls

import GitEase
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * DockAblePage
 * Dock functions
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var docks: []

    property var leftSideTabGroupDocks:   []
    property var topSideTabGroupDocks:    []
    property var rightSideTabGroupDocks:  []
    property var bottomSideTabGroupDocks: []

    property bool showDropZone: false

    readonly property real defaultWidth: 300
    readonly property real defaultHeight: 180

    /* Children
     * ****************************************************************************************/
    onDocksChanged: {
        root.updateSideDocks()
    }

    PageDropZone{
        id: pageDropZone
        anchors.fill: parent
        visible: showDropZone
        opacity: 0.7
        z: 9

        defaultWidth : root.defaultWidth * 0.6
        defaultHeight : root.defaultHeight * 0.6
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 1

        // Left docks
        Item {
            id: leftColumn
            width: root.leftSideTabGroupDocks.length > 0 ? root.defaultWidth : 0
            height: parent.height

            // Group docks with TabGroupSide
            Item {
                width: leftColumn.width
                height: leftColumn.height
                visible: root.leftSideTabGroupDocks.length > 0

                TabGroupSide {
                    anchors.fill: parent
                    docks: root.leftSideTabGroupDocks
                }
            }
        }

        // Center area
        Column {
            width: parent.width - leftColumn.width - rightColumn.width
            height: parent.height
            spacing: 1

            // Top docks
            Item {
                id: topArea
                width: parent.width
                height: root.topSideTabGroupDocks.length > 0 ? root.defaultHeight : 0

                // Group docks with TabGroupSide
                Item {
                    width: topArea.width
                    height: topArea.height
                    visible: root.topSideTabGroupDocks.length > 0

                    TabGroupSide {
                        anchors.fill: parent
                        docks: root.topSideTabGroupDocks
                    }
                }
            }

            // Center area
            Item {
                id: centerArea
                width: parent.width
                height: parent.height - topArea.height - bottomArea.height
            }

            // Bottom docks
            Item {
                id: bottomArea
                width: parent.width
                height: root.bottomSideTabGroupDocks.length > 0 ? root.defaultHeight : 0

                // Group docks with TabGroupSide
                Item {
                    width: bottomArea.width
                    height: bottomArea.height
                    visible: root.bottomSideTabGroupDocks.length > 0

                    TabGroupSide {
                        anchors.fill: parent
                        docks: root.bottomSideTabGroupDocks
                    }
                }
            }
        }

        // Right docks
        Item {
            id: rightColumn
            width:  root.rightSideTabGroupDocks.length > 0 ? root.defaultWidth : 0
            height: parent.height

            // Group docks with TabGroupSide
            Item {
                width: rightColumn.width
                height: rightColumn.height
                visible: root.rightSideTabGroupDocks.length > 0

                TabGroupSide {
                    anchors.fill: parent
                    docks: root.rightSideTabGroupDocks
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    // clear all side docks and reAssign (for update states)
    function updateSideDocks(){

        root.leftSideTabGroupDocks = []
        root.topSideTabGroupDocks = []
        root.rightSideTabGroupDocks = []
        root.bottomSideTabGroupDocks = []

        for (var i = 0; i < root.docks.length; i++) {
            let dock = root.docks[i]
            switch (dock.position){
                case Enums.DockPosition.Left:
                    root.leftSideTabGroupDocks.push(dock)
                    root.leftSideTabGroupDocks = root.leftSideTabGroupDocks.slice(0)
                    break
                case Enums.DockPosition.Top:
                    root.topSideTabGroupDocks.push(dock)
                    root.topSideTabGroupDocks = root.topSideTabGroupDocks.slice(0)
                    break
                case Enums.DockPosition.Right:
                    root.rightSideTabGroupDocks.push(dock)
                    root.rightSideTabGroupDocks = root.rightSideTabGroupDocks.slice(0)
                    break
                case Enums.DockPosition.Bottom:
                    root.bottomSideTabGroupDocks.push(dock)
                    root.bottomSideTabGroupDocks = root.bottomSideTabGroupDocks.slice(0)
                    break
                default : break
            }
        }
    }

    function moveDock(dockId : string){
        var dock = root.docks.find(d => d.dockId === dockId)

        if (!dock) {
            console.warn("[DockAblePage] Dock not found:", dockId)
            return
        }

        var globalPos = dock.mapToGlobal(dock.width / 3, 15)
        var pagePos = root.mapFromGlobal(globalPos.x, globalPos.y)
        var droppedPosition = getDropPosition(pagePos.x, pagePos.y)

        dock.position = droppedPosition

        root.updateSideDocks()
    }

    function getDropPosition(x, y) {
        // // Left edge
        if (x < root.defaultWidth) {
            return Enums.DockPosition.Left
        }
        // Right edge
        if (x > root.width - root.defaultWidth) {
            return Enums.DockPosition.Right
        }
        // Top edge
        if (y < root.defaultHeight) {
            return Enums.DockPosition.Top
        }
        // Bottom edge
        if (y > root.height - root.defaultHeight) {
            return Enums.DockPosition.Bottom
        }

        // No center zone - if not on edge, stay floating
        return -1
    }

    function closeDock(dockId : string){
        var index = root.docks.findIndex(d => d.dockId === dockId)

        if (index === -1) {
            console.warn("[DockAblePage] Dock not found:", dockId)
            return
        }

        var dock = root.docks[index]
        root.docks = root.docks.slice(0, index).concat(root.docks.slice(index + 1))
        dock.destroy()
    }
}
