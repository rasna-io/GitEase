import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl
import GitEaseGitignore

/*! ***********************************************************************************************
 * GitignoreView
 * Shows the .gitignore of the repository root, line by line, and edits it: remove a rule, add a
 * pattern, or edit the whole file as text. When the file does not exist it offers to create it.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property GitignoreEngine        engine:                 null
    property var                    analysis:               null
    property NotificationController notificationController: null
    //! Template catalog, used to name the applied sections.
    property var                    templates:              []

    property bool   editing:  false
    property string editBase: ""

    readonly property bool   ready:   analysis !== null && analysis.success === true
    readonly property bool   exists:  ready && analysis.hasGitignore === true
    readonly property string content: ready ? analysis.gitignoreContent : ""
    readonly property bool   dirty:   editing && editor.text !== content
    readonly property bool   externalChange: editing && content !== editBase

    readonly property var lines: {
        if (!exists || content.length === 0)
            return []
        return content.split("\n").map((text, i) => ({ number: i + 1, text: text, kind: kindOf(text) }))
    }

    readonly property int ruleCount: lines.filter(l => l.kind === "pattern" || l.kind === "negation").length

    readonly property var appliedNames: {
        const ids = ready ? analysis.appliedTemplates || [] : []
        return ids.map(id => {
            const info = templates.find(candidate => candidate.id === id)
            return info ? info.name : id
        })
    }

    /* Signals
     * ****************************************************************************************/
    //! .gitignore was written; the page rescans.
    signal changed()
    signal openTemplates()

    /* Functions
     * ****************************************************************************************/
    function kindOf(text) {
        const s = text.trim()
        if (s.length === 0)
            return "blank"
        if (/^# >>> .+ \(template\)$/.test(s) || /^# <<< .+$/.test(s))
            return "marker"
        if (s.startsWith("#"))
            return "comment"
        if (s.startsWith("!"))
            return "negation"
        return "pattern"
    }

    function fail(title, message) {
        root.notificationController?.error(message, title, 7000)
    }

    function startEditing() {
        editBase = content
        editor.text = content
        editing = true
        editor.focusEditor()
    }

    function save() {
        const result = engine.saveGitignore(editor.text)
        if (!result.success) {
            fail("Could not save .gitignore", result.errorMessage)
            return
        }
        editing = false
        root.notificationController?.success(".gitignore saved", "Gitignore", 2500)
        root.changed()
    }

    function create() {
        const result = engine.createGitignore([])
        if (!result.success) {
            fail("Could not create .gitignore", result.errorMessage)
            return
        }
        root.notificationController?.success(".gitignore created", "Gitignore", 2500)
        root.changed()
    }

    function removeLine(line) {
        const result = engine.removeRules([{ line: line.number, pattern: line.text }])
        if (!result.success)
            fail("Could not remove the rule", result.errorMessage)
        root.changed()
    }

    function addPattern(pattern) {
        const result = engine.addPatterns([pattern])
        if (!result.success) {
            fail("Could not update .gitignore", result.errorMessage)
            return
        }
        if (result.added === 0)
            fail("Gitignore", "\"" + pattern + "\" is already in .gitignore")
        patternInput.clear()
        root.changed()
    }

    function copyContent() {
        clipboardHelper.text = root.content
        clipboardHelper.selectAll()
        clipboardHelper.copy()
        clipboardHelper.deselect()
        root.notificationController?.success(".gitignore copied to the clipboard", "Gitignore", 2000)
    }

    /* Children
     * ****************************************************************************************/
    TextEdit {
        id: clipboardHelper
        visible: false
    }

    GitignoreCard {
        anchors.fill: parent

        GitignoreEmptyState {
            anchors.centerIn: parent
            width: Math.min(parent.width - Style.dp(32), Style.dp(420))
            visible: !root.exists
            busy: root.analysis === null
            iconText: !root.analysis ? Style.icons.folder : !root.ready ? Style.icons.warning : Style.icons.file
            iconColor: root.analysis && !root.ready ? Style.colors.warning : Style.colors.accent
            title: !root.analysis ? "Reading..."
                 : !root.ready ? "Can't read the repository"
                 : "This repository has no .gitignore"
            message: !root.analysis ? ""
                   : !root.ready ? root.analysis.errorMessage
                   : "Create one to keep build output, dependencies and editor files out of your commits. You can start from a template."
            actionText: root.ready ? "Create .gitignore" : ""
            actionIcon: Style.icons.plus
            secondaryText: root.ready ? "Use a template" : ""
            secondaryIcon: Style.icons.list
            onActionClicked: root.create()
            onSecondaryClicked: root.openTemplates()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.dp(14)
            spacing: Style.dp(10)
            visible: root.exists

            GitignoreFileToolbar {
                Layout.fillWidth: true
                ruleCount: root.ruleCount
                lineCount: root.lines.length
                eol: root.analysis ? root.analysis.eol : ""
                editing: root.editing
                dirty: root.dirty
                canCopy: root.content.length > 0

                onCopyRequested: root.copyContent()
                onEditRequested: root.startEditing()
                onDiscardRequested: root.editing = false
                onSaveRequested: root.save()
            }

            Text {
                Layout.fillWidth: true
                visible: root.appliedNames.length > 0 && !root.editing
                wrapMode: Text.WordWrap
                text: "Templates applied: " + root.appliedNames.join(", ")
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.captionPt
                color: Style.colors.accent
            }

            // The file changed while it was being edited
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: changedText.implicitHeight + Style.dp(16)
                visible: root.externalChange
                radius: Style.dp(8)
                color: Style.colors.repoItemStatusDirtyBg

                Text {
                    id: changedText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Style.dp(12)
                    anchors.rightMargin: Style.dp(12)
                    wrapMode: Text.WordWrap
                    text: "The file changed on disk while you were editing. Saving will overwrite those changes."
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                    color: Style.colors.repoItemStatusDirtyText
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Style.colors.pluginDivider
            }

            // Reading view
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.editing

                ListView {
                    anchors.fill: parent
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.lines

                    ScrollBar.vertical: ScrollBar {}

                    delegate: GitignoreLineRow {
                        required property var modelData

                        width: ListView.view.width - Style.dp(12)
                        line: modelData
                        onRemoveRequested: root.removeLine(modelData)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.lines.length === 0
                    text: "The file is empty. Add a pattern below or pick a template."
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                    color: Style.colors.mutedText
                }
            }

            GitignoreCodeEditor {
                id: editor
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.editing
            }

            PatternInput {
                id: patternInput
                Layout.fillWidth: true
                visible: !root.editing
                onSubmitted: function(pattern) { root.addPattern(pattern) }
            }
        }
    }
}
