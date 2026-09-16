import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * Terminal
 * Embedded shell panel, built on DetachablePanel for its shared header/minimize/detach behavior.
 * ************************************************************************************************/
DetachablePanel {
    id: root

    /* Inline Components
     * ****************************************************************************************/
    component TerminalSession: QtObject {
        property ListModel output:        ListModel {}
        property ListModel history:       ListModel {}
        property int       historyCursor: -1
        property string    draft:         ""
    }

    /* Property Declarations
     * ****************************************************************************************/
    property var                sessions: ({})
    property TerminalSession    activeSession: null
    property TerminalSession    commandSession: null
    property int                fontSize: 13
    property TerminalController terminalController: null
    property string             currentPath: terminalController.workingDirectory + "$ "
    property string             prompt: terminalController ? terminalController.username + "@" + terminalController.hostname + ":"
                                : "user@host:~$ "
    property bool               commandRunning: false

    /* Object Properties
     * ****************************************************************************************/
    title: qsTr("Terminal")
    icon: Style.icons.terminal

    onTerminalControllerChanged: root.showSession(root.terminalController?.workingDirectory ?? "")
    Component.onCompleted:       root.showSession(root.terminalController?.workingDirectory ?? "")

    /* Functions
     * ****************************************************************************************/
    function showSession(key) {
        let session = root.sessions[key]
        if (!session) {
            session = sessionComponent.createObject(root)
            root.sessions[key] = session
        }

        if (session === root.activeSession)
            return

        if (root.activeSession)
            root.activeSession.draft = cmdTextInput.text

        root.activeSession = session
        cmdTextInput.text = session.draft
    }

    /* Children
     * ****************************************************************************************/
    Component {
        id: sessionComponent
        TerminalSession {}
    }

    Connections {
        target: root.terminalController
        function onLineReceived(segmentsJson) {
            const session = root.commandSession ?? root.activeSession
            session.output.append({ segments: JSON.parse(segmentsJson)})
        }
        }

        function onWorkingDirectoryChanged() {
            root.showSession(root.terminalController.workingDirectory)
        }
    }

    Connections {
        target: root
        function onIsMinimizedChanged() {
            if (!root.isMinimized)
                cmdTextInput.forceActiveFocus()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Style.colors.terminalBackground
        radius: 5
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

            ScrollBar.vertical: ScrollBar {
                id: vScrollBar
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 10
                    radius: 2
                    color: vScrollBar.pressed ? "#6e6e6e"
                         : vScrollBar.hovered ? "#5a5a5a"
                         : "#3e3e3e"
                }
                background: Rectangle { color: "transparent" }
            }

            onContentHeightChanged: contentY = Math.max(0, contentHeight - height)

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

                        // Row showing the entered command, not visible for the outputs of the command
                        Row {
                            visible: rowSegments.count === 0

                            Text {
                                width: implicitWidth
                                text: root.prompt
                                color: Style.colors.terminalUserAndHost
                                font.family: Style.fontTypes.jetBrainsMono
                                font.pixelSize: root.fontSize
                                font.bold: true
                            }

                            Text {
                                width: implicitWidth
                                text: root.currentPath
                                color: Style.colors.terminalWorkDir
                                font.family: Style.fontTypes.jetBrainsMono
                                font.pixelSize: root.fontSize
                                font.bold: true
                            }

                            TextEdit {
                                width: implicitWidth
                                text: rowText
                                color: Style.colors.terminalCommand
                                font.family: Style.fontTypes.jetBrainsMono
                                font.pixelSize: root.fontSize
                                wrapMode: TextEdit.WrapAnywhere
                                readOnly: true
                            }
                        }

                        Repeater {
                            model: rowSegments

                            delegate: TextEdit {
                                text: model.text
                                color: model.color !== "" ? model.color : Style.colors.terminalCommand
                                font.family: Style.fontTypes.jetBrainsMono
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
                        font.family: Style.fontTypes.jetBrainsMono
                        font.pixelSize: root.fontSize
                        font.bold: true
                        visible: !root.commandRunning
                    }

                    Text {
                        text: root.currentPath
                        color: Style.colors.terminalWorkDir
                        font.family: Style.fontTypes.jetBrainsMono
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
                        font.family: Style.fontTypes.jetBrainsMono
                        font.pixelSize: root.fontSize
                        cursorVisible: true
                        selectByMouse: true
                        focus: true
                        wrapMode: TextInput.WrapAnywhere
                        visible: !root.commandRunning

                        Keys.onReturnPressed: {
                            if (text.trim() === "") return

                            const session = root.activeSession

                            if (text.trim() === "clear") {
                                session.output.clear()
                                cmdTextInput.text = ""
                                return
                            }

                            session.output.append({
                                segments: [],
                                text: cmdTextInput.text
                            })

                            root.terminalController.sendCommand(text)

                            session.history.append({ text: cmdTextInput.text })
                            cmdTextInput.text = ""
                            session.historyCursor = -1
                        }

                        Keys.onTabPressed: {
                            // TODO
                            return
                        }

                        Keys.onUpPressed: {
                            const session = root.activeSession
                            if (session.history.count === 0) return
                            if (session.historyCursor < session.history.count - 1)
                                session.historyCursor++
                            cmdTextInput.text = session.history.get(session.history.count - 1 - session.historyCursor).text
                        }

                        Keys.onDownPressed: {
                            const session = root.activeSession
                            if (session.historyCursor <= 0) {
                                session.historyCursor = -1
                                cmdTextInput.text = ""
                                return
                            }
                            session.historyCursor--
                            cmdTextInput.text = session.history.get(session.history.count - 1 - session.historyCursor).text
                        }
                    }
                }
            }
        }
    }
}
