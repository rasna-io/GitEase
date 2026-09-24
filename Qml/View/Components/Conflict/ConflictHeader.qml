import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ConflictHeader
 * Title block of the conflict window: what operation is running, which commit it stopped on, and the
 * window commands.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string title:              ""
    property string applyingSubject:    ""
    property string commitHash:         ""
    property string ontoRef:            ""
    property string positionText:       ""

    property WindowController windowController: null

    /* Signals
     * ****************************************************************************************/
    signal closeRequested()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: titleColumn.implicitHeight

    /* Children
     * ****************************************************************************************/
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressed: root.windowController?.startSystemMove()
        onDoubleClicked: root.windowController?.toggleMaxRestore()
    }

    ColumnLayout {
        id: titleColumn
        anchors.left: parent.left
        anchors.right: commandRow.left
        anchors.top: parent.top
        anchors.rightMargin: 12
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Style.colors.foreground
            font.family: Style.fontTypes.inter
            font.weight: Font.DemiBold
            font.pointSize: Style.appFont.h4Pt
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.applyingSubject !== ""
            spacing: 6

            Text {
                text: "Applying:"
                color: Style.colors.conflictSectionLabel
                font.family: Style.fontTypes.jetBrainsMono
                font.pixelSize: Style.appFont.captionPt
            }

            Text {
                Layout.fillWidth: true
                text: `"${root.applyingSubject}"`
                color: Style.colors.mutedText
                font.family: Style.fontTypes.jetBrainsMono
                font.pixelSize: Style.appFont.captionPt
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.commitHash !== "" || root.positionText !== ""
            spacing: 8

            Text {
                visible: root.commitHash !== ""
                text: root.commitHash
                color: Style.colors.conflictProgressFiles
                font.family: Style.fontTypes.jetBrainsMono
                font.weight: Font.DemiBold
                font.pixelSize: Style.appFont.captionPt
            }

            Text {
                visible: root.ontoRef !== ""
                text: "onto"
                color: Style.colors.conflictSectionLabel
                font.family: Style.fontTypes.jetBrainsMono
                font.pixelSize: Style.appFont.captionPt
            }

            Text {
                visible: root.ontoRef !== ""
                text: root.ontoRef
                color: Style.colors.foreground
                font.family: Style.fontTypes.jetBrainsMono
                font.weight: Font.DemiBold
                font.pixelSize: Style.appFont.captionPt
            }

            Text {
                visible: root.positionText !== ""
                Layout.leftMargin: 6
                text: root.positionText
                color: Style.colors.conflictCardOpenBorder
                font.family: Style.fontTypes.jetBrainsMono
                font.weight: Font.DemiBold
                font.pixelSize: Style.appFont.captionPt
            }

            Item { Layout.fillWidth: true }
        }
    }

    RowLayout {
        id: commandRow
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 6

        WindowsButton {
            id: minimizeButton
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            Material.accent: Style.colors.windowsMinimize
            onClicked: root.windowController?.minimize()

            content: Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 2
                radius: 1
                color: minimizeButton.containsMouse ? Style.colors.primaryBackground
                                                    : Style.colors.foreground
            }
        }

        WindowsButton {
            id: closeButton
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            Material.accent: Style.colors.windowsClose
            onClicked: root.closeRequested()

            content: Item {
                anchors.centerIn: parent
                width: 10
                height: 10

                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 2
                    radius: 1
                    rotation: 45
                    color: closeButton.containsMouse ? Style.colors.primaryBackground
                                                     : Style.colors.foreground
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 2
                    radius: 1
                    rotation: -45
                    color: closeButton.containsMouse ? Style.colors.primaryBackground
                                                     : Style.colors.foreground
                }
            }
        }
    }
}
