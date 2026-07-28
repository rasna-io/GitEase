import QtQuick
import QtQuick.Controls

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RebaseActionSelector
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string action:         RebaseActions.pick
    property bool   actionEnabled:  true

    readonly property color accentColor: RebaseActions.colorOf(root.action)

    /* Signals
     * ****************************************************************************************/
    signal actionPicked(string action)

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: Math.max(Style.dp(64), label.implicitWidth + caret.implicitWidth + 20)
    implicitHeight: Style.dp(22)
    radius: 4

    opacity: root.actionEnabled ? 1.0 : 0.5

    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b,
                   pillMouse.containsMouse && root.actionEnabled ? 0.28 : 0.14)
    border.width: 1
    border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.5)

    Behavior on color { ColorAnimation { duration: 120 } }

    /* Children
     * ****************************************************************************************/
    MouseArea {
        id: pillMouse

        anchors.fill: parent
        enabled: root.actionEnabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: menu.open()
    }

    Text {
        id: label
        anchors.left: parent.left
        anchors.leftMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        text: root.action
        color: root.accentColor
        font.family: Style.fontTypes.jetBrainsMono
        font.pixelSize: Style.appFont.captionPt
    }

    Text {
        id: caret
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: Style.icons.caretDown
        color: root.accentColor
        font.family: Style.fontTypes.font6ProSolid
        font.pixelSize: Style.appFont.microPt
    }

    Popup {
        id: menu

        y: root.height + 2
        width: Style.dp(258)
        padding: 4

        background: Rectangle {
            color: Style.colors.contextMenuBackground
            border.color: Style.colors.contextMenuBorder
            border.width: 1
            radius: 6
        }

        contentItem: Column {
            spacing: 0

            Repeater {
                model: RebaseActions.all
                delegate: Column {
                    id: entry

                    required property string modelData

                    readonly property bool isCurrent: entry.modelData === root.action

                    width: menu.availableWidth
                    spacing: 0

                    //! todo: reword/squash/fixup/edit are not wired to the rebase backend yet, so
                    //!       they stay hidden until the corresponding operations are implemented.
                    visible: RebaseActions.isSupported(entry.modelData)

                    Item {
                        width: parent.width
                        height: Style.dp(7)
                        visible: RebaseActions.startsGroup(entry.modelData)

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Style.colors.contextMenuSeparator
                        }
                    }

                    Rectangle {
                        id: option

                        width: parent.width
                        height: Style.dp(28)
                        radius: 4
                        color: optionHover.hovered ? Style.colors.contextMenuHover : "transparent"

                        HoverHandler {
                            id: optionHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: {
                                menu.close()
                                if (!entry.isCurrent)
                                    root.actionPicked(entry.modelData)
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 7
                            anchors.verticalCenter: parent.verticalCenter
                            visible: entry.isCurrent
                            text: Style.icons.check
                            color: RebaseActions.menuColorOf(entry.modelData)
                            font.family: Style.fontTypes.font6ProSolid
                            font.pixelSize: Style.appFont.microPt
                        }

                        Text {
                            id: optionName

                            anchors.left: parent.left
                            anchors.leftMargin: Style.dp(24)
                            anchors.verticalCenter: parent.verticalCenter
                            text: entry.modelData
                            color: RebaseActions.menuColorOf(entry.modelData)
                            font.family: Style.fontTypes.jetBrainsMono
                            font.pixelSize: Style.appFont.captionPt
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: Style.dp(88)
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: RebaseActions.descriptionOf(entry.modelData)
                            color: Style.colors.mutedText
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.captionPt
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
