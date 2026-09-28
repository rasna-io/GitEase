import QtQuick
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * ConflictToolbar
 * Chunk navigation for the file currently open in the editor, plus how far through it the user is.
 * ************************************************************************************************/
RowLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int  resolvedChunks:   0
    property int  totalChunks:      0
    property bool canNavigate:      false

    //! todo
    //! The AI assist entry point is designed but not wired up; flip this on to preview it.
    property bool assistEnabled:    false

    /* Signals
     * ****************************************************************************************/
    signal previousChunkRequested()
    signal nextChunkRequested()
    signal assistRequested()

    /* Object Properties
     * ****************************************************************************************/
    spacing: 8

    /* Children
     * ****************************************************************************************/
    ConflictPillButton {
        text: "Prev chunk"
        leadingText: Style.icons.caretUp
        actionEnabled: root.canNavigate
        accentColor: Style.colors.mutedText
        onClicked: root.previousChunkRequested()
    }

    ConflictPillButton {
        text: "Next chunk"
        trailingText: Style.icons.caretDown
        actionEnabled: root.canNavigate
        accentColor: Style.colors.mutedText
        onClicked: root.nextChunkRequested()
    }

    Text {
        Layout.leftMargin: 4
        text: `${root.resolvedChunks} of ${root.totalChunks} resolved in this file`
        color: Style.colors.conflictSectionLabel
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.captionPt
    }

    Item {
        Layout.fillWidth: true
    }

    ConflictPillButton {
        visible: root.assistEnabled
        text: "Ask Claude"
        leadingText: Style.icons.star
        accentColor: Style.colors.conflictAssistAccent
        onClicked: root.assistRequested()
    }
}
