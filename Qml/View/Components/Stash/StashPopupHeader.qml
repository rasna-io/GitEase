import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * StashPopupHeader
 * Title block of the stash windows: what the window is about, a mono metadata line underneath, and
 * the close command. Mirrors ConflictHeader so both flows read the same.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string title:      ""
    property string stashRef:   ""
    property string metaText:   ""

    /* Signals
     * ****************************************************************************************/
    signal closeRequested()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: Math.max(titleColumn.implicitHeight, closeButton.height)

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: titleColumn
        anchors.left: parent.left
        anchors.right: closeButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 12
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                visible: root.stashRef !== ""
                text: root.stashRef
                color: Style.colors.mutedText
                font.family: Style.fontTypes.jetBrainsMono
                font.pixelSize: Style.appFont.captionPt
            }

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Style.colors.foreground
                font.family: Style.fontTypes.inter
                font.weight: Font.DemiBold
                font.pixelSize: Style.appFont.mediumPt
                elide: Text.ElideRight
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.metaText !== ""
            text: root.metaText
            color: Style.colors.mutedText
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.captionPt
            elide: Text.ElideRight
        }
    }

    WindowsButton {
        id: closeButton

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 22

        Material.accent: Style.colors.windowsClose

        content: Item {
            width: 10
            height: 10

            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 2
                radius: 1
                rotation: 45
                color: closeButton.containsMouse ? Style.colors.primaryBackground
                                                 : Style.colors.foreground
            }

            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 2
                radius: 1
                rotation: -45
                color: closeButton.containsMouse ? Style.colors.primaryBackground
                                                 : Style.colors.foreground
            }
        }

        onClicked: root.closeRequested()
    }
}
