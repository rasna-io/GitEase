import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import GitEase
import GitEase_Style

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int historyCursor: -1
    property bool isMinimized: false
    readonly property int headerHeight: 35
    property TerminalController terminalController: null
    property string currentPath: terminalController.workingDirectory + "$ "
    property string prompt: terminalController
                            ? terminalController.username + "@" + terminalController.hostname + ":"
                            : "user@host:~$ "
    property bool commandRunning: false


    /* Signals
     * ****************************************************************************************/
    signal minimizeRequested()
    signal expandRequested()

    /* Children
     * ****************************************************************************************/
    Connections {
        target: root.terminalController
        function onLineReceived(segmentsJson, type) {
            outputModel.append({ segments: JSON.parse(segmentsJson)})
        }

        function onOutputReceived(text, type) {
            outputModel.append({ segments: [{ text: text, color: "", bold: false }]})
        }

        function onCommandStarted() { root.commandRunning = true }
        function onCommandFinished() { root.commandRunning = false }
    }

    onHeightChanged: {
        if(root.height > headerHeight)
        {
            isMinimized = false
        } else {
            isMinimized = true
        }
    }

    ListModel { id: historyModel }
    ListModel { id: outputModel }

    Rectangle {
        anchors.fill: parent
        color: Style.colors.terminalBackground
        radius: 5

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            Rectangle {
                Layout.fillWidth: true
                height: root.headerHeight
                color: Style.colors.secondaryBackground

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Label {
                        text: "Terminal"
                        color: Style.colors.foreground
                        font.family: Style.fontTypes.roboto
                        font.weight: 500
                        font.pixelSize: 10
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 4
                        color: btnHover.containsMouse ? "#3c3c3c" : "transparent"
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: root.isMinimized ? "▲" : "▼"
                            color: btnHover.containsMouse ? "#ffffff" : "#aaaaaa"
                            font.pixelSize: 9
                        }

                        HoverHandler { id: btnHover }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.isMinimized) {
                                    root.expandRequested()
                                    textInputId.forceActiveFocus()
                                } else {
                                    root.minimizeRequested()
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: !root.isMinimized
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: "#333333"
                }
            }

            // Terminal content
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.isMinimized
                clip: true

                Flickable {
                    id: flickable
                    anchors {
                        fill: parent
                        margins: 10
                        rightMargin: 14
                    }
                    contentHeight: contentColumn.implicitHeight
                    clip: true

                    onContentHeightChanged: {
                        if (contentHeight > height)
                            contentY = contentHeight - height
                    }

                    Column {
                        id: contentColumn
                        width: flickable.width
                        spacing: 2

                        // Output rows
                        Repeater {
                            model: outputModel
                            delegate: Row {
                                width: contentColumn.width
                                spacing: 0

                                property var rowSegments: model.segments
                                property var rowText: model.text

                                Text {
                                    visible: rowSegments.count === 0
                                    width: visible ? implicitWidth : 0
                                    text: root.prompt
                                    color: Style.colors.terminalUserAndHost
                                    font.family: Style.fontTypes.monospace
                                    font.pixelSize: 13
                                }
                                Text {
                                    visible: rowSegments.count === 0
                                    width: visible ? implicitWidth : 0
                                    text: root.currentPath
                                    color: Style.colors.terminalWorkDir
                                    font.family: Style.fontTypes.monospace
                                    font.pixelSize: 13
                                }
                                Text {
                                    visible: rowSegments.count === 0
                                    width: visible ? implicitWidth : 0
                                    text: rowText
                                    color: Style.colors.terminalCommand
                                    font.family: Style.fontTypes.monospace
                                    font.pixelSize: 13
                                }

                                Repeater {
                                    model: rowSegments

                                    delegate: Text {
                                        text: model.text
                                        color: model.color !== "" ? model.color : Style.colors.terminalCommand
                                        font.family: Style.fontTypes.monospace
                                        font.pixelSize: 13
                                        font.bold: model.bold
                                    }
                                }
                            }
                        }

                        // Input row
                        RowLayout {
                            width: contentColumn.width
                            spacing: 0

                            Text {
                                id: promptLabel
                                text: root.prompt
                                color: Style.colors.terminalUserAndHost
                                font.family: Style.fontTypes.monospace
                                font.pixelSize: 13
                                font.bold: true
                                visible: !root.commandRunning
                            }

                            Text {
                                text: root.currentPath
                                color: Style.colors.terminalWorkDir
                                font.family: Style.fontTypes.monospace
                                font.pixelSize: 13
                                font.bold: true
                                visible: !root.commandRunning
                            }

                            Row {
                                visible: root.commandRunning
                                spacing: 4

                                Repeater {
                                    model: 3
                                    delegate: Rectangle {
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: Style.colors.terminalUserAndHost

                                        SequentialAnimation on opacity {
                                            running: root.commandRunning
                                            loops: Animation.Infinite
                                            NumberAnimation { to: 0.2; duration: 400 }
                                            NumberAnimation { to: 1.0; duration: 400 }
                                            PauseAnimation { duration: index * 150 }
                                        }
                                    }
                                }
                            }

                            TextInput {
                                id: textInputId
                                Layout.fillWidth: true
                                color: Style.colors.terminalCommand
                                font.family: Style.fontTypes.monospace
                                font.pixelSize: 13
                                cursorVisible: true
                                selectByMouse: true
                                selectionColor: "#264f78"
                                selectedTextColor: "#ffffff"
                                focus: true
                                wrapMode: TextInput.WrapAnywhere
                                visible: !root.commandRunning

                                Keys.onReturnPressed: {
                                    if (text.trim() === "") return

                                    if (text.trim() === "clear") {
                                        outputModel.clear()
                                        textInputId.text = ""
                                        return
                                    }

                                    // Track cd commands
                                    if (text.trim().startsWith("cd ")) {
                                        // Can't reliably resolve path in QML — ask backend
                                        root.terminalController.sendCommand("cd " + text.trim().mid(3) + " && pwd")
                                    } else {
                                        root.terminalController.sendCommand(text)
                                    }

                                    outputModel.append({
                                        segments: [],
                                        text: textInputId.text
                                    })
                                    historyModel.append({ text: textInputId.text })
                                    textInputId.text = ""
                                    historyCursor = -1
                                }

                                Keys.onTabPressed: {

                                }

                                Keys.onUpPressed: {
                                    if (historyModel.count === 0) return
                                    if (historyCursor < historyModel.count - 1)
                                        historyCursor++
                                    textInputId.text = historyModel.get(historyModel.count - 1 - historyCursor).text
                                }

                                Keys.onDownPressed: {
                                    if (historyCursor <= 0) {
                                        historyCursor = -1
                                        textInputId.text = ""
                                        return
                                    }
                                    historyCursor--
                                    textInputId.text = historyModel.get(historyModel.count - 1 - historyCursor).text
                                }
                            }
                        }
                    }
                }
                ScrollBar {
                    id: vScrollBar
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        rightMargin: 2
                    }
                    policy: ScrollBar.AsNeeded
                    orientation: Qt.Vertical
                    contentItem: Rectangle {
                        implicitWidth: 10
                        radius: 2
                        color: vScrollBar.pressed ? "#6e6e6e"
                             : vScrollBar.hovered ? "#5a5a5a"
                             : "#3e3e3e"
                    }
                    background: Rectangle { color: "transparent" }
                }

                Binding {
                    target: flickable
                    property: "ScrollBar.vertical"
                    value: vScrollBar
                }
            }
        }
    }
}