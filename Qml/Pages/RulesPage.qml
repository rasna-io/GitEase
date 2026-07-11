import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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

    property var categoriesInfo: [
        { name: "COMMIT MESSAGE", color: "#58a6ff",
          description: "Enforce message format, prefixes & length"
        },
        { name: "BRANCH NAMING", color: "#3fb950",
          description: "Naming patterns, forbidden chars & protection"
        },
        { name: "FILE & CODE", color: "#f0883e",
          description: "Extensions, secrets & file size limits"
        },
        { name: "PUSH RULES", color: "#f85149",
          description: "Force-push, deletion & GPG requirements"
        },
        { name: "NOTIFICATION", color: "#58a6ff",
          description: "Slack, email & audit log routing"
        },
        { name: "CUSTOM HOOKS", color: "#d2a8ff",
          description: "Custom pre-commit/push scripts"
        }
    ]

    property var categoryModels: [commitRules, branchRules, fileRules, pushRules, notificationRules, hookRules]

    /* Children
     * ****************************************************************************************/

    // One ListModel per category, holding the actual rule instances
    ListModel { id: commitRules }
    ListModel { id: branchRules }
    ListModel { id: fileRules }
    ListModel { id: pushRules }
    ListModel { id: notificationRules }
    ListModel { id: hookRules }

    AddRulePopup {
        id: addRulePopup
        categoriesModel: root.categoriesInfo

        onCategoryClicked: (index) => {
            switch (index) {
                case 0:
                    commitRules.append({ name: "New Commit Message Rule" })
                    break
                case 1:
                    branchRules.append({ name: "New Branch Naming Rule" })
                    break
                case 2:
                    fileRules.append({ name: "New File & Code Rule" })
                    break
                case 3:
                    pushRules.append({ name: "New Push Rules Rule" })
                    break
                case 4:
                    notificationRules.append({ name: "New Notification Rule" })
                    break
                case 5:
                    hookRules.append({ name: "New Custom Hooks Rule" })
                    break
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Left column - tree of categories + nested rules
        Rectangle {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            color: "transparent"
            border.width: 1
            border.color: Style.colors.secondaryBackground
            radius: 5

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Rules"
                        Layout.fillWidth: true
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 13
                        color: Style.colors.placeholderText
                    }

                    Button {
                        Layout.preferredWidth: 90
                        implicitHeight: 44

                        background: Rectangle {
                            radius: 8
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
                                    font.bold: true
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Add Rule"
                                    color: Style.colors.textButton
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }
                        }

                        onClicked: addRulePopup.open()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Style.colors.secondaryBackground
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: root.categoriesInfo

                            delegate: ColumnLayout {
                                id: categoryBlock

                                // capture the outer (category) index BEFORE the nested Repeater shadows it
                                property int categoryIndex: index
                                property color categoryColor: modelData.color
                                property var categoryRulesModel: root.categoryModels[categoryIndex]

                                Layout.fillWidth: true
                                spacing: 0

                                // --- category header row ---
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 25
                                    color: "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 10

                                        Rectangle {
                                            Layout.preferredWidth: 3
                                            Layout.preferredHeight: 15
                                            color: modelData.color
                                            radius: 5
                                        }

                                        Text {
                                            text: modelData.name
                                            font.family: Style.fontTypes.roboto
                                            color: Style.colors.placeholderText
                                            font.pixelSize: 11
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 1
                                            color: Style.colors.secondaryBackground
                                        }

                                        Text {
                                            text: categoryBlock.categoryRulesModel.count
                                            font.family: Style.fontTypes.roboto
                                            color: Style.colors.placeholderText
                                            font.pixelSize: 11
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: "PointingHandCursor"
                                        onClicked: {
                                            root.selectedCategory = categoryBlock.categoryIndex
                                            root.selectedRule = -1   // header click: no specific rule yet
                                        }
                                    }
                                }

                                // --- nested rule names ---
                                Repeater {
                                    model: categoryBlock.categoryRulesModel

                                    delegate: Rectangle {
                                        id: ruleDelegate

                                        // this "index" belongs to the inner Repeater (rule's own index)
                                        Layout.fillWidth: true
                                        height: 30
                                        radius: 5
                                        color: (root.selectedCategory === categoryBlock.categoryIndex
                                                && root.selectedRule === index)
                                               ? Style.colors.accent
                                               : "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            spacing: 5

                                            Rectangle {
                                                width: 10
                                                height: 10
                                                radius: 5
                                                Layout.alignment: Qt.AlignVCenter
                                                color: categoryBlock.categoryColor
                                            }

                                            ScrollingText {
                                                text: name
                                                font.family: Style.fontTypes.roboto
                                                font.pixelSize: 11
                                                color: "white"
                                                Layout.alignment: Qt.AlignVCenter
                                                Layout.fillWidth: true
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: "PointingHandCursor"
                                            onClicked: {
                                                root.selectedCategory = categoryBlock.categoryIndex
                                                root.selectedRule = index
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Style.colors.primaryBackground

            EmptyStateView {
                title: "No rule to show"
                details: "Select a rule to edit its setting"
                visible: root.selectedRule < 0
            }

            ColumnLayout {
                anchors.fill: parent

                Loader {
                    id: settingsLoader
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 20
                    active: root.selectedRule >= 0

                    sourceComponent: {
                        switch (root.selectedCategory) {
                            case 0: return commitSettingsComp
                            case 1: return branchSettingsComp
                            case 2: return fileSettingsComp
                            case 3: return pushSettingsComp
                            case 4: return notificationSettingsComp
                            case 5: return hookSettingsComp
                            default: return null
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    color: Style.colors.secondaryBackground
                    visible: root.selectedRule >= 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5


                        Item {
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 90
                            height: 35
                            radius: 5
                            color: "red"

                            Text {
                                anchors.centerIn: parent
                                text: "Discard"
                                font.family: Style.fontTypes.roboto
                                font.pixelSize: 11
                                font.bold: true
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {

                                }
                            }
                        }

                        Rectangle {
                            width: 100
                            height: 35
                            radius: 5
                            color: "#238636"

                            Text {
                                anchors.centerIn: parent
                                text: "Save Changes"
                                font.family: Style.fontTypes.roboto
                                font.pixelSize: 11
                                font.bold: true
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {

                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: commitSettingsComp

                CommitMessageSettings {
                    ruleColor: root.categoriesInfo[0].color
                }
            }

            Component {
                id: branchSettingsComp

                BranchNamingSettings {
                    ruleColor: root.categoriesInfo[1].color
                }
            }

            Component {
                id: fileSettingsComp

                FileSettings {
                    ruleColor: root.categoriesInfo[2].color
                }
            }

            Component {
                id: pushSettingsComp

                PushRulesSettings {
                    ruleColor: root.categoriesInfo[3].color
                }
            }

            Component {
                id: notificationSettingsComp

                NotificationRulesSettings {
                    ruleColor: root.categoriesInfo[4].color
                }
            }

            Component {
                id: hookSettingsComp

                CustomHooksSettings {
                    ruleColor: root.categoriesInfo[5].color
                }
            }
        }
    }
}