import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

Rectangle {
    id: root
    Layout.fillHeight: true
    Layout.preferredWidth: 220
    color: Style.colors.primaryBackground

    property int selectedCategory: 0
    property int selectedInstalledMode: -1

    property var categoryModel: [
        { name: "All Plugins", iconName: Style.icons.allPlugins, iconColor: Style.colors.mutedText },
        { name: "Hosting",     iconName: Style.icons.hosting,    iconColor: Style.colors.hosting },
        { name: "Workflow",    iconName: Style.icons.workflow,   iconColor: Style.colors.workflow },
        { name: "Merge",       iconName: Style.icons.merge,      iconColor: Style.colors.merge },
        { name: "Inspection",  iconName: Style.icons.inspection, iconColor: Style.colors.inspection },
        { name: "AI",          iconName: Style.icons.ai,         iconColor: Style.colors.ai },
    ]

    property var installedModel: [
        { name: "Enabled",      iconName: Style.icons.check,   iconColor: Style.colors.compatible },
        { name: "Disabled",     iconName: Style.icons.pause,   iconColor: "#363650" },
        { name: "Needs Update", iconName: Style.icons.warning, iconColor: Style.colors.warning }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 5

        Text {
            text: "BROWSE"
            color: "#363650"
            font.pixelSize: Style.appFont.largePt
            font.family: Style.fontTypes.roboto
        }

        ListView {
            model: categoryModel
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

                    Text {
                        text: Style.icons.workflow
                        color: isSelected ? "#60A5FA" : "#363650"
                        font.pixelSize: Style.appFont.largePt
                        font.family: Style.fontTypes.font6Pro
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
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

                        Text {
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

        Text {
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

                    Text {
                        text: modelData.iconName
                        color: modelData.iconColor
                        font.pixelSize: Style.appFont.largePt
                        font.family: Style.fontTypes.font6Pro
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
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

                        Text {
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

        Text {
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
            Text {
                text: "Compatible"
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
                color: Style.colors.warning
            }
            Text {
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
            }
            Text {
                text: "Incompatible"
                font.family: Style.fontTypes.roboto
                font.pixelSize: Style.appFont.largePt
                color: "#363650"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}