import QtQuick
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RebasePlanFooter
 * ************************************************************************************************/
RowLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property bool   canUndo:        false
    property bool   canRedo:        false
    property bool   canStart:       false
    property bool   showCancel:     true
    property string startText:      "Start Rebase"

    /* Signals
     * ****************************************************************************************/
    signal undoRequested()
    signal redoRequested()
    signal cancelRequested()
    signal startRequested()

    /* Object Properties
     * ****************************************************************************************/
    spacing: 8

    /* Children
     * ****************************************************************************************/
    ConflictPillButton {
        text: "Undo"
        leadingText: Style.icons.undo
        accentColor: Style.colors.mutedText
        actionEnabled: root.canUndo
        tooltip: root.canUndo ? "Undo the last change to the plan" : "Nothing to undo"
        onClicked: root.undoRequested()
    }

    ConflictPillButton {
        text: "Redo"
        leadingText: Style.icons.refresh
        accentColor: Style.colors.mutedText
        actionEnabled: root.canRedo
        tooltip: root.canRedo ? "Redo the last undone change" : "Nothing to redo"
        onClicked: root.redoRequested()
    }

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        text: "Alt+↑↓ reorder · P/R/S/F/E/D action"
        color: Style.colors.mutedText
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.captionPt
        elide: Text.ElideRight
    }

    ConflictPillButton {
        visible: root.showCancel
        text: "Cancel"
        accentColor: Style.colors.mutedText
        Layout.preferredWidth: Style.dp(84)
        Layout.preferredHeight: Style.dp(30)
        onClicked: root.cancelRequested()
    }

    ConflictPillButton {
        text: root.startText
        leadingText: Style.icons.play
        accentColor: Style.colors.accent
        prominent: true
        actionEnabled: root.canStart
        Layout.preferredWidth: Style.dp(132)
        Layout.preferredHeight: Style.dp(30)
        onClicked: root.startRequested()
    }
}
