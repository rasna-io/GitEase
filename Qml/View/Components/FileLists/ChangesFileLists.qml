import QtQuick
import QtQuick.Layouts

/*! ***********************************************************************************************
 * ChangesFileLists
 * Two stacked file lists used in Committing page:
 *   - Staged Changes (top)
 *   - Unstaged Changes (bottom)
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var unstagedModel: []
    property var stagedModel: []
    property string selectedFilePath: ""

    /* Signals
     * ****************************************************************************************/
    signal fileSelected(string filePath)
    signal stageFileRequested(string filePath)
    signal unstageFileRequested(string filePath)
    signal discardFileRequested(string filePath)
    signal openFileRequested(string filePath)
    signal stageAllRequested()
    signal unstageAllRequested()
    signal discardAllRequested()
    signal stashAllRequested(string section)

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: 1
    implicitHeight: 1

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        StagedFileListSection {
            id: stagedSection
            Layout.fillWidth: true
            Layout.fillHeight: wantsFillHeight
            Layout.minimumHeight: 32
            Layout.preferredHeight: expanded ? -1 : 32

            model: root.stagedModel

            selectedFilePath: root.selectedFilePath

            onUnstageFileRequested: function(filePath) {
                root.unstageFileRequested(filePath)
            }

            onOpenFileRequested: function(filePath) {
                root.openFileRequested(filePath)
            }

            onUnstageAllRequested: function() {
                root.unstageAllRequested()
            }

            onStashAllRequested: function() {
                root.stashAllRequested("staged")
            }

            onFileSelected: function(filePath) {
                root.selectedFilePath = filePath
                root.fileSelected(filePath)
            }
        }

        UnstagedFileListSection {
            id: unstagedSection
            Layout.fillWidth: true
            Layout.fillHeight: wantsFillHeight
            Layout.minimumHeight: 32
            Layout.preferredHeight: expanded ? -1 : 32

            model: root.unstagedModel

            selectedFilePath: root.selectedFilePath

            onStageFileRequested: function(filePath) {
                root.stageFileRequested(filePath)
            }

            onDiscardFileRequested: function(filePath) {
                root.discardFileRequested(filePath)
            }

            onOpenFileRequested: function(filePath) {
                root.openFileRequested(filePath)
            }

            onStageAllRequested: function() {
                root.stageAllRequested()
            }

            onDiscardAllRequested: function() {
                root.discardAllRequested()
            }

            onStashAllRequested: function() {
                root.stashAllRequested("unstaged")
            }

            onFileSelected: function(filePath) {
                root.selectedFilePath = filePath
                root.fileSelected(filePath)
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: !(stagedSection.wantsFillHeight && unstagedSection.wantsFillHeight)
            Layout.preferredHeight: 0
            visible: true
        }
    }
}
