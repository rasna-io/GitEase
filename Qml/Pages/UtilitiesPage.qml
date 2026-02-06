import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * UtilitiesPage
 * Utilities Page : import export git bundle and etc.
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var page: null

    property BranchController branchController: null
    property BundleController bundleController: null
    property RemoteController remoteController: null
    property UiSessionPopups  uiSessionPopups: null

    property StashController  stashController   : null

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Children
     * ****************************************************************************************/

    GridLayout {
        anchors.fill: parent
        columns: 4
        rows: 2
        columnSpacing: 5
        rowSpacing: 5

        ImportExportBundleDock {
            Layout.preferredHeight: 370
            Layout.preferredWidth: 261
            Layout.fillWidth: false

            branchController: root.branchController
            bundleController: root.bundleController
        }

        RemoteView {
            Layout.preferredHeight: 370
            Layout.preferredWidth: 310
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignTop

            remoteController: root.remoteController
            addEditRemotePopup: uiSessionPopups.addEditRemotePopup
        }

        BranchManagementView {
            Layout.preferredHeight: 370
            Layout.preferredWidth: 350
            Layout.fillWidth: false
            branchController: root.branchController
            addBranchPopup: uiSessionPopups.addBranchPopup
        }

        StashManagerDock {
            Layout.preferredHeight: 370
            Layout.preferredWidth: 261
            Layout.fillWidth: false

            stashController: root.stashController
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 370
            Layout.preferredWidth: 261
            Layout.fillWidth: false

            stashController: root.stashController
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.columnSpan: 3
        }
    }
}
