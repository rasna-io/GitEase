import QtQuick
import QtQuick.Controls

/*! ***********************************************************************************************
 * PalettoSegmented
 * A row of mutually exclusive options.
 *
 *   PalettoSegmented {
 *       options: [ { key: "a", label: "A" }, { key: "b", label: "B" } ]
 *       currentKey: "a"
 *       onSelected: function(key) { ... }
 *   }
 * ************************************************************************************************/
Rectangle {
    id: root

    //! The editor colors and fonts, passed in by PalettoPage.
    required property PalettoChrome chrome

    property var    options:    []
    property string currentKey: ""

    /* Signals
     * ****************************************************************************************/
    signal selected(string key)

    implicitHeight: 30
    implicitWidth: row.implicitWidth + 6
    radius: 8
    color: root.chrome.field
    border.width: 1
    border.color: root.chrome.border

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.options

            delegate: AbstractButton {
                id: segment

                required property var modelData

                readonly property bool current: segment.modelData.key === root.currentKey

                implicitHeight: 24
                implicitWidth: label.implicitWidth + 22
                hoverEnabled: true
                text: segment.modelData.label

                background: Rectangle {
                    radius: 6
                    color: segment.current ? root.chrome.accent
                         : segment.hovered ? root.chrome.rowHover : "transparent"
                }

                contentItem: Text {
                    id: label
                    text: segment.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: root.chrome.fontText
                    font.pixelSize: root.chrome.sizeCaption
                    font.weight: segment.current ? Font.DemiBold : Font.Medium
                    color: segment.current ? root.chrome.accentText : root.chrome.textDim
                }

                onClicked: root.selected(segment.modelData.key)

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
