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
    title: "Unstaged"
    emptyText: "No unstaged changes"
    emptySubText: "Your working tree is clean"

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
                textColor: Style.colors.actionIconIdle
                hoverTextColor: Style.colors.stashAmber
                enabled: root.count > 0
                opacity: enabled ? 1 : 0.35

                onClicked: root.stashAllRequested()
            }

            ActionIconButton {
                iconText: Style.icons.plus
                tooltip: "Stage all"
                textColor: Style.colors.stageGreen
                hoverTextColor: Style.colors.stageGreen
                hoverBackgroundColor: Qt.rgba(Style.colors.stageGreen.r, Style.colors.stageGreen.g, Style.colors.stageGreen.b, 0.1)
                enabled: root.count > 0
                opacity: enabled ? 1 : 0.35

                onClicked: root.stageAllRequested()
            }

            ActionIconButton {
                iconText: Style.icons.close
                tooltip: "Discard all"
                textColor: Style.colors.discardRed
                hoverTextColor: Style.colors.discardRed
                hoverBackgroundColor: Qt.rgba(Style.colors.discardRed.r, Style.colors.discardRed.g, Style.colors.discardRed.b, 0.1)
                enabled: root.count > 0
                opacity: enabled ? 1 : 0.35

                onClicked: root.discardAllRequested()
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
