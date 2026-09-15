import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * WorktreeCard
 * A single worktree entry: folder icon, branch name (+ optional "primary" badge), path and an
 * Open action. Presentation only — the host wires onOpenClicked.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string branchName: "main"
    property string path:       ""
    property bool   isPrimary:  false

    /* Signals
     * ****************************************************************************************/
    signal openClicked()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: 64
    radius: 10
    color: Style.colors.secondaryBackground
    border.width: 1
    border.color: Style.colors.primaryBorder

    /* Children
     * ****************************************************************************************/
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 12
        spacing: 12

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: Style.icons.folder
            font.family: Style.fontTypes.font6Pro
            font.pixelSize: 13
            color: Style.colors.mutedText
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: root.branchName
                    font.family: Style.fontTypes.inter
                    font.weight: Font.DemiBold
                    font.pixelSize: 12
                    color: Style.colors.foreground
                }

                Rectangle {
                    visible: root.isPrimary
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: primaryText.implicitWidth + 12
                    implicitHeight: 15
                    radius: 4
                    color: Style.colors.accent

                    Text {
                        id: primaryText
                        anchors.centerIn: parent
                        text: "primary"
                        font.family: Style.fontTypes.inter
                        font.weight: 700
                        font.pixelSize: 8
                        color: "#FFFFFF"
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.path
                elide: Text.ElideRight
                font.family: Style.fontTypes.inter
                font.pixelSize: 10
                color: Style.colors.mutedText
            }
        }

        RepoBrowseButton {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 66
            text: "Open"
            onClicked: root.openClicked()
        }
    }
}
