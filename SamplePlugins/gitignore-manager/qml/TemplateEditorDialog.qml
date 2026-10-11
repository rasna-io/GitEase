import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl
import GitEaseGitignore

/*! ***********************************************************************************************
 * TemplateEditorDialog
 * Creates a template of your own, edits one, or customizes a bundled one (the original can be
 * restored). Open it with edit(id); an empty id starts a new template.
 * ************************************************************************************************/
GitignoreDialog {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property GitignoreEngine        engine:                 null
    property var                    analysis:               null
    property NotificationController notificationController: null
    property var                    templates:              []

    //! Id of the template in the editor; empty for a new one.
    property string editingId:      ""
    //! The template ships with the plugin; saving keeps a customized copy.
    property bool   editingBundled: false
    property string errorText:      ""

    readonly property bool hasGitignore: analysis !== null && analysis.success === true
                                         && analysis.hasGitignore === true

    /* Signals
     * ****************************************************************************************/
    //! A template was written; the catalog must be reloaded.
    signal saved()

    /* Functions
     * ****************************************************************************************/
    function edit(id) {
        const info = templates.find(t => t.id === id)
        editingId = id
        editingBundled = id.length > 0 && info !== undefined && !info.custom
        errorText = ""
        nameField.text = id.length === 0 ? "" : editingBundled ? info.name : id.substring(5)
        editor.text = id.length > 0 ? engine.templateContent(id) : ""
        open()
    }

    function save() {
        if (editor.text.trim().length === 0) {
            errorText = "Add at least one rule."
            return
        }

        if (editingBundled) {
            const customized = engine.saveTemplateOverride(editingId, editor.text)
            if (!customized.success) {
                errorText = customized.errorMessage
                return
            }
            finish("Template \"" + nameField.text + "\" customized")
            return
        }

        const name = nameField.text.trim()
        if (!/^[A-Za-z0-9][A-Za-z0-9 _.+()-]{0,59}$/.test(name)) {
            errorText = "Use letters, digits, spaces and _ . + ( ) - for the name (up to 60 characters)."
            return
        }

        const result = engine.saveUserTemplate(name, editor.text)
        if (!result.success) {
            errorText = result.errorMessage
            return
        }
        // A renamed template replaces the old file.
        if (editingId.length > 0 && editingId !== result.id)
            engine.deleteUserTemplate(editingId)
        finish("Template \"" + name + "\" saved")
    }

    function finish(message) {
        close()
        notificationController?.success(message, "Gitignore", 3000)
        saved()
    }

    /* Object Properties
     * ****************************************************************************************/
    maxWidth: Style.dp(560)
    maxHeight: Style.dp(500)
    closePolicy: Popup.CloseOnEscape
    onOpened: nameField.forceActiveFocus()

    /* Children
     * ****************************************************************************************/
    Text {
        Layout.fillWidth: true
        text: root.editingBundled ? "Customize template"
            : root.editingId.length > 0 ? "Edit template" : "New template"
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.largePt
        font.weight: Font.DemiBold
        color: Style.colors.pluginCardTitle
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: root.editingBundled
              ? "Your changes are kept on this computer and replace the original everywhere. You can restore the original at any time."
              : "Custom templates are stored on this computer and listed under \"My templates\" in every repository."
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.captionPt
        color: Style.colors.pluginCardDescription
    }

    TextField {
        id: nameField
        Layout.fillWidth: true
        minHeight: Style.dp(34)
        baseFontSize: Style.appFont.captionPt
        placeholderText: "Template name"
        enabled: !root.editingBundled
        backgroundColor: Style.colors.controlBackground
        borderColor: Style.colors.controlBorder
        onTextEdited: root.errorText = ""
    }

    GitignoreCodeEditor {
        id: editor
        Layout.fillWidth: true
        Layout.fillHeight: true
        placeholder: "One pattern per line, e.g.\n*.log\n/build/\n# comments are allowed"
        onEdited: root.errorText = ""
    }

    Text {
        Layout.fillWidth: true
        visible: root.errorText.length > 0
        wrapMode: Text.WordWrap
        text: root.errorText
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.captionPt
        color: Style.colors.error
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.dp(8)

        GitignoreButton {
            visible: root.editingBundled
            variant: "ghost"
            text: "Restore original"
            tooltip: "Put the text the template ships with back into the editor"
            onClicked: editor.text = root.engine.defaultTemplateContent(root.editingId)
        }

        GitignoreButton {
            visible: !root.editingBundled
            variant: "ghost"
            enabled: root.hasGitignore
            text: "Use current .gitignore"
            tooltip: "Fill the editor with the rules of this repository's .gitignore"
            onClicked: editor.text = root.analysis.gitignoreContent
        }

        Item { Layout.fillWidth: true }

        GitignoreButton {
            text: "Cancel"
            onClicked: root.close()
        }

        GitignoreButton {
            variant: "primary"
            text: root.editingBundled ? "Save changes" : "Save template"
            onClicked: root.save()
        }
    }
}
