import QtQuick
import QtQuick.Controls

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RebasePlanRow
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string action:     RebaseActions.pick
    property string shortHash:  ""
    property string summary:    ""
    property string author:     ""
    property string authorDate: ""
    property string status:     ""
    property color  statusColor: Style.colors.rebaseStatusPending

    property bool   isCurrent:      false
    property bool   showStatus:     false
    property bool   actionEnabled:  true
    property bool   canMoveUp:      true
    property bool   canMoveDown:    true

    //! Column widths, owned by the table so the header and every row stay aligned.
    property var    columns:    ({})

    //! Set once the rebase has finished with this commit, whether it was replayed or skipped.
    property bool   isDone:         false
    readonly property bool isDropped: root.action === RebaseActions.drop
    readonly property bool isSetAside: root.isDropped || root.isDone

    /* Signals
     * ****************************************************************************************/
    signal clicked()
    signal actionPicked(string action)
    signal moveUpRequested()
    signal moveDownRequested()
    signal dragMoveRequested(int deltaRows)

    /* Object Properties
     * ****************************************************************************************/
    height: Style.dp(36)
    color: {
        if (root.isCurrent)
            return Style.colors.conflictFileSelectedBg

        return hoverHandler.hovered ? Style.colors.cardBackground : "transparent"
    }

    Behavior on color { ColorAnimation { duration: 120 } }

    /* Children
     * ****************************************************************************************/
    HoverHandler {
        id: hoverHandler
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        visible: root.isCurrent
        color: Style.colors.accent
    }

    Item {
        id: grip

        anchors.left: parent.left
        anchors.leftMargin: (root.columns.gripX ?? 0) - Style.dp(4)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Style.dp(20)

        Text {
            anchors.centerIn: parent
            text: Style.icons.grip
            color: dragHandler.active || gripHover.hovered ? Style.colors.foreground
                                                           : Style.colors.mutedText
            font.family: Style.fontTypes.font6Pro
            font.styleName: "Solid"
            font.pixelSize: Style.appFont.smallPt
        }

        HoverHandler {
            id: gripHover
            cursorShape: root.actionEnabled ? Qt.SizeVerCursor : Qt.ClosedHandCursor
        }

        DragHandler {
            id: dragHandler

            enabled: root.actionEnabled
            target: null
            xAxis.enabled: false

            grabPermissions: PointerHandler.CanTakeOverFromItems
                             | PointerHandler.CanTakeOverFromHandlersOfDifferentType
            dragThreshold: 3

            property real lastStep: 0

            onActiveChanged: dragHandler.lastStep = 0

            onActiveTranslationChanged: {
                if (!dragHandler.active)
                    return

                let step = Math.round(dragHandler.activeTranslation.y / root.height)
                if (step === dragHandler.lastStep)
                    return

                root.dragMoveRequested(step - dragHandler.lastStep)
                dragHandler.lastStep = step
            }
        }
    }

    MouseArea {
        id: rowClickArea

        anchors.left: grip.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RebaseActionSelector {
        id: actionSelector

        anchors.left: parent.left
        anchors.leftMargin: root.columns.actionX ?? 0
        anchors.verticalCenter: parent.verticalCenter

        action: root.action
        actionEnabled: root.actionEnabled

        onActionPicked: (picked) => root.actionPicked(picked)
    }

    Text {
        id: shaText

        anchors.left: parent.left
        anchors.leftMargin: root.columns.shaX ?? 0
        anchors.verticalCenter: parent.verticalCenter
        width: (root.columns.shaWidth ?? 0) - 8

        text: root.shortHash
        color: Style.colors.mutedText
        opacity: root.isSetAside ? 0.5 : 1.0
        font.family: Style.fontTypes.jetBrainsMono
        font.pixelSize: Style.appFont.captionPt
        elide: Text.ElideRight
    }

    Text {
        id: summaryText

        anchors.left: parent.left
        anchors.leftMargin: root.columns.messageX ?? 0
        anchors.verticalCenter: parent.verticalCenter
        width: (root.columns.messageWidth ?? 0) - 12

        text: root.summary
        color: root.isSetAside ? Style.colors.mutedText : Style.colors.foreground
        opacity: root.isSetAside ? 0.6 : 1.0
        // Struck through once the commit is out of play -- dropped by the plan, or already replayed.
        font.strikeout: root.isSetAside
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.smallPt
        elide: Text.ElideRight
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: root.columns.authorX ?? 0
        anchors.verticalCenter: parent.verticalCenter
        width: (root.columns.authorWidth ?? 0) - 8

        text: root.author
        color: Style.colors.mutedText
        opacity: root.isSetAside ? 0.5 : 1.0
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.captionPt
        elide: Text.ElideRight
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: root.columns.dateX ?? 0
        anchors.verticalCenter: parent.verticalCenter
        width: (root.columns.dateWidth ?? 0) - 8

        text: root.authorDate ? Qt.formatDateTime(new Date(root.authorDate), "MMM d") : ""
        color: Style.colors.mutedText
        opacity: root.isSetAside ? 0.5 : 1.0
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.captionPt
        elide: Text.ElideRight
    }

    Text {
        visible: root.showStatus
        anchors.left: parent.left
        anchors.leftMargin: root.columns.statusX ?? 0
        anchors.verticalCenter: parent.verticalCenter
        width: (root.columns.statusWidth ?? 0) - 8

        text: root.status
        color: root.statusColor
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.captionPt
        elide: Text.ElideRight
    }

    Column {
        id: reorderButtons

        anchors.left: parent.left
        anchors.leftMargin: root.columns.reorderX ?? 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        opacity: root.actionEnabled && hoverHandler.hovered ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 120 } }

        Repeater {
            model: [{ up: true }, { up: false }]

            delegate: Rectangle {
                id: arrow

                required property var modelData

                readonly property bool arrowEnabled: arrow.modelData.up ? root.canMoveUp
                                                                        : root.canMoveDown

                width: Style.dp(22)
                height: Style.dp(15)
                radius: 3
                color: arrowMouse.containsMouse ? Style.colors.cardBackground : "transparent"
                opacity: arrow.arrowEnabled ? 1.0 : 0.25

                MouseArea {
                    id: arrowMouse

                    anchors.fill: parent
                    enabled: arrow.arrowEnabled
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (arrow.modelData.up)
                            root.moveUpRequested()
                        else
                            root.moveDownRequested()
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: arrow.modelData.up ? Style.icons.caretUp : Style.icons.caretDown
                    color: arrowMouse.containsMouse ? Style.colors.foreground
                                                    : Style.colors.mutedText
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.appFont.captionPt
                }
            }
        }
    }
}
