import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * CommitMessageSettings
 * ************************************************************************************************/

Flickable {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property color ruleColor
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
            headerText: "Length & Format"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Min Length"
                    subtitle: "Subject line chars"
                    control: ModernSpinBox {
                        id: minLengthSpin
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Max Length"
                    subtitle: "Subject line chars"
                    control: ModernSpinBox {
                        id: maxLengthSpin
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Require Prefix"
                    subtitle: "feat|fix|chore..."

                    control: RowLayout {
                        anchors.fill: parent

                        ModernSwitch {
                            id: requirePrefixSwitch
                            Layout.fillHeight: true
                        }

                        HorizontalTagInput {
                            id: allowedPrefixesInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "No trailing period"

                    control: ModernSwitch {
                        id: noTrailingPeriodSwitch
                        height: parent.height
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Imperative verb"
                    subtitle: "First word must be a verb"

                    control: ModernSwitch {
                        id: imperativeVerbSwitch
                        height: parent.height
                    }
                }
            }
        }

        RuleChip {
            headerText: "References & Body"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Forbidden words"
                    subtitle: "Blocks if subject contains"

                    control: HorizontalTagInput {
                        id: forbiddenWordsInput
                        anchors.fill: parent
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Ticket reference"
                    subtitle: "Regex, e.g. JIRA-\d+"

                    control: RowLayout {
                        anchors.fill: parent

                        ModernSwitch {
                            id: ticketRefSwitch
                            Layout.fillHeight: true
                        }

                        TextField {
                            id: ticketRefInput
                            Layout.fillWidth: true
                            placeholderText: "JIRA-\d+"
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
                    title: "Body separator"

                    control: RowLayout {
                        anchors.fill: parent

                        ModernSwitch {
                            id: bodySeparatorSwitch
                            Layout.fillHeight: true
                        }

                        Text {
                            text: "Blank line required between subject and body"
                            font.family: Style.fontTypes.roboto
                            color: Style.colors.mutedText
                            font.pixelSize: 12
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Min Length"
                    subtitle: "Subject line chars"
                    control: ModernSpinBox {
                        id: bodyMinLengthSpin
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Require Signed-off-by"

                    control: ModernSwitch {
                        id: signedOffBySwitch
                        height: parent.height
                    }
                }
            }
        }

        RuleChip {
            headerText: "Custom Validator (Optional)"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Regex pattern"
                    subtitle: "Tested against full message"

                    control: TextField {
                        id: customRegexField
                        anchors.fill: parent
                        placeholderText: "^(feat|fix)\(.+\):.+"
                        selectByMouse: true

                        background: Rectangle {
                            color: Style.colors.secondaryBackground
                            radius: 5
                        }
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Error message"

                    control: TextField {
                        id: customErrorField
                        anchors.fill: parent
                        placeholderText: "Commit message must match ..."
                        selectByMouse: true

                        background: Rectangle {
                            color: Style.colors.secondaryBackground
                            radius: 5
                        }
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
        basicInfo.isActive = ruleData.enabled ?? 0

        minLengthSpin.value = ruleData.minLength ?? 0
        maxLengthSpin.value = ruleData.maxLength ?? 72
        requirePrefixSwitch.checked = ruleData.requirePrefix ?? false
        allowedPrefixesInput.setWords(ruleData.allowedPrefixes ? ruleData.allowedPrefixes.split(",") : [])
        noTrailingPeriodSwitch.checked = ruleData.noTrailingPeriod ?? false
        imperativeVerbSwitch.checked = ruleData.imperativeVerb ?? false

        forbiddenWordsInput.setWords(ruleData.forbiddenWords ? ruleData.forbiddenWords.split(",") : [])
        ticketRefSwitch.checked = ruleData.requireTicketRef ?? false
        ticketRefInput.text = ruleData.ticketRefPattern ?? ""
        bodySeparatorSwitch.checked = ruleData.requireBodySeparator ?? false
        bodyMinLengthSpin.value = ruleData.bodyMinLength ?? 0
        signedOffBySwitch.checked = ruleData.requireSignedOffBy ?? false

        customRegexField.text = ruleData.customRegex ?? ""
        customErrorField.text = ruleData.customErrorMessage ?? ""
    }

    function saveChanges() {
        if (!targetModel || ruleIndex < 0) return

        targetModel.setProperty(ruleIndex, "ruleName", basicInfo.ruleName)
        targetModel.setProperty(ruleIndex, "description", basicInfo.description)
        targetModel.setProperty(ruleIndex, "severity", basicInfo.severityIndex)
        targetModel.setProperty(ruleIndex, "enabled", basicInfo.isActive)

        targetModel.setProperty(ruleIndex, "minLength", minLengthSpin.value)
        targetModel.setProperty(ruleIndex, "maxLength", maxLengthSpin.value)
        targetModel.setProperty(ruleIndex, "requirePrefix", requirePrefixSwitch.checked)
        targetModel.setProperty(ruleIndex, "allowedPrefixes", allowedPrefixesInput.getWords().join(","))
        targetModel.setProperty(ruleIndex, "noTrailingPeriod", noTrailingPeriodSwitch.checked)
        targetModel.setProperty(ruleIndex, "imperativeVerb", imperativeVerbSwitch.checked)

        targetModel.setProperty(ruleIndex, "forbiddenWords", forbiddenWordsInput.getWords().join(","))
        targetModel.setProperty(ruleIndex, "requireTicketRef", ticketRefSwitch.checked)
        targetModel.setProperty(ruleIndex, "ticketRefPattern", ticketRefInput.text)
        targetModel.setProperty(ruleIndex, "requireBodySeparator", bodySeparatorSwitch.checked)
        targetModel.setProperty(ruleIndex, "bodyMinLength", bodyMinLengthSpin.value)
        targetModel.setProperty(ruleIndex, "requireSignedOffBy", signedOffBySwitch.checked)

        targetModel.setProperty(ruleIndex, "customRegex", customRegexField.text)
        targetModel.setProperty(ruleIndex, "customErrorMessage", customErrorField.text)
    }
}
