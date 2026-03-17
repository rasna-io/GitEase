import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RepoForestPopup
 * ************************************************************************************************/

IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property   RepositoryController   repositoryController
    property   BranchController       branchController
    property   RemoteController       remoteController
    property   string                 rootPath
    property   GitScanner             gitScanner:               GitScanner{}

    /* Object Properties
     * ****************************************************************************************/
    width: 800
    height: 650
    padding: 12

    /* Children
     * ****************************************************************************************/
    contentItem: RepoForest {
        repositoryController: root.repositoryController
        branchController: root.branchController
        remoteController: root.remoteController
        rootPath: root.rootPath
        gitScanner: root.gitScanner

        onCloseRequested: root.close()
    }

    onAboutToHide: gitScanner.stop()
    onClosed: gitScanner.stop()

    /* Functions
     * ****************************************************************************************/
}
