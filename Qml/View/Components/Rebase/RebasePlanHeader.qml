import QtQuick
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RebasePlanHeader
 * Title, what is being rebased onto what, and a tally of the plan by action.
 * ************************************************************************************************/
ColumnLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string branch:     ""
    property string ontoRef:    ""
    property int    commitCount: 0

    //! action -> how many commits carry it. Only non-zero entries are shown.
    property var    actionCounts: ({})

    /*! TODO(GE-xxx): no backend yet. Hidden until an advisor exists -- flip this on to preview it. */
    property bool   adviseEnabled: false

    /* Signals
     * ****************************************************************************************/
    signal closeRequested()
    signal adviseRequested()

    /* Object Properties
     * ****************************************************************************************/
    spacing: 4

    /* Children
     * ****************************************************************************************/
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: "Interactive Rebase Plan"
            color: Style.colors.foreground
            font.family: Style.fontTypes.inter
            font.weight: Font.DemiBold
            font.pixelSize: Style.appFont.largePt
            elide: Text.ElideRight
        }

        ConflictPillButton {
            visible: root.adviseEnabled
            text: "Advise"
            leadingText: Style.icons.star
            accentColor: Style.colors.conflictAssistAccent
            tooltip: "Suggest a plan for these commits"
            onClicked: root.adviseRequested()
        }

        // A sized target rather than the bare glyph: a 14px icon is a hard thing to hit.
        Rectangle {
            id: closeButton

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Style.dp(26)
            Layout.preferredHeight: Style.dp(26)

            radius: 4
            color: closeHover.hovered ? Style.colors.cardBackground : "transparent"

            HoverHandler {
                id: closeHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: root.closeRequested()
            }

            Text {
                anchors.centerIn: parent
                text: Style.icons.close
                color: closeHover.hovered ? Style.colors.foreground : Style.colors.mutedText
                font.family: Style.fontTypes.font6ProSolid
                font.pixelSize: Style.appFont.mediumPt
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: root.branch !== "" || root.ontoRef !== ""

        Text {
            text: "Rebasing"
            color: Style.colors.mutedText
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.captionPt
        }

        Text {
            Layout.maximumWidth: root.width * 0.5
            text: root.branch
            color: Style.colors.accent
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.captionPt
            elide: Text.ElideMiddle
        }

        Text {
            visible: root.ontoRef !== ""
            text: "onto"
            color: Style.colors.mutedText
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.captionPt
        }

        Text {
            visible: root.ontoRef !== ""
            text: root.ontoRef
            color: Style.colors.foreground
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.captionPt
            elide: Text.ElideRight
        }

        Item {
            Layout.fillWidth: true
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2
        spacing: 6

        Text {
            text: root.commitCount === 1 ? "1 commit" : `${root.commitCount} commits`
            color: Style.colors.mutedText
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.captionPt
        }

        Text {
            visible: root.commitCount > 0
            text: "·"
            color: Style.colors.mutedText
            font.pixelSize: Style.appFont.captionPt
        }

        Repeater {
            model: RebaseActions.all

            delegate: RebaseActionBadge {
                required property string modelData

                action: modelData
                count: root.actionCounts[modelData] ?? 0
                visible: count > 0
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
