import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*!
 * StatsPage — plugin page that demonstrates:
 *   - IPagePlugin registration (this page appears in the NavigationRail)
 *   - Event bus subscription (live feed of "commit.selected" and "branch.changed" events)
 *   - Access to injected controllers
 */
Item {
    id: root

    // Injected by MainWindow.qml — same as any built-in page
    property var eventBus:              null   // = pluginManager (event bus API)
    property var repositoryController: null
    property var branchController:     null
    property var pluginController:     null

    // ── Event bus subscriptions ───────────────────────────────────────────────
    property int _commitToken:  -1
    property int _branchToken:  -1
    property int _repoToken:    -1

    property var eventLog: []   // list of {time, text} strings shown in the feed

    Component.onCompleted: {
        if (root.eventBus) {
            root._commitToken = root.eventBus.subscribeEvent("commit.selected", function(payload) {
                addEvent("commit.selected → " + (payload.hash || "?").substring(0, 7))
            })
            root._branchToken = root.eventBus.subscribeEvent("branch.changed", function(payload) {
                addEvent("branch.changed → " + (payload.branch || "?"))
            })
            root._repoToken = root.eventBus.subscribeEvent("repo.switched", function(payload) {
                addEvent("repo.switched")
            })
        }
    }

    Component.onDestruction: {
        if (root.eventBus) {
            if (root._commitToken >= 0) root.eventBus.unsubscribeEvent(root._commitToken)
            if (root._branchToken >= 0) root.eventBus.unsubscribeEvent(root._branchToken)
            if (root._repoToken  >= 0) root.eventBus.unsubscribeEvent(root._repoToken)
        }
    }

    function addEvent(text) {
        const t = new Date().toLocaleTimeString(Qt.locale(), "HH:mm:ss")
        root.eventLog = [{ time: t, text: text }].concat(root.eventLog).slice(0, 50)
    }

    // ── UI ────────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Style.colors.primaryBackground

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            // Header
            RowLayout {
                spacing: 12

                Label {
                    text: "\uf080"
                    font.family: Style.fontTypes.font6ProSolid
                    font.pixelSize: 20
                    color: Style.colors.accent
                }
                Label {
                    text: "Stats Page"
                    font.pixelSize: 18
                    font.bold: true
                    color: Style.colors.foreground
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: "Plugin SDK Test"
                    font.pixelSize: 11
                    color: Style.colors.mutedText
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Style.colors.primaryBorder
            }

            // Plugin info cards
            GridLayout {
                columns: 2
                rowSpacing: 12
                columnSpacing: 12
                Layout.fillWidth: true

                StatCard {
                    title: "Plugin ID"
                    value: "com.gitease.stats-page"
                    Layout.fillWidth: true
                }
                StatCard {
                    title: "Loaded Plugins"
                    value: root.pluginController
                           ? root.pluginController.pluginManager.pluginInfos.length.toString()
                           : "—"
                    Layout.fillWidth: true
                }
                StatCard {
                    title: "Current Branch"
                    value: root.branchController
                           ? (root.branchController.getCurrentBranchName() || "—")
                           : "—"
                    Layout.fillWidth: true
                }
                StatCard {
                    title: "Event Bus"
                    value: root.eventBus ? "Connected" : "Not available"
                    accent: root.eventBus !== null
                    Layout.fillWidth: true
                }
            }

            // Live event feed
            Label {
                text: "Live Event Feed"
                font.pixelSize: 13
                font.bold: true
                color: Style.colors.foreground
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Style.colors.secondaryBackground
                radius: 6
                border.width: 1
                border.color: Style.colors.primaryBorder
                clip: true

                ListView {
                    anchors.fill: parent
                    anchors.margins: 8
                    model: root.eventLog
                    spacing: 4

                    delegate: RowLayout {
                        width: ListView.view.width
                        spacing: 10

                        Label {
                            text: modelData.time
                            font.family: Style.fontTypes.jetBrainsMono
                            font.pixelSize: 11
                            color: Style.colors.mutedText
                        }
                        Label {
                            text: modelData.text
                            font.family: Style.fontTypes.jetBrainsMono
                            font.pixelSize: 11
                            color: Style.colors.accent
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        visible: root.eventLog.length === 0
                        text: "Waiting for events…\nClick a commit or switch branch."
                        horizontalAlignment: Text.AlignHCenter
                        color: Style.colors.mutedText
                        font.pixelSize: 12
                    }
                }
            }

            // Manual publish button (for testing event bus)
            Button {
                text: "Publish Test Event"
                onClicked: {
                    if (root.eventBus)
                        root.eventBus.publishEvent("test.event", { source: "StatsPage" })
                    addEvent("Published: test.event")
                }
            }
        }
    }

    // ── StatCard component ────────────────────────────────────────────────────
    component StatCard : Rectangle {
        property string title: ""
        property string value: ""
        property bool   accent: false

        height: 60
        color: Style.colors.secondaryBackground
        radius: 6
        border.width: 1
        border.color: accent ? Style.colors.accent : Style.colors.primaryBorder

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Label {
                text: parent.parent.title
                font.pixelSize: 10
                color: Style.colors.mutedText
            }
            Label {
                text: parent.parent.value
                font.pixelSize: 13
                font.bold: true
                color: parent.parent.accent ? Style.colors.accent : Style.colors.foreground
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}
