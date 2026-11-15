import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * OpenLocalTab
 * Browse / type the path of an existing repository. Exposes the path via `selectedPath`.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property AppModel appModel
    property string   selectedPath: ""

    readonly property string typedPath:   pathField.text
    readonly property bool   isGitRepo:   root.typedPath !== ""
                                          && (root.appModel?.fileIO?.isGitRepository(root.typedPath) ?? false)

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: col.implicitHeight + 32

    /* Signal Handlers
     * ****************************************************************************************/
    onIsGitRepoChanged: root.selectedPath = root.isGitRepo ? root.typedPath : ""

    onTypedPathChanged: root.selectedPath = root.isGitRepo ? root.typedPath : ""

    /* Functions
     * ****************************************************************************************/
    function reset() {
        root.selectedPath = ""
        pathField.text = ""
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: col
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 6

        RepoSectionLabel {
            text: "Repository location"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            RepoTextField {
                id: pathField
                placeholderText: "C:/Users/Username/Documents/MyRepository"
            }

            RepoBrowseButton {
                onClicked: folderDialog.open()
            }
        }

        Text {
            text: "Select a folder containing a .git directory"
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.captionPt
            color: Style.colors.mutedText
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.preferredHeight: 38
            visible: root.typedPath !== ""
            radius: 8
            color: Qt.rgba(accent.r, accent.g, accent.b, 0.10)
            border.width: 1
            border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.45)

            readonly property color accent: root.isGitRepo ? Style.colors.notificationSuccessIcon
                                                           : Style.colors.notificationErrorIcon

            RepoValidationLine {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                valid: root.isGitRepo
                strong: {
                    var p = root.typedPath.replace(/[\/\\]+$/, "")
                    return p.split(/[\/\\]/).pop() || "Repository"
                }
                muted: root.isGitRepo ? "— Git repository, ready to open"
                                      : "— Not a Git repository (no .git directory found)"
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Select Repository Folder"
        currentFolder: root.appModel?.appSettings?.generalSettings?.defaultPath ?? ""

        onAccepted: {
            if (folderDialog.selectedFolder)
                pathField.text = root.appModel.fileIO.pathNormalizer(folderDialog.selectedFolder.toString())
        }
    }
}
