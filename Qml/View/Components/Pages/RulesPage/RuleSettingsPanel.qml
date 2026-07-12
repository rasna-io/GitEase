import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * RuleSettingsPanel
 * Right-column panel: loads the correct settings component for the selected rule,
 * plus the shared Delete / Discard / Save Changes bar.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var categoriesInfo: []
    property var categoryModels: []
    property int selectedCategory: 0
    property int selectedRule: -1

    /* Signals
     * ****************************************************************************************/
    signal deleteRequested()
    signal savedChanges()

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.primaryBackground

    /* Children
     * ****************************************************************************************/
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

            function refreshItem() {
                if (!item) return
                var list = root.categoryModels[root.selectedCategory]
                item.targetModel = list
                item.ruleIndex = root.selectedRule
                item.ruleData = list.get(root.selectedRule)
            }

            onLoaded: refreshItem()
        }

        Connections {
            target: root
            function onSelectedRuleChanged() { settingsLoader.refreshItem() }
            function onSelectedCategoryChanged() { settingsLoader.refreshItem() }
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

                Item { Layout.fillWidth: true }

                Button {
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 35

                    background: Rectangle {
                        anchors.fill: parent
                        radius: 5
                        color: "red"
                    }

                    contentItem: Text {
                        anchors.centerIn: parent
                        text: "Delete"
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 11
                        font.bold: true
                        color: Style.colors.textButton
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        var list = root.categoryModels[root.selectedCategory]
                        list.remove(root.selectedRule)
                        root.deleteRequested()
                    }
                }

                Button {
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 35

                    background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 1
                        border.color: "#888"
                        radius: 5
                    }

                    contentItem: Text {
                        anchors.centerIn: parent
                        text: "Discard"
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 11
                        font.bold: true
                        color: "#ccc"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (settingsLoader.item) settingsLoader.item.loadFromModel()
                    }
                }

                Button {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 35

                    background: Rectangle {
                        anchors.fill: parent
                        radius: 5
                        color: "#238636"
                    }

                    contentItem: Text {
                        anchors.centerIn: parent
                        text: "Save Changes"
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 11
                        font.bold: true
                        color: Style.colors.textButton
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (settingsLoader.item) settingsLoader.item.saveChanges()
                        root.savedChanges()
                    }
                }
            }
        }
    }

    Component {
        id: commitSettingsComp
        CommitMessageSettings { ruleColor: root.categoriesInfo[0].color }
    }
    Component {
        id: branchSettingsComp
        BranchNamingSettings { ruleColor: root.categoriesInfo[1].color }
    }
    Component {
        id: fileSettingsComp
        FileSettings { ruleColor: root.categoriesInfo[2].color }
    }
    Component {
        id: pushSettingsComp
        PushRulesSettings { ruleColor: root.categoriesInfo[3].color }
    }
    Component {
        id: notificationSettingsComp
        NotificationRulesSettings { ruleColor: root.categoriesInfo[4].color }
    }
    Component {
        id: hookSettingsComp
        CustomHooksSettings { ruleColor: root.categoriesInfo[5].color }
    }
}