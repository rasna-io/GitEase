import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style
import GitEase_Style_Impl
import GitEase.Plugins.QmlHighlighter 1.0

Rectangle {
    id: root

    property var    pluginManager: null
    property string pluginId:      "gitease.qml-highlighter"
    property GuideController guideController: null

    color:        "#1E1E1E"   // VSCode dark background
    radius:       7
    border.width: 1
    border.color: "#3C3C3C"

    // ── Layout ───────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill:    parent
        anchors.margins: 0
        spacing:         0

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "qml_highlighter_tutorial"
            guideName: "QML Highlighter"
            guideIcon: "{ }"
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return root },
                        icon: "{ }",
                        title: "QML Highlighter Dock",
                        description: "View and edit QML files with syntax highlighting. Click the header to expand this dock if it's collapsed.",
                        isInPopup: false,
                        activationDelay: 300,
                    },
                    {
                        targetProvider: function() { return openArea },
                        icon: "⊞",
                        title: "Open QML File",
                        description: "Click to select a .qml file from disk. The file will be loaded with full syntax highlighting."
                    },
                    {
                        targetProvider: function() { return editor },
                        icon: "{ }",
                        title: "Code Editor",
                        description: "Edit QML code with syntax highlighting, line numbers, and scrollable view. Paste code directly or open a file."
                    },
                    {
                        targetProvider: function() { return clearArea },
                        icon: "✕",
                        title: "Clear",
                        description: "Click the ✕ button to clear the editor and start fresh."
                    }
                ]
            }
        }

        // ── Header bar ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth:    true
            height:              36
            color:               "#2D2D2D"
            radius:              7

            // Square bottom corners
            Rectangle {
                anchors.bottom: parent.bottom
                width:          parent.width
                height:         parent.radius
                color:          parent.color
            }

            RowLayout {
                anchors.fill:         parent
                anchors.leftMargin:   12
                anchors.rightMargin:  8
                spacing:              8

                // Icon + title
                Label {
                    text:           "{ }"
                    color:          "#569CD6"
                    font.pixelSize: 14
                    font.bold:      true
                    font.family:    Style.fontTypes.inter
                }
                Label {
                    text:             filePathLabel.text !== "" ? filePathLabel.text : "QML Viewer"
                    color:            "#CCCCCC"
                    font.family:      Style.fontTypes.inter
                    font.pixelSize:   12
                    elide:            Text.ElideLeft
                    Layout.fillWidth: true
                }

                // Open file button
                Rectangle {
                    width:   24
                    height:  24
                    radius:  4
                    color:   openArea.containsMouse ? "#3E3E3E" : "transparent"

                    Label {
                        anchors.centerIn: parent
                        text:             "⊞"
                        color:            "#CCCCCC"
                        font.pixelSize:   16
                    }

                    MouseArea {
                        id:           openArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    fileDialog.open()
                    }
                }

                // Clear button
                Rectangle {
                    width:   24
                    height:  24
                    radius:  4
                    color:   clearArea.containsMouse ? "#3E3E3E" : "transparent"

                    Label {
                        anchors.centerIn: parent
                        text:             "✕"
                        color:            "#CCCCCC"
                        font.pixelSize:   12
                    }

                    MouseArea {
                        id:           clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            editor.text        = ""
                            filePathLabel.text = ""
                        }
                    }
                }
            }
        }

        // ── Editor ───────────────────────────────────────────────────────────
        Item {
            Layout.fillWidth:  true
            Layout.fillHeight: true

            // Line numbers
            Rectangle {
                id:     lineNumbers
                width:  40
                anchors {
                    left:   parent.left
                    top:    parent.top
                    bottom: parent.bottom
                }
                color: "#252526"

                Flickable {
                    anchors.fill:        parent
                    contentY:            editorFlick.contentY
                    interactive:         false
                    clip:                true
                    contentHeight:       editorFlick.contentHeight

                    Column {
                        width: parent.width

                        Repeater {
                            model: editor.lineCount

                            Label {
                                width:           lineNumbers.width
                                height:          Math.ceil(editor.contentHeight / Math.max(editor.lineCount, 1))
                                text:            index + 1
                                color:           "#858585"
                                font.family:     Style.fontTypes.jetBrainsMono
                                font.pixelSize:  13
                                horizontalAlignment: Text.AlignRight
                                rightPadding:    8
                            }
                        }
                    }
                }
            }

            // Code area
            Flickable {
                id: editorFlick
                anchors {
                    left:   lineNumbers.right
                    right:  parent.right
                    top:    parent.top
                    bottom: parent.bottom
                }
                clip:             true
                contentWidth:     editor.contentWidth
                contentHeight:    editor.contentHeight
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior:   Flickable.StopAtBounds

                ScrollBar.vertical:   ScrollBar { policy: ScrollBar.AsNeeded }
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

                Label {
                    visible:        editor.text.length === 0
                    text:           "Open a .qml file or paste code here…"
                    color:          "#555555"
                    font.family:    Style.fontTypes.jetBrainsMono
                    font.pixelSize: 13
                    topPadding:     4
                    leftPadding:    8
                }

                TextEdit {
                    id:          editor
                    width:       Math.max(editorFlick.width, contentWidth)
                    topPadding:  4
                    leftPadding: 8
                    readOnly:    false
                    wrapMode:    TextEdit.NoWrap
                    color:       "#D4D4D4"
                    selectionColor:         "#264F78"
                    selectedTextColor:      "#D4D4D4"
                    font.family:            Style.fontTypes.jetBrainsMono
                    font.pixelSize:         13
                    // ── Syntax highlighter bound to this editor ───────────────
                    QmlSyntaxHighlighter {
                        textDocument: editor.textDocument
                    }
                }
            }
        }
    }

    // ── Invisible state ───────────────────────────────────────────────────────
    Label { id: filePathLabel; visible: false; text: "" }

    // ── File picker ───────────────────────────────────────────────────────────
    FileDialog {
        id:           fileDialog
        title:        "Open QML File"
        nameFilters:  ["QML files (*.qml)", "All files (*)"]
        onAccepted: {
            const path = selectedFile.toString().replace("file:///", "")
            filePathLabel.text = path
            var xhr = new XMLHttpRequest()
            xhr.open("GET", selectedFile)
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE)
                    editor.text = xhr.responseText
            }
            xhr.send()
        }
    }
}
