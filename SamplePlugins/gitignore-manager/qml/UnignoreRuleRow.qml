import QtQuick
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * UnignoreRuleRow
 * One rule of the "stop ignoring" confirmation: the pattern, where it lives and how many of the
 * selected items it covers.
 * ************************************************************************************************/
Rectangle {
    id: root

    //! { line, pattern, source, editable, paths } from GitignoreEngine::planUnignore().
    property var rule: null

    implicitHeight: ruleColumn.implicitHeight + Style.dp(16)
    height: implicitHeight
    radius: Style.dp(8)
    color: Style.colors.controlBackground
    border.width: 1
    border.color: Style.colors.controlBorder

    ColumnLayout {
        id: ruleColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Style.dp(12)
        anchors.rightMargin: Style.dp(12)
        spacing: Style.dp(2)

        Text {
            Layout.fillWidth: true
            text: root.rule ? root.rule.pattern : ""
            elide: Text.ElideRight
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.smallPt
            font.weight: Font.DemiBold
            color: Style.colors.foreground
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: root.rule
                  ? (root.rule.editable ? ".gitignore, line " + root.rule.line
                                        : root.rule.source + " - not managed here, edit that file instead")
                    + "  \u00b7  covers " + root.rule.paths.length + " selected"
                  : ""
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.microPt
            color: root.rule && root.rule.editable ? Style.colors.pluginCardMetaText : Style.colors.warning
        }
    }
}
