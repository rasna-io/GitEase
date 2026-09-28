import QtQuick
import QtQuick.Controls

import GitEase_Style

/*! ***********************************************************************************************
 * NotesPreview
 * Read-only, selectable Markdown rendering of release notes. Links open in the browser.
 * ************************************************************************************************/
Flickable {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string markdown:    ""
    property string placeholder: "No notable changes."
    property real   padding:     Style.dp(14)

    readonly property bool hasContent: markdown.trim().length > 0

    /* Object Properties
     * ****************************************************************************************/
    clip: true
    contentWidth: width
    contentHeight: notesText.implicitHeight + padding * 2
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick

    ScrollBar.vertical: ScrollBar {}

    /* Children
     * ****************************************************************************************/
    TextEdit {
        id: notesText

        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        readOnly: true
        selectByMouse: true
        textFormat: root.hasContent ? TextEdit.MarkdownText : TextEdit.PlainText
        text: root.hasContent ? root.markdown : root.placeholder
        wrapMode: TextEdit.Wrap
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.smallPt
        color: root.hasContent ? Style.colors.foreground : Style.colors.mutedText
        selectionColor: Style.colors.accent
        selectedTextColor: Style.colors.onAccentText

        onLinkActivated: function(link) { Qt.openUrlExternally(link) }

        HoverHandler {
            cursorShape: notesText.hoveredLink.length > 0 ? Qt.PointingHandCursor : Qt.IBeamCursor
        }
    }
}
