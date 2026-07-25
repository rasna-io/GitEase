import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * FileListRow
 * Generic row for a file list section.
 * - Handles selection click + hover highlight
 * - Shows mode indicator and optional extra right-side content
 * ************************************************************************************************/

Rectangle {
    id: root
    clip: true

    /* Property Declarations
     * ****************************************************************************************/
    required property string text
    property bool selected: false

    // Optional file status (e.g. "M", "A", "D", "R"). Empty = no indicator.
    property real status

    // Row context (populated by FileListSection's delegate)
    property var rowModelData: null
    property int rowIndex: -1

    // Optional right-side content injected by specialized rows.
    property Component rightAccessory: null

    /* Object Properties
     * ****************************************************************************************/
    readonly property bool isHovered: hoverHandler.hovered
    implicitHeight: 24
    radius: 4
    color: root.selected ? Style.colors.subtleAzureGlow
                    : (isHovered ? Style.colors.rowHoverBg : "transparent")

    readonly property color statusColor: (function () {
        switch (root.status) {
            case GitFileStatus.StagedNew:
                return Style.colors.stageGreen
            case GitFileStatus.Deleted:
            case GitFileStatus.StagedDeleted:
                return Style.colors.discardRed
            case GitFileStatus.Modified:
            case GitFileStatus.TypeChange:
            case GitFileStatus.StagedModified:
                return Style.colors.stashAmber
            case GitFileStatus.Renamed:
            case GitFileStatus.StagedRenamed:
                return Style.colors.renamedFile
            case GitFileStatus.Untracked:
                return Style.colors.openBlue
            default:
                return "transparent"
        }
    })()

    readonly property string statusLetter: (function () {
        switch (root.status) {
            case GitFileStatus.StagedNew:
                return "A"
            case GitFileStatus.Deleted:
            case GitFileStatus.StagedDeleted:
                return "D"
            case GitFileStatus.Modified:
            case GitFileStatus.TypeChange:
            case GitFileStatus.StagedModified:
                return "M"
            case GitFileStatus.Renamed:
            case GitFileStatus.StagedRenamed:
                return "R"
            case GitFileStatus.Untracked:
                return "U"
            default:
                return ""
        }
    })()

    /* Signals
     * ****************************************************************************************/
    signal clicked()

    /* Children
     * ****************************************************************************************/
    HoverHandler {
        id: hoverHandler
        acceptedDevices: PointerDevice.Mouse
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 6
        spacing: 6

        // Status letter badge
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 16
            height: 16
            radius: 3
            color: Qt.rgba(root.statusColor.r, root.statusColor.g, root.statusColor.b, 0.10)
            visible: root.statusLetter !== ""

            Text {
                anchors.centerIn: parent
                text: root.statusLetter
                font.family: Style.fontTypes.jetBrainsMono
                font.pixelSize: Style.appFont.secondaryPt
                font.bold: true
                color: root.statusColor
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            text: root.text
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.mediumPt
            color: Style.colors.secondaryText
            elide: Text.ElideRight
        }

        Loader {
            id: accessoryLoader
            Layout.alignment: Qt.AlignVCenter
            active: root.rightAccessory !== null
            sourceComponent: root.rightAccessory
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: {
                switch (root.status) {
                case GitFileStatus.StagedNew:
                    return "A";
                case GitFileStatus.Deleted:
                case GitFileStatus.StagedDeleted:
                    return "D";
                case GitFileStatus.Modified:
                case GitFileStatus.TypeChange:
                case GitFileStatus.StagedModified:
                    return "M";
                case GitFileStatus.Renamed:
                case GitFileStatus.StagedRenamed:
                    return "R";
                case GitFileStatus.Untracked:
                    return "U";
                default:
                    return ""
                }
            }
            visible: text !== ""
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.defaultPt
            font.bold: true
            color: root.indicatorColor
        }
    }
}
