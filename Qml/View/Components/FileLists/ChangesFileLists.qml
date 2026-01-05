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

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: 1
    implicitHeight: 1

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        FileListSection {
            id: stagedSection
            Layout.fillWidth: true
            Layout.fillHeight: wantsFillHeight
            Layout.minimumHeight: 32
            Layout.preferredHeight: expanded ? -1 : 32

            title: "Staged Changes"
            emptyText: "No staged changes"
            model: root.stagedModel

            selectedFilePath: root.selectedFilePath
            onFileSelected: function(filePath) {
                root.selectedFilePath = filePath
                root.fileSelected(filePath)
            }
        }

        FileListSection {
            id: unstagedSection
            Layout.fillWidth: true
            Layout.fillHeight: wantsFillHeight
            Layout.minimumHeight: 32
            Layout.preferredHeight: expanded ? -1 : 32

            title: "Unstaged Changes"
            emptyText: "No unstaged changes"
            model: root.unstagedModel

            selectedFilePath: root.selectedFilePath
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
