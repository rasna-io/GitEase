import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style_Impl
import GitEase_Style
import GitEase

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var  plugin:     null
    property bool hovered:    false
    property bool pluginBusy: root.plugin?.busy ?? false

    /* Signals
     * ****************************************************************************************/
    signal installClicked  (string pluginId)
    signal uninstallClicked(string pluginId)
    signal updateClicked   (string pluginId)
    signal enableToggled   (string pluginId, bool enabled)

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.primaryBackground
    radius: 5
    border {
        width: 1
        color: Style.colors.primaryBorder
    }

    // Scaling animation on hover
    scale: root.hovered ? 1.03 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    /* Children
     * ****************************************************************************************/

    // Mouse area handling the hovered property
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Icon Rectangle
            Rectangle {
                Layout.preferredWidth: 50
                Layout.preferredHeight: 50
                Layout.alignment: Qt.AlignTop
                color: "#19281e"
                radius: 10
                Item {
                    anchors.centerIn: parent
                    width: 50
                    height: 50

                    Image {
                        id: pluginIconImage
                        anchors.fill: parent
                        source: root.plugin.iconUrl || ""
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: pluginIconImage.status !== Image.Ready
                        text: Style.icons.plugins
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: Style.appFont.displaySmPt
                        color: Style.colors.mutedText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Name and author
            ColumnLayout {
                id: infoColumn
                spacing: 0
                RowLayout {
                    Label {
                        text: root.plugin.name
                        color: Style.colors.placeholderText
                        font.pixelSize: Style.appFont.h2Pt
                        font.bold: true
                        font.family: Style.fontTypes.roboto
                    }

                    Label {
                        text: "v1.0.0"
                        color: Style.colors.hintText
                        font.pixelSize: Style.appFont.h2Pt
                        font.family: Style.fontTypes.roboto
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredHeight: 10
                        Layout.preferredWidth: 10
                        radius: 5
                        color: !root.plugin.isCompatible ? Style.colors.incompatible
                               : root.plugin.updateAvailable ? Style.colors.warning
                               : Style.colors.compatible
                        Layout.alignment: Qt.AlignTop
                    }
                }

                Label {
                    text: "by " + root.plugin.author
                    color: Style.colors.hintText
                    font.pixelSize: Style.appFont.mediumPt
                    font.family: Style.fontTypes.roboto
                }

                Item {
                    Layout.preferredHeight: 20
                }

                // Description
                Label {
                    Layout.fillWidth: true
                    text: root.plugin.description
                    color: Style.colors.placeholderText
                    font.pixelSize: Style.appFont.h3Pt
                    font.family: Style.fontTypes.roboto
                    wrapMode: Label.WordWrap
                }
            }

            // Plugin enabled
            // Switch {
            //     Material.accent: Style.colors.accent
            //     visible: root.plugin.isInstalled
            //     checked: root.plugin.isEnabled

            //     onToggled: {
            //         root.enableToggled(root.plugin.pluginId, checked)
            //     }
            // }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Style.colors.primaryBorder
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                spacing: 15
                // // Size
                // Label {
                //     text: "📦 " + root.plugin.size
                //     color: Style.colors.mutedText
                //     font.pixelSize: Style.appFont.largePt
                //     font.family: Style.fontTypes.roboto
                //     wrapMode: Text.WordWrap
                // }
                // Rectangle {
                //     Layout.preferredHeight: 15
                //     Layout.preferredWidth: 1
                //     Layout.alignment: Qt.AlignHCenter
                //     color: Style.colors.primaryBorder
                // }
                // // Latest version
                // Label {
                //     text: "⬆ " + root.plugin.latestVersion
                //     color: Style.colors.mutedText
                //     font.pixelSize: Style.appFont.largePt
                //     font.family: Style.fontTypes.roboto
                //     wrapMode: Text.WordWrap
                // }

                Rectangle {
                    Layout.preferredWidth: categoryLabel.width + 20
                    Layout.preferredHeight: 20
                    color: Style.colors.vibrantMintBg
                    Layout.alignment: Qt.AlignVCenter
                    radius: 5

                    Label {
                        id: categoryLabel
                        anchors.centerIn: parent
                        text: "Inspection"
                        color: Style.colors.vibrantMint
                        font.pixelSize: Style.appFont.mediumPt
                        font.family: Style.fontTypes.roboto
                        font.bold: true
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                BusyIndicator {
                    visible: root.pluginBusy
                    running: root.pluginBusy
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    Material.accent: Style.colors.accent
                }

                // Unistall
                Button {
                    Layout.preferredWidth: 90
                    implicitHeight: 40
                    visible: root.plugin.isInstalled

                    background: Rectangle {
                        radius: 5
                        color: "transparent"
                        border.width: 1
                        border.color: Style.colors.primaryBorder
                    }

                    contentItem: Item {
                        anchors.fill: parent

                        Row {
                            spacing: 10
                            anchors.centerIn: parent

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Uninstall"
                                color: "#363650"
                                font.pixelSize: Style.appFont.h3Pt
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    onClicked: {
                        if (root.plugin.isInstalled)
                            root.uninstallClicked(root.plugin.pluginId)
                        else
                            root.installClicked(root.plugin.pluginId)
                    }
                }

                // Plugin enabled
                Switch {
                    Material.accent: Style.colors.accent
                    visible: root.plugin.isInstalled
                    checked: root.plugin.isEnabled

                    onToggled: {
                        root.enableToggled(root.plugin.pluginId, checked)
                    }
                }

                Label {
                    text: "⭳ 48.2k"
                    color: "#363650"
                    font.pixelSize: Style.appFont.mediumPt
                    font.family: Style.fontTypes.roboto
                    font.bold: true
                    visible: !root.plugin.isInstalled
                }

                // Install
                Button {
                    Layout.preferredWidth: 75
                    implicitHeight: 40
                    visible: !root.plugin.isInstalled

                    background: Rectangle {
                        radius: 5
                        color: enabled ? Style.colors.accent : Style.colors.disabledButton
                    }

                    contentItem: Item {
                        anchors.fill: parent

                        Row {
                            spacing: 10
                            anchors.centerIn: parent

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Install"
                                color: Style.colors.textButton
                                font.pixelSize: Style.appFont.h3Pt
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    onClicked: {
                        if (root.plugin.isInstalled)
                            root.uninstallClicked(root.plugin.pluginId)
                        else
                            root.installClicked(root.plugin.pluginId)
                    }
                }

                // Update
                Button {
                    Layout.preferredWidth: 90
                    implicitHeight: 40
                    visible: root.plugin.updateAvailable
                    enabled: !root.pluginBusy

                    background: Rectangle {
                        radius: 5
                        color: enabled ? Style.colors.updateButton : Style.colors.disabledButton
                    }

                    contentItem: Item {
                        anchors.fill: parent

                        Row {
                            spacing: 10
                            anchors.centerIn: parent

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Style.icons.update
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: Style.appFont.mediumPt
                                color: Style.colors.textButton
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Update"
                                color: Style.colors.textButton
                                font.pixelSize: Style.appFont.h3Pt
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    onClicked: {
                        root.updateClicked(root.plugin.pluginId)
                    }
                }
            }


        }


    }

    /* Functions
     * ****************************************************************************************/

}