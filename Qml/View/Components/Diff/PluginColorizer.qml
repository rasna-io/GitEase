import QtQuick

/*! ***********************************************************************************************
 * PluginColorizer
 * Loads the diff plugin colorizer registered for the extension of filePath and exposes it as
 * colorize(text) for single lines and colorizeLines(lines) for whole files. The file path is
 * passed on, so one plugin can serve many languages.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    pluginManager: null
    property string filePath:      ""

    //! (text) => rich text for one line, or null when no plugin colours this file.
    readonly property var colorize: loader.item ? root.lineColorizer(loader.item, root.filePath) : null

    //! Bumped when plugins come and go so the lookup runs again.
    property int  revision:  0
    property bool suspended: false

    readonly property string extension: {
        const name = root.filePath.split(/[\\/]/).pop().toLowerCase()
        const dot = name.lastIndexOf(".")
        return dot >= 0 ? name.substring(dot + 1) : name
    }

    readonly property url colorizerUrl: {
        root.revision
        if (!root.pluginManager || root.extension.length === 0)
            return ""
        return root.pluginManager.colorizerUrlFor(root.extension)
    }

    /* Object Properties
     * ****************************************************************************************/
    visible: false

    /* Functions
     * ****************************************************************************************/
    function lineColorizer(item, path) {
        return text => item.colorize(text, path)
    }

    //! Rich text for every line, or [] when no plugin colours this file.
    function colorizeLines(lines) {
        const item = loader.item
        if (!item)
            return []
        if (typeof item.colorizeLines === "function")
            return item.colorizeLines(lines, root.filePath)
        return lines.map(line => item.colorize(line, root.filePath))
    }

    /* Children
     * ****************************************************************************************/
    Loader {
        id: loader
        active: !root.suspended && root.colorizerUrl.toString().length > 0
        source: root.colorizerUrl
    }

    Connections {
        target: root.pluginManager
        ignoreUnknownSignals: true

        // The colorizer comes from the plugin's resources, so it must go before the library does.
        function onPluginAboutToUnload(id) {
            root.suspended = true
            Qt.callLater(() => {
                root.suspended = false
                root.revision++
            })
        }

        function onPluginLoaded(id) {
            root.revision++
        }

        function onPluginsChanged() {
            root.revision++
        }
    }
}
