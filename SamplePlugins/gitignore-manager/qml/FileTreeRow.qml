import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * FileTreeRow
 * One row of the file tree, laid out like the file panel of the commit browser: checkbox,
 * indentation, caret, icon, JetBrains Mono name, status pill and a LED for folders with changes.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! { kind: "folder"|"file", depth, name, path, status?, file? } from FileTree.buildRows().
    property var  rowData:    null
    property bool selected:   false
    //! A selected folder above this row already covers it.
    property bool covered:    false
    property bool open:       false
    //! A folder that holds changed or untracked files.
    property bool hasChanges: false

    readonly property bool   isFolder:  rowData !== null && rowData.kind === "folder"
    readonly property var    file:      isFolder || rowData === null ? null : rowData.file
    //! An ignored folder is a single entry from git and cannot be opened.
    readonly property bool   isLeafDir: file !== null && file.isDir
    readonly property bool   isIgnored: file !== null && file.status === "ignored"
    readonly property string status:    rowData === null ? "" : isFolder ? rowData.status : file.status

    readonly property color fill: selected ? Style.colors.accent : Style.colors.fileBrowserRowHoverBg

    /* Signals
     * ****************************************************************************************/
    //! The checkbox or (for files) the row was clicked.
    signal toggled()
    //! A folder row was clicked: open or close it.
    signal expandToggled()

    /* Object Properties
     * ****************************************************************************************/
    height: Style.dp(26)
    radius: 4
    color: selected || rowHover.hovered ? fill : Qt.rgba(fill.r, fill.g, fill.b, 0)

    Behavior on color { ColorAnimation { duration: Style.motionFast } }

    /* Children
     * ****************************************************************************************/
    HoverHandler {
        id: rowHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: {
            if (root.isFolder)
                root.expandToggled()
            else
                root.toggled()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.dp(6)
        anchors.rightMargin: Style.dp(8)
        spacing: Style.dp(5)

        GitignoreCheckBox {
            Layout.preferredWidth: Style.dp(24)
            checked: root.selected
            enabled: !root.covered
            onAccent: root.selected
            onToggled: root.toggled()
        }

        // Indentation
        Item {
            Layout.preferredWidth: (root.rowData ? root.rowData.depth : 0) * Style.dp(14)
            Layout.fillHeight: true
        }

        // Caret (folders only)
        Item {
            Layout.preferredWidth: Style.dp(12)
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                visible: root.isFolder
                text: Style.icons.caretRight
                rotation: root.open ? 90 : 0
                font.family: Style.fontTypes.font6Pro
                font.pixelSize: Style.appFont.captionPt
                color: root.selected ? Style.colors.selectedText : Style.colors.mutedText

                Behavior on rotation {
                    NumberAnimation {
                        duration: Style.motionFast
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        // Icon
        Text {
            text: root.isFolder || root.isLeafDir ? Style.icons.folder : Style.icons.file
            font.family: Style.fontTypes.font6Pro
            font.pixelSize: Style.appFont.smallPt
            color: root.isIgnored ? Style.colors.mutedText
                 : root.isFolder || root.isLeafDir ? Style.colors.warning : Style.colors.secondaryText
        }

        // Name
        Text {
            Layout.fillWidth: true
            text: root.rowData ? root.rowData.name + (root.isLeafDir ? "/" : "") : ""
            elide: Text.ElideRight
            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.mediumPt
            color: root.selected ? Style.colors.selectedText
                 : root.isIgnored ? Style.colors.mutedText : Style.colors.foreground
        }

        // Tracked although a rule matches it
        Text {
            visible: root.file !== null && root.file.trackedIgnored
            text: Style.icons.warning
            font.family: Style.fontTypes.font6Pro
            font.pixelSize: Style.appFont.captionPt
            color: Style.colors.warning

            HoverHandler { id: trackedHover }

            GitignoreToolTip {
                visible: trackedHover.hovered
                text: "A rule matches this file, but it is already tracked, so Git keeps tracking it"
            }
        }

        // LED: the folder holds changed files
        Rectangle {
            Layout.preferredWidth: 5
            Layout.preferredHeight: 5
            radius: 2.5
            color: Style.colors.modifiediedFile
            visible: root.isFolder && root.hasChanges
        }

        // The warning and the LED come first so the status badges line up at the right edge.
        GitignoreStatusBadge {
            status: root.status
        }
    }
}
