import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl
import GitEaseGitignore

/*! ***********************************************************************************************
 * TemplatesView
 * Ready-made .gitignore templates, grouped like GitHub's, plus your own. Tick the ones you need
 * and add them in one go; a template that is already applied is marked, and patterns already in
 * the file are not repeated. Click a row to preview the template.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property GitignoreEngine        engine:                 null
    property var                    analysis:               null
    property NotificationController notificationController: null
    property var                    templates:              []

    property string search:       ""
    property var    checked:      ({})
    property int    checkedCount: 0
    property string previewId:    ""
    //! Category name -> true when the user opened it; categories are closed until then.
    property var    opened:       ({})

    readonly property bool ready:   analysis !== null && analysis.success === true
    readonly property bool exists:  ready && analysis.hasGitignore === true
    readonly property var  applied: ready ? analysis.appliedTemplates || [] : []

    readonly property var visibleTemplates: {
        const needle = search.trim().toLowerCase()
        if (needle.length === 0)
            return templates
        return templates.filter(t => t.name.toLowerCase().indexOf(needle) !== -1
                                  || t.category.toLowerCase().indexOf(needle) !== -1
                                  || t.description.toLowerCase().indexOf(needle) !== -1)
    }

    //! Open every category while searching, otherwise matches would be hidden.
    readonly property bool searching: search.trim().length > 0

    //! Flat rows of the tree: a category row, then its templates when it is open.
    readonly property var rows: {
        const order = []
        const groups = {}
        for (const t of visibleTemplates) {
            if (!groups[t.category]) {
                groups[t.category] = []
                order.push(t.category)
            }
            groups[t.category].push(t)
        }

        const out = []
        for (const category of order) {
            const items = groups[category]
            const open = searching || opened[category] === true
            out.push({ kind: "category", name: category, total: items.length, open: open,
                       checkedCount: items.filter(t => checked[t.id] === true).length })
            if (open) {
                for (const t of items)
                    out.push({ kind: "template", info: t })
            }
        }
        return out
    }

    readonly property string previewText: previewId.length > 0 && engine ? engine.templateContent(previewId) : ""
    readonly property var    previewInfo: templates.find(t => t.id === previewId) || null

    /* Signals
     * ****************************************************************************************/
    //! .gitignore was written; the page rescans.
    signal changed()
    //! A custom template was created, changed or deleted; the page reloads the catalog.
    signal templatesModified()

    /* Functions
     * ****************************************************************************************/
    function setChecked(next) {
        checked = next
        checkedCount = Object.keys(next).length
    }

    function toggle(id) {
        const next = Object.assign({}, checked)
        if (next[id])
            delete next[id]
        else
            next[id] = true
        setChecked(next)
    }

    //! Opens every category (\a open true) or closes them all so only the headings show.
    function setAllOpen(open) {
        const next = {}
        for (const t of templates)
            next[t.category] = open
        opened = next
    }

    //! Categories of the visible list that are open / closed right now.
    function categoryCounts() {
        const names = []
        for (const t of visibleTemplates) {
            if (names.indexOf(t.category) === -1)
                names.push(t.category)
        }
        let open = 0
        for (const name of names) {
            if (searching || opened[name] === true)
                open++
        }
        // While searching every category is held open, so there is nothing to change.
        return searching ? { open: 0, closed: 0 } : { open: open, closed: names.length - open }
    }

    function toggleCategoryOpen(name) {
        const next = Object.assign({}, opened)
        next[name] = next[name] !== true
        opened = next
    }

    //! Ticks every template of the category, or clears them when they are all ticked.
    function toggleCategory(name) {
        const items = visibleTemplates.filter(t => t.category === name)
        const allChecked = items.length > 0 && items.every(t => checked[t.id] === true)
        const next = Object.assign({}, checked)
        for (const t of items) {
            if (allChecked)
                delete next[t.id]
            else
                next[t.id] = true
        }
        setChecked(next)
    }

    function fail(title, message) {
        root.notificationController?.error(message, title, 5000)
    }

    function resetBundled(id) {
        const result = engine.resetTemplateOverride(id)
        if (!result.success) {
            fail("Could not reset the template", result.errorMessage)
            return
        }
        root.notificationController?.success("Original template restored", "Gitignore", 2500)
        root.templatesModified()
    }

    function deleteCustom(id) {
        const result = engine.deleteUserTemplate(id)
        if (!result.success) {
            fail("Could not delete the template", result.errorMessage)
            return
        }
        if (previewId === id)
            previewId = ""
        if (checked[id]) {
            const next = Object.assign({}, checked)
            delete next[id]
            setChecked(next)
        }
        root.templatesModified()
    }

    //! Writes the templates \a ids into .gitignore, creating the file when it is missing.
    function applyIds(ids, clearTicks) {
        if (ids.length === 0)
            return

        const wasMissing = !exists
        const result = wasMissing ? engine.createGitignore(ids) : engine.applyTemplates(ids)
        if (!result.success) {
            root.notificationController?.error(result.errorMessage, "Could not update .gitignore", 7000)
            return
        }

        let message
        if (result.applied.length === 0)
            message = "Nothing to add: everything from the selection is already in .gitignore"
        else
            message = (wasMissing ? "Created .gitignore with " : "Added ") + result.applied.join(", ")
                      + " (" + result.added + (result.added === 1 ? " rule)" : " rules)")
        root.notificationController?.success(message, "Gitignore", 4000)

        if (clearTicks)
            setChecked({})
        root.changed()
    }

    //! Adds every ticked template, in catalog order (which is also the order of the sections).
    function apply() {
        applyIds(templates.filter(t => checked[t.id]).map(t => t.id), true)
    }

    function copyText(text, what) {
        clipboardHelper.text = text
        clipboardHelper.selectAll()
        clipboardHelper.copy()
        clipboardHelper.deselect()
        root.notificationController?.success(what + " copied to the clipboard", "Gitignore", 2000)
    }

    //! The entries a right-click on \a row offers.
    function menuEntriesFor(row) {
        const entries = []
        const danger = Style.colors.contextMenuDanger

        if (row.kind === "category") {
            const allTicked = row.total > 0 && row.checkedCount === row.total
            entries.push({ text: allTicked ? "Untick all templates" : "Tick all templates",
                           icon: Style.icons.check,
                           action: function() { root.toggleCategory(row.name) } })
            entries.push({ text: row.open ? "Collapse this category" : "Expand this category",
                           icon: row.open ? Style.icons.caretUp : Style.icons.caretDown,
                           enabled: !searching,
                           action: function() { root.toggleCategoryOpen(row.name) } })
            return entries
        }

        const info = row.info
        const ticked = checked[info.id] === true

        entries.push({ text: "Preview", icon: Style.icons.search,
                       action: function() { root.previewId = info.id } })
        entries.push({ text: ticked ? "Untick" : "Tick", icon: Style.icons.check,
                       action: function() { root.toggle(info.id) } })
        entries.push({ text: exists ? "Add to .gitignore now" : "Create .gitignore with this",
                       icon: Style.icons.plus, enabled: ready,
                       action: function() { root.applyIds([info.id], false) } })
        entries.push({ separator: true })
        entries.push({ text: info.custom ? "Edit template" : "Customize template", icon: Style.icons.edit,
                       action: function() { editorDialog.edit(info.id) } })
        if (!info.custom && info.customized)
            entries.push({ text: "Restore original", icon: Style.icons.undo,
                           action: function() { root.resetBundled(info.id) } })
        if (info.custom)
            entries.push({ text: "Delete template", icon: Style.icons.trash, color: danger,
                           action: function() { root.deleteCustom(info.id) } })
        entries.push({ separator: true })
        entries.push({ text: "Copy rules", icon: Style.icons.copy,
                       action: function() { root.copyText(engine.templateContent(info.id), "Rules") } })
        return entries
    }

    //! Right-click: the clicked row decides the entries, the tree state decides expand / collapse.
    function openContextMenu(scenePosition) {
        const local = templateList.mapFromItem(null, scenePosition.x, scenePosition.y)
        const index = templateList.indexAt(local.x + templateList.contentX, local.y + templateList.contentY)
        const counts = categoryCounts()
        treeMenu.openFor(scenePosition, index >= 0 ? menuEntriesFor(rows[index]) : [],
                         counts.closed > 0, counts.open > 0)
    }

    /* Children
     * ****************************************************************************************/
    GitignoreCard {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.dp(14)
            spacing: Style.dp(10)

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                GitignoreLabel {
                    Layout.fillWidth: true
                    text: "TEMPLATES"
                }

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.exists ? "Add ready-made rules to your .gitignore"
                                      : "Start your new .gitignore from ready-made rules"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.microPt
                    color: Style.colors.pluginCardMetaText
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.dp(8)

                GitignoreSearchField {
                    Layout.fillWidth: true
                    placeholderText: "Search templates"
                    text: root.search
                    onTextEdited: root.search = text
                }

                GitignoreButton {
                    iconText: Style.icons.plus
                    text: "New template"
                    tooltip: "Write your own template and keep it in this list"
                    onClicked: editorDialog.edit("")
                }
            }

            ListView {
                id: templateList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 1
                boundsBehavior: Flickable.StopAtBounds
                model: root.rows

                // Right-click: actions for the row under the pointer, plus expand / collapse all.
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: function(eventPoint) { root.openContextMenu(eventPoint.scenePosition) }
                }

                ScrollBar.vertical: ScrollBar {}

                delegate: Item {
                    id: treeItem

                    required property var modelData
                    readonly property bool isCategory: modelData.kind === "category"

                    width: ListView.view.width - Style.dp(12)
                    height: isCategory ? categoryRow.height : templateRow.height

                    TemplateCategoryRow {
                        id: categoryRow
                        width: parent.width
                        visible: treeItem.isCategory
                        name: treeItem.isCategory ? treeItem.modelData.name : ""
                        total: treeItem.isCategory ? treeItem.modelData.total : 0
                        checkedCount: treeItem.isCategory ? treeItem.modelData.checkedCount : 0
                        open: treeItem.isCategory ? treeItem.modelData.open : false

                        onExpandToggled: root.toggleCategoryOpen(treeItem.modelData.name)
                        onToggled: root.toggleCategory(treeItem.modelData.name)
                    }

                    TemplateRow {
                        id: templateRow
                        width: parent.width
                        visible: !treeItem.isCategory
                        indent: Style.dp(18)
                        info: treeItem.isCategory ? null : treeItem.modelData.info
                        checked: !treeItem.isCategory && root.checked[treeItem.modelData.info.id] === true
                        applied: !treeItem.isCategory && root.applied.indexOf(treeItem.modelData.info.id) !== -1
                        previewed: !treeItem.isCategory && root.previewId === treeItem.modelData.info.id

                        onToggled: root.toggle(treeItem.modelData.info.id)
                        onPreviewRequested: root.previewId = treeItem.modelData.info.id
                        onEditRequested: editorDialog.edit(treeItem.modelData.info.id)
                        onResetRequested: root.resetBundled(treeItem.modelData.info.id)
                        onDeleteRequested: root.deleteCustom(treeItem.modelData.info.id)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.visibleTemplates.length === 0
                    text: root.templates.length === 0 ? "No templates are bundled with this plugin"
                                                      : "No template matches \"" + root.search + "\""
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                    color: Style.colors.mutedText
                }
            }

            TemplatePreview {
                shown: root.previewId.length > 0
                title: root.previewInfo ? root.previewInfo.name : ""
                body: root.previewText
                onCloseRequested: root.previewId = ""
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.dp(10)

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.checkedCount === 0 ? "Tick one or more templates"
                                                  : root.checkedCount + (root.checkedCount === 1 ? " template" : " templates") + " selected"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                    color: root.checkedCount === 0 ? Style.colors.mutedText : Style.colors.foreground
                }

                GitignoreButton {
                    visible: root.checkedCount > 0
                    variant: "ghost"
                    text: "Clear"
                    onClicked: root.setChecked({})
                }

                GitignoreButton {
                    variant: "primary"
                    enabled: root.ready && root.checkedCount > 0
                    iconText: root.exists ? Style.icons.plus : Style.icons.file
                    text: root.exists ? "Add to .gitignore" : "Create .gitignore"
                    onClicked: root.apply()
                }
            }
        }
    }

    TextEdit {
        id: clipboardHelper
        visible: false
    }

    TreeContextMenu {
        id: treeMenu

        expandText: "Expand all categories"
        collapseText: "Collapse all categories"

        onExpandAllRequested: root.setAllOpen(true)
        onCollapseAllRequested: root.setAllOpen(false)
    }

    TemplateEditorDialog {
        id: editorDialog

        engine: root.engine
        analysis: root.analysis
        notificationController: root.notificationController
        templates: root.templates

        onSaved: root.templatesModified()
    }
}
