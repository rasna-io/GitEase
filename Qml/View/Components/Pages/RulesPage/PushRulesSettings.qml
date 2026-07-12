import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PushRulesSettings
 * ************************************************************************************************/

Flickable {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string ruleColor: ""
    property var ruleData
    property var targetModel
    property int ruleIndex: -1

    /* Object Properties
     * ****************************************************************************************/
    contentWidth: width
    contentHeight: contentColumn.implicitHeight
    clip: true

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

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
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Block branch deletion"
                    subtitle: "Glob patterns"

                    control: HorizontalTagInput {
                        id: blockBranchDeletionInput
                        anchors.fill: parent
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
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Block conflict markers"

                    control: ModernSwitch {
                        id: blockConflictMarkersSwitch
                        height: parent.height
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Block WIP commits"

                    control: ModernSwitch {
                        id: blockWIPCommitsSwitch
                        height: parent.height
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Max commits per push"
                    subtitle: "0 = unlimited"
                    control: ModernSpinBox {
                        id: maxCommitsSpin
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function loadFromModel() {
        if (!ruleData) return

        basicInfo.ruleName = ruleData.ruleName ?? ""
        basicInfo.description = ruleData.description ?? ""
        basicInfo.severityIndex = ruleData.severity ?? 0
        basicInfo.isActive = ruleData.enabled ?? true

        blockForcePushInput.setWords(ruleData.blockForcePushPatterns ? ruleData.blockForcePushPatterns.split(",") : [])
        blockBranchDeletionInput.setWords(ruleData.blockDeletionPatterns ? ruleData.blockDeletionPatterns.split(",") : [])

        requireGPGSignatureSwitch.checked = ruleData.requireGpgSignature ?? false
        blockConflictMarkersSwitch.checked = ruleData.blockConflictMarkers ?? false
        blockWIPCommitsSwitch.checked = ruleData.blockWipCommits ?? false
        maxCommitsSpin.value = ruleData.maxCommitsPerPush ?? 0
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
    }
}
