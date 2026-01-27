import QtQuick
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * StagedFileListSection
 * Specialization of FileListSection for staged files.
 * Shows: Unstage (-), Open
 * ************************************************************************************************/

FileListSection {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    title: "Staged Changes"
    emptyText: "No staged changes"

    /* Signals
     * ****************************************************************************************/
    signal unstageFileRequested(string filePath)
    signal openFileRequested(string filePath)
    signal unstageAllRequested()
    signal stashAllRequested()

    /* Children
     * ****************************************************************************************/
    headerActions: Component {
        RowLayout {
            spacing: 4

            ActionIconButton {
                iconText: Style.icons.minus
                tooltip: "Unstage all"
                textColor: Style.colors.deletededFile
                enabled: root.count > 0
                opacity: enabled ? 1 : 0.35

                onClicked: root.unstageAllRequested()
            }

            ActionIconButton {
                iconText: Style.icons.archive
                tooltip: "Stash all"
                textColor: Style.colors.mutedText
                enabled: root.count > 0
                opacity: enabled ? 1 : 0.35

                onClicked: root.stashAllRequested()
            }
        }
    }

    rowDelegate: Component {
        StagedFileListRow {
            text: rowModelData && rowModelData.path ? rowModelData.path : ""
            status: rowModelData && rowModelData.status ? rowModelData.status : GitFileStatus.Unknown
            selected: root.selectedFilePath !== "" && root.selectedFilePath === (rowModelData && rowModelData.path ? rowModelData.path : "")

            onClicked: root.selectFile(text)

            onUnstageRequested: function(filePath) {
                root.unstageFileRequested(filePath)
            }

            onOpenRequested: function(filePath) {
                root.openFileRequested(filePath)
            }
        }
    }
}
