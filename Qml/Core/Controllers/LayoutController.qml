import QtQuick
import GitEase

/*! ***********************************************************************************************
 * LayoutController
 * Per-session controller for managing application layouts including default and custom layouts.
 * Handles layout persistence (save/load/delete) for dock widget arrangements, and tracks which
 * DetachablePanel/Terminal instances are currently minimized (see MinimizedPanels.qml).
 * ************************************************************************************************/

QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property AppModel appModel: null

    property var defaultLayouts: ({})
    property var customLayouts: ({})
    property var panels: []

    // Persisted per-panel layout state, keyed by DetachablePanel.layoutId.
    // Shape: { "<layoutId>": { width: <int>, minimized: <bool> } }
    property var panelLayouts: ({})

    readonly property string layoutFileName: "Layout.json"

    /* Functions
     * ****************************************************************************************/
    /**
     * Register a panel as minimized
     */
    function register(panel) {
        if (root.panels.indexOf(panel) !== -1)
            return

        root.panels = root.panels.concat([panel])
    }

    /**
     * Unregister a panel that is no longer minimized (or is being destroyed)
     */
    function unregister(panel) {
        let idx = root.panels.indexOf(panel)
        if (idx === -1)
            return

        let updated = root.panels.slice()
        updated.splice(idx, 1)
        root.panels = updated
    }

    /**
     * Restore a DetachablePanel's persisted width/minimized state (keyed by panel.layoutId)
     */
    function registerPanelLayout(panel) {
        if (!panel || !panel.layoutId)
            return

        let entry = root.panelLayouts[panel.layoutId]
        if (!entry)
            return

        if (entry.width !== undefined)
            panel.lastWidth = entry.width
        if (entry.minimized !== undefined)
            panel.isMinimized = entry.minimized
    }

    /**
     * Persist a DetachablePanel's current width/minimized state (keyed by panel.layoutId)
     */
    function persistPanelLayout(panel) {
        if (!panel || !panel.layoutId)
            return

        let layouts = root.panelLayouts
        layouts[panel.layoutId] = {
            width: panel.lastWidth,
            minimized: panel.isMinimized
        }
        root.panelLayouts = layouts
        root.saveLayouts()
    }

    /**
     * Load persisted panel layouts from disk (via AppModel's FileIO)
     */
    function loadLayouts() {
        if (!root.appModel || !root.appModel.fileIO)
            return

        let fileIO = root.appModel.fileIO
        let path = fileIO.configFilePath + "/" + root.layoutFileName

        if (!fileIO.isFileExist(path))
            return

        fileIO.fileName = path
        fileIO.read()

        try {
            root.panelLayouts = JSON.parse(fileIO.fileContent) || {}
        } catch (e) {
            console.warn("[LayoutController] Failed to parse", path, e)
        }
    }

    /**
     * Persist all panel layouts to disk (via AppModel's FileIO)
     */
    function saveLayouts() {
        if (!root.appModel || !root.appModel.fileIO)
            return

        let fileIO = root.appModel.fileIO
        fileIO.createDir(fileIO.configFilePath)
        fileIO.fileName = fileIO.configFilePath + "/" + root.layoutFileName
        fileIO.fileContent = JSON.stringify(root.panelLayouts, null, 2)
        fileIO.write()
    }

    /**
     * Save a layout configuration with the given name
     */
    function saveLayout(name, layout) {
        // TODO: Implementation
    }

    /**
     * Load a layout configuration by name
     */
    function loadLayout(name) {
        // TODO: Implementation
        return null
    }

    /**
     * Delete a custom layout
     */
    function deleteLayout(name) {
        // TODO: Implementation
    }

    /**
     * Get a default layout for a specific type
     */
    function getDefaultLayout(type) {
        // TODO: Implementation
        return null
    }

    Component.onCompleted: {
        root.loadLayouts()
    }
}


