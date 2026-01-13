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
    property bool showDropZone: false
    readonly property real defaultWidth: 300
    readonly property real defaultHeight: 180

    /* Children
     * ****************************************************************************************/
    PageDropZone{
        id: pageDropZone
        anchors.fill: parent
        visible: showDropZone
        opacity: 0.7
        z: 9

        defaultWidth : root.defaultWidth
        defaultHeight : root.defaultHeight
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
            width: {
                var count = 0
                for (var i = 0; i < root.docks.length; i++) {
                    if (root.docks[i].position === Enums.DockPosition.Left &&
                        !root.docks[i].isDragging) {
                        count++
                    }
                }
                return count > 0 ? root.defaultWidth : 0
            }
            height: parent.height

            // Group docks with TabGroupSide
            Item {
                width: leftColumn.width
                height: leftColumn.height
                visible: {
                    var count = 0
                    for (var i = 0; i < root.docks.length; i++) {
                        if (root.docks[i].position === Enums.DockPosition.Left &&
                            !root.docks[i].isDragging) {
                            count++
                        }
                    }
                    return count > 0
                }

                TabGroupSide {
                    anchors.fill: parent
                    docks: {
                        var leftDocks = []
                        for (var i = 0; i < root.docks.length; i++) {
                            if (root.docks[i].position === Enums.DockPosition.Left &&
                                !root.docks[i].isDragging) {
                                leftDocks.push(root.docks[i])
                            }
                        }
                        return leftDocks
                    }
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
                height: {
                    var count = 0
                    for (var i = 0; i < root.docks.length; i++) {
                        if (root.docks[i].position === Enums.DockPosition.Top &&
                            !root.docks[i].isDragging) {
                            count++
                        }
                    }
                    return count > 0 ? root.defaultHeight : 0
                }

                // Group docks with TabGroupSide
                Item {
                    width: topArea.width
                    height: topArea.height
                    visible: {
                        var count = 0
                        for (var i = 0; i < root.docks.length; i++) {
                            if (root.docks[i].position === Enums.DockPosition.Top &&
                                !root.docks[i].isDragging) {
                                count++
                            }
                        }
                        return count > 0
                    }

                    TabGroupSide {
                        anchors.fill: parent
                        docks: {
                            var topDocks = []
                            for (var i = 0; i < root.docks.length; i++) {
                                if (root.docks[i].position === Enums.DockPosition.Top &&
                                    !root.docks[i].isDragging) {
                                    topDocks.push(root.docks[i])
                                }
                            }
                            return topDocks
                        }
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
                height: {
                    var count = 0
                    for (var i = 0; i < root.docks.length; i++) {
                        if (root.docks[i].position === Enums.DockPosition.Bottom &&
                            !root.docks[i].isDragging) {
                            count++
                        }
                    }
                    return count > 0 ? root.defaultHeight : 0
                }

                // Group docks with TabGroupSide
                Item {
                    width: bottomArea.width
                    height: bottomArea.height
                    visible: {
                        var count = 0
                        for (var i = 0; i < docks.length; i++) {
                            if (root.docks[i].position === Enums.DockPosition.Bottom &&
                                !root.docks[i].isDragging) {
                                count++
                            }
                        }
                        return count > 0
                    }

                    TabGroupSide {
                        anchors.fill: parent
                        docks: {
                            var bottomDocks = []
                            for (var i = 0; i < root.docks.length; i++) {
                                if (root.docks[i].position === Enums.DockPosition.Bottom &&
                                    !root.docks[i].isDragging) {
                                    bottomDocks.push(root.docks[i])
                                }
                            }
                            return bottomDocks
                        }
                    }
                }
            }
        }

        // Right docks
        Item {
            id: rightColumn
            width: {
                var count = 0
                for (var i = 0; i < root.docks.length; i++) {
                    if (root.docks[i].position === Enums.DockPosition.Right &&
                        !root.docks[i].isDragging) {
                        count++
                    }
                }
                return count > 0 ? root.defaultWidth : 0
            }
            height: parent.height

            // Group docks with TabGroupSide
            Item {
                width: rightColumn.width
                height: rightColumn.height
                visible: {
                    var count = 0
                    for (var i = 0; i < root.docks.length; i++) {
                        if (root.docks[i].position === Enums.DockPosition.Right &&
                            !root.docks[i].isDragging) {
                            count++
                        }
                    }
                    return count > 0
                }

                TabGroupSide {
                    anchors.fill: parent
                    docks: {
                        var rightDocks = []
                        for (var i = 0; i < root.docks.length; i++) {
                            if (root.docks[i].position === Enums.DockPosition.Right &&
                                !root.docks[i].isDragging) {
                                rightDocks.push(root.docks[i])
                            }
                        }
                        return rightDocks
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
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
}
