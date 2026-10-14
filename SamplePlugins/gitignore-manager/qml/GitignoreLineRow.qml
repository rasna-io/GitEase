import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * GitignoreLineRow
 * One line of the .gitignore: its number, the text coloured by kind and, for rules, a trash icon
 * that appears under the pointer.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! { number, text, kind } where kind is blank, marker, comment, negation or pattern.
    property var line: null

    readonly property bool removable: line !== null && (line.kind === "pattern" || line.kind === "negation")

    readonly property color hoverFill: Style.colors.controlBackgroundHover

    /* Signals
     * ****************************************************************************************/
    signal removeRequested()

    /* Object Properties
     * ****************************************************************************************/
    height: Style.dp(24)

    /* Children
     * ****************************************************************************************/
    Rectangle {
        anchors.fill: parent
        radius: Style.dp(5)
        color: lineHover.hovered ? root.hoverFill : Qt.rgba(root.hoverFill.r, root.hoverFill.g, root.hoverFill.b, 0)

        Behavior on color { ColorAnimation { duration: Style.motionFast } }
    }

    HoverHandler { id: lineHover }

    Text {
        id: lineNumber
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Style.dp(34)
        horizontalAlignment: Text.AlignRight
        text: root.line ? root.line.number : ""
        font.family: Style.fontTypes.jetBrainsMono
        font.pixelSize: Style.appFont.captionPt
        color: Style.colors.mutedText
    }

    Text {
        anchors.left: lineNumber.right
        anchors.leftMargin: Style.dp(12)
        anchors.right: removeAction.left
        anchors.rightMargin: Style.dp(6)
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: root.line ? root.line.text : ""
        font.family: Style.fontTypes.jetBrainsMono
        font.pixelSize: Style.appFont.smallPt
        font.weight: root.line && root.line.kind === "marker" ? Font.DemiBold : Font.Normal
        font.italic: root.line !== null && root.line.kind === "comment"
        color: {
            switch (root.line ? root.line.kind : "") {
            case "comment":
                return Style.colors.mutedText
            case "marker":
                return Style.colors.accent
            case "negation":
                return Style.colors.repoItemStatusDoneText
            default:
                return Style.colors.foreground
            }
        }
    }

    GitignoreIconAction {
        id: removeAction
        anchors.right: parent.right
        anchors.rightMargin: Style.dp(6)
        anchors.verticalCenter: parent.verticalCenter
        visible: root.removable && lineHover.hovered
        text: Style.icons.trash
        tooltip: "Remove this rule"
        hoverColor: Style.colors.error
        onClicked: root.removeRequested()
    }
}
