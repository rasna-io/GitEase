import QtQuick
import QtQuick.Layouts

import GitEase
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
    title           : "Staged"
    emptyText       : "No staged changes"
    emptySubText    : "Stage files below to commit"
    fillWhenEmpty   : true

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
                iconText: Style.icons.archive
                tooltip: "Stash all"
                textColor: Style.colors.actionIconIdle
                hoverTextColor: Style.colors.stashAmber
                enabled: root.count > 0
                opacity: enabled ? 1 : 0.35

                onClicked: root.stashAllRequested()
            }

            ActionIconButton {
                iconText: Style.icons.minus
                tooltip: "Unstage all"
                textColor: Style.colors.discardRed
                hoverTextColor: Style.colors.discardRed
                hoverBackgroundColor: Qt.rgba(Style.colors.discardRed.r, Style.colors.discardRed.g, Style.colors.discardRed.b, 0.1)
                enabled: root.count > 0
                opacity: enabled ? 1 : 0.35

                onClicked: root.unstageAllRequested()
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
