import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import GitEaseOrganizationRulesPlugin

/*! ***********************************************************************************************
 * CustomHooksSettings
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
        width: root.contentAvailableWidth
        spacing: 16

        BasicInfoRect {
            id: basicInfo
            ruleColor: root.ruleColor
            onRuleNameChanged: root.markDirty()
            onDescriptionChanged: root.markDirty()
            onSeverityIndexChanged: root.markDirty()
            onIsActiveChanged: root.markDirty()
        }

        RuleChip {
            headerText: "Trigger"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 12

                OptionRow {
                    title: "Hook trigger"

                    control: ComboBox {
                        id: triggerCombo
                        width: 200
                        anchors.verticalCenter: parent.verticalCenter
                        minHeight: 34
                        focusBorderWidth: 1
                        font.family: Style.fontTypes.jetBrainsMono
                        font.weight: 400
                        font.pixelSize: Style.appFont.defaultPt
                        model: ListModel {
                                 id: model
                                 ListElement { text: "pre-commit" }
                                 ListElement { text: "commit-msg" }
                                 ListElement { text: "pre-push" }
                                 ListElement { text: "post-merge" }
                                 ListElement { text: "post-checkout" }
                        }
                        currentIndex: 0

                        Material.background: Style.colors.popupBackground
                        Material.foreground: Style.colors.foreground
                        Material.accent: Style.colors.accent

                        background: Rectangle {
                            implicitHeight: 34
                            radius: 7
                            color: triggerCombo.hovered ? Style.colors.controlBackgroundHover : Style.colors.controlBackground
                            border.width: 1
                            border.color: triggerCombo.activeFocus || triggerCombo.popup.visible ? Style.colors.accent
                                        : triggerCombo.hovered ? Style.colors.controlBorderHover
                                                               : Style.colors.controlBorder

                            Behavior on color { ColorAnimation { duration: Style.motionFast } }
                            Behavior on border.color { ColorAnimation { duration: Style.motionFast } }
                        }

                        onCurrentIndexChanged: root.markDirty()
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Run in background"
                    subtitle: "Async, non-blocking"

                    control: ModernSwitch {
                        id: runInBackgroundSwitch
                        height: parent.height

                        onCheckedChanged: root.markDirty()
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Timeout"
                    subtitle: "Seconds"

                    control: ModernSpinBox {
                        id: timeoutSpin

                        onValueModified: root.markDirty()
                    }
                }
            }
        }

        RuleChip {
            headerText: "Script"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 12

                OptionRow {
                    title: "Script path"
                    subtitle: "Relative to repo root"

                    control: RuleTextField {
                        id: scriptPathField
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        placeholderText: "./scripts/lint.sh"
                        font.family: Style.fontTypes.jetBrainsMono

                        onTextChanged: root.markDirty()
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Inline script"
                    subtitle: "Overrides path if set"
                    rowHeight: inlinescriptInput.height

                    control: ModernInputArea {
                        id: inlinescriptInput

                        width: parent.width
                        height: 110

                        color: Style.colors.controlBackground
                        radius: 7
                        fontSize: Style.appFont.defaultPt

                        onTextChanged: root.markDirty()
                    }
                }
            }
        }

        RuleChip {
            headerText: "Environment & Failure"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 12

                OptionRow {
                    title: "Environment vars"
                    rowHeight: variablesRect.height

                    ListModel {
                        id: listModel
                    }

                    control: Rectangle {
                        id: variablesRect
                        width: parent.width
                        color: "transparent"
                        implicitHeight: variablesColumn.implicitHeight

                        ColumnLayout {
                            id: variablesColumn

                            anchors.fill: parent
                            spacing: 8

                            ListView {
                                id: listView

                                Layout.fillWidth: true
                                Layout.preferredHeight: contentHeight

                                model: listModel
                                spacing: 6
                                clip: true
                                interactive: false

                                visible: count !== 0

                                delegate: RowLayout {
                                    width: listView.width
                                    height: 34
                                    spacing: 8

                                    RuleTextField {
                                        text: key

                                        Layout.preferredWidth: 130
                                        Layout.preferredHeight: 34

                                        placeholderText: "KEY"
                                        font.family: Style.fontTypes.jetBrainsMono

                                        onTextChanged: {
                                            listModel.setProperty(index, "key", text)
                                            root.markDirty()
                                        }
                                    }

                                    Text {
                                        text: "="
                                        Layout.alignment: Qt.AlignVCenter
                                        font.family: Style.fontTypes.jetBrainsMono
                                        font.pixelSize: Style.appFont.defaultPt
                                        color: Style.colors.pluginCardMetaText
                                    }

                                    RuleTextField {
                                        id: valueTextField

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34

                                        text: value

                                        placeholderText: "value"
                                        font.family: Style.fontTypes.jetBrainsMono

                                        onTextChanged: {
                                            listModel.setProperty(index, "value", text)
                                            root.markDirty()
                                        }
                                    }

                                    Rectangle {
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.preferredWidth: 28
                                        Layout.preferredHeight: 28
                                        radius: 7
                                        color: removeVarMouse.containsMouse ? Style.colors.stashActionDangerHoverBackground
                                                                            : "transparent"

                                        Behavior on color { ColorAnimation { duration: Style.motionFast } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: Style.icons.trash
                                            font.family: Style.fontTypes.font6Pro
                                            font.styleName: "Solid"
                                            font.pixelSize: Style.appFont.captionPt
                                            color: removeVarMouse.containsMouse ? Style.colors.error
                                                                                : Style.colors.pluginCardMetaText
                                        }

                                        MouseArea {
                                            id: removeVarMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                listModel.remove(index)
                                                root.markDirty()
                                            }
                                        }
                                    }
                                }
                            }

                            RuleButton {
                                Layout.alignment: Qt.AlignLeft
                                text: "Add variable"
                                iconText: Style.icons.plus

                                onClicked: {
                                    listModel.append({
                                        key: "",
                                        value: ""
                                    })
                                    root.markDirty()
                                }
                            }

                        }

                    }
                }

                DividerLine {}

                OptionRow {
                    title: "On failure"

                    control: SegmentedSelector {
                        id: row
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        model: [
                            { text: "Block",  color: Style.colors.error },
                            { text: "Warn",   color: Style.colors.warning },
                            { text: "Ignore", color: Style.colors.secondaryText }
                        ]

                        onCurrentIndexChanged: root.markDirty()
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

        var triggers = ["pre-commit", "commit-msg", "pre-push", "post-merge", "post-checkout"]
        triggerCombo.currentIndex = triggers.indexOf(ruleData.trigger ?? "pre-commit")
        runInBackgroundSwitch.checked = ruleData.runInBackground ?? false
        timeoutSpin.value = ruleData.timeoutSeconds ?? 30

        scriptPathField.text = ruleData.scriptPath ?? ""
        inlinescriptInput.text = ruleData.inlineScript ?? ""

        listModel.clear()
        var vars = ruleData.envVars ? ruleData.envVars.split(",") : []
        for (var i = 0; i < vars.length; i++)
            listModel.append({ key: vars[i].split("=")[0], value: vars[i].split("=")[1] })

        row.currentIndex = ruleData.onFailure ?? 0

        isDirty = false
        suppressDirty = false
    }

    function saveChanges() {
        if (!targetModel || ruleIndex < 0) return

        targetModel.setProperty(ruleIndex, "ruleName", basicInfo.ruleName)
        targetModel.setProperty(ruleIndex, "description", basicInfo.description)
        targetModel.setProperty(ruleIndex, "severity", basicInfo.severityIndex)
        targetModel.setProperty(ruleIndex, "enabled", basicInfo.isActive)

        var triggers = ["pre-commit", "commit-msg", "pre-push", "post-merge", "post-checkout"]
        targetModel.setProperty(ruleIndex, "trigger", triggers[triggerCombo.currentIndex])
        targetModel.setProperty(ruleIndex, "runInBackground", runInBackgroundSwitch.checked)
        targetModel.setProperty(ruleIndex, "timeoutSeconds", timeoutSpin.value)

        targetModel.setProperty(ruleIndex, "scriptPath", scriptPathField.text)
        targetModel.setProperty(ruleIndex, "inlineScript", inlinescriptInput.text)

        var vars = []
        for (var i = 0; i < listModel.count; i++) {
            var rowData = listModel.get(i)
            vars.push(rowData.key + "=" + rowData.value)
        }
        targetModel.setProperty(ruleIndex, "envVars", vars.join(","))

        targetModel.setProperty(ruleIndex, "onFailure", row.currentIndex)

        isDirty = false
    }
}
