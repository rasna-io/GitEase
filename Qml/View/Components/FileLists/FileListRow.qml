import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * FileListRow
 * A single row in the commit file list.
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property string text
    property bool selected: false

    // Optional file mode (e.g. "M", "A", "D", "R"). Empty = no indicator.
    property string mode: ""
    property bool showSeparator: true

    /* Object Properties
     * ****************************************************************************************/
    property bool isHovered: false
    implicitHeight: 24
    radius: 4
    color: root.selected ? Qt.darker(Style.colors.surfaceLight, 1.06)
                    : (isHovered ? Style.colors.surfaceLight : "transparent")

    /* Signals
     * ****************************************************************************************/
    signal clicked()

    /* Children
     * ****************************************************************************************/

    // Left change indicator color
    readonly property color indicatorColor: (function () {
        switch ((root.mode || "").toString().toUpperCase()) {
            case "A": return Qt.darker(Style.colors.addedFile, 1.5)
            case "D": return Qt.darker(Style.colors.deletededFile, 1.5)
            case "M": return Qt.darker(Style.colors.modifiediedFile, 1.5)
            case "R": return Qt.darker(Style.colors.renamedFile, 1.5)
            case "U": return Qt.darker(Style.colors.untrackedFile, 1.5)
        default:  return "transparent"
        }
    })()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.isHovered = true
        onExited: root.isHovered = false
        onClicked: root.clicked()
    }

    // Change indicator bar (left)
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: root.indicatorColor
        visible: root.mode !== ""
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
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

        // Mode label (right)
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: (root.mode || "").toString().toUpperCase()
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
