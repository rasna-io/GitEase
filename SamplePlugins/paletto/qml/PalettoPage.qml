import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts

import GitEase_Style
import GitEasePaletto

/*! ***********************************************************************************************
 * PalettoPage
 * Live editor for the application's color tokens.
 *
 * How it works: the page owns a private Colors object ("workColors"), fills it from the chosen base
 * theme, lays the user's changes on top and installs it as Style.colors. Every token edit is a
 * plain assignment on that object, so every binding in the application updates immediately.
 * The built-in theme objects are never touched, so "Use app theme" simply asks the host to
 * select its own theme again.
 *
 * A palette is the base theme name plus only the tokens that differ from it. The page keeps the
 * work in progress as a draft in the plugin settings and re-applies it at startup; when the host
 * switches theme afterwards (Settings > Appearance) the palette is switched off.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    pluginManager:          null
    property var    notificationController: null
    property string pluginId:               "com.gitease.paletto"

    readonly property var themes: [
        {
            key: "Modern Light",
            label: "Light"
        },
        {
            key: "Modern Soft",
            label: "Soft"
        },
        {
            key: "Modern Dark",
            label: "Dark"
        }
    ]

    //! Theme the palette is laid over.
    property string baseTheme:   "Modern Light"
    //! Name of the saved / imported palette being edited; empty for an untitled one.
    property string paletteName: ""
    property bool   dirty:       false
    //! True while the work colors are installed as Style.colors.
    property bool   live:        false
    //! Set around our own writes to Style.colors so the change watcher ignores them.
    property bool   applying:    false

    property bool   settingsLoaded: false
    property bool   startupGrace:   true
    property string draftText:      ""

    //! Every token: { name, label, group, value, base, changed }.
    property var    allTokens:    []
    property var    tokenIndex:   ({})
    property var    baseValues:   ({})
    property var    groupNames:   []
    property int    changedCount: 0

    property var    library:      []
    //! Colors objects registered as custom themes (see registerThemes()).
    property var    themeObjects: []

    property string search:       ""
    property string groupFilter:  ""
    property bool   changedOnly:  false

    property string selectedName:  ""
    //! Name shown in the inspector; kept while the panel slides closed.
    property string inspectorName: ""
    property string selectedLabel: ""
    property string selectedValue: "#000000"
    property string selectedBase:  "#000000"

    property string saveName: ""
    //! Function to run once the user agreed to drop unsaved changes.
    property var    pendingAction: null

    readonly property bool compact: width < 1100

    //! Status line of the header.
    readonly property string headerSubtitle: {
        if(!live) {
            return "Using the application theme (" + Style.currentTheme + ")  \u00b7  edit any color to start"
        }
        const name = paletteName.length > 0 ? paletteName : "Untitled palette"
        return name + (dirty ? " \u00b7 unsaved" : "") + "  \u00b7  base " + baseLabel
               + "  \u00b7  " + changedCount + (changedCount === 1 ? " change" : " changes")
    }

    readonly property string baseLabel: {
        for(const t of themes) {
            if(t.key === baseTheme) {
                return t.label
            }
        }
        return baseTheme
    }

    /* Object Properties
     * ****************************************************************************************/
    color: palettoChrome.page

    onPluginManagerChanged: loadSettings()
    onPaletteNameChanged: root.saveName = root.paletteName

    Component.onCompleted: {
        root.refreshLibrary()
        root.passiveRefresh()
        root.loadSettings()
    }

    Component.onDestruction: {
        // Never leave the application pointing at a Colors object that is about to be destroyed.
        Style.setCustomThemes([], true)
        if(Style.colors === workColors) {
            Style.changeTheme()
        }
    }

    /* Functions
     * ****************************************************************************************/
    function onPageActivated() {
    }

    function notify(kind, message) {
        const n = root.notificationController
        if(n && typeof n[kind] === "function") {
            n[kind](message)
        }
    }

    function themeKnown(key) {
        for(const t of themes) {
            if(t.key === key) {
                return true
            }
        }
        return false
    }

    function baseObject(key) {
        switch(key) {
        case "Modern Soft":
            return Style.modernSoftColors
        case "Modern Dark":
            return Style.modernDarkColors
        default:
            return Style.modernLightColors
        }
    }

    function saveSetting(key, value) {
        if(root.pluginManager && root.pluginId) {
            root.pluginManager.setPluginSetting(root.pluginId, key, value)
        }
    }

    function loadSettings() {
        if(root.settingsLoaded || !root.pluginManager) {
            return
        }
        root.settingsLoaded = true

        const draft = root.pluginManager.pluginSetting(root.pluginId, "draft", "")
        root.draftText = typeof draft === "string" ? draft : ""

        root.refreshLibrary()
        if(root.draftText.length > 0) {
            root.restoreDraft()
        }
        graceTimer.start()
    }

    function refreshLibrary() {
        root.library = palettoEngine.palettes()
        root.registerThemes()
    }

    //! The saved palette that is the application's current theme, or null.
    function currentCustom() {
        for(const p of root.library) {
            if(p.name === Style.currentTheme) {
                return p
            }
        }
        return null
    }

    /*!
     * Makes every saved palette selectable in Settings > Appearance. Each one becomes a complete
     * Colors object (base theme plus its changes) registered with Style, which applies it by name
     * and the settings file remembers the name, so the app starts with it every time.
     */
    function registerThemes() {
        const previous = root.themeObjects
        const objects = []
        const entries = []

        for(const p of root.library) {
            const baseKey = root.themeKnown(p.base) ? p.base : "Modern Light"
            const values = palettoEngine.snapshot(root.baseObject(baseKey))
            const obj = themeColorsFactory.createObject(root)
            if(!obj) {
                continue
            }

            for(const key in values) {
                obj[key] = values[key]
            }
            for(const key in p.colors) {
                if(values[key] !== undefined) {
                    obj[key] = p.colors[key]
                }
            }
            objects.push(obj)
            entries.push({
                             name: p.name,
                             colors: obj,
                             dark: baseKey === "Modern Dark"
                         })
        }

        // While the editor's own work colors are installed the theme must not be re-selected,
        // unless the object in use is one of the previous ones.
        let usingPrevious = false
        for(const old of previous) {
            if(Style.colors === old) {
                usingPrevious = true
            }
        }
        root.themeObjects = objects
        Style.setCustomThemes(entries, usingPrevious || Style.colors !== workColors)

        for(const old of previous) {
            old.destroy()
        }
    }

    // -- Tokens -------------------------------------------------------------------------------

    //! Rebuilds the token list from Style.colors and the current base values.
    function rebuild() {
        const list = palettoEngine.tokens(Style.colors)
        const order = palettoEngine.groups()
        const rank = {}
        for(let g = 0; g < order.length; g++) {
            rank[order[g]] = g
        }

        for(let i = 0; i < list.length; i++) {
            list[i].seq = i
        }
        list.sort(function(a, b) {
            const ra = rank[a.group] !== undefined ? rank[a.group] : order.length
            const rb = rank[b.group] !== undefined ? rank[b.group] : order.length
            return ra !== rb ? ra - rb : a.seq - b.seq
        })

        const index = {}
        const present = {}
        let changed = 0
        for(let i = 0; i < list.length; i++) {
            const t = list[i]
            const base = root.baseValues[t.name]
            t.base = base !== undefined ? base : t.value
            t.changed = t.value !== t.base
            if(t.changed) {
                ++changed
            }
            index[t.name] = i
            present[t.group] = true
        }

        const names = []
        for(const g of order) {
            if(present[g]) {
                names.push(g)
            }
        }

        root.allTokens = list
        root.tokenIndex = index
        root.groupNames = names
        root.changedCount = changed

        if(root.groupFilter !== "" && !present[root.groupFilter]) {
            root.groupFilter = ""
        }

        root.refreshShown()
        root.select(root.selectedName)
    }

    function refreshShown() {
        const q = root.search.trim().toLowerCase()

        shownTokens.clear()
        for(let i = 0; i < root.allTokens.length; i++) {
            const t = root.allTokens[i]
            if(root.groupFilter !== "" && t.group !== root.groupFilter) {
                continue
            }
            if(root.changedOnly && !t.changed) {
                continue
            }
            if(q.length > 0 && t.name.toLowerCase().indexOf(q) === -1
                    && t.label.toLowerCase().indexOf(q) === -1
                    && t.value.indexOf(q) === -1) {
                continue
            }

            shownTokens.append({
                                   tokenName: t.name,
                                   label: t.label,
                                   group: t.group,
                                   value: t.value,
                                   changed: t.changed
                               })
        }
    }

    function shownRow(name) {
        for(let i = 0; i < shownTokens.count; i++) {
            if(shownTokens.get(i).tokenName === name) {
                return i
            }
        }
        return -1
    }

    function select(name) {
        const i = root.tokenIndex[name]
        if(name === "" || i === undefined) {
            root.selectedName = ""
            return
        }
        const t = root.allTokens[i]
        root.selectedName = t.name
        root.inspectorName = t.name
        root.selectedLabel = t.label
        root.selectedValue = t.value
        root.selectedBase = t.base
    }

    function currentOverrides() {
        const out = {}
        for(const t of root.allTokens) {
            if(t.changed) {
                out[t.name] = t.value
            }
        }
        return out
    }

    // -- Applying -----------------------------------------------------------------------------

    //! Shows the host's current theme without taking over Style.colors.
    function passiveRefresh() {
        const custom = root.currentCustom()
        if(custom && root.themeKnown(custom.base)) {
            root.baseTheme = custom.base
        } else if(root.themeKnown(Style.currentTheme)) {
            root.baseTheme = Style.currentTheme
        }
        root.baseValues = palettoEngine.snapshot(root.baseObject(root.baseTheme))
        root.rebuild()
    }

    /*!
     * Fills the work colors from \a base, lays \a overrides on top and installs them.
     * Tokens the application does not know (a palette from another version) are ignored.
     */
    function applyState(base, overrides, name, isDirty) {
        root.baseTheme = root.themeKnown(base) ? base : root.baseTheme
        root.baseValues = palettoEngine.snapshot(root.baseObject(root.baseTheme))

        root.applying = true
        for(const key in root.baseValues) {
            workColors[key] = root.baseValues[key]
        }
        for(const key in overrides) {
            if(root.baseValues[key] !== undefined) {
                workColors[key] = overrides[key]
            }
        }
        // Style.Theme is Light = 0, Dark = 1; brightness-dependent code reads it.
        Style.theme = root.baseTheme === "Modern Dark" ? 1 : 0
        Style.colors = workColors
        root.applying = false

        root.live = true
        root.paletteName = name
        root.dirty = isDirty
        root.rebuild()
        root.scheduleDraft()
    }

    function setToken(name, hex) {
        if(root.tokenIndex[name] === undefined) {
            return
        }

        // First edit: take over from the host theme.
        if(!root.live) {
            const custom = root.currentCustom()
            if(custom) {
                root.applyState(custom.base, custom.colors, custom.name, false)
            } else {
                root.applyState(root.baseTheme, ({}), root.paletteName, false)
            }
        }

        const t = root.allTokens[root.tokenIndex[name]]
        if(t.value === hex) {
            return
        }

        workColors[name] = hex

        const wasChanged = t.changed
        t.value = hex
        t.changed = hex !== t.base
        root.changedCount += (t.changed ? 1 : 0) - (wasChanged ? 1 : 0)

        if(root.changedOnly && wasChanged !== t.changed) {
            root.refreshShown()
        } else {
            const row = root.shownRow(name)
            if(row >= 0) {
                shownTokens.setProperty(row, "value", hex)
            }
            if(row >= 0 && wasChanged !== t.changed) {
                shownTokens.setProperty(row, "changed", t.changed)
            }
        }

        if(root.selectedName === name) {
            root.selectedValue = hex
        }

        root.dirty = true
        root.scheduleDraft()
    }

    function revertToken(name) {
        const i = root.tokenIndex[name]
        if(i !== undefined) {
            root.setToken(name, root.allTokens[i].base)
        }
    }

    function setBase(key) {
        if(key === root.baseTheme && root.live) {
            return
        }
        root.applyState(key, root.currentOverrides(), root.paletteName, root.live || root.dirty)
    }

    function revertAll() {
        root.applyState(root.baseTheme, ({}), root.paletteName, root.paletteName.length === 0 ? false : true)
    }

    //! Gives the application back to its own theme.
    function stopLive() {
        root.applying = true
        Style.changeTheme()
        root.applying = false
        root.leaveLive()
    }

    function leaveLive() {
        root.live = false
        root.paletteName = ""
        root.dirty = false
        root.draftText = ""
        root.saveSetting("draft", "")
        root.passiveRefresh()
    }

    //! Runs \a action now, or after the user agreed to drop unsaved changes.
    function guarded(action) {
        if(root.live && root.dirty) {
            root.pendingAction = action
            discardPopup.open()
        } else {
            action()
        }
    }

    // -- Draft --------------------------------------------------------------------------------

    function scheduleDraft() {
        draftTimer.restart()
    }

    function writeDraft() {
        if(!root.live) {
            root.draftText = ""
        } else {
            root.draftText = JSON.stringify({
                name: root.paletteName,
                base: root.baseTheme,
                dirty: root.dirty,
                colors: root.currentOverrides()
            })
        }
        root.saveSetting("draft", root.draftText)
    }

    function restoreDraft() {
        let draft = null
        try {
            draft = JSON.parse(root.draftText)
        } catch (e) {
            return
        }
        if(!draft || typeof draft !== "object") {
            return
        }
        root.applyState(draft.base || root.baseTheme, draft.colors || ({}),
                        draft.name || "", draft.dirty === true)
    }

    // -- Library and files --------------------------------------------------------------------

    function loadPalette(palette) {
        root.guarded(function() {
            root.applyState(palette.base, palette.colors, palette.name, false)
            root.notify("info", "Palette \"" + palette.name + "\" applied")
        })
    }

    function savePalette() {
        const name = root.saveName.trim()
        if(name.length === 0) {
            return
        }

        const result = palettoEngine.savePalette(name, root.baseTheme, root.currentOverrides())
        if(!result.success) {
            root.notify("error", result.errorMessage)
            return
        }
        root.paletteName = name
        root.dirty = false
        root.refreshLibrary()
        root.scheduleDraft()
        root.notify("success", "Palette \"" + name + "\" saved. Choose it in Settings > Appearance to use it everywhere.")
    }

    function deletePalette(name) {
        const result = palettoEngine.deletePalette(name)
        if(!result.success) {
            root.notify("error", result.errorMessage)
            return
        }
        // The deleted palette may be the application's theme: select the default one first.
        if(Style.currentTheme.toLowerCase() === name.toLowerCase()) {
            Style.fallbackToDefaultTheme()
        }
        if(root.paletteName.toLowerCase() === name.toLowerCase()) {
            root.paletteName = ""
            root.dirty = root.live
        }
        root.refreshLibrary()
        root.notify("info", "Palette \"" + name + "\" deleted")
    }

    function exportTo(url) {
        const name = root.paletteName.length > 0 ? root.paletteName
                   : root.saveName.trim().length > 0 ? root.saveName.trim() : "My palette"
        const result = palettoEngine.exportPalette(palettoEngine.localPath(url), name, root.baseTheme,
                                            root.currentOverrides())
        if(result.success) {
            root.notify("success", "Palette exported")
        } else {
            root.notify("error", result.errorMessage)
        }
    }

    function importFrom(url) {
        const result = palettoEngine.importPalette(palettoEngine.localPath(url))
        if(!result.success) {
            root.notify("error", result.errorMessage)
            return
        }

        root.guarded(function() {
            root.applyState(result.base, result.colors, result.name, true)

            let unknown = 0
            for(const key in result.colors) {
                if(root.baseValues[key] === undefined) {
                    ++unknown
                }
            }
            const skipped = result.skipped + unknown
            root.notify("success", "Imported \"" + result.name + "\" - " + root.changedCount
                        + " tokens" + (skipped > 0 ? ", " + skipped + " skipped" : "")
                        + ". Save it to keep it in your library.")
        })
    }

    /* Children
     * ****************************************************************************************/
    //! Colors and fonts of the editor; handed to every component below as `chrome`.
    PalettoChrome {
        id: palettoChrome
    }

    PalettoEngine {
        id: palettoEngine
    }

    //! Screen-wide color picker: a click on any pixel applies that color to the selected token.
    EyeDropper {
        id: eyeDropper

        onPicked: function(hex, red, green, blue) {
            if(root.selectedName.length === 0) {
                return
            }
            root.setToken(root.selectedName, hex)
            root.notify("success", "Picked " + hex.toUpperCase() + "  (" + red + ", " + green + ", " + blue + ")")
        }
    }

    //! The color set Paletto edits and installs as Style.colors.
    Colors {
        id: workColors
    }

    //! The editor has a chrome for each base theme.
    Binding {
        target: palettoChrome
        property: "mode"
        value: root.baseTheme === "Modern Dark" ? "dark"
             : root.baseTheme === "Modern Soft" ? "soft" : "light"
    }

    //! Creates the Colors objects of the saved palettes.
    Component {
        id: themeColorsFactory
        Colors {}
    }

    //! The rows of the token list after search and filters.
    ListModel {
        id: shownTokens
    }

    Timer {
        id: draftTimer
        interval: 500
        onTriggered: root.writeDraft()
    }

    //! The host may select its saved theme a moment after the plugin pages were created.
    Timer {
        id: graceTimer
        interval: 4000
        onTriggered: root.startupGrace = false
    }

    Connections {
        target: Style
        ignoreUnknownSignals: true

        function onColorsChanged() {
            if(root.applying || Style.colors === workColors) {
                return
            }

            if(root.startupGrace && root.draftText.length > 0) {
                Qt.callLater(root.restoreDraft)
                return
            }
            if(root.live) {
                root.leaveLive()
                root.notify("info", "Theme changed - the Paletto palette was switched off")
            } else {
                root.passiveRefresh()
            }
        }
    }

    FileDialog {
        id: exportDialog
        title: "Export palette"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Paletto palette (*.paletto.json)", "JSON (*.json)"]
        defaultSuffix: "json"
        onAccepted: root.exportTo(selectedFile)
    }

    FileDialog {
        id: importDialog
        title: "Import palette"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Paletto palette (*.paletto.json *.json)", "All files (*)"]
        onAccepted: root.importFrom(selectedFile)
    }

    DiscardChangesPopup {
        id: discardPopup

        chrome: palettoChrome

        onDiscardConfirmed: {
            const action = root.pendingAction
            root.pendingAction = null
            if(action) {
                action()
            }
        }
        // Cancelled or dismissed: the action is dropped.
        onClosed: root.pendingAction = null
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PalettoHeader {
            chrome: palettoChrome
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            subtitle: root.headerSubtitle
            themes: root.themes
            baseTheme: root.baseTheme
            paletteActive: root.live

            onBaseSelected: function(key) {
                root.setBase(key)
            }
            onUseAppThemeRequested: root.guarded(root.stopLive)
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            PaletteLibraryPanel {
                chrome: palettoChrome
                Layout.fillHeight: true
                Layout.preferredWidth: root.compact ? 220 : 270
                palettes: root.library
                themes: root.themes
                activePaletteName: root.paletteName
                saveName: root.saveName
                paletteActive: root.live

                onSaveNameEdited: function(name) {
                    root.saveName = name
                }
                onPaletteSelected: function(palette) {
                    root.loadPalette(palette)
                }
                onPaletteDeleteRequested: function(name) {
                    root.deletePalette(name)
                }
                onNewRequested: root.guarded(function() {
                    root.applyState(root.baseTheme, ({}), "", false)
                })
                onSaveRequested: root.savePalette()
                onImportRequested: importDialog.open()
                onExportRequested: {
                    exportDialog.currentFile = palettoEngine.suggestedExportUrl(
                        root.paletteName.length > 0 ? root.paletteName : root.saveName)
                    exportDialog.open()
                }
            }

            TokenBrowser {
                chrome: palettoChrome
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 16
                tokens: shownTokens
                groupNames: root.groupNames
                searchText: root.search
                groupFilter: root.groupFilter
                changedOnly: root.changedOnly
                selectedName: root.selectedName
                canRevertAll: root.live && root.changedCount > 0

                onSearchEdited: function(text) {
                    root.search = text
                    root.refreshShown()
                }
                onGroupSelected: function(group) {
                    root.groupFilter = group
                    root.refreshShown()
                }
                onChangedOnlyToggled: {
                    root.changedOnly = !root.changedOnly
                    root.refreshShown()
                }
                onTokenClicked: function(tokenName) {
                    root.select(tokenName)
                }
                onTokenRevertRequested: function(tokenName) {
                    root.revertToken(tokenName)
                }
                onRevertAllRequested: root.guarded(root.revertAll)
            }

            TokenInspector {
                chrome: palettoChrome
                engine: palettoEngine
                Layout.fillHeight: true
                open: root.selectedName.length > 0
                tokenName: root.inspectorName
                tokenLabel: root.selectedLabel
                value: root.selectedValue
                baseValue: root.selectedBase
                eyeDropperActive: eyeDropper.active

                onValueEdited: function(hex) {
                    root.setToken(root.selectedName, hex)
                }
                onRevertRequested: root.revertToken(root.selectedName)
                onCloseRequested: root.select("")
                onEyeDropperRequested: eyeDropper.start()
            }
        }
    }
}
