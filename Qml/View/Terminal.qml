import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import GitEase
import GitEase_Style

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int                historyCursor: -1
    property bool               isMinimized: false
    property int                fontSize: 13
    readonly property int       headerHeight: 35
    property TerminalController terminalController: null
    property string             currentPath: terminalController.workingDirectory + "$ "
    property string             prompt: terminalController ? terminalController.username + "@" + terminalController.hostname + ":"
                                : "user@host:~$ "
    property bool               commandRunning: false


    /* Signals
     * ****************************************************************************************/
    signal minimizeRequested()
    signal expandRequested()

    /* Children
     * ****************************************************************************************/
    Connections {
        target: root.terminalController
        function onLineReceived(segmentsJson) {
            outputModel.append({ segments: JSON.parse(segmentsJson)})
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
            TerminalHeader {
                Layout.fillWidth: true
                height: root.headerHeight
                color: Style.colors.secondaryBackground
                isMinimized: root.isMinimized
                onMinimizeRequested: root.minimizeRequested()
                onExpandRequested: {
                    root.expandRequested()
                    cmdTextInput.forceActiveFocus()
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
                                    font.pixelSize: root.fontSize
                                    font.bold: true
                                }

                                Text {
                                    visible: rowSegments.count === 0
                                    width: visible ? implicitWidth : 0
                                    text: root.currentPath
                                    color: Style.colors.terminalWorkDir
                                    font.family: Style.fontTypes.monospace
                                    font.pixelSize: root.fontSize
                                    font.bold: true
                                }

                                TextEdit {
                                    visible: rowSegments.count === 0
                                    width: visible ? implicitWidth : 0
                                    text: rowText
                                    color: Style.colors.terminalCommand
                                    font.family: Style.fontTypes.monospace
                                    font.pixelSize: root.fontSize
                                    wrapMode: TextEdit.WrapAnywhere
                                    readOnly: true
                                }

                                Repeater {
                                    model: rowSegments

                                    delegate: TextEdit {
                                        text: model.text
                                        color: model.color !== "" ? model.color : Style.colors.terminalCommand
                                        font.family: Style.fontTypes.monospace
                                        font.pixelSize: root.fontSize
                                        wrapMode: TextEdit.WrapAnywhere
                                        readOnly: true
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
                                font.pixelSize: root.fontSize
                                font.bold: true
                                visible: !root.commandRunning
                            }

                            Text {
                                text: root.currentPath
                                color: Style.colors.terminalWorkDir
                                font.family: Style.fontTypes.monospace
                                font.pixelSize: root.fontSize
                                font.bold: true
                                visible: !root.commandRunning
                            }

                            // Busy waiter, showing while command is running
                            Item {
                                visible: root.commandRunning
                                Layout.fillWidth: true
                                Layout.preferredHeight: 20

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Repeater {
                                        model: 3
                                        delegate: Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: Style.colors.terminalUserAndHost
                                            anchors.verticalCenter: parent.verticalCenter

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
                            }

                            TextInput {
                                id: cmdTextInput
                                Layout.fillWidth: true
                                color: Style.colors.terminalCommand
                                font.family: Style.fontTypes.monospace
                                font.pixelSize: root.fontSize
                                cursorVisible: true
                                selectByMouse: true
                                focus: true
                                wrapMode: TextInput.WrapAnywhere
                                visible: !root.commandRunning

                                Keys.onReturnPressed: {
                                    if (text.trim() === "") return

                                    if (text.trim() === "clear") {
                                        outputModel.clear()
                                        cmdTextInput.text = ""
                                        return
                                    }

                                    outputModel.append({
                                        segments: [],
                                        text: cmdTextInput.text
                                    })

                                    root.terminalController.sendCommand(text)

                                    historyModel.append({ text: cmdTextInput.text })
                                    cmdTextInput.text = ""
                                    historyCursor = -1
                                }

                                Keys.onUpPressed: {
                                    if (historyModel.count === 0) return
                                    if (historyCursor < historyModel.count - 1)
                                        historyCursor++
                                    cmdTextInput.text = historyModel.get(historyModel.count - 1 - historyCursor).text
                                }

                                Keys.onDownPressed: {
                                    if (historyCursor <= 0) {
                                        historyCursor = -1
                                        cmdTextInput.text = ""
                                        return
                                    }
                                    historyCursor--
                                    cmdTextInput.text = historyModel.get(historyModel.count - 1 - historyCursor).text
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