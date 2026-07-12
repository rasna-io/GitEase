import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * CustomHooksSettings
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
            headerText: "Trigger"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Hook trigger"

                    control: ComboBox {
                        id: triggerCombo
                        width: 200
                        minHeight: 40
                        focusBorderWidth: 1
                        font.family: Style.fontTypes.roboto
                        font.weight: 400
                        font.pixelSize: 12
                        model: ListModel {
                                 id: model
                                 ListElement { text: "pre-commit" }
                                 ListElement { text: "commit-msg" }
                                 ListElement { text: "pre-push" }
                                 ListElement { text: "post-merge" }
                                 ListElement { text: "post-checkout" }
                        }
                        currentIndex: 0

                        Material.background: Style.colors.primaryBackground
                        Material.foreground: Style.colors.secondaryText

                        background: Rectangle {
                            radius: 5
                            color: triggerCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                            border.color: triggerCombo.activeFocus ? Style.colors.accent : "transparent"
                        }
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Run in background"
                    subtitle: "Async, non-blocking"

                    control: ModernSwitch {
                        id: runInBackgroundSwitch
                        height: parent.height
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Timeout"
                    subtitle: "Seconds"

                    control: ModernSpinBox {
                        id: timeoutSpin
                    }
                }
            }
        }

        RuleChip {
            headerText: "Script"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Script path"
                    subtitle: "Relative to repo root"

                    control: TextField {
                        id: scriptPathField
                        anchors.fill: parent
                        placeholderText: "./scripts/lint.sh"
                        selectByMouse: true

                        background: Rectangle {
                            implicitHeight: 40
                            color: Style.colors.secondaryBackground
                            radius: 5
                        }
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
                        height: 100

                        color: Style.colors.secondaryBackground
                        border.width: 0
                        fontSize: 11
                    }
                }
            }
        }

        RuleChip {
            headerText: "Environment & Failure"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

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
                            spacing: 0

                            ListView {
                                id: listView

                                Layout.fillWidth: true
                                Layout.preferredHeight: contentHeight

                                model: listModel
                                spacing: 5
                                clip: true

                                visible: count !== 0

                                delegate: RowLayout {
                                    width: listView.width
                                    height: 30

                                    TextField {
                                        text: key

                                        Layout.preferredWidth: 80
                                        Layout.preferredHeight: 30

                                        placeholderText: "KEY"
                                        selectByMouse: true

                                        background: Rectangle {
                                            color: Style.colors.secondaryBackground
                                            radius: 5
                                        }

                                        onTextChanged: {
                                            listModel.setProperty(index, "key", text)
                                        }
                                    }

                                    Text {
                                        text: "="
                                        verticalAlignment: Text.AlignVCenter
                                        font.family: Style.fontTypes.roboto
                                        font.pixelSize: 12
                                        color: Style.colors.placeholderText
                                    }

                                    TextField {
                                        id: valueTextField

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30

                                        text: value

                                        placeholderText: "value"
                                        selectByMouse: true

                                        background: Rectangle {
                                            color: Style.colors.secondaryBackground
                                            radius: 5
                                        }

                                        onTextChanged: {
                                            listModel.setProperty(index, "value", text)
                                        }
                                    }

                                    ToolButton {
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20

                                        padding: 0

                                        contentItem: Text {
                                            text: "×"
                                            color: Style.colors.placeholderText
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: listModel.remove(index)
                                    }
                                }
                            }

                            Button {
                                Layout.preferredWidth: 120
                                Layout.alignment: Qt.AlignVCenter
                                implicitHeight: 40

                                background: Rectangle {
                                    radius: 5
                                    color: Style.colors.accent
                                }

                                contentItem: Item {
                                    anchors.fill: parent

                                    Row {
                                        spacing: 10
                                        anchors.centerIn: parent

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: Style.icons.plus
                                            font.family: Style.fontTypes.font6Pro
                                            font.pixelSize: 12
                                            color: Style.colors.textButton
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Add variable"
                                            color: Style.colors.textButton
                                            font.pixelSize: 13
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }

                                onClicked: {
                                    listModel.append({
                                        key: "",
                                        value: ""
                                    })
                                }
                            }

                        }

                    }
                }

                DividerLine {}

                OptionRow {
                    title: "On failure"

                    control: Row {
                        id: row
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        property int currentIndex: 0

                        Repeater {
                            model: [
                                { text: "Block", color: "#E53935" },
                                { text: "Warn", color: "#FB8C00" },
                                { text: "Ignore", color: "#152741" }
                            ]

                            delegate: Rectangle {
                                width: 60
                                height: 30

                                color: row.currentIndex === index
                                       ? modelData.color
                                       : "transparent"

                                border.width: 1
                                border.color: row.currentIndex === index
                                              ? modelData.color
                                              : "#555"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.text
                                    color: row.currentIndex === index
                                           ? "white"
                                           : "#DDD"
                                    font.bold: row.currentIndex === index
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: row.currentIndex = index
                                }
                            }
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
    }
}
