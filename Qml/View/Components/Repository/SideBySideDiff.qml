import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property var diffData: []
    color: "#1e1e1e"

    Component {
        id: diagonalHatch
        Canvas {
            anchors.fill: parent
            opacity: 0.2
            onPaint: {
                var ctx = getContext("2d");
                ctx.strokeStyle = "#ffffff";
                ctx.lineWidth = 1;
                ctx.beginPath();
                var step = 10;
                for (var i = -height; i < width + height; i += step) {
                    ctx.moveTo(i + height, 0);
                    ctx.lineTo(i, height);
                }
                ctx.stroke();
            }
        }
    }

    ListView {
        id: diffList
        anchors.fill: parent
        model: root.diffData
        clip: true
        delegate: Item {
            width: diffList.width
            height: 22

            Row {
                anchors.fill: parent

                // Left side
                Rectangle {
                    width: parent.width / 2; height: 22
                    color: (modelData.type === 2 || modelData.type === 3) ? "#4b1818" : (modelData.type === 1 ? "#1a1a1a" : "transparent")

                    Loader {
                        anchors.fill: parent;
                        sourceComponent: modelData.type === 1 ? diagonalHatch : null
                        active: modelData.type === 1
                    }

                    Row {
                        anchors.fill: parent; spacing: 8
                        Text {
                            width: 35; text: modelData.oldLine !== -1 ? modelData.oldLine : ""
                            color: "#606060"; font.pixelSize: 10; horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.type !== 1 ? modelData.content : ""
                            color: "#d4d4d4"; font.family: "Consolas"; font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Middle side
                Rectangle { width: 1; height: 22; color: "#2d2d2d" }

                // Right side
                Rectangle {
                    width: (parent.width / 2) - 1; height: 22
                    color: (modelData.type === 1 || modelData.type === 3) ? "#2d4a2d" : (modelData.type === 2 ? "#1a1a1a" : "transparent")

                    Loader {
                        anchors.fill: parent;
                        sourceComponent: modelData.type === 2 ? diagonalHatch : null
                        active: modelData.type === 2
                    }

                    Row {
                        anchors.fill: parent; spacing: 8
                        Text {
                            width: 35; text: modelData.newLine !== -1 ? modelData.newLine : ""
                            color: "#606060"; font.pixelSize: 10; horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.type === 3 ? modelData.contentNew : (modelData.type !== 2 ? modelData.content : "")
                            color: "#d4d4d4"; font.family: "Consolas"; font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
    }
}
