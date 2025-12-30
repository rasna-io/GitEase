import QtQuick
import QtQuick.Layouts

RowLayout {
    property alias text: label.text
    property int type: 0 // 0: normal, 1: added, 2: deleted
    property string bgColor: type === 1 ? "#2d4a2d" : (type === 2 ? "#4b1818" : "transparent")
    
    width: parent.width
    spacing: 0

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 20
        color: bgColor

        Text {
            id: label
            anchors.fill: parent
            anchors.leftMargin: 10
            font.family: "Consolas, 'Courier New', monospace"
            color: "#d4d4d4"
            verticalAlignment: Text.AlignVCenter
        }
    }
}
