import QtQuick
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * ConflictFooter
 * Progress readouts plus the three operation-level commands. Abort lives here rather than behind the
 * window's close button, so quitting the operation is a deliberate act.
 * ************************************************************************************************/
ColumnLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string operationName:  ""
    property bool   canContinue:    false
    property bool   canSkip:        false

    property int    resolvedFiles:      0
    property int    totalFiles:         0

    //! Across every conflicted file, not just the one open in the editor.
    property int    resolvedConflicts:  0
    property int    totalConflicts:     0

    /* Signals
     * ****************************************************************************************/
    signal abortRequested()
    signal skipRequested()
    signal continueRequested()

    /* Object Properties
     * ****************************************************************************************/
    spacing: 12

    /* Children
     * ****************************************************************************************/
    RowLayout {
        Layout.fillWidth: true
        spacing: 32

        ConflictProgressBar {
            Layout.fillWidth: true
            caption: "FILES"
            value: root.resolvedFiles
            total: root.totalFiles
            fillColor: Style.colors.conflictProgressFiles
        }

        ConflictProgressBar {
            Layout.fillWidth: true
            caption: "CONFLICTS"
            value: root.resolvedConflicts
            total: root.totalConflicts
            fillColor: Style.colors.conflictProgressChunks
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        ConflictPillButton {
            Layout.preferredHeight: Style.dp(30)
            text: `Abort ${root.operationName}`
            accentColor: Style.colors.conflictDestructive
            tooltip: "Discard all progress and return to the state before the operation started"
            onClicked: root.abortRequested()
        }

        Item { Layout.fillWidth: true }

        ConflictPillButton {
            Layout.preferredHeight: Style.dp(30)
            visible: root.canSkip
            text: "Skip commit"
            accentColor: Style.colors.mutedText
            tooltip: "Leave this commit out and move on to the next one"
            onClicked: root.skipRequested()
        }

        ConflictPillButton {
            Layout.preferredHeight: Style.dp(30)
            text: `Continue ${root.operationName}`
            trailingText: Style.icons.arrowRight
            accentColor: Style.colors.accent
            prominent: root.canContinue
            actionEnabled: root.canContinue
            tooltip: root.canContinue ? "Click to continue"
                                      : "Resolve every file to continue"
            onClicked: root.continueRequested()
        }
    }
}
