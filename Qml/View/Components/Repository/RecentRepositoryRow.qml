import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RecentRepositoryRow
 * A recent-repository list row: initial avatar, name (+ selected check) and path. Selectable and
 * double-clickable. Presentation only — the host wires onClicked / onDoubleClicked.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string repoName:    ""
    property string repoPath:    ""
    property color  avatarColor: Style.colors.repositoryAvatarDefault
    property bool   selected:    false
    property bool   isExists:    true

    readonly property string initial: repoName.length >= 1 ? repoName.charAt(0).toUpperCase() : "?"

    /* Signals
     * ****************************************************************************************/
    signal clicked()
    signal doubleClicked()
    signal relocateRequested()
    signal removeRequested()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: 50
    radius: 8
    color: {
        var accent = Style.colors.accent
        if (root.selected)
            return Qt.rgba(accent.r, accent.g, accent.b, rowMouse.containsMouse ? 0.25 : 0.12)
        if (rowMouse.containsMouse)
            return Qt.rgba(accent.r, accent.g, accent.b, 0.15)
        return Style.colors.secondaryBackground
    }
    border.width: root.selected ? 1 : 0
    border.color: Style.colors.accent
    scale: rowMouse.pressed ? 0.985 : 1.0

    Behavior on border.color {
        ColorAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }

    /* Children
     * ****************************************************************************************/
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: root.isExists ? 12 : (missingActions.width + 20)
        spacing: 10

        // Initial avatar
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 32
            height: 32
            radius: width / 2
            color: root.avatarColor
            opacity: root.isExists ? 1.0 : 0.5

            Text {
                anchors.centerIn: parent
                text: root.initial
                font.family: Style.fontTypes.inter
                font.weight: 700
                font.pixelSize: 13
                color: Style.theme === Style.Light
                       ? Qt.darker(root.avatarColor, 2.2)
                       : Qt.lighter(root.avatarColor, 2.2)
            }
        }

        // Name + path
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: root.repoName
                    font.family: Style.fontTypes.inter
                    font.weight: Font.DemiBold
                    font.pixelSize: 12
                    font.strikeout: !root.isExists
                    color: root.isExists ? Style.colors.foreground : Style.colors.utilitiesRowMissingText
                }

                Text {
                    visible: root.selected
                    text: Style.icons.check
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: 9
                    color: Style.colors.accent
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            ScrollingText {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                text: root.repoPath
                running: rowMouse.containsMouse
                color: root.isExists ? Style.colors.mutedText : Style.colors.utilitiesRowMissingText
                font.family: Style.fontTypes.inter
                font.pixelSize: 10
                font.strikeout: !root.isExists
            }
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.isExists ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
        onDoubleClicked: root.doubleClicked()
    }

    Row {
        id: missingActions
        visible: !root.isExists
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        ActionIconButton {
            width: 26
            height: 26
            iconText: Style.icons.edit
            tooltip: "Locate the new folder"
            textColor: Style.colors.accent
            backgroundColor: Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.12)
            onClicked: root.relocateRequested()
        }

        ActionIconButton {
            width: 26
            height: 26
            iconText: Style.icons.trash
            tooltip: "Remove from recents"
            textColor: Style.colors.utilitiesRowMissingText
            backgroundColor: Qt.rgba(Style.colors.utilitiesRowMissingText.r, Style.colors.utilitiesRowMissingText.g, Style.colors.utilitiesRowMissingText.b, 0.12)
            onClicked: root.removeRequested()
        }
    }
}
