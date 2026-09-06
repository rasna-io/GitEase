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
    property color  avatarColor: "#B9FAB9"
    property bool   selected:    false

    readonly property string initial: repoName.length >= 1 ? repoName.charAt(0).toUpperCase() : "?"

    /* Signals
     * ****************************************************************************************/
    signal clicked()
    signal doubleClicked()

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

    /* Children
     * ****************************************************************************************/
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        spacing: 10

        // Initial avatar
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 32
            height: 32
            radius: width / 2
            color: root.avatarColor

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
                    color: Style.colors.foreground
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
                color: Style.colors.mutedText
                font.family: Style.fontTypes.inter
                font.pixelSize: 10
            }
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onDoubleClicked: root.doubleClicked()
    }
}
