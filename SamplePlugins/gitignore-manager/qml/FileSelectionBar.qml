import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * FileSelectionBar
 * Actions for the selected files: choose how a rule is written, add it to .gitignore, stop
 * ignoring, or stop tracking. Slides in when something is selected.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int  selectedCount: 0
    //! { toIgnore, toUnignore, tracked, trackedIgnored } from FileTree.analyseSelection().
    property var  selection:     ({ toIgnore: [], toUnignore: [], tracked: [], trackedIgnored: [] })
    //! "exact", "name", "extension" or "folder".
    property string patternMode: "exact"
    //! The rules the current selection and style would write.
    property var  patternPreview: []
    property bool alsoUntrack:   true

    readonly property bool shown: selectedCount > 0
    readonly property var  patternModes: [
        { key: "exact",     label: "Exact path", tip: "Ignore exactly this file or folder" },
        { key: "name",      label: "Name",       tip: "Ignore anything with this name, anywhere" },
        { key: "extension", label: "Extension",  tip: "Ignore every file with this extension" },
        { key: "folder",    label: "Folder",     tip: "Ignore the whole parent folder" }
    ]

    /* Signals
     * ****************************************************************************************/
    signal patternModeRequested(string mode)
    signal alsoUntrackRequested(bool value)
    signal ignoreRequested()
    signal unignoreRequested()
    signal untrackRequested()

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.preferredHeight: shown ? barColumn.implicitHeight + Style.dp(20) : 0
    opacity: shown ? 1 : 0
    visible: Layout.preferredHeight > 0
    clip: true

    radius: Style.dp(10)
    color: Style.colors.controlBackground
    border.width: 1
    border.color: Style.colors.controlBorder

    Behavior on Layout.preferredHeight {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: barColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Style.dp(12)
        anchors.rightMargin: Style.dp(12)
        spacing: Style.dp(8)

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.dp(10)

            Flow {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Style.dp(10)

                Text {
                    height: Style.dp(26)
                    verticalAlignment: Text.AlignVCenter
                    text: root.selectedCount + " selected"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                    font.weight: Font.DemiBold
                    color: Style.colors.foreground
                }

                // How the rule is written
                Rectangle {
                    visible: root.selection.toIgnore.length > 0
                    height: Style.dp(26)
                    width: modeRow.implicitWidth + Style.dp(6)
                    radius: Style.dp(7)
                    color: Style.colors.pluginCardBackground
                    border.width: 1
                    border.color: Style.colors.controlBorder

                    Row {
                        id: modeRow
                        anchors.centerIn: parent
                        spacing: Style.dp(2)

                        Repeater {
                            model: root.patternModes

                            delegate: PatternModeTab {
                                required property var modelData

                                label: modelData.label
                                tip: modelData.tip
                                active: root.patternMode === modelData.key
                                onClicked: root.patternModeRequested(modelData.key)
                            }
                        }
                    }
                }
            }

            GitignoreButton {
                Layout.alignment: Qt.AlignVCenter
                visible: root.selection.toIgnore.length > 0
                variant: "primary"
                implicitHeight: Style.dp(26)
                iconText: Style.icons.plus
                text: "Add to .gitignore"
                onClicked: root.ignoreRequested()
            }
        }

        // The rules that will be written
        Text {
            Layout.fillWidth: true
            visible: root.patternPreview.length > 0
            elide: Text.ElideRight
            maximumLineCount: 1
            text: {
                const p = root.patternPreview
                const shownRules = p.slice(0, 3).join("    ")
                return p.length > 3 ? shownRules + "    +" + (p.length - 3) + " more" : shownRules
            }
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.captionPt
            color: Style.colors.pluginCardDescription
        }

        GitignoreCheckBox {
            visible: root.selection.tracked.length > 0
            text: root.selection.tracked.length + " selected file(s) are already committed. Also stop tracking them (kept on disk)"
            checked: root.alsoUntrack
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.captionPt
            onToggled: root.alsoUntrackRequested(checked)
        }

        Flow {
            Layout.fillWidth: true
            visible: root.selection.toUnignore.length > 0 || root.selection.trackedIgnored.length > 0
            spacing: Style.dp(8)

            GitignoreButton {
                visible: root.selection.toUnignore.length > 0
                iconText: Style.icons.minus
                text: "Stop ignoring"
                tooltip: "Remove the rules that ignore the selected items"
                onClicked: root.unignoreRequested()
            }

            GitignoreButton {
                visible: root.selection.trackedIgnored.length > 0
                iconText: Style.icons.trash
                text: "Stop tracking"
                tooltip: "Remove from the Git index but keep the files on disk"
                onClicked: root.untrackRequested()
            }
        }
    }
}
