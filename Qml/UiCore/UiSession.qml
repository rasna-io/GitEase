import QtQuick

import GitEase

import "../Core/Controllers"
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
            configController.currentRepo = currentRepo
            stashController.currentRepo = currentRepo
        }

        onRepositorySelected: function(repo) {
            if (repo && repo.name) {
                root.notificationController.currentRepositoryKey = repo.name
            } else {
                root.notificationController.currentRepositoryKey = ""
            }
        }
    }

    property BranchController branchController: BranchController {}

    property RemoteController remoteController: RemoteController {}

    property CommitController commitController: CommitController {}

    property StatusController statusController: StatusController {}

    property BundleController bundleController: BundleController {}

    property ConfigController configController: ConfigController {}

    property StashController  stashController : StashController  {}

    property UserProfileController userProfileController: UserProfileController {
        appModel: root.appModel
        configController: root.configController
    }

    property ShellController shellController: ShellController {
        pageController : root.pageController
        repositoryController : root.repositoryController
    }

    property NotificationController notificationController: NotificationController {
        fileIO: root.appModel.fileIO
        appSettings: root.appModel.appSettings
    }

    property UiSessionPopups      popups
}

