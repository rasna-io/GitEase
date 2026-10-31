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

    //! One entry per plugin that registered a conflict assistant.
    property var assists: []
    property bool canAssist: false

    /* Signals
     * ****************************************************************************************/
    signal previousChunkRequested()
    signal nextChunkRequested()
    signal assistRequested(var assist)

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

    Row {
        spacing: 8
        visible: root.canAssist

        Repeater {
            model: root.assists

            ConflictPillButton {
                required property var modelData
                text: modelData.action || modelData.title
                leadingText: Style.icons.star
                accentColor: Style.colors.conflictAssistAccent
                tooltip: modelData.title || ""
                onClicked: root.assistRequested(modelData)
            }
        }
    }
}
