import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * WorktreesTab
 * UI only — lists the active repository's worktrees and an "add" affordance. No backend wiring.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property AppModel appModel

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: col.implicitHeight + 32

    /* Functions
     * ****************************************************************************************/
    function reset() {}

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: col
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Active repository:"
                font.family: Style.fontTypes.inter
                font.pixelSize: 12
                color: Style.colors.mutedText
            }

            Text {
                text: root.appModel?.currentRepository?.name ?? "—"
                font.family: Style.fontTypes.inter
                font.weight: Font.DemiBold
                font.pixelSize: 12
                color: Style.colors.accent
            }

            Text {
                Layout.fillWidth: true
                text: root.appModel?.currentRepository?.path
                      ? "— " + root.appModel.currentRepository.path
                      : ""
                elide: Text.ElideRight
                font.family: Style.fontTypes.inter
                font.pixelSize: 12
                color: Style.colors.mutedText
            }
        }

        WorktreeCard {
            Layout.fillWidth: true
            branchName: "main"
            path: root.appModel?.currentRepository?.path ?? "C:/work/repo"
            isPrimary: true
        }

        // Add new worktree (mock)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 8
            color: addWtMouse.containsMouse
                   ? Qt.rgba(Style.colors.foreground.r, Style.colors.foreground.g, Style.colors.foreground.b, 0.04)
                   : "transparent"
            border.width: 1
            border.color: Style.colors.controlBorder

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                spacing: 8

                Text {
                    text: Style.icons.plus
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: 11
                    color: addWtMouse.containsMouse ? Style.colors.foreground : Style.colors.mutedText
                }

                Text {
                    text: "Add new worktree"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: 12
                    color: addWtMouse.containsMouse ? Style.colors.foreground : Style.colors.mutedText
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: addWtMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
