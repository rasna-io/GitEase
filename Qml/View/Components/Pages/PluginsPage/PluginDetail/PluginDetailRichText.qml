import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailRichText
 * Body copy that switches to Markdown only when the text actually contains Markdown.
 * ************************************************************************************************/
Label {
    id: root

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    color: Style.colors.pluginCardDescription
    linkColor: Style.colors.accent
    font.pixelSize: Style.appFont.mediumPt
    font.family: Style.fontTypes.inter
    wrapMode: Text.WordWrap
    lineHeight: 1.5
    lineHeightMode: Text.ProportionalHeight
    textFormat: /(^|\n)\s*(#{1,6}\s|[-*]\s|\d+\.\s|```)|\*\*[^*]+\*\*|\[[^\]]+\]\([^)]+\)/.test(root.text)
                ? Text.MarkdownText : Text.PlainText

    onLinkActivated: function(link) {
        Qt.openUrlExternally(link)
    }

    /* Children
     * ****************************************************************************************/
    HoverHandler {
        cursorShape: root.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
