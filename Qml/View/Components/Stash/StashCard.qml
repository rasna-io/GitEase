import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * StashCard
 * A single stash entry: reference + message + relative time on the first line, branch / base commit
 * / file count on the second, and the Apply, Pop, Drop and View diff actions on the third.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string stashRef:   ""
    property string message:    ""
    property string branchName: ""
    property string baseId:     ""
    property int    fileCount:  -1
    property var    dateTime:   null

    property bool   selected:   false

    readonly property bool hovered: hoverHandler.hovered

    readonly property bool   hasMessage:     root.message.trim().length > 0
    readonly property string displayMessage: root.hasMessage ? root.message.trim()
                                                             : qsTr("(no message)")

    readonly property string metaText: {
        let parts = []
        if (root.branchName.length > 0)
            parts.push(root.branchName)
        if (root.baseId.length > 0)
            parts.push(root.baseId)
        if (root.fileCount >= 0)
            parts.push(root.fileCount === 1 ? qsTr("1 file") : qsTr("%1 files").arg(root.fileCount))

        return parts.join("  •  ")
    }

    /* Signals
     * ****************************************************************************************/
    signal applyClicked()
    signal popClicked()
    signal dropClicked()
    signal viewDiffClicked()
    signal menuRequested(var overlayPosition)

    /* Reusable pill action button
     * ****************************************************************************************/
    component StashActionButton: AbstractButton {
        id: actionBtn

        property string trailingIcon:        ""
        property color  textColor:           Style.colors.stashActionText
        property color  hoverTextColor:      actionBtn.textColor
        property color  borderColor:         Style.colors.stashActionBorder
        property color  backgroundColor:     "transparent"
        property color hoverBackgroundColor: Style.colors.stashActionHoverBackground

        readonly property color effectiveTextColor: actionBtn.hovered ? actionBtn.hoverTextColor
                                                                      : actionBtn.textColor

        implicitHeight: Style.dp(24)
        implicitWidth: actionRow.implicitWidth + Style.dp(20)

        hoverEnabled: true

        font.family: Style.fontTypes.inter
        font.weight: Font.Medium
        font.pixelSize: Style.appFont.captionPt

        background: Rectangle {
            radius: Style.dp(4)
            color: actionBtn.hovered ? actionBtn.hoverBackgroundColor
                                     : actionBtn.backgroundColor
            border.width: 1
            border.color: actionBtn.borderColor

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }

        contentItem: Item {
            Row {
                id: actionRow
                anchors.centerIn: parent
                spacing: Style.dp(5)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: actionBtn.text
                    font: actionBtn.font
                    color: actionBtn.effectiveTextColor
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: actionBtn.trailingIcon.length > 0
                    text: actionBtn.trailingIcon
                    color: actionBtn.effectiveTextColor
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: actionBtn.font.pixelSize
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
        }
    }

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: layout.implicitHeight + Style.dp(20)
    radius: Style.dp(8)
    color: Style.colors.stashCardBackground
    border.width: 1
    border.color: root.selected ? Style.colors.stashCardBorderSelected
                                : (root.hovered ? Style.colors.stashCardBorderHover
                                                : Style.colors.stashCardBorder)

    Behavior on border.color {
        ColorAnimation {
            duration: 120
        }
    }

    /* Children
     * ****************************************************************************************/
    HoverHandler {
        id: hoverHandler
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: (mouse) => root.menuRequested(mapToItem(Overlay.overlay, mouse.x, mouse.y))
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Style.dp(10)
        spacing: Style.dp(6)

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.dp(6)

            Text {
                text: root.stashRef
                color: Style.colors.stashCardRef
                font.family: Style.fontTypes.jetBrainsMono
                font.pixelSize: Style.appFont.captionPt
            }

            ScrollingText {
                Layout.fillWidth: true
                text: root.displayMessage
                color: root.hasMessage ? Style.colors.stashCardMessage
                                       : Style.colors.stashCardRef
                font.family: Style.fontTypes.inter
                font.weight: Font.DemiBold
                font.pixelSize: Style.appFont.smallPt
            }

            Text {
                visible: text.length > 0
                text: root.relativeTime(root.dateTime)
                color: Style.colors.stashCardTime
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.captionPt
            }
        }

        ScrollingText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.metaText
            color: Style.colors.stashCardMeta
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.captionPt
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Style.dp(2)
            spacing: Style.dp(6)

            StashActionButton {
                text: qsTr("Apply")
                onClicked: root.applyClicked()
            }

            StashActionButton {
                text: qsTr("Pop")
                textColor: Style.colors.stashActionFilledText
                borderColor: Style.colors.stashActionFilledBackground
                backgroundColor: Style.colors.stashActionFilledBackground
                hoverBackgroundColor: Style.colors.stashActionFilledHoverBackground
                onClicked: root.popClicked()
            }

            StashActionButton {
                text: qsTr("Drop")
                textColor: Style.colors.stashActionDangerText
                borderColor: Style.colors.stashActionDangerBorder
                hoverBackgroundColor: Style.colors.stashActionDangerHoverBackground
                onClicked: root.dropClicked()
            }

            Item {
                Layout.fillWidth: true
            }

            StashActionButton {
                text: qsTr("View diff")
                trailingIcon: Style.icons.arrowRight

                textColor: Style.colors.stashDiffLink
                hoverTextColor: Style.colors.stashDiffLinkHover
                borderColor: Style.colors.stashCardBorder

                onClicked: root.viewDiffClicked()
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function relativeTime(dateTime) {
        if (!dateTime)
            return ""

        const now = new Date()
        const date = new Date(dateTime)
        const minutes = Math.floor((now - date) / 60000)
        const hours = Math.floor(minutes / 60)
        const days = Math.floor(hours / 24)

        if (minutes < 1)
            return qsTr("Just now")
        if (minutes < 60)
            return qsTr("%1m ago").arg(minutes)
        if (hours < 24)
            return qsTr("%1h ago").arg(hours)
        if (days === 1)
            return qsTr("Yesterday")
        if (days < 7)
            return qsTr("%1d ago").arg(days)

        return now.getFullYear() === date.getFullYear() ? Qt.formatDate(date, "MMM d")
                                                        : Qt.formatDate(date, "MMM d, yyyy")
    }
}
