import QtQuick
import QtQuick.Controls

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * DockAblePage
 * Dock functions
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    // Provided by MainWindow Loader (current Page model)
    property var page: null

    // Provided by MainWindow Loader (UiSession context)
    property AppModel appModel: null
    property LayoutController layoutController: null

    property var docks: []

    property var leftSideTabGroupDocks:   []
    property var topSideTabGroupDocks:    []
    property var rightSideTabGroupDocks:  []
    property var bottomSideTabGroupDocks: []

    property bool showDropZone: false
    property var activeDraggingDock: null
    property int hoveredDockPosition: -1

    readonly property real defaultWidth: 300
    readonly property real defaultHeight: 180

    readonly property real minCenterSize: 200

    /* Children
     * ****************************************************************************************/
    onDocksChanged: {
        root.updateSideDocks()
    }

    onLayoutControllerChanged: {
        applyLayout()
    }

    PageDropZone{
        id: pageDropZone
        anchors.fill: parent
        visible: showDropZone
        opacity: 0.7
        z: 9

        defaultWidth : root.defaultWidth * 0.6
        defaultHeight : root.defaultHeight * 0.6
        activePosition: root.hoveredDockPosition
    }

    Timer {
        id: dropZoneHoverTimer
        interval: 16
        repeat: true
        running: root.showDropZone && root.activeDraggingDock
        onTriggered: root.updateHoveredDockPosition()
    }

    onShowDropZoneChanged: {
        if (!showDropZone) {
            hoveredDockPosition = -1
            activeDraggingDock = null
        }
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
            width: root.leftSideTabGroupDocks.length > 0 ? leftTabGroup.preferredSize : 0
            height: parent.height

            TabGroupSide {
                id: leftTabGroup
                anchors.fill: parent
                position: Enums.DockPosition.Left
                docks: root.leftSideTabGroupDocks
                preferredSize: root.defaultWidth
                minPreferredSize: 160
                maxPreferredSize: Math.max(minPreferredSize, root.width - (root.rightSideTabGroupDocks.length > 0 ? rightTabGroup.preferredSize : 0) - root.minCenterSize)
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
                height: root.topSideTabGroupDocks.length > 0 ? topTabGroup.preferredSize : 0

                TabGroupSide {
                    id: topTabGroup
                    anchors.fill: parent
                    position: Enums.DockPosition.Top
                    docks: root.topSideTabGroupDocks
                    preferredSize: root.defaultHeight
                    minPreferredSize: 120
                    maxPreferredSize: Math.max(minPreferredSize, root.height - (root.bottomSideTabGroupDocks.length > 0 ? bottomTabGroup.preferredSize : 0) - root.minCenterSize)
                }
            }

            // Center area
            Item {
                id: centerArea
                width: parent.width
                height: parent.height - topArea.height - bottomArea.height

                // Default content - only show when no docks exist
                Column {
                    anchors.centerIn: parent
                    visible : root.docks.length === 0 && parent.height > 50
                    Label {
                        text: "No Docks Open"
                        color: "#a0a0a0"
                        font.pointSize: Style.appFont.h3Pt
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // Bottom docks
            Item {
                id: bottomArea
                width: parent.width
                height: root.bottomSideTabGroupDocks.length > 0 ? bottomTabGroup.preferredSize : 0

                TabGroupSide {
                    id: bottomTabGroup
                    anchors.fill: parent
                    position: Enums.DockPosition.Bottom
                    docks: root.bottomSideTabGroupDocks
                    preferredSize: root.defaultHeight
                    minPreferredSize: 120
                    maxPreferredSize: Math.max(minPreferredSize, root.height - (root.topSideTabGroupDocks.length > 0 ? topTabGroup.preferredSize : 0) - root.minCenterSize)
                }
            }
        }

        // Right docks
        Item {
            id: rightColumn
            width:  root.rightSideTabGroupDocks.length > 0 ? rightTabGroup.preferredSize : 0
            height: parent.height

            TabGroupSide {
                id: rightTabGroup
                anchors.fill: parent
                position: Enums.DockPosition.Right
                docks: root.rightSideTabGroupDocks
                preferredSize: root.defaultWidth
                minPreferredSize: 160
                maxPreferredSize: Math.max(minPreferredSize, root.width - (root.leftSideTabGroupDocks.length > 0 ? leftTabGroup.preferredSize : 0) - root.minCenterSize)
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

        if (root.layoutController && root.page) {
            if (root.page.title && root.page.title.length)
                root.layoutController.captureLayoutFromDocks(root.page.title, root.docks)
        }
    }

    function updateHoveredDockPosition() {
        if (!root.activeDraggingDock)
            return

        var globalPos = root.activeDraggingDock.mapToGlobal(root.activeDraggingDock.width / 3, 15)
        var pagePos = root.mapFromGlobal(globalPos.x, globalPos.y)
        root.hoveredDockPosition = getDropPosition(pagePos.x, pagePos.y)
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

        if (root.layoutController && root.page) {
            if (root.page.title && root.page.title.length)
                root.layoutController.captureLayoutFromDocks(root.page.title, root.docks)
        }
    }

    function applyLayout() {
        if (!root.layoutController || !root.page)
            return

        if (!root.page.title || root.page.title.length === 0)
            return

        if (!root.docks || root.docks.length === 0)
            return

        root.layoutController.applyLayoutToDocks(root.page.title, root.docks)
        root.updateSideDocks()
    }
}
