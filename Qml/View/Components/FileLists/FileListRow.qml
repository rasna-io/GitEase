import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * FileListRow
 * Generic row for a file list section.
 * - Handles selection click + hover highlight
 * - Shows a colored status letter badge and optional extra right-side content
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
    implicitHeight: 28
    color: root.selected ? Style.colors.subtleAzureGlow
                    : (isHovered ? Style.colors.rowHoverBg : "transparent")

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
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 6
        spacing: 6

        // Status letter badge
        FileStatusTag {
            compact: true
            showBackground: true
            fileStatus: root.status
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            text: root.text
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.smallPt
            color: Style.colors.filePathText
            elide: Text.ElideRight
        }

        Loader {
            id: accessoryLoader
            Layout.alignment: Qt.AlignVCenter
            active: root.rightAccessory !== null
            sourceComponent: root.rightAccessory
        }
    }
}
