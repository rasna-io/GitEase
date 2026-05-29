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

    property WindowController   windowController:   WindowController    {}

    property ActivityController activityController: ActivityController {}

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
            mergeController.currentRepo = currentRepo
            rebaseController.currentRepo = currentRepo
            cherryPickController.currentRepo = currentRepo
            conflictController.currentRepo = currentRepo
            tagController.currentRepo = currentRepo
            pluginController.currentRepo = currentRepo
        }

        onRepositorySelected: function(repo) {
            if (repo && repo.name) {
                root.notificationController.currentRepositoryKey = repo.name
            } else {
                root.notificationController.currentRepositoryKey = ""
            }
        }
    }

    property BranchController branchController: BranchController {
        onGitCommandGenerated: function(command){
            activityController.addActivity(command)
        }
    }

    property RemoteController remoteController: RemoteController {
        onGitCommandGenerated: function(command){
            activityController.addActivity(command)
        }
    }

    property CommitController commitController: CommitController {
        onGitCommandGenerated: function(command){
            activityController.addActivity(command)
        }
    }

    property StatusController statusController: StatusController {
        onGitCommandGenerated: function(command){
            activityController.addActivity(command)
        }
    }

    property BundleController bundleController: BundleController {
        onGitCommandGenerated: function(command){
            activityController.addActivity(command)
        }
    }

    property ConfigController configController: ConfigController {
        onGitCommandGenerated: function(command){
            activityController.addActivity(command)
        }
    }

    property StashController  stashController : StashController  {
        onGitCommandGenerated: function(command){
            activityController.addActivity(command)
        }
    }

    property TagController tagController: TagController {
        onGitCommandGenerated: function(command){
            activityController.addActivity(command)
        }
    }

    property UserProfileController userProfileController: UserProfileController {
        appModel: root.appModel
        configController: root.configController
        notificationController: root.notificationController
    }

    property ShellController shellController: ShellController {
        pageController : root.pageController
        repositoryController : root.repositoryController
        notificationController: root.notificationController
    }

    property NotificationController notificationController: NotificationController {
        fileIO: root.appModel.fileIO
        appSettings: root.appModel.appSettings
    }

    property MergeController mergeController: MergeController {
        onGitCommandGenerated: function(command){
            activityController.addActivity(command)
        }
    }

    property RebaseController rebaseController: RebaseController {
        onGitCommandGenerated: function(command){
            activityController.addActivity(command)
        }
    }

    property CherryPickController cherryPickController: CherryPickController {
        onGitCommandGenerated: function(command){
            activityController.addActivity(command)
        }
    }

    property ConflictController conflictController: ConflictController {
        onGitCommandGenerated: function(command){
            activityController.addActivity(command)
        }
    }

    property PluginController pluginController: PluginController {
        notificationController: root.notificationController
    }

    property UiSessionPopups      popups
}

