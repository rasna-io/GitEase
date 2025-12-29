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
        pages: appModel.pages
        currentPage: appModel.currentPage
    }

    property RepositoryController repositoryController: RepositoryController {
        appModel: root.appModel
    }
}

