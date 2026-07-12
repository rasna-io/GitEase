import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style
import GitEase_Style_Impl
import GitEase

Item {
    id: root
    anchors.fill: parent

    /* Property Declarations
     * ****************************************************************************************/
    property int selectedCategory: 0
    property int selectedRule: -1
    property RuleController ruleController: null

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
            if (!root.ruleController) return
            var jsonText = JSON.stringify(root.buildRulesJson(), null, 2)
            var result = root.ruleController.exportRules(selectedFile, jsonText)
            if (!result.success) console.warn("Export failed:", result.errorMessage)
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
            onCategorySelected: (idx) => { root.selectedCategory = idx }
            onRuleSelected: (catIdx, ruleIdx) => {
                root.selectedCategory = catIdx
                root.selectedRule = ruleIdx
            }
        }

        RuleSettingsPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            categoriesInfo: root.categoriesInfo
            categoryModels: root.categoryModels
            selectedCategory: root.selectedCategory
            selectedRule: root.selectedRule

            onDeleteRequested: {
                root.selectedRule = -1
                root.saveRulesToDisk()
            }
            onSavedChanges: root.saveRulesToDisk()
        }
    }

    Connections {
        target: ruleController
        function onCurrentRepoChanged() { root.loadRulesFromDisk() }
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
        if (!root.ruleController) return
        var data = buildRulesJson()
        var result = root.ruleController.saveRules(JSON.stringify(data, null, 2))
        if (!result.success) console.warn("Failed to save rules:", result.errorMessage)
    }

    function loadArrayInto(listModel, arr) {
        listModel.clear()
        if (!arr) return
        for (var i = 0; i < arr.length; i++)
            listModel.append(arr[i])
    }

    function loadRulesFromDisk() {
        if (!root.ruleController) return
        var result = root.ruleController.loadRules()
        if (!result.success) {
            console.warn("Failed to load rules:", result.errorMessage)
            return
        }
        var raw = result.data
        if (raw && raw.length > 0) {
            try {
                var data = JSON.parse(raw)
                loadArrayInto(commitRules, data.rules.commitMessage)
                loadArrayInto(branchRules, data.rules.branchNaming)
                loadArrayInto(fileRules, data.rules.fileCode)
                loadArrayInto(pushRules, data.rules.pushRules)
                loadArrayInto(notificationRules, data.rules.notification)
                loadArrayInto(hookRules, data.rules.customHooks)
            } catch (e) {
                console.error("Failed to parse rules file:", e)
            }
        } else {
            commitRules.clear()
            branchRules.clear()
            fileRules.clear()
            pushRules.clear()
            notificationRules.clear()
            hookRules.clear()
        }
    }

    function importFile(fileUrl) {
        if (!root.ruleController) return
        var result = root.ruleController.importRules(fileUrl)
        if (!result.success) {
            console.warn("Import failed:", result.errorMessage)
            return
        }
        try {
            var data = JSON.parse(result.data)
            loadArrayInto(commitRules, data.rules.commitMessage)
            loadArrayInto(branchRules, data.rules.branchNaming)
            loadArrayInto(fileRules, data.rules.fileCode)
            loadArrayInto(pushRules, data.rules.pushRules)
            loadArrayInto(notificationRules, data.rules.notification)
            loadArrayInto(hookRules, data.rules.customHooks)
            root.saveRulesToDisk()
        } catch (e) {
            console.error("Imported file is not valid rules JSON:", e)
        }
    }

    function hasAnyRules() {
        return commitRules.count > 0 || branchRules.count > 0 || fileRules.count > 0 ||
               pushRules.count > 0 || notificationRules.count > 0 || hookRules.count > 0
    }

    Component.onCompleted: {
        Qt.callLater(loadRulesFromDisk)
    }
}