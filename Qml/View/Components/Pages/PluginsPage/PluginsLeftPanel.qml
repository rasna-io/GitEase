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
    property var installedModel: []
    property var categoriesCounts: ({})

    /* Signals
     * ****************************************************************************************/
    signal categorySelected(string category)

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillHeight: true
    Layout.preferredWidth: 220
    color: Style.colors.primaryBackground

    onCategoriesDataChanged: root.populateCategoriesModel()

    /* Children
     * ****************************************************************************************/
    ListModel {
        id: categoriesModel
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 5

        Label {
            text: "BROWSE"
            color: "#363650"
            font.pixelSize: Style.appFont.largePt
            font.family: Style.fontTypes.roboto
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 5

            property bool isSelected: root.selectedCategory === -1

            color: isSelected ? "#1F3B82" : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10

                Item {
                    Layout.preferredHeight: 20
                    Layout.preferredWidth: 20
                    Layout.alignment: Qt.AlignVCenter

                    Label {
                        anchors.fill: parent
                        text: Style.icons.plugins
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: Style.appFont.largerPt
                        color: root.selectedCategory === -1 ? "#60A5FA" : "#363650"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Label {
                    text: "All Plugins"
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: Style.appFont.largePt
                    color: root.selectedCategory === -1 ? "#60A5FA" : "#363650"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 25
                    height: 18
                    radius: 4
                    color: Style.colors.secondaryBackground

                    Label {
                        anchors.centerIn: parent
                        text: root.pluginsCount
                        color: Style.colors.mutedText
                        font.pixelSize: Style.appFont.largePt
                        font.family: Style.fontTypes.roboto
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.selectedCategory = -1
                    root.categorySelected("All")
                }
            }
        }

        ListView {
            model: categoriesModel
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            interactive: false
            spacing: 5

            delegate: Rectangle {
                width: parent.width
                height: 30
                radius: 5

                property bool isSelected: index === root.selectedCategory

                color: isSelected ? "#1F3B82" : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    Item {
                        Layout.preferredHeight: 20
                        Layout.preferredWidth: 20
                        Layout.alignment: Qt.AlignVCenter

                        IconImage {
                            id: categoryIconImage
                            anchors.fill: parent
                            source: iconUrl || ""
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready
                            color: isSelected ? "#60A5FA" : "#363650"
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: categoryIconImage.status !== Image.Ready
                            text: Style.icons.plugins
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: Style.appFont.largePt
                            color: "#363650"
                        }
                    }

                    // Text {
                    //     text: Style.icons.plugins
                    //     font.family: Style.fontTypes.font6Pro
                    //     font.pixelSize: Style.appFont.largePt
                    //     color: Style.colors.mutedText
                    //     horizontalAlignment: Text.AlignHCenter
                    //     verticalAlignment: Text.AlignVCenter
                    // }

                    Label {
                        text: name
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: Style.appFont.largePt
                        color: isSelected ? "#60A5FA" : "#363650"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 25
                        height: 18
                        radius: 4
                        color: Style.colors.secondaryBackground

                        Label {
                            anchors.centerIn: parent
                            text: root.categoriesCounts[id] || 0
                            color: Style.colors.mutedText
                            font.pixelSize: Style.appFont.largePt
                            font.family: Style.fontTypes.roboto
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.selectedCategory = index
                        root.categorySelected(id)
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Style.colors.primaryBorder
        }

        Label {
            text: "INSTALLED"
            color: "#363650"
            font.pixelSize: Style.appFont.largePt
            font.family: Style.fontTypes.roboto
        }

        ListView {
            model: installedModel
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            interactive: false
            spacing: 5

            delegate: Rectangle {
                width: parent.width
                height: 30
                radius: 5

                property bool isSelected: index === root.selectedInstalledMode

                color: isSelected ? "#1F3B82F6" : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    Item {
                        Layout.preferredHeight: 20
                        Layout.preferredWidth: 20
                        Layout.alignment: Qt.AlignVCenter

                        Label {
                            anchors.centerIn: parent
                            text: modelData.iconName
                            color: modelData.iconColor
                            font.pixelSize: Style.appFont.largePt
                            font.family: Style.fontTypes.font6Pro
                        }
                    }

                    Label {
                        text: modelData.name
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: Style.appFont.largePt
                        color: isSelected ? "#60A5FA" : "#363650"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 25
                        height: 18
                        radius: 4
                        color: Style.colors.secondaryBackground

                        Label {
                            anchors.centerIn: parent
                            text: "5"
                            color: Style.colors.mutedText
                            font.pixelSize: Style.appFont.largePt
                            font.family: Style.fontTypes.roboto
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if(root.selectedInstalledMode === index) root.selectedInstalledMode = -1
                        else root.selectedInstalledMode = index
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Style.colors.primaryBorder
        }

        Label {
            text: "Compatibility"
            color: "#363650"
            font.pixelSize: Style.appFont.largePt
            font.family: Style.fontTypes.roboto
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 10
                radius: 5
                color: Style.colors.compatible
                Layout.alignment: Qt.AlignVCenter
            }

            Label {
                text: "Compatible"
                font.family: Style.fontTypes.roboto
                font.pixelSize: Style.appFont.largePt
                color: "#363650"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 10
                radius: 5
                color: Style.colors.warning
                Layout.alignment: Qt.AlignVCenter
            }
            Label {
                text: "Needs Update"
                font.family: Style.fontTypes.roboto
                font.pixelSize: Style.appFont.largePt
                color: "#363650"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 10
                Layout.preferredHeight: 10
                radius: 5
                color: Style.colors.incompatible
                Layout.alignment: Qt.AlignVCenter
            }
            Label {
                text: "Incompatible"
                font.family: Style.fontTypes.roboto
                font.pixelSize: Style.appFont.largePt
                color: "#363650"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
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