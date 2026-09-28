import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ReleaseCommitRow
 * One commit in the release: include toggle, type, scope, subject and metadata.
 * In compact mode the metadata shrinks to the short hash so the subject keeps its room.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property int    index
    required property string shortHash
    required property string author
    required property string date
    required property string type
    required property string scope
    required property string subject
    required property bool   breaking
    required property bool   included

    property bool enabledForEdit: true
    property bool compact:        false
    property bool showToggle:     true

    readonly property color typeFg: {
        if (breaking)          return Style.colors.repoItemStatusConflictText
        switch (type) {
        case "feat":           return Style.colors.accent
        case "fix":            return Style.colors.repoItemStatusDoneText
        case "perf":           return Style.colors.repoItemStatusPullingText
        case "revert":         return Style.colors.repoItemStatusDirtyText
        default:               return Style.colors.secondaryText
        }
    }

    readonly property color typeBg: {
        if (breaking)          return Style.colors.repoItemStatusConflictBg
        switch (type) {
        case "feat":           return Style.colors.accentWash
        case "fix":            return Style.colors.repoItemStatusDoneBg
        case "perf":           return Style.colors.repoItemStatusPullingBg
        case "revert":         return Style.colors.repoItemStatusDirtyBg
        default:               return Style.colors.controlBackground
        }
    }

    /* Signals
     * ****************************************************************************************/
    signal toggled()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: content.implicitHeight + Style.dp(14)
    radius: Style.dp(7)
    color: hover.hovered && enabledForEdit ? Style.colors.pluginSidebarRowHoverBg : "transparent"
    opacity: included || !showToggle ? 1.0 : 0.5

    Behavior on opacity { NumberAnimation { duration: Style.motionFast } }

    /* Functions
     * ****************************************************************************************/
    function escaped(text) {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    /* Children
     * ****************************************************************************************/
    HoverHandler {
        id: hover
        cursorShape: root.enabledForEdit && root.showToggle ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        enabled: root.enabledForEdit && root.showToggle
        onTapped: root.toggled()
    }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Style.dp(8)
        anchors.rightMargin: Style.dp(8)
        spacing: Style.dp(10)

        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: Style.dp(2)
            Layout.preferredWidth: Style.dp(16)
            Layout.preferredHeight: Style.dp(16)
            visible: root.showToggle
            radius: Style.dp(4)
            color: root.included ? Style.colors.accent : "transparent"
            border.width: root.included ? 0 : 1
            border.color: Style.colors.controlBorder

            Behavior on color { ColorAnimation { duration: Style.motionFast } }

            Text {
                anchors.centerIn: parent
                visible: root.included
                text: Style.icons.check
                font.family: Style.fontTypes.font6Pro
                font.pixelSize: Style.appFont.microPt
                color: Style.colors.onAccentText
            }
        }

        // Type column, aligned across rows when there is room
        Item {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: root.compact ? typeBadge.width : Style.dp(64)
            Layout.preferredHeight: Style.dp(20)

            Rectangle {
                id: typeBadge
                anchors.verticalCenter: parent.verticalCenter
                height: Style.dp(18)
                width: typeText.implicitWidth + Style.dp(12)
                radius: Style.dp(5)
                color: root.typeBg

                Text {
                    id: typeText
                    anchors.centerIn: parent
                    text: (root.type.length > 0 ? root.type : "change") + (root.breaking ? "!" : "")
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.microPt
                    font.weight: Font.DemiBold
                    color: root.typeFg
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.dp(3)

            Text {
                Layout.fillWidth: true
                text: (root.scope.length > 0 ? "<b>" + root.escaped(root.scope) + ":</b> " : "") + root.escaped(root.subject)
                textFormat: Text.StyledText
                elide: Text.ElideRight
                maximumLineCount: root.compact ? 2 : 1
                wrapMode: root.compact ? Text.WordWrap : Text.NoWrap
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.captionPt
                color: Style.colors.foreground
            }

            Text {
                Layout.fillWidth: true
                text: root.compact ? root.shortHash : root.shortHash + "  ·  " + root.author + "  ·  " + root.date
                elide: Text.ElideRight
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.microPt
                color: Style.colors.mutedText
            }
        }
    }
}
