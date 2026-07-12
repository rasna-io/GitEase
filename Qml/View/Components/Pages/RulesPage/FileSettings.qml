import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * FileSettings
 * ************************************************************************************************/

RuleSettingsBase {
    id: root

    /* Property Declarations
     * ****************************************************************************************/


    /* Object Properties
     * ****************************************************************************************/
    contentHeight: contentColumn.implicitHeight

    onRuleDataChanged: loadFromModel()

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: contentColumn
        width: root.width
        spacing: 5

        BasicInfoRect {
            id: basicInfo
            ruleColor: root.ruleColor
            onRuleNameChanged: root.markDirty()
            onDescriptionChanged: root.markDirty()
            onSeverityIndexChanged: root.markDirty()
            onIsActiveChanged: root.markDirty()
        }

        RuleChip {
            headerText: "File Restrictions"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Forbidden extensions"
                    subtitle: "Blocks these file types"

                    control: HorizontalTagInput {
                        id: forbiddenExtensionsInput
                        anchors.fill: parent

                        onWordsChanged: root.markDirty()
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Max file size"
                    subtitle: "Megabytes"

                    control: ModernSpinBox {
                        id: maxFileSizeSpin

                        onValueModified: root.markDirty()
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "No trailing whitespace"

                    control: ModernSwitch {
                        id: trailingWhitespaceSwitch
                        height: parent.height

                        onCheckedChanged: root.markDirty()
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Require final newline"

                    control: ModernSwitch {
                        id: requireFinalNewlineSwitch
                        height: parent.height

                        onCheckedChanged: root.markDirty()
                    }
                }
            }
        }

        RuleChip {
            headerText: "Secret Detection"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Secret patterns"
                    subtitle: "Regex per line scanned"
                    rowHeight: secretPatternsInput.height + 10

                    control: VerticalTagInput {
                        id: secretPatternsInput
                        width: parent.width
                        placeHolderText: "(?i)aws_secret_access_key"

                        onWordsChanged: root.markDirty()
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Locked files"
                    subtitle: "Glob — block direct edits"

                    control: HorizontalTagInput {
                        id: lockedFilesInput
                        anchors.fill: parent

                        onWordsChanged: root.markDirty()
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function loadFromModel() {
        suppressDirty = true
        if (!ruleData) { suppressDirty = false; return }

        basicInfo.ruleName = ruleData.ruleName ?? ""
        basicInfo.description = ruleData.description ?? ""
        basicInfo.severityIndex = ruleData.severity ?? 0
        basicInfo.isActive = ruleData.enabled ?? true

        forbiddenExtensionsInput.setWords(ruleData.forbiddenExtensions ? ruleData.forbiddenExtensions.split(",") : [])
        maxFileSizeSpin.value = ruleData.maxFileSizeMb ?? 10
        trailingWhitespaceSwitch.checked = ruleData.noTrailingWhitespace ?? false
        requireFinalNewlineSwitch.checked = ruleData.requireFinalNewline ?? false

        secretPatternsInput.setWords(ruleData.secretPatterns ? ruleData.secretPatterns.split(",") : [])
        lockedFilesInput.setWords(ruleData.lockedFiles ? ruleData.lockedFiles.split(",") : [])

        isDirty = false
        suppressDirty = false
    }

    function saveChanges() {
        if (!targetModel || ruleIndex < 0) return

        targetModel.setProperty(ruleIndex, "ruleName", basicInfo.ruleName)
        targetModel.setProperty(ruleIndex, "description", basicInfo.description)
        targetModel.setProperty(ruleIndex, "severity", basicInfo.severityIndex)
        targetModel.setProperty(ruleIndex, "enabled", basicInfo.isActive)

        targetModel.setProperty(ruleIndex, "forbiddenExtensions", forbiddenExtensionsInput.getWords().join(","))
        targetModel.setProperty(ruleIndex, "maxFileSizeMb", maxFileSizeSpin.value)
        targetModel.setProperty(ruleIndex, "noTrailingWhitespace", trailingWhitespaceSwitch.checked)
        targetModel.setProperty(ruleIndex, "requireFinalNewline", requireFinalNewlineSwitch.checked)

        targetModel.setProperty(ruleIndex, "secretPatterns", secretPatternsInput.getWords().join(","))
        targetModel.setProperty(ruleIndex, "lockedFiles", lockedFilesInput.getWords().join(","))

        isDirty = false
    }
}
