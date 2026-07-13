import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

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
    color: "transparent"
    border.width: 1
    border.color: Style.colors.secondaryBackground
    radius: 5

    /* Children
     * ****************************************************************************************/
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
                implicitHeight: 40

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

                onClicked: root.addRuleRequested()
            }
        }

        TextField {
            Layout.fillWidth: true
            placeholderText: "Search rules..."
            selectByMouse: true

            background: Rectangle {
                color: Style.colors.secondaryBackground
                radius: 5
            }

            onTextChanged: root.searchText = text
        }

        DividerLine {}

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: Style.colors.secondaryBackground
            radius: 5

            RowLayout {
                anchors.fill: parent
                spacing: 5

                Button {
                    Layout.preferredWidth: 90
                    implicitHeight: 40
                    Layout.alignment: Qt.AlignCenter

                    background: Rectangle {
                        radius: 5
                        color: "transparent"
                        border.width: 1
                        border.color: "#888"
                    }

                    contentItem: Item {
                        anchors.fill: parent

                        Row {
                            spacing: 10
                            anchors.centerIn: parent

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Style.icons.upload
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: 10
                                color: Style.colors.textButton
                                font.bold: true
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Import"
                                color: Style.colors.textButton
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }

                    onClicked: root.importRequested()
                }

                Button {
                    Layout.preferredWidth: 90
                    implicitHeight: 40
                    Layout.alignment: Qt.AlignCenter
                    enabled: root.exportEnabled

                    background: Rectangle {
                        radius: 5
                        color: enabled ? "transparent" : Style.colors.disabledButton
                        border.width: 1
                        border.color: "#888"
                    }

                    contentItem: Item {
                        anchors.fill: parent

                        Row {
                            spacing: 10
                            anchors.centerIn: parent

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Style.icons.download
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: 10
                                color: Style.colors.textButton
                                font.bold: true
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Export"
                                color: Style.colors.textButton
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }

                    onClicked: root.exportRequested()
                }
            }
        }

        DividerLine {}

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 8

                // Categories repeater
                Repeater {
                    model: root.categoriesInfo

                    delegate: ColumnLayout {
                        id: categoryBlock

                        property int categoryIndex: index
                        property color categoryColor: modelData.color
                        property var categoryRulesModel: root.categoryModels[categoryIndex]

                        Layout.fillWidth: true
                        spacing: 0

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
                        }

                        // Rules repeater
                        Repeater {
                            model: categoryBlock.categoryRulesModel

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: matchesSearch ? 30 : 0
                                visible: matchesSearch
                                radius: 5

                                property bool matchesSearch: root.searchText.length === 0 ||
                                                              ruleName.toLowerCase().includes(root.searchText.toLowerCase())

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
                                        text: ruleName
                                        font.family: Style.fontTypes.roboto
                                        font.pixelSize: 11
                                        color: Style.colors.textButton
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: "PointingHandCursor"
                                    onClicked: {
                                        root.ruleSelected(categoryBlock.categoryIndex, index)
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