import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * CommitPlanPopup
 * Shows a previewable commits todo list with commit file changes and diff view.
 * ************************************************************************************************/

IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property StatusController statusController: null
    property CommitController commitController: null

    property var    planData            : ({})
    property string selectedCommitHash  : ""

    /* Signals
     * ****************************************************************************************/
    signal accepted(var operations)

    /* Object Properties
     * ****************************************************************************************/
    width   : Math.min(1180 , Overlay.overlay   ? Overlay.overlay.width - 80    : 1180)
    height  : Math.min(760  , Overlay.overlay   ? Overlay.overlay.height - 80   : 760)

    modal           : true
    closePolicy     : Popup.NoAutoClose
    anchors.centerIn: Overlay.overlay

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 12
        clip: true
        border.color: Style.colors.primaryBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Main content: vertical split
            SplitView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Vertical

                // Top: commit list (full width)
                Rectangle {
                    SplitView.preferredHeight: 300
                    SplitView.minimumHeight: 150
                    color: Style.colors.secondaryBackground
                    border.color: Style.colors.primaryBorder
                    radius: 8
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        ListView {
                            id: commitList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: commitModel
                            currentIndex: commitModel.count > 0 ? 0 : -1

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 32
                                color: ListView.isCurrentItem ? Qt.rgba(0.533, 0.694, 0.875, 0.38)
                                      : commitMouse.containsMouse ? Style.colors.hoverTitle
                                      : Style.colors.secondaryBackground

                                MouseArea {
                                    id: commitMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    onClicked: selectCommit(index)
                                    cursorShape: Qt.PointingHandCursor
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    // Action combo (pick / skip)
                                    ComboBox {
                                        id: actionCombo
                                        Layout.preferredWidth: 78
                                        Layout.preferredHeight: 26
                                        model: root.planData.supportedActions
                                        currentIndex: actionCombo.currentText === "skip" ? 1 : 0
                                        font.pixelSize: 11
                                        onActivated: commitModel.setProperty(index, "action", currentText)
                                    }

                                    // Commit info (short hash + message)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: shortHash
                                            color: actionCombo.currentText === "skip" ? Style.colors.mutedText : Style.colors.accent
                                            font.family: Style.fontTypes.roboto
                                            font.pixelSize: 11
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: summary
                                            color: actionCombo.currentText === "skip" ? Style.colors.mutedText : Style.colors.foreground
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }

                                    // Author
                                    Text {
                                        text: author
                                        color: actionCombo.currentText === "skip" ? Style.colors.mutedText : Style.colors.foreground
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        Layout.preferredWidth: 130
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    // Date
                                    Text {
                                        text: authorDate ? Qt.formatDateTime(new Date(authorDate), "yyyy-MM-dd hh:mm") : ""
                                        color: actionCombo.currentText === "skip" ? Style.colors.mutedText : Style.colors.secondaryText
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                        Layout.preferredWidth: 130
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // Bottom: file changes + diff view side‑by‑side
                SplitView {
                    orientation: Qt.Horizontal

                    FileChangesDock {
                        id: fileChangesDock

                        SplitView.preferredWidth: 500

                        statusController: root.statusController

                        onFileSelected: function(filePath) { root.loadDiff(filePath) }
                    }

                    DiffView {
                        id: diffView
                        readOnly: true
                    }
                }
            }

            // Bottom action bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: "Cancel"
                    flat: true
                    Layout.preferredWidth: 100
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 6
                    }
                    onClicked: root.close()
                }

                Button {
                    id: startButton
                    text: "Start Rebase"
                    Layout.preferredWidth: 130
                    enabled: commitModel.count > 0 && pickedCount() > 0
                    Material.foreground: Style.colors.textButton
                    background: Rectangle {
                        implicitHeight: 34
                        color: startButton.enabled
                               ? (startButton.hovered ? Style.colors.accentHover : Style.colors.accent)
                               : Style.colors.disabledButton
                        radius: 6
                    }
                    onClicked: {
                        root.accepted(root.operations())
                        root.close()
                    }
                }
            }
        }
    }

    ListModel {
        id: commitModel
    }

    function pickedCount() {
        var count = 0
        for (var i = 0; i < commitModel.count; i++) {
            if (commitModel.get(i).action !== "skip")
                count++
        }
        return count
    }

    function showPlan(data) {
        commitModel.clear()

        root.planData           = data || {}
        diffView.diffData       = null
        fileChangesDock.files   = []
        root.selectedCommitHash = ""

        var commits = root.planData.commits || []
        for (var i = 0; i < commits.length; i++) {
            var commit = commits[i]
            commitModel.append({
                action      : commit.action     || "pick",
                hash        : commit.hash       || "",
                shortHash   : commit.shortHash  || "",
                summary     : commit.summary    || "",
                message     : commit.message    || "",
                author      : commit.author     || "",
                authorDate  : commit.authorDate || "",
                parentHash  : commit.parentHash || "",
                isMerge     : commit.isMerge    || false
            })
        }

        if (commitModel.count > 0)
            selectCommit(0)

        root.open()
    }

    function selectCommit(index) {
        if (index < 0 || index >= commitModel.count)
            return

        commitList.currentIndex     = index
        var commit                  = commitModel.get(index)
        root.selectedCommitHash     = commit.hash
        diffView.diffData           = null
        fileChangesDock.commitHash  = commit.hash
    }

    function loadDiff(filePath) {
        if (!root.selectedCommitHash || !filePath)
            return

        var parentHash = root.commitController.getParentHash(root.selectedCommitHash)
        var selected = commitModel.get(commitList.currentIndex)
        if (!parentHash && selected && selected.parentHash)
            parentHash = selected.parentHash

        if (!parentHash)
            return

        var diffRes = root.statusController.getDiff(parentHash, root.selectedCommitHash, filePath)
        if (diffRes && diffRes.success)
            diffView.diffData = diffRes.data
    }

    function operations() {
        var result = []
        for (var i = 0; i < commitModel.count; i++) {
            var commit = commitModel.get(i)
            result.push({
                action  : commit.action,
                hash    : commit.hash,
                summary : commit.summary
            })
        }
        return result
    }
}
