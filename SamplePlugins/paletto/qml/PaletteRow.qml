import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/*! ***********************************************************************************************
 * PaletteRow
 * One saved palette in the library list.
 * ************************************************************************************************/
Rectangle {
    id: root

    //! The editor colors and fonts, passed in by PalettoPage.
    required property PalettoChrome chrome

    /* Property Declarations
     * ****************************************************************************************/
    property string paletteName: ""
    property string baseLabel:   ""
    property int    changes:     0
    property bool   current:     false

    /* Signals
     * ****************************************************************************************/
    signal clicked()
    signal deleteRequested()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: 48
    radius: 8
    color: current ? root.chrome.rowSelected : hover.hovered ? root.chrome.rowHover : "transparent"
    border.width: current ? 1 : 0
    border.color: root.chrome.accent

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 6
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.paletteName
                elide: Text.ElideRight
                font.family: root.chrome.fontText
                font.pixelSize: root.chrome.sizeBody
                font.weight: Font.DemiBold
                color: root.chrome.text
            }

            Text {
                Layout.fillWidth: true
                text: root.baseLabel + "  ·  " + root.changes + (root.changes === 1 ? " change" : " changes")
                elide: Text.ElideRight
                font.family: root.chrome.fontText
                font.pixelSize: root.chrome.sizeMicro
                color: root.chrome.textFaint
            }
        }

        AbstractButton {
            id: deleteButton
            visible: hover.hovered || deleteButton.hovered
            implicitWidth: 26
            implicitHeight: 26
            hoverEnabled: true

            background: Rectangle {
                radius: 6
                color: deleteButton.hovered ? root.chrome.panelRaised : "transparent"
            }
            contentItem: Text {
                text: "" // trash
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: root.chrome.fontIcons
                font.pixelSize: root.chrome.sizeCaption
                color: deleteButton.hovered ? root.chrome.danger : root.chrome.textFaint
            }

            PalettoToolTip {
                visible: deleteButton.hovered
                text: "Delete palette"
            }

            onClicked: root.deleteRequested()
        }
    }
}
