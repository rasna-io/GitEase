import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * TemplateRow
 * One template of the catalog: tick box, name and description, hover actions (edit, restore,
 * delete) and badges for "Customized", "Applied" and the rule count.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! { id, name, description, rules, custom, customized } from GitignoreEngine::templates().
    property var  info:      null
    property bool checked:   false
    property bool applied:   false
    property bool previewed: false
    //! Extra left space, used to sit the row under its category in the tree.
    property real indent:    0

    readonly property bool custom:     info !== null && info.custom === true
    readonly property bool customized: info !== null && !custom && info.customized === true

    readonly property color fill: previewed ? Style.colors.accentWash : Style.colors.controlBackgroundHover

    /* Signals
     * ****************************************************************************************/
    signal toggled()
    signal previewRequested()
    signal editRequested()
    signal resetRequested()
    signal deleteRequested()

    /* Object Properties
     * ****************************************************************************************/
    height: Style.dp(46)
    radius: Style.dp(8)
    color: previewed || rowHover.hovered ? fill : Qt.rgba(fill.r, fill.g, fill.b, 0)

    Behavior on color { ColorAnimation { duration: Style.motionFast } }

    /* Children
     * ****************************************************************************************/
    HoverHandler {
        id: rowHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler { onTapped: root.previewRequested() }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.dp(6) + root.indent
        anchors.rightMargin: Style.dp(10)
        spacing: Style.dp(8)

        GitignoreCheckBox {
            checked: root.checked
            onToggled: root.toggled()
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.info ? root.info.name : ""
                elide: Text.ElideRight
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.smallPt
                font.weight: Font.Medium
                color: Style.colors.foreground
            }

            Text {
                Layout.fillWidth: true
                text: root.info ? root.info.description : ""
                elide: Text.ElideRight
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.microPt
                color: Style.colors.pluginCardMetaText
            }
        }

        Row {
            visible: rowHover.hovered
            spacing: Style.dp(10)

            GitignoreIconAction {
                text: Style.icons.edit
                tooltip: root.custom ? "Edit this template" : "Customize this template"
                onClicked: root.editRequested()
            }

            GitignoreIconAction {
                visible: root.customized
                text: Style.icons.undo
                tooltip: "Restore the original template"
                onClicked: root.resetRequested()
            }

            GitignoreIconAction {
                visible: root.custom
                text: Style.icons.trash
                tooltip: "Delete this template"
                hoverColor: Style.colors.error
                onClicked: root.deleteRequested()
            }
        }

        GitignoreBadge {
            visible: root.customized
            label: "Customized"
            strong: true
            textColor: Style.colors.accent
            fillColor: Style.colors.accentWash
        }

        GitignoreBadge {
            visible: root.applied
            label: "Applied"
            strong: true
            textColor: Style.colors.repoItemStatusDoneText
            fillColor: Style.colors.repoItemStatusDoneBg
        }

        GitignoreBadge {
            label: root.info ? root.info.rules + (root.info.rules === 1 ? " rule" : " rules") : ""
        }
    }
}
