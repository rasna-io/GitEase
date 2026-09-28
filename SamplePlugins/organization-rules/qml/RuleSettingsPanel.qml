import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import GitEaseOrganizationRulesPlugin

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

    readonly property bool hasUnsavedChanges: settingsLoader.item ? settingsLoader.item.isDirty === true : false

    /* Signals
     * ****************************************************************************************/
    signal deleteRequested()
    signal savedChanges()

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.pluginPageBackground

    /* Children
     * ****************************************************************************************/
    EmptyStateView {
        title: "No rule selected"
        details: "Pick a rule from the list, or add a new one to start editing its settings."
        color: Style.colors.pluginPageBackground
        visible: root.selectedRule < 0
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Loader {
            id: settingsLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 24
            Layout.rightMargin: 10
            Layout.topMargin: 20
            Layout.bottomMargin: 12
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
        }

        // ── Action bar ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: Style.colors.pluginPanelBackground
            visible: root.selectedRule >= 0

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Style.colors.pluginPanelBorder
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 10

                RuleButton {
                    variant: "danger"
                    text: "Delete"
                    iconText: Style.icons.trash
                    onClicked: {
                        var list = root.categoryModels[root.selectedCategory]
                        list.remove(root.selectedRule)
                        root.deleteRequested()
                    }
                }

                Item { Layout.fillWidth: true }

                Row {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6
                    opacity: root.hasUnsavedChanges ? 1.0 : 0.0
                    visible: opacity > 0

                    Behavior on opacity { NumberAnimation { duration: Style.motionFast } }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7
                        height: 7
                        radius: 3.5
                        color: Style.colors.marigold
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Unsaved changes"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.pluginSectionMetaText
                    }
                }

                RuleButton {
                    text: "Discard"
                    enabled: root.hasUnsavedChanges
                    onClicked: {
                        if (settingsLoader.item) settingsLoader.item.loadFromModel()
                    }
                }

                RuleButton {
                    variant: "primary"
                    text: "Save Changes"
                    iconText: Style.icons.check
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

    /* Functions
     * ****************************************************************************************/
    function currentIsDirty() {
        if (!settingsLoader.item) return false
        return settingsLoader.item.isDirty === true
    }

    function settingsLoaderItem() {
        return settingsLoader.item
    }
}
