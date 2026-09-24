import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import GitEaseOrganizationRulesPlugin

/*!
 * RulesPage
 * Fetching list of rules from the repo and displaying it
 */

Rectangle {
    id: root

    color: Style.colors.primaryBackground

    /* Property Declarations
     * ****************************************************************************************/
    property int                     selectedCategory: 0
    property int                     selectedRule: -1
    property var                     pendingNavigationAction: null
    property NotificationController  notificationController:  null

    property var categoriesInfo: [
        { name: "COMMIT MESSAGE", color: "#58a6ff", description: "Enforce message format, prefixes & length" },
        { name: "BRANCH NAMING",  color: "#3fb950", description: "Naming patterns, forbidden chars & protection" },
        { name: "FILE & CODE",    color: "#f0883e", description: "Extensions, secrets & file size limits" },
        { name: "PUSH RULES",     color: "#f85149", description: "Force-push, deletion & GPG requirements" },
        { name: "NOTIFICATION",   color: "#770180", description: "Slack, email & audit log routing" },
        { name: "CUSTOM HOOKS",   color: "#bc8cff", description: "Custom pre-commit/push scripts" }
    ]

    property var categoryModels: [commitRules, branchRules, fileRules, pushRules, notificationRules, hookRules]

    ListModel { id: commitRules }
    ListModel { id: branchRules }
    ListModel { id: fileRules }
    ListModel { id: pushRules }
    ListModel { id: notificationRules }
    ListModel { id: hookRules }

    /* Children
     * ****************************************************************************************/
    AddRulePopup {
        id: addRulePopup
        categoriesModel: root.categoriesInfo

        onCategoryClicked: (index) => {
            switch (index) {
                case 0:
                    commitRules.append({ ruleName: "New Commit Message Rule" })
                    root.selectedCategory = 0
                    root.selectedRule = commitRules.count - 1
                    break
                case 1:
                    branchRules.append({ ruleName: "New Branch Naming Rule" })
                    root.selectedCategory = 1
                    root.selectedRule = branchRules.count - 1
                    break
                case 2:
                    fileRules.append({ ruleName: "New File & Code Rule" })
                    root.selectedCategory = 2
                    root.selectedRule = fileRules.count - 1
                    break
                case 3:
                    pushRules.append({ ruleName: "New Push Rules Rule" })
                    root.selectedCategory = 3
                    root.selectedRule = pushRules.count - 1
                    break
                case 4:
                    notificationRules.append({ ruleName: "New Notification Rule" })
                    root.selectedCategory = 4
                    root.selectedRule = notificationRules.count - 1
                    break
                case 5:
                    hookRules.append({ ruleName: "New Custom Hooks Rule" })
                    root.selectedCategory = 5
                    root.selectedRule = hookRules.count - 1
                    break
            }
        }
    }

    RuleImportPopup {
        id: ruleImportPopup
        onConfirmed: (fileUrl) => root.importFile(fileUrl)
    }

    FileDialog {
        id: exportDialog
        title: "Export Rules"
        fileMode: FileDialog.SaveFile
        nameFilters: ["JSON files (*.json)"]
        defaultSuffix: "json"

        onAccepted: {
            var jsonText = JSON.stringify(root.buildRulesJson(), null, 2)
            var res = RuleController.exportRules(selectedFile, jsonText)
            if (res.success) {
                root.notificationController.success("Rules exported successfully", "Export", 3000)
            } else {
                root.notificationController.error(res.errorMessage || "Failed to export rules", "Export Error", 5000)
            }
        }
    }

    FileDialog {
        id: importDialog
        title: "Import Rules"
        fileMode: FileDialog.OpenFile
        nameFilters: ["JSON files (*.json)"]

        onAccepted: {
            if (root.hasAnyRules()) {
                ruleImportPopup.pendingFile = selectedFile
                ruleImportPopup.open()
            } else {
                root.importFile(selectedFile)
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Left side column displaying various rule categories and their rules
        RulesTreeView {
            Layout.preferredWidth: 300
            Layout.fillHeight: true

            categoriesInfo: root.categoriesInfo
            categoryModels: root.categoryModels
            selectedCategory: root.selectedCategory
            selectedRule: root.selectedRule
            exportEnabled: root.hasAnyRules()

            onAddRuleRequested: addRulePopup.open()
            onImportRequested: importDialog.open()
            onExportRequested: exportDialog.open()
            onRuleSelected: (catIdx, ruleIdx) => {
                root.guardNavigation(function() {
                    root.selectedCategory = catIdx
                    root.selectedRule = ruleIdx
                })
            }
        }

        // Right side column displaying selected rule settings
        RuleSettingsPanel {
            id: settingsPanel

            Layout.fillWidth: true
            Layout.fillHeight: true

            categoriesInfo: root.categoriesInfo
            categoryModels: root.categoryModels
            selectedCategory: root.selectedCategory
            selectedRule: root.selectedRule

            onDeleteRequested: {
                root.selectedRule = -1
                if(root.saveRulesToDisk()) {
                    root.notificationController.success("Rule deleted successfully", "Delete", 3000)
                } else {
                    root.notificationController.error(res.errorMessage || "Failed to delete rule", "Delete Error", 5000)
                }
            }
            onSavedChanges: {
                if(root.saveRulesToDisk()) {
                    root.notificationController.success("Rule saved successfully", "Save", 3000)
                } else {
                    root.notificationController.error(res.errorMessage || "Failed to save rule", "Save Error", 5000)
                }
            }
        }
    }

    Connections {
        target: RuleController
        function onCurrentRepoChanged() { root.loadRulesFromDisk() }
    }

    Component {
        id: unsavedChangesComp
        UnsavedChangesDialog {
            title: "Unsaved Changes"
            message: "This rule has unsaved modifications.\nDo you want to save your changes before switching?"
            saveTitle: "Save Changes"
            saveDescription: "Save this rule and continue"
            acceptTitle: "Discard Changes"
            acceptDescription: "Discard edits and continue without saving"
        }
    }

    /* Functions
     * ****************************************************************************************/
    function modelToArray(listModel) {
        var arr = []
        for (var i = 0; i < listModel.count; i++) {
            var row = listModel.get(i)
            var plain = {}
            for (var key in row) plain[key] = row[key]
            arr.push(plain)
        }
        return arr
    }

    function buildRulesJson() {
        return {
            rules: {
                commitMessage: modelToArray(commitRules),
                branchNaming:  modelToArray(branchRules),
                fileCode:      modelToArray(fileRules),
                pushRules:     modelToArray(pushRules),
                notification:  modelToArray(notificationRules),
                customHooks:   modelToArray(hookRules)
            }
        }
    }

    function saveRulesToDisk() {
        var data = buildRulesJson()
        var res = RuleController.saveRules(JSON.stringify(data, null, 2))
        return res.success
    }

    function loadArrayInto(listModel, arr) {
        listModel.clear()
        if (!arr) return
        for (var i = 0; i < arr.length; i++)
            listModel.append(arr[i])
    }

    function loadRulesFromDisk() {
        var res = RuleController.loadRules()
        if (!res.success) {
            return
        }
        var raw = res.data
        if (raw && raw.length > 0) {
            var data = JSON.parse(raw)
            // Fill the listModels from data read from json file
            loadArrayInto(commitRules, data.rules.commitMessage)
            loadArrayInto(branchRules, data.rules.branchNaming)
            loadArrayInto(fileRules, data.rules.fileCode)
            loadArrayInto(pushRules, data.rules.pushRules)
            loadArrayInto(notificationRules, data.rules.notification)
            loadArrayInto(hookRules, data.rules.customHooks)
        } else {
            // Clear rules if the json file does not exist or it is empty
            commitRules.clear()
            branchRules.clear()
            fileRules.clear()
            pushRules.clear()
            notificationRules.clear()
            hookRules.clear()
        }
    }

    function importFile(fileUrl) {
        var res = RuleController.importRules(fileUrl)
        if (!res.success) {
            root.notificationController.error(res.errorMessage, "Import Error", 5000)
            return
        }
        var data = JSON.parse(res.data)
        loadArrayInto(commitRules, data.rules.commitMessage)
        loadArrayInto(branchRules, data.rules.branchNaming)
        loadArrayInto(fileRules, data.rules.fileCode)
        loadArrayInto(pushRules, data.rules.pushRules)
        loadArrayInto(notificationRules, data.rules.notification)
        loadArrayInto(hookRules, data.rules.customHooks)
        root.saveRulesToDisk()
    }

    function hasAnyRules() {
        return commitRules.count > 0 || branchRules.count > 0 || fileRules.count > 0 ||
               pushRules.count > 0 || notificationRules.count > 0 || hookRules.count > 0
    }

    // Check for unsaved changes and show the dialog
    function guardNavigation(action) {
        if (settingsPanel.currentIsDirty()) {
            root.pendingNavigationAction = action
            var dialog = unsavedChangesComp.createObject(root)

            dialog.saved.connect(function() {
                var item = settingsPanel.settingsLoaderItem()
                if (item) item.saveChanges()
                root.saveRulesToDisk()
                if (root.pendingNavigationAction) root.pendingNavigationAction()
                root.pendingNavigationAction = null
            })
            dialog.aborted.connect(function() {
                if (root.pendingNavigationAction) root.pendingNavigationAction()
                root.pendingNavigationAction = null
            })
            dialog.cancelled.connect(function() {
                root.pendingNavigationAction = null
            })

            dialog.open()
        } else {
            action()
        }
    }

    Component.onCompleted: {
        Qt.callLater(loadRulesFromDisk)
    }
}