import QtQuick

import GitEase

/*! ***********************************************************************************************
 * LayoutController
 * Singleton controller for managing application layouts including default and custom layouts.
 * Handles layout persistence (save/load/delete) for dock widget arrangements.
 * ************************************************************************************************/

QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property var pageLayouts

    // Map: pageTitle -> default dock layout array
    // Each entry is an array of: { key: string, position: int, isFloating: bool }
    property var defaultLayouts: ({})

    /* Defaults
     * ****************************************************************************************/
    function initDefaultLayouts() {
        root.defaultLayouts = {
            // Graph page (DockAblePage)
            "Graph View": [
                { key: "Commit Graph Dock", position: -1,    isFloating: true },
                { key: "File Changes Dock", position: Enums.DockPosition.Bottom, isFloating: false },
                { key: "Diff View Dock",    position: Enums.DockPosition.Right,  isFloating: false }
            ],

            "Committing": [],

            "Blank Page": []
        }
    }

    /* Functions
     * ****************************************************************************************/
    function getDefaultLayout(pageTitle) {
        let map = root.defaultLayouts || ({})
        return map[pageTitle] || []
    }

    function arrayCheck(v) {
        return (v && v.length !== undefined) ? v : []
    }

    function findPageLayout(pageTitle) {
        let layouts = arrayCheck(root.pageLayouts)

        for (let i = 0; i < layouts.length; i++) {
            let l = layouts[i]

            if (!l)
                continue

            if (l.pageTitle && l.pageTitle === pageTitle)
                return l
        }
        return null
    }

    function createPageLayout(pageTitle) {
        let comp = Qt.createComponent("qrc:/GitEase/Qml/Core/Models/PageLayout.qml")
        if (comp.status !== Component.Ready) {
            console.error("[LayoutController] Failed to create PageLayout component:", comp.errorString())
            return null
        }

        let layoutObj = comp.createObject(root, {
            pageTitle: pageTitle,
            docks: []
        })

        if (!layoutObj)
            return null

        root.pageLayouts.push(layoutObj)
        return layoutObj
    }

    function getOrCreatePageLayout(pageTitle) {
        if (!pageTitle || pageTitle.length === 0)
            return null

        let existing = findPageLayout(pageTitle)
        if (existing)
            return existing

        return createPageLayout(pageTitle)
    }

    function applyLayoutToDocks(pageTitle, docks) {
        if (!pageTitle)
            return

        let dockList = arrayCheck(docks)
        if (dockList.length === 0)
            return

        let pageLayout = getOrCreatePageLayout(pageTitle)
        if (!pageLayout)
            return

        // If layout has never been initialized, seed it from defaults.
        if (!pageLayout.docks || pageLayout.docks.length === 0) {
            let defaults = getDefaultLayout(pageTitle)
            pageLayout.docks = defaults.slice(0)
        }

        let layoutByKey = ({})
        let items = arrayCheck(pageLayout.docks)
        for (let i = 0; i < items.length; i++) {
            let it = items[i]
            if (it && it.key)
                layoutByKey[it.key] = it
        }

        // Apply to docks
        for (let d = 0; d < dockList.length; d++) {
            let dock = dockList[d]
            if (!dock)
                continue

            let key = dock.title
            let layoutItem = layoutByKey[key]
            if (!layoutItem)
                continue

            dock.position = layoutItem.position
            dock.isFloating = (layoutItem.isFloating === true) || (layoutItem.position === -1)
        }
    }

    // Capture current runtime dock state into the page layout (in-memory).
    function captureLayoutFromDocks(pageTitle, docks) {
        let dockList = arrayCheck(docks)
        let pageLayout = getOrCreatePageLayout(pageTitle)
        if (!pageLayout)
            return

        let captured = []
        for (let d = 0; d < dockList.length; d++) {
            let dock = dockList[d]
            if (!dock)
                continue

            captured.push({
                key: dock.title,
                position: dock.position,
                isFloating: dock.isFloating
            })
        }

        pageLayout.docks = captured
    }

    Component.onCompleted: {
        initDefaultLayouts()
    }
}
