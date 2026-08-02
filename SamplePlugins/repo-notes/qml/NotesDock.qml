import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*!
 * Repo Notes — sample QML-only plugin dock
 *
 * Stores free-form text notes per plugin instance.
 * PluginDockHost sets `pluginManager` and `pluginId` after loading.
 *
 * To install for testing, copy the repo-notes/ folder into:
 *   Windows : %APPDATA%\GitEase\GitEase\plugins\
 *   Linux   : ~/.local/share/GitEase/GitEase/plugins/
 * or place it in <app binary dir>/plugins/
 */
Rectangle {
    id: root

    // Injected by PluginDockHost after component creation
    property var    pluginManager: null
    property string pluginId:      "com.gitease.repo-notes"

    readonly property string settingKey: "notes"

    color:  Style.colors.primaryBackground
    radius: 7
    border.width: 1
    border.color: Style.colors.primaryBorder

    // ── Load persisted notes when the dock is ready ──────────────────────────
    Component.onCompleted: {
        if (pluginManager)
            noteArea.text = pluginManager.pluginSetting(pluginId, settingKey, "")
    }

    // ── Layout ───────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text:            Style.icons.note ?? "✎"
                color:           Style.colors.accent
                font.family:     Style.fontTypes.font6Pro
                font.pixelSize:  15
            }

            Label {
                text:            "Repo Notes"
                color:           Style.colors.foreground
                font.family:     Style.fontTypes.inter
                font.pixelSize:  13
                font.bold:       true
                Layout.fillWidth: true
            }

            // Clear button
            Label {
                text:           "✕"
                color:          Style.colors.mutedText
                font.pixelSize: 12

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: noteArea.text = ""
                }
            }
        }

        // Note area
        Rectangle {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            radius: 5
            color:  Style.colors.secondaryBackground

            ScrollView {
                anchors.fill: parent
                anchors.margins: 6
                clip: true

                TextArea {
                    id: noteArea

                    wrapMode:        TextArea.Wrap
                    color:           Style.colors.foreground
                    font.family:     Style.fontTypes.inter
                    font.pixelSize:  12
                    placeholderText: "Write notes for this repository…"
                    background:      null
                    padding:         4

                    // Persist on every change with a small debounce
                    onTextChanged: saveTimer.restart()
                }
            }
        }
    }

    // ── Debounced save ───────────────────────────────────────────────────────
    Timer {
        id: saveTimer
        interval: 800
        repeat:   false
        onTriggered: {
            if (root.pluginManager)
                root.pluginManager.setPluginSetting(
                    root.pluginId, root.settingKey, noteArea.text)
        }
    }
}
