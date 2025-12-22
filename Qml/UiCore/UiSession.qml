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
        currentRepository: appModel.currentRepository
    }

    property RepositoryController repositoryController: RepositoryController {
        appModel: root.appModel
    }
}

