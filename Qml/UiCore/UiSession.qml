import QtQuick

import GitEase

/*! ***********************************************************************************************
 * UiSession
 * Main UI session manager that coordinates application controllers and models
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property AppModel             appModel:             AppModel {}

    property PageController       pageController:       PageController {
        appModel: root.appModel
    }

    property RepositoryController repositoryController: RepositoryController {
        appModel: root.appModel
        onCurrentRepoChanged: {
            branchController.currentRepo = currentRepo
            remoteController.currentRepo = currentRepo
            commitController.currentRepo = currentRepo
            statusController.currentRepo = currentRepo
            bundleController.currentRepo = currentRepo
        }
    }

    property BranchController branchController: BranchController {}

    property RemoteController remoteController: RemoteController {}

    property CommitController commitController: CommitController {}

    property StatusController statusController: StatusController {}

    property BundleController bundleController: BundleController {}

    property UserProfileController userProfileController: UserProfileController {
        userProfiles: root.appModel.userProfiles
        currentUserProfile: root.appModel.currentUserProfile
    }

    property UiSessionPopups      popups
}

