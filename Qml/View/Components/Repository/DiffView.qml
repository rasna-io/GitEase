import QtQuick
import QtQuick.Controls

Rectangle {
    id: diffView
    anchors.fill: parent
    color: "#161616"

    property var diffModel: []

    ListView {
        id: listView
        anchors.fill: parent
        model: diffView.diffModel
        clip: true
        cacheBuffer: 1000 

        delegate: Item {
            width: listView.width
            height: 25

            Row {
                anchors.fill: parent
                
                DiffRow {
                    width: (parent.width / 2) - 0.5
                    text: modelData.type !== 1 ? modelData.content : ""
                    type: modelData.type === 2 ? 2 : 0
                }

                Rectangle {
                    width: 1
                    height: parent.height
                    color: "#2d2d2d"
                }

                DiffRow {
                    width: (parent.width / 2) - 0.5
                    text: modelData.type !== 2 ? modelData.content : ""
                    type: modelData.type === 1 ? 1 : 0
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }
}