import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

IPopup {
    id: root

    property string sourceBranch: ""
    property string targetBranch: ""

    signal accepted(bool noFF)

    width: 300
    height: 250
    padding: 0

    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 10
        clip: true
        border.color: Style.colors.primaryBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 0

            ScrollingText {
                text: root.sourceBranch + "  →  " + root.targetBranch
                color: Style.colors.foreground
                font.family: Style.fontTypes.roboto
                font.pixelSize: 13
                font.bold: true
                Layout.fillWidth: true
                Layout.bottomMargin: 16
            }

            RadioButton {
                id: ffRadio
                text: "Fast-forward"
                checked: true
                Layout.bottomMargin: 2
                font.family: Style.fontTypes.roboto
                font.pixelSize: 12
                Material.accent: Style.colors.accent
                Material.foreground: Style.colors.foreground
            }

            RadioButton {
                id: noFFRadio
                text: "No fast-forward  (--no-ff)"
                checked: false
                Layout.bottomMargin: 16
                font.family: Style.fontTypes.roboto
                font.pixelSize: 12
                Material.accent: Style.colors.accent
                Material.foreground: Style.colors.foreground
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: "Cancel"
                    flat: true
                    Layout.preferredWidth: 80
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 12
                    Material.foreground: Style.colors.mutedText
                    onClicked: root.close()
                    background: Rectangle { color: "transparent" }
                }

                Item { Layout.fillWidth: true }

                Button {
                    id: mergeBtn
                    text: "Merge"
                    Layout.preferredWidth: 80
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 12
                    Material.foreground: Style.colors.textButton
                    background: Rectangle {
                        implicitHeight: 32
                        color: mergeBtn.hovered ? Style.colors.accentHover : Style.colors.accent
                        radius: 5
                    }
                    onClicked: {
                        root.accepted(noFFRadio.checked)
                        root.close()
                    }
                }
            }
        }
    }

    onAboutToHide: ffRadio.checked = true
}
