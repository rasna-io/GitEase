import QtQuick

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * ShellController
 * Manages the Commands of cmd
 * ************************************************************************************************/

QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property PageController        pageController
    required property RepositoryController  repositoryController

    property          var                   arguments:              ({})
    property          bool                  pageSelected:           false
    property          bool                  repositorySelected:     false

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/
    Component.onCompleted: {
        Qt.application.arguments.forEach(a => {
            if (a.startsWith("--")) {
                let p = a.substring(2).split("=")
                root.arguments[p[0]] = p.length > 1 ? p[1] : true
            }
        })

        if(root.arguments["repo"]) {
            root.repositorySelected = repositoryController.openRepository(root.arguments["repo"])
        }

        if(root.arguments["page"]) {
            pageController.switchToPage(root.arguments["page"])
            root.pageSelected = true
        }
    }

    /* Functions
     * ****************************************************************************************/
}
