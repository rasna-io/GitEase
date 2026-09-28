import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

// This file is compiled into the .dll via qt_add_resources.
// The source text is NOT accessible on the user's disk at runtime.
Rectangle {
    id: root

    property var    pluginManager: null
    property string pluginId:      "com.gitease.repo-notes"

    color:  Style.colors.primaryBackground
    radius: 7
    border.width: 1
    border.color: Style.colors.primaryBorder

    Component.onCompleted: {
        if (pluginManager)
            noteArea.text = pluginManager.pluginSetting(pluginId, "notes", "")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text:           "✎"
                color:          Style.colors.accent
                font.pixelSize: 15
            }
            Label {
                text:             "Repo Notes"
                color:            Style.colors.foreground
                font.family:      Style.fontTypes.inter
                font.pixelSize:   13
                font.bold:        true
                Layout.fillWidth: true
            }
            Label {
                text:           "✕"
                color:          Style.colors.mutedText
                font.pixelSize: 12
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    noteArea.text = ""
                }
            }
        }

        Rectangle {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            radius: 5
            color:  Style.colors.secondaryBackground

            ScrollView {
                anchors.fill:    parent
                anchors.margins: 6
                clip:            true

                TextArea {
                    id:              noteArea
                    wrapMode:        TextArea.Wrap
                    color:           Style.colors.foreground
                    font.family:     Style.fontTypes.inter
                    font.pixelSize:  12
                    placeholderText: "Write notes for this repository…"
                    background:      null
                    padding:         4
                    onTextChanged:   saveTimer.restart()
                }
            }
        }
    }

    Timer {
        id:       saveTimer
        interval: 800
        onTriggered: {
            if (root.pluginManager)
                root.pluginManager.setPluginSetting(
                    root.pluginId, "notes", noteArea.text)
        }
    }
}
