import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int selectedCategory: 0
    property int selectedInstalledMode: -1
    property var categoriesData: []
    property var installedModel: []

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

        ListView {
            model: categoriesModel
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            interactive: false
            spacing: 2

            delegate: Rectangle {
                width: parent.width
                height: 30
                radius: 5

                property bool isSelected: index === root.selectedCategory

                color: isSelected ? "#1F3B82F6" : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    Item {
                        width: 50
                        height: 50

                        Image {
                            id: categoryIconImage
                            anchors.fill: parent
                            source: iconUrl || ""
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: categoryIconImage.status !== Image.Ready
                            text: Style.icons.plugins
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: Style.appFont.displaySmPt
                            color: Style.colors.mutedText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

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
                            text: "10"
                            color: "#363650"
                            font.pixelSize: Style.appFont.largePt
                            font.family: Style.fontTypes.roboto
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.selectedCategory = index
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
            spacing: 2

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

                    Label {
                        text: modelData.iconName
                        color: modelData.iconColor
                        font.pixelSize: Style.appFont.largePt
                        font.family: Style.fontTypes.font6Pro
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
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
                            color: "#363650"
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