import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * CommittingPage
 * Committing Page shown commit actions placeholder, file list placeholder and diff placeholder
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var                  page:                 null
    property RepositoryController repositoryController: null
    property string               selectedFilePath:     ""

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Children
     * ****************************************************************************************/
    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        anchors.topMargin: 32
        spacing: 12

        // Left panel: two stacked placeholders
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: root.width / 3
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "(commit actions) (placeholder)"
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 13
                        color: Style.colors.placeholderText
                    }
                }

                // File lists
                Rectangle {
                    id: fileListsPanel
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"

                    // Default fake data so the UI is visibly populated without git wiring.
                    // Keep one list non-empty and the other empty to demonstrate both states.
                    property var unstagedChanges: [
                        { path: "README.md", mode: "M" },
                        { path: "Src/main.cpp", mode: "A" },
                        { path: "Qml/Pages/CommittingPage.qml", mode: "M" },
                        { path: "Src/Git/GitWrapperCPP.cpp", mode: "D" },
                        { path: "Res/Images/Logo.svg", mode: "R" },
                        { path: "Res/Images/q.svg", mode: "R" },
                        { path: "Res/Images/b.svg", mode: "R" },
                        { path: "Res/Images/c.svg", mode: "R" },
                        { path: "CMakeLists.txt", mode: "M" }
                    ]
                    property var stagedChanges: []

                    ChangesFileLists {
                        anchors.fill: parent
                        unstagedModel: fileListsPanel.unstagedChanges
                        stagedModel: fileListsPanel.stagedChanges

                        selectedFilePath: root.selectedFilePath

                        onFileSelected: function(filePath) {
                            root.selectedFilePath = filePath
                        }

                        // TODO :: only for show demo and handlers
                        onStageFileRequested: function(filePath) {
                            const src = fileListsPanel.unstagedChanges
                            const dst = fileListsPanel.stagedChanges

                            const idx = src.findIndex(function(it) { return it.path === filePath })
                            if (idx < 0)
                                return

                            const item = src[idx]
                            fileListsPanel.unstagedChanges = src.slice(0, idx).concat(src.slice(idx + 1))
                            fileListsPanel.stagedChanges = dst.concat([item])
                        }

                        onUnstageFileRequested: function(filePath) {
                            const src = fileListsPanel.stagedChanges
                            const dst = fileListsPanel.unstagedChanges

                            const idx = src.findIndex(function(it) { return it.path === filePath })
                            if (idx < 0)
                                return

                            const item = src[idx]
                            fileListsPanel.stagedChanges = src.slice(0, idx).concat(src.slice(idx + 1))
                            fileListsPanel.unstagedChanges = dst.concat([item])
                        }

                        onDiscardFileRequested: function(filePath) {
                            const src = fileListsPanel.unstagedChanges
                            const idx = src.findIndex(function(it) { return it.path === filePath })
                            if (idx < 0)
                                return

                            fileListsPanel.unstagedChanges = src.slice(0, idx).concat(src.slice(idx + 1))

                            if (root.selectedFilePath === filePath)
                                root.selectedFilePath = ""
                        }

                        onOpenFileRequested: function(filePath) {
                            console.log("Open file (placeholder):", filePath)
                        }

                        onStageAllRequested: function() {
                            const src = fileListsPanel.unstagedChanges
                            if (!src || src.length === 0)
                                return

                            fileListsPanel.stagedChanges = fileListsPanel.stagedChanges.concat(src)
                            fileListsPanel.unstagedChanges = []
                        }

                        onUnstageAllRequested: function() {
                            const src = fileListsPanel.stagedChanges
                            if (!src || src.length === 0)
                                return

                            fileListsPanel.unstagedChanges = fileListsPanel.unstagedChanges.concat(src)
                            fileListsPanel.stagedChanges = []
                        }

                        onDiscardAllRequested: function() {
                            fileListsPanel.unstagedChanges = []
                            if (root.selectedFilePath !== "" && root.selectedFilePath !== null)
                                root.selectedFilePath = ""
                        }

                        onStashAllRequested: function(section) {
                            if (section === "unstaged") {
                                fileListsPanel.unstagedChanges = []
                            } else if (section === "staged") {
                                fileListsPanel.stagedChanges = []
                            }

                            if (root.selectedFilePath !== "" && root.selectedFilePath !== null)
                                root.selectedFilePath = ""
                        }
                    }
                }
            }
        }

        // Right panel: diff placeholder
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: root.width * 2 / 3
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: root.selectedFilePath === "" ? "Diff (placeholder)" : ("Diff (placeholder)\n" + root.selectedFilePath)
                horizontalAlignment: Text.AlignHCenter
                font.family: Style.fontTypes.roboto
                font.pixelSize: 13
                color: Style.colors.placeholderText
            }
        }
    }
}
