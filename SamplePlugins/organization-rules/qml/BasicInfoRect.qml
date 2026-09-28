import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import GitEaseOrganizationRulesPlugin

/*!
 * BasicInfoRect
 * Showing basic info for each rule (name, description, severity, enabled)
 * Used for every rule
 */

RuleChip {
    /* Property Declarations
     * ****************************************************************************************/
    property alias ruleName:      nameTextField.text
    property alias description:   descriptionInputArea.text
    property alias severityIndex: severitySelector.currentIndex
    property alias isActive:      enabledSwitch.checked

    /* Object Properties
     * ****************************************************************************************/
    headerText: "Basic"
    Layout.fillWidth: true

    content: ColumnLayout {
        spacing: 12

        OptionRow {
            title: "Rule Name"

            control: RuleTextField {
                id: nameTextField
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                placeholderText: "Type a name for the rule..."
            }
        }

        DividerLine {}

        OptionRow {
            title: "Description"
            rowHeight: 96

            control: ModernInputArea {
                id: descriptionInputArea
                anchors.fill: parent
                placeholder: "Describe what this rule enforces..."
                color: Style.colors.controlBackground
                radius: 7
                fontSize: Style.appFont.defaultPt
            }
        }

        DividerLine {}

        OptionRow {
            title: "Severity"
            subtitle: "How violations are reported"

            control: SegmentedSelector {
                id: severitySelector
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                model: [
                    { text: "Error",   color: Style.colors.error },
                    { text: "Warning", color: Style.colors.warning }
                ]
            }
        }

        DividerLine {}

        OptionRow {
            title: "Enabled"
            subtitle: "Turn this rule on or off"

            control: ModernSwitch {
                id: enabledSwitch
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
