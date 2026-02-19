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

        notificationController: root.notificationController

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



    property RemoteController remoteController: RemoteController {}

    property CommitController commitController: CommitController {}

    property StatusController statusController: StatusController {}

    property BundleController bundleController: BundleController {}

    property ConfigController configController: ConfigController {}

    property StashController  stashController : StashController  {}

    property ActivityController activityController: ActivityController {}

    property UserProfileController userProfileController: UserProfileController {
        appModel: root.appModel
        configController: root.configController
        notificationController: root.notificationController
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

    property BranchController branchController: BranchController {

        onGitCommandGenerated: function(command){
            console.log(command)
            activityController.addActivity(command, "Branch")
        }
    }

}

