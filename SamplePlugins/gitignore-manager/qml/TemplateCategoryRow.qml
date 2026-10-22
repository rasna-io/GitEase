import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * TemplateCategoryRow
 * Folder-like row of the template tree: caret, icon, category name and how many of its templates
 * are ticked. Clicking the row opens or closes it; the checkbox ticks the whole category.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string name:         ""
    property int    total:        0
    property int    checkedCount: 0
    property bool   open:         true

    readonly property bool allChecked: total > 0 && checkedCount === total

    readonly property color fill: Style.colors.controlBackgroundHover

    /* Signals
     * ****************************************************************************************/
    signal expandToggled()
    signal toggled()

    /* Object Properties
     * ****************************************************************************************/
    height: Style.dp(32)
    radius: Style.dp(8)
    color: rowHover.hovered ? fill : Qt.rgba(fill.r, fill.g, fill.b, 0)

    Behavior on color { ColorAnimation { duration: Style.motionFast } }

    /* Children
     * ****************************************************************************************/
    HoverHandler {
        id: rowHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler { onTapped: root.expandToggled() }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.dp(6)
        anchors.rightMargin: Style.dp(10)
        spacing: Style.dp(8)

        GitignoreCheckBox {
            checked: root.allChecked
            onToggled: root.toggled()
        }

        Text {
            Layout.preferredWidth: Style.dp(12)
            horizontalAlignment: Text.AlignHCenter
            text: Style.icons.caretRight
            rotation: root.open ? 90 : 0
            font.family: Style.fontTypes.font6Pro
            font.pixelSize: Style.appFont.captionPt
            color: Style.colors.mutedText

            Behavior on rotation {
                NumberAnimation {
                    duration: Style.motionFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            text: Style.icons.folder
            font.family: Style.fontTypes.font6Pro
            font.pixelSize: Style.appFont.smallPt
            color: Style.colors.warning
        }

        Text {
            Layout.fillWidth: true
            text: root.name
            elide: Text.ElideRight
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.smallPt
            font.weight: Font.DemiBold
            color: Style.colors.foreground
        }

        Text {
            text: root.checkedCount > 0 ? root.checkedCount + " / " + root.total : root.total
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.microPt
            font.weight: Font.Medium
            color: root.checkedCount > 0 ? Style.colors.accent : Style.colors.pluginCountPillText
        }
    }
}
