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
    property   RepositoryController         repositoryController
    property   BranchController             branchController
    property   RemoteController             remoteController
    property   UserAuthenticationPopup      userAuthenticationPopup
    property   string                       rootPath
    property   GitScanner                   gitScanner:               GitScanner{}

    /* Object Properties
     * ****************************************************************************************/
    width: 800
    height: 650
    padding: 12

    /* Children
     * ****************************************************************************************/
    contentItem: RepoForest {
        id: repoForest
        repositoryController: root.repositoryController
        branchController: root.branchController
        remoteController: root.remoteController
        userAuthenticationPopup: root.userAuthenticationPopup
        rootPath: root.rootPath
        gitScanner: root.gitScanner

        onCloseRequested: root.close()
    }

    onAboutToHide: root.resetRepoForest()
    onClosed: root.resetRepoForest()

    /* Functions
     * ****************************************************************************************/
    function resetRepoForest() {
        repoForest.reposModel = []
        repoForest.pat = ""
        repoForest.pendingOperation = ""
        repoForest.selectedIndexes = []
        repoForest.isRunning = false
        repoForest.operationQueue = []
        repoForest.queueState = RepoForest.QueueState.Ready
        gitScanner.stop()
    }
}
