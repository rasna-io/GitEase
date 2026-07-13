import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PushRulesSettings
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
            headerText: "Branch Protection"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Block force-push on"
                    subtitle: "Glob patterns"

                    control: HorizontalTagInput {
                        id: blockForcePushInput
                        anchors.fill: parent

                        onWordsChanged: root.markDirty()
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Block branch deletion"
                    subtitle: "Glob patterns"

                    control: HorizontalTagInput {
                        id: blockBranchDeletionInput
                        anchors.fill: parent

                        onWordsChanged: root.markDirty()
                    }
                }
            }
        }

        RuleChip {
            headerText: "Push Validation"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Require GPG signature"

                    control: ModernSwitch {
                        id: requireGPGSignatureSwitch
                        height: parent.height

                        onCheckedChanged: root.markDirty()
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Block conflict markers"

                    control: ModernSwitch {
                        id: blockConflictMarkersSwitch
                        height: parent.height

                        onCheckedChanged: root.markDirty()
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Block WIP commits"

                    control: ModernSwitch {
                        id: blockWIPCommitsSwitch
                        height: parent.height

                        onCheckedChanged: root.markDirty()
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Max commits per push"
                    subtitle: "0 = unlimited"
                    control: ModernSpinBox {
                        id: maxCommitsSpin

                        onValueChanged: root.markDirty()
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

        blockForcePushInput.setWords(ruleData.blockForcePushPatterns ? ruleData.blockForcePushPatterns.split(",") : [])
        blockBranchDeletionInput.setWords(ruleData.blockDeletionPatterns ? ruleData.blockDeletionPatterns.split(",") : [])

        requireGPGSignatureSwitch.checked = ruleData.requireGpgSignature ?? false
        blockConflictMarkersSwitch.checked = ruleData.blockConflictMarkers ?? false
        blockWIPCommitsSwitch.checked = ruleData.blockWipCommits ?? false
        maxCommitsSpin.value = ruleData.maxCommitsPerPush === "" || ruleData.maxCommitsPerPush === undefined ? 0 : ruleData.maxCommitsPerPush

        isDirty = false
        suppressDirty = false
    }

    function saveChanges() {
        if (!targetModel || ruleIndex < 0) return

        targetModel.setProperty(ruleIndex, "ruleName", basicInfo.ruleName)
        targetModel.setProperty(ruleIndex, "description", basicInfo.description)
        targetModel.setProperty(ruleIndex, "severity", basicInfo.severityIndex)
        targetModel.setProperty(ruleIndex, "enabled", basicInfo.isActive)

        targetModel.setProperty(ruleIndex, "blockForcePushPatterns", blockForcePushInput.getWords().join(","))
        targetModel.setProperty(ruleIndex, "blockDeletionPatterns", blockBranchDeletionInput.getWords().join(","))

        targetModel.setProperty(ruleIndex, "requireGpgSignature", requireGPGSignatureSwitch.checked)
        targetModel.setProperty(ruleIndex, "blockConflictMarkers", blockConflictMarkersSwitch.checked)
        targetModel.setProperty(ruleIndex, "blockWipCommits", blockWIPCommitsSwitch.checked)
        targetModel.setProperty(ruleIndex, "maxCommitsPerPush", maxCommitsSpin.value)

        isDirty = false
    }
}
