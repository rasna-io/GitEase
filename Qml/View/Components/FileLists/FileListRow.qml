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
    property bool showSeparator: true

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
    color: root.selected ? Qt.darker(Style.colors.surfaceLight, 1.06)
                    : (isHovered ? Style.colors.surfaceLight : "transparent")

    // Left change indicator color
    readonly property color indicatorColor: (function () {
        switch ((root.mode || "").toString().toUpperCase()) {
            case GitFileStatus.ADDED:
                return Qt.darker(Style.colors.addedFile, 1.5)
            case GitFileStatus.DELETED:
                return Qt.darker(Style.colors.deletededFile, 1.5)
            case GitFileStatus.MODIFIED:
                return Qt.darker(Style.colors.modifiediedFile, 1.5)
            case GitFileStatus.RENAMED:
                return Qt.darker(Style.colors.renamedFile, 1.5)
            case GitFileStatus.UNTRACKED:
                return Qt.darker(Style.colors.untrackedFile, 1.5)
            default:
                return "transparent"
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

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: root.indicatorColor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 6
        spacing: 8

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            text: root.text
            font.family: Style.fontTypes.roboto
            font.pixelSize: 12
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
                switch (root.mode) {
                case GitFileStatus.ADDED:
                    return "A";
                case GitFileStatus.DELETED:
                    return "D";
                case GitFileStatus.MODIFIED:
                    return "M";
                case GitFileStatus.RENAMED:
                    return "R";
                case GitFileStatus.UNTRACKED:
                    return "U";
                default:
                    return ""
                }
            }
            visible: text !== ""
            font.family: Style.fontTypes.roboto
            font.pixelSize: 11
            font.bold: true
            color: root.indicatorColor
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Style.colors.primaryBorder
        opacity: 0.45
        visible: root.showSeparator
    }
}
