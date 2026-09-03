import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int selectedCategory: -1
    property int selectedInstalledMode: -1
    property int pluginsCount: 0
    property var categoriesData: []
    property var categoriesCounts: ({})

    //! Counts for the Installed filter rows (Enabled / Disabled / Needs Update)
    property var installedCounts: ({})

    property var installedModelWithAll: [
        { name: "All", iconName: Style.icons.plugins, iconColor: Style.colors.pluginSidebarRowText },
        { name: "Enabled", iconName: Style.icons.check, iconColor: Style.colors.compatible },
        { name: "Disabled", iconName: Style.icons.pause, iconColor: Style.colors.incompatible },
        { name: "Needs Update", iconName: Style.icons.warning, iconColor: Style.colors.marigold }
    ]

    /* Signals
     * ****************************************************************************************/
    signal categorySelected(string category)
    signal installedModeSelected(string mode)

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillHeight: true
    Layout.preferredWidth: 188
    color: Style.colors.pluginPanelBackground

    // Right border of the sidebar
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
        color: Style.colors.pluginPanelBorder
    }

    onCategoriesDataChanged: root.populateCategoriesModel()

    /* Children
     * ****************************************************************************************/
    ListModel {
        id: categoriesModel
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Browse section ─────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Style.dp(12)
            Layout.bottomMargin: Style.dp(4)
            spacing: 0

            Label {
                text: "Browse"
                color: Style.colors.pluginSidebarLabel
                font.pixelSize: Style.appFont.captionPt
                font.weight: Font.DemiBold
                font.family: Style.fontTypes.inter
                font.letterSpacing: 0.7
                font.capitalization: Font.AllUppercase
                Layout.leftMargin: Style.dp(14)
                Layout.bottomMargin: Style.dp(6)
            }

            // All Plugins row
            Rectangle {
                id: allPluginsRow
                Layout.fillWidth: true
                Layout.leftMargin: Style.dp(10)
                Layout.rightMargin: Style.dp(10)
                implicitHeight: 28
                radius: 5
                color: root.selectedCategory === -1
                       ? Style.colors.pluginSidebarRowActiveBg
                       : (allPluginsHover.containsMouse ? Style.colors.pluginSidebarRowHoverBg
                                                       : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Style.dp(10)
                    anchors.rightMargin: Style.dp(10)
                    spacing: 8

                    Text {
                        text: Style.icons.plugins
                        font.family: Style.fontTypes.font6Pro
                        font.styleName: "Solid"
                        font.pixelSize: Style.fontIconSize.smallPt
                        color: root.selectedCategory === -1
                               ? Style.colors.pluginSidebarRowActiveText
                               : Style.colors.pluginSidebarRowText
                    }

                    Label {
                        text: "All Plugins"
                        Layout.fillWidth: true
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.mediumPt
                        font.weight: root.selectedCategory === -1 ? Font.Medium : Font.Normal
                        color: root.selectedCategory === -1
                               ? Style.colors.pluginSidebarRowActiveText
                               : Style.colors.pluginSidebarRowText
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        visible: root.pluginsCount > 0
                        radius: 8
                        color: Style.colors.pluginCountPillBackground
                        implicitHeight: allCountLabel.implicitHeight + 3
                        implicitWidth: allCountLabel.implicitWidth + 12

                        Label {
                            id: allCountLabel
                            anchors.centerIn: parent
                            text: root.pluginsCount
                            color: Style.colors.pluginCountPillText
                            font.pixelSize: Style.appFont.smallPt
                            font.family: Style.fontTypes.jetBrainsMono
                        }
                    }
                }

                MouseArea {
                    id: allPluginsHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedCategory = -1
                        root.categorySelected("All")
                    }
                }
            }

            // Category rows
            ListView {
                model: categoriesModel
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                interactive: false
                spacing: 1
                clip: true

                delegate: Rectangle {
                    id: categoryRow
                    width: ListView.view.width
                    height: 28
                    radius: 5

                    property bool isSelected: index === root.selectedCategory

                    color: isSelected ? Style.colors.pluginSidebarRowActiveBg
                           : (categoryRowHover.containsMouse ? Style.colors.pluginSidebarRowHoverBg
                                                            : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Style.dp(10)
                        anchors.rightMargin: Style.dp(10)
                        spacing: 8

                        Item {
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14

                            IconImage {
                                id: categoryIconImage
                                anchors.fill: parent
                                source: iconUrl || ""
                                fillMode: Image.PreserveAspectFit
                                visible: status === Image.Ready
                                color: isSelected
                                       ? Style.colors.pluginSidebarRowActiveText
                                       : Style.colors.pluginSidebarRowText
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: categoryIconImage.status !== Image.Ready
                                text: Style.icons.plugins
                                font.family: Style.fontTypes.font6Pro
                                font.styleName: "Solid"
                                font.pixelSize: Style.fontIconSize.smallPt
                                color: isSelected
                                       ? Style.colors.pluginSidebarRowActiveText
                                       : Style.colors.pluginSidebarRowText
                            }
                        }

                        Label {
                            text: name
                            Layout.fillWidth: true
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.mediumPt
                            font.weight: isSelected ? Font.Medium : Font.Normal
                            color: isSelected
                                   ? Style.colors.pluginSidebarRowActiveText
                                   : Style.colors.pluginSidebarRowText
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            visible: (root.categoriesCounts[id] || 0) > 0
                            radius: 8
                            color: Style.colors.pluginCountPillBackground
                            implicitHeight: categoryCountLabel.implicitHeight + 3
                            implicitWidth: categoryCountLabel.implicitWidth + 12

                            Label {
                                id: categoryCountLabel
                                anchors.centerIn: parent
                                text: root.categoriesCounts[id] || 0
                                color: Style.colors.pluginCountPillText
                                font.pixelSize: Style.appFont.smallPt
                                font.family: Style.fontTypes.jetBrainsMono
                            }
                        }
                    }

                    MouseArea {
                        id: categoryRowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedCategory = index
                            root.categorySelected(id)
                        }
                    }
                }
            }
        }

        // ── Installed section ──────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Style.dp(8)
            Layout.bottomMargin: Style.dp(4)
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: Style.dp(8)
                Layout.preferredHeight: 1
                color: Style.colors.pluginDivider
            }

            Label {
                text: "Installed"
                color: Style.colors.pluginSidebarLabel
                font.pixelSize: Style.appFont.captionPt
                font.weight: Font.DemiBold
                font.family: Style.fontTypes.inter
                font.letterSpacing: 0.7
                font.capitalization: Font.AllUppercase
                Layout.leftMargin: Style.dp(14)
                Layout.bottomMargin: Style.dp(6)
            }

            ListView {
                id: installedListView
                model: root.installedModelWithAll
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                Layout.leftMargin: Style.dp(10)
                Layout.rightMargin: Style.dp(10)
                interactive: false
                spacing: 1

                delegate: Rectangle {
                    id: installedModeRow
                    width: ListView.view.width
                    height: 28
                    radius: 5

                    property bool isSelected: index === root.selectedInstalledMode
                    property bool isAllItem: index === 0

                    color: isSelected ? Style.colors.pluginSidebarRowActiveBg
                           : (installedModeHover.containsMouse ? Style.colors.pluginSidebarRowHoverBg
                                                               : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Style.dp(10)
                        anchors.rightMargin: Style.dp(10)
                        spacing: 8

                        Text {
                            text: isAllItem ? Style.icons.plugins : modelData.iconName
                            font.family: isAllItem ? Style.fontTypes.font6Pro : Style.fontTypes.font6Pro
                            font.styleName: "Solid"
                            font.pixelSize: Style.fontIconSize.smallPt
                            color: isSelected ? Style.colors.pluginSidebarRowActiveText
                                              : (isAllItem ? Style.colors.pluginSidebarRowText
                                                           : modelData.iconColor)
                        }

                        Label {
                            text: isAllItem ? "All Installed" : modelData.name
                            Layout.fillWidth: true
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.mediumPt
                            font.weight: isSelected ? Font.Medium : Font.Normal
                            color: isSelected
                                   ? Style.colors.pluginSidebarRowActiveText
                                   : Style.colors.pluginSidebarRowText
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            visible: !isAllItem && (root.installedCounts[modelData.name] || 0) > 0
                            radius: 8
                            color: Style.colors.pluginCountPillBackground
                            implicitHeight: installedCountLabel.implicitHeight + 3
                            implicitWidth: installedCountLabel.implicitWidth + 12

                            Label {
                                id: installedCountLabel
                                anchors.centerIn: parent
                                text: root.installedCounts[modelData.name] || 0
                                color: Style.colors.pluginCountPillText
                                font.pixelSize: Style.appFont.smallPt
                                font.family: Style.fontTypes.jetBrainsMono
                            }
                        }
                    }

                    MouseArea {
                        id: installedModeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.selectedInstalledMode !== index) {
                                root.selectedInstalledMode = index
                                root.installedModeSelected(index === 0 ? "All" : modelData.name)
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ── Compatibility legend ───────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.pluginDivider
            }

            Label {
                text: "Compatibility"
                color: Style.colors.pluginSidebarLabel
                font.pixelSize: Style.appFont.captionPt
                font.weight: Font.DemiBold
                font.family: Style.fontTypes.inter
                font.letterSpacing: 0.7
                font.capitalization: Font.AllUppercase
                Layout.topMargin: Style.dp(12)
                Layout.leftMargin: Style.dp(14)
                Layout.bottomMargin: Style.dp(8)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Style.dp(14)
                Layout.rightMargin: Style.dp(14)
                Layout.bottomMargin: Style.dp(6)
                spacing: 7

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: 4
                    color: Style.colors.compatible
                }

                Label {
                    text: "Compatible"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.h4Pt
                    color: Style.colors.pluginSidebarRowText
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Style.dp(14)
                Layout.rightMargin: Style.dp(14)
                Layout.bottomMargin: Style.dp(6)
                spacing: 7

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: 4
                    color: Style.colors.marigold
                }

                Label {
                    text: "Needs update"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.h4Pt
                    color: Style.colors.pluginSidebarRowText
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Style.dp(14)
                Layout.rightMargin: Style.dp(14)
                Layout.bottomMargin: Style.dp(12)
                spacing: 7

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: 4
                    color: Style.colors.incompatible
                }

                Label {
                    text: "Incompatible"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.h4Pt
                    color: Style.colors.pluginSidebarRowText
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function populateCategoriesModel() {
        categoriesModel.clear()

        for (var i = 0; i < root.categoriesData.length; i++) {
            var category = root.categoriesData[i]
            categoriesModel.append(category)
        }
    }
}
