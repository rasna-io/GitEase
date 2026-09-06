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
    property GuideController guideController: null

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

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "repo_notes_tutorial"
            guideName: "Repo Notes"
            guideIcon: Style.icons.note
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return root },
                        icon: Style.icons.note,
                        title: "Repo Notes Dock",
                        description: "Write and save free-form notes for this repository. Click the header to expand this dock if it's collapsed.",
                        isInPopup: false,
                        activationDelay: 300,
                        onActivate: function() { }
                    },
                    {
                        targetProvider: function() { return noteArea },
                        icon: Style.icons.edit,
                        title: "Write Notes",
                        description: "Type anything here — commit ideas, TODOs, links, or reminders. Notes are auto-saved per repository and persist across restarts."
                    },
                    {
                        targetProvider: function() { return clearBtn },
                        icon: Style.icons.trash,
                        title: "Clear Notes",
                        description: "Click the ✕ button to erase all notes for this repository."
                    }
                ]
            }
        }

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
                id: clearBtn
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
