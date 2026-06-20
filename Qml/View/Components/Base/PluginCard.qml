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
    property string pluginId: ""
    property string name: ""
    property string description: ""
    property string author: ""
    property string latestVersion: ""
    property string minAppVersion: ""
    property string size: ""
    property string iconUrl: ""
    property string releaseDate: ""

    property bool   isInstalled: false
    property bool   isCompatible: false // TODO
    property bool   updateAvailable: true // TODO
    property bool   isEnabled: false

    property bool   hovered: false

    /* Signals
     * ****************************************************************************************/

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
        anchors.margins: 15
        spacing: 15

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Icon Rectangle
            Rectangle {
                Layout.preferredWidth: 60
                Layout.preferredHeight: 60
                color: "transparent"
                radius: 10
                border {
                    width: 1
                    color: Style.colors.primaryBorder
                }
                Image {
                    anchors.centerIn: parent
                    width: 50
                    height: 50
                    source: root.iconUrl
                }
            }

            // Name and author
            ColumnLayout {
                spacing: 8
                Label {
                    text: root.name
                    color: Style.colors.foreground
                    font.pixelSize: 16
                    font.bold: true
                    font.family: Style.fontTypes.roboto
                }
                Label {
                    text: root.author
                    color: Style.colors.mutedText
                    font.pixelSize: 12
                    font.family: Style.fontTypes.roboto
                    wrapMode: Text.WordWrap
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Plugin enabled
            Switch {
                Material.accent: Style.colors.accent
                visible: root.isInstalled
                checked: root.isEnabled

                onToggled: {
                    // TODO
                }
            }
        }

        // Description
        ScrollingText {
            text: root.description
            color: Style.colors.placeholderText
            font.pixelSize: 13
            font.family: Style.fontTypes.roboto
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true

            // Size
            Label {
                text: "📦 " + root.size
                color: Style.colors.mutedText
                font.pixelSize: 14
                font.family: Style.fontTypes.roboto
                wrapMode: Text.WordWrap
            }
            Rectangle {
                Layout.preferredHeight: 15
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignHCenter
                color: Style.colors.primaryBorder
            }
            // Latest version
            Label {
                text: "⬆ " + root.latestVersion
                color: Style.colors.mutedText
                font.pixelSize: 14
                font.family: Style.fontTypes.roboto
                wrapMode: Text.WordWrap
            }

            Item {
                Layout.fillWidth: true
            }

            // Install/Unistall
            Button {
                Layout.preferredWidth: 90
                implicitHeight: 40
                enabled: root.isInstalled ? true : root.isCompatible

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
                            text: root.isInstalled ? Style.icons.uninstall : Style.icons.install
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: 12
                            color: Style.colors.textButton
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.isInstalled ? "Uninstall" : "Install"
                            color: Style.colors.textButton
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                onClicked: {
                    // TODO
                }
            }

            // Update
            Button {
                Layout.preferredWidth: 90
                implicitHeight: 40
                enabled: root.isInstalled && root.updateAvailable

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
                            font.pixelSize: 12
                            color: Style.colors.textButton
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Update"
                            color: Style.colors.textButton
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                onClicked: {
                    // TODO
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Style.colors.primaryBorder
        }

        // Compatibility
        RowLayout {
            id: compatibilityRow
            Layout.fillWidth: true
            spacing: 5

            property bool supported: root.isCompatible || root.isInstalled

            Label {
                text: compatibilityRow.supported ? Style.icons.compatible : Style.icons.incompatible
                color: compatibilityRow.supported ? Style.colors.compatible : Style.colors.incompatible
                font.pixelSize: 18
                font.family: Style.fontTypes.font6Pro
                wrapMode: Text.WordWrap
            }
            Label {
                text: compatibilityRow.supported ? "Compatible with your version of GitEase" : "Incompatible with your version of GitEase"
                color: Style.colors.placeholderText
                font.pixelSize: 13
                font.family: Style.fontTypes.roboto
                wrapMode: Text.WordWrap
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
}