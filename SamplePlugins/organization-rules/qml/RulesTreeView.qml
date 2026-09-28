import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import GitEaseOrganizationRulesPlugin

/*! ***********************************************************************************************
 * RulesTreeView
 * Left-column tree: fixed rule categories, each showing its nested rule instances.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var categoriesInfo: []
    property var categoryModels: []
    property int selectedCategory: 0
    property int selectedRule: -1
    property bool exportEnabled: false
    property string searchText: ""

    /* Signals
     * ****************************************************************************************/
    signal addRuleRequested()
    signal importRequested()
    signal exportRequested()
    signal ruleSelected(int categoryIndex, int ruleIndex)

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.pluginPanelBackground

    // Right border of the sidebar
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
        color: Style.colors.pluginPanelBorder
        z: 1
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        anchors.rightMargin: 1
        spacing: 0

        // ── Header ─────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 18
            Layout.bottomMargin: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Rules"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.largePt
                        font.weight: Font.DemiBold
                        color: Style.colors.pluginCardTitle
                    }

                    Text {
                        text: root.totalRuleCount() + (root.totalRuleCount() === 1 ? " rule" : " rules")
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.pluginSectionMetaText
                    }
                }

                RuleButton {
                    variant: "primary"
                    text: "Add Rule"
                    iconText: Style.icons.plus
                    onClicked: root.addRuleRequested()
                }
            }

            RuleTextField {
                Layout.fillWidth: true
                placeholderText: "Search rules..."
                icon: Style.icons.search
                onTextChanged: root.searchText = text
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RuleButton {
                    Layout.fillWidth: true
                    text: "Import"
                    iconText: Style.icons.upload
                    onClicked: root.importRequested()
                }

                RuleButton {
                    Layout.fillWidth: true
                    text: "Export"
                    iconText: Style.icons.download
                    enabled: root.exportEnabled
                    onClicked: root.exportRequested()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Style.colors.pluginDivider
        }

        // ── Categories ─────────────────────────────────────────────
        Flickable {
            id: categoriesScroll

            //! Space kept free on the right for the scrollbar plus breathing room.
            readonly property int scrollGutter: contentHeight > height ? 18 : 10

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: categoriesColumn.implicitHeight

            ScrollBar.vertical: RuleScrollBar {}

            ColumnLayout {
                id: categoriesColumn
                width: categoriesScroll.width - categoriesScroll.scrollGutter
                spacing: 6

                Item { Layout.preferredHeight: 8 }

                Repeater {
                    model: root.categoriesInfo

                    delegate: ColumnLayout {
                        id: categoryBlock

                        property int categoryIndex: index
                        property color categoryColor: modelData.color
                        property var categoryRulesModel: root.categoryModels[categoryIndex]

                        Layout.fillWidth: true
                        Layout.leftMargin: 10
                        spacing: 2

                        // Category header
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 3
                                Layout.preferredHeight: 12
                                Layout.alignment: Qt.AlignVCenter
                                color: modelData.color
                                radius: 2
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.family: Style.fontTypes.inter
                                font.pixelSize: Style.appFont.captionPt
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.7
                                font.capitalization: Font.AllUppercase
                                color: Style.colors.pluginSidebarLabel
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                radius: 8
                                color: Style.colors.pluginCountPillBackground
                                implicitHeight: countLabel.implicitHeight + 3
                                implicitWidth: countLabel.implicitWidth + 12

                                Label {
                                    id: countLabel
                                    anchors.centerIn: parent
                                    text: categoryBlock.categoryRulesModel ? categoryBlock.categoryRulesModel.count : 0
                                    color: Style.colors.pluginCountPillText
                                    font.pixelSize: Style.appFont.smallPt
                                    font.family: Style.fontTypes.jetBrainsMono
                                }
                            }
                        }

                        // Rules
                        Repeater {
                            model: categoryBlock.categoryRulesModel

                            delegate: Rectangle {
                                id: ruleRow

                                property bool matchesSearch: root.searchText.length === 0 ||
                                                              ruleName.toLowerCase().includes(root.searchText.toLowerCase())
                                property bool isSelected: root.selectedCategory === categoryBlock.categoryIndex
                                                          && root.selectedRule === index

                                Layout.fillWidth: true
                                Layout.preferredHeight: matchesSearch ? 32 : 0
                                visible: matchesSearch
                                radius: 6
                                color: isSelected ? Style.colors.pluginSidebarRowActiveBg
                                     : (ruleHover.containsMouse ? Style.colors.pluginSidebarRowHoverBg
                                                                : "transparent")

                                Behavior on color { ColorAnimation { duration: Style.motionFast } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 10
                                    spacing: 9

                                    Rectangle {
                                        Layout.preferredWidth: 7
                                        Layout.preferredHeight: 7
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: 3.5
                                        color: categoryBlock.categoryColor
                                        opacity: model.enabled === false ? 0.35 : 1.0
                                    }

                                    ScrollingText {
                                        text: ruleName
                                        font.family: Style.fontTypes.inter
                                        font.pixelSize: Style.appFont.mediumPt
                                        font.weight: ruleRow.isSelected ? Font.Medium : Font.Normal
                                        color: ruleRow.isSelected ? Style.colors.pluginSidebarRowActiveText
                                                                  : Style.colors.pluginSidebarRowText
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    id: ruleHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.ruleSelected(categoryBlock.categoryIndex, index)
                                }
                            }
                        }

                        Text {
                            visible: !!categoryBlock.categoryRulesModel && categoryBlock.categoryRulesModel.count === 0
                            Layout.leftMargin: 16
                            Layout.bottomMargin: 2
                            text: "No rules yet"
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.captionPt
                            font.italic: true
                            color: Style.colors.emptyStateSubText
                        }

                        Item { Layout.preferredHeight: 6 }
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function totalRuleCount() {
        var total = 0
        for (var i = 0; i < root.categoryModels.length; i++)
            if (root.categoryModels[i]) total += root.categoryModels[i].count
        return total
    }
}
