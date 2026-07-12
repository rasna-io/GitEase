import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * BranchNamingSettings
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
        }

        RuleChip {
            headerText: "Name Rules"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Allowed prefixes"

                    control: HorizontalTagInput {
                        id: allowedPrefixesInput
                        anchors.fill: parent
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Max name length"
                    subtitle: "Characters"
                    control: ModernSpinBox {
                        id: maxLengthSpin
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Forbidden: spaces"

                    control: ModernSwitch {
                        id: forbiddenSpacesSwitch
                        height: parent.height
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Forbidden: uppercase"

                    control: ModernSwitch {
                        id: forbiddenUppercaseSwitch
                        height: parent.height
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Forbidden: special chars"

                    control: ModernSwitch {
                        id: forbiddensSpecialCharsSwitch
                        height: parent.height
                    }
                }
            }
        }

        RuleChip {
            headerText: "Branch Protection"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Ticket reference"
                    subtitle: "Required in branch name"

                    control: RowLayout {
                        anchors.fill: parent

                        ModernSwitch {
                            id: ticketReferenceSwitch
                            Layout.fillHeight: true
                        }

                        TextField {
                            id: ticketReferenceField
                            Layout.fillWidth: true
                            placeholderText: "[A-Z]+-\d+"
                            selectByMouse: true

                            background: Rectangle {
                                color: Style.colors.secondaryBackground
                                radius: 5
                            }
                        }
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Protected branches"
                    subtitle: "Glob patterns"

                    control: HorizontalTagInput {
                        id: protectedBranchesInput
                        anchors.fill: parent
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Auto-delete after merge"
                    subtitle: "Clean up merged branches"

                    control: ModernSwitch {
                        id: autoDeleteSwitch
                        height: parent.height
                    }
                }
            }
        }
    }

    function loadFromModel() {
        if (!ruleData) return

        basicInfo.ruleName = ruleData.ruleName ?? ""
        basicInfo.description = ruleData.description ?? ""
        basicInfo.severityIndex = ruleData.severity ?? 0
        basicInfo.isActive = ruleData.isActive ?? true

        allowedPrefixesInput.setWords(ruleData.allowedPrefixes ? ruleData.allowedPrefixes.split(",") : [])
        maxLengthSpin.value = ruleData.maxLength ?? 50
        forbiddenSpacesSwitch.checked = ruleData.forbidSpaces ?? false
        forbiddenUppercaseSwitch.checked = ruleData.forbidUppercase ?? false
        forbiddensSpecialCharsSwitch.checked = ruleData.forbidSpecialChars ?? false

        ticketReferenceSwitch.checked = ruleData.requireTicketRef ?? false
        ticketReferenceField.text = ruleData.ticketRefPattern ?? ""
        protectedBranchesInput.setWords(ruleData.protectedBranches ? ruleData.protectedBranches.split(",") : [])
        autoDeleteSwitch.checked = ruleData.autoDeleteAfterMerge ?? false
    }

    function saveChanges() {
        if (!targetModel || ruleIndex < 0) return

        targetModel.setProperty(ruleIndex, "ruleName", basicInfo.ruleName)
        targetModel.setProperty(ruleIndex, "description", basicInfo.description)
        targetModel.setProperty(ruleIndex, "severity", basicInfo.severityIndex)
        targetModel.setProperty(ruleIndex, "enabled", basicInfo.isActive)

        targetModel.setProperty(ruleIndex, "allowedPrefixes", allowedPrefixesInput.getWords().join(","))
        targetModel.setProperty(ruleIndex, "maxLength", maxLengthSpin.value)
        targetModel.setProperty(ruleIndex, "forbidSpaces", forbiddenSpacesSwitch.checked)
        targetModel.setProperty(ruleIndex, "forbidUppercase", forbiddenUppercaseSwitch.checked)
        targetModel.setProperty(ruleIndex, "forbidSpecialChars", forbiddensSpecialCharsSwitch.checked)

        targetModel.setProperty(ruleIndex, "requireTicketRef", ticketReferenceSwitch.checked)
        targetModel.setProperty(ruleIndex, "ticketRefPattern", ticketReferenceField.text)
        targetModel.setProperty(ruleIndex, "protectedBranches", protectedBranchesInput.getWords().join(","))
        targetModel.setProperty(ruleIndex, "autoDeleteAfterMerge", autoDeleteSwitch.checked)
    }
}
