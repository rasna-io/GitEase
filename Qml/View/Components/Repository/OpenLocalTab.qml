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

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: col.implicitHeight + 32

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
                onTextChanged: root.selectedPath = text
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
            visible: root.selectedPath !== ""
            radius: 8
            color: Qt.rgba(Style.colors.notificationSuccessIcon.r, Style.colors.notificationSuccessIcon.g, Style.colors.notificationSuccessIcon.b, 0.10)
            border.width: 1
            border.color: Qt.rgba(Style.colors.notificationSuccessIcon.r, Style.colors.notificationSuccessIcon.g, Style.colors.notificationSuccessIcon.b, 0.45)

            RepoValidationLine {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                strong: {
                    var p = root.selectedPath.replace(/[\/\\]+$/, "")
                    return p.split(/[\/\\]/).pop() || "Repository"
                }
                muted: "— Git repository, ready to open"
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
