import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * MergeMethodPopup
 * ************************************************************************************************/


IPopup {
    id: root

    property string sourceBranch: ""
    property string targetBranch: ""

    signal accepted(bool noFF)

    width: 340
    height: 280
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
            spacing: 16

            ScrollingText {
                text: root.sourceBranch + "  →  " + root.targetBranch
                color: Style.colors.foreground
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.largePt
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle{
                Layout.fillHeight: true
                Layout.fillWidth: true

                color: Style.colors.surfaceMuted
                border.color: Style.colors.primaryBorder
                border.width: 1
                radius: 8

                ColumnLayout{
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RadioButton {
                        id: ffRadio
                        text: "Fast-forward"
                        checked: true
                        Layout.fillWidth: true
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.h3Pt
                        Material.accent: Style.colors.accent
                        Material.foreground: Style.colors.foreground
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.NoButton
                        }


                        hoverEnabled: true
                        font.bold: hovered
                    }

                    RadioButton {
                        id: noFFRadio
                        text: "No fast-forward  (--no-ff)"
                        checked: false
                        Layout.fillWidth: true
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.h3Pt
                        Material.accent: Style.colors.accent
                        Material.foreground: Style.colors.foreground
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.NoButton
                        }

                        hoverEnabled: true
                        font.bold: hovered
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item { Layout.fillWidth: true }

                Button {
                    text: "Cancel"
                    flat: true
                    Layout.preferredWidth: 100
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }

                Button {
                    id: mergeBtn
                    text: "Merge"
                    Layout.preferredWidth: 100
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                    Material.foreground: Style.colors.textButton
                    background: Rectangle {
                        implicitHeight: 32
                        color: mergeBtn.hovered ? Style.colors.accentHover : Style.colors.accent
                        radius: 5
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.accepted(noFFRadio.checked)
                            root.close()
                        }
                    }
                }
            }
        }
    }

    onAboutToHide: ffRadio.checked = true
}
