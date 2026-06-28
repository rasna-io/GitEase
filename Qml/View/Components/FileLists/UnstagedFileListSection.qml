import QtQuick
import QtQuick.Layouts

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * UnstagedFileListSection
 * Specialization of FileListSection for unstaged files.
 * Shows: Stage (+), Discard, Open
 * ************************************************************************************************/

FileListSection {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    title: "Unstaged Changes"
    emptyText: "No unstaged changes"

    /* Signals
     * ****************************************************************************************/
    signal stageFileRequested(string filePath, bool isDeleted)
    signal discardFileRequested(string filePath)
    signal openFileRequested(string filePath)
    signal stashFileRequested(string filePath)
    signal stageAllRequested()
    signal discardAllRequested()
    signal stashAllRequested()

    /* Children
     * ****************************************************************************************/
    headerActions: Component {
        RowLayout {
            spacing: 4

            ActionIconButton {
                iconText: Style.icons.archive
                tooltip: "Stash all"
                textColor: Style.colors.mutedText
                enabled: root.count > 0
                opacity: enabled ? 1 : 0.35

                onClicked: root.stashAllRequested()
            }

            ActionIconButton {
                iconText: Style.icons.trash
                tooltip: "Discard all"
                textColor: Style.colors.error
                enabled: root.count > 0
                opacity: enabled ? 1 : 0.35

                onClicked: root.discardAllRequested()
            }

            ActionIconButton {
                iconText: Style.icons.plus
                tooltip: "Stage all"
                textColor: Style.theme == Style.Light ?
                            Qt.darker(Style.colors.addedFile, 1.5) :
                            Qt.lighter(Style.colors.addedFile, 1.5)
                enabled: root.count > 0
                opacity: enabled ? 1 : 0.35

                onClicked: root.stageAllRequested()
            }
        }
    }

    rowDelegate: Component {
        UnstagedFileListRow {
            text: rowModelData && rowModelData.path ? rowModelData.path : ""
            status: rowModelData && rowModelData.status ? rowModelData.status : GitFileStatus.Unknown
            selected: root.selectedFilePath !== "" && root.selectedFilePath === (rowModelData && rowModelData.path ? rowModelData.path : "")

            onClicked: root.selectFile(text, rowModelData.status)

            onStageRequested: function(filePath, isDeleted) {
                root.stageFileRequested(filePath, rowModelData.status === GitFileStatus.Deleted)
            }

            onDiscardRequested: function(filePath) {
                root.discardFileRequested(filePath)
            }

            onStashRequested: function(filePath) {
                root.stashFileRequested(filePath)
            }

            onOpenRequested: function(filePath) {
                root.openFileRequested(filePath)
            }
        }
    }
}
