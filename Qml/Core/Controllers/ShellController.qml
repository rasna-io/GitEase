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
    property          string                selectedPath:           ""
    property          bool                  commandExecuted:        false

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

        // --path=""
        if(!root.arguments["path"])
            return

        root.selectedPath = repositoryController?.appModel?.fileIO.pathNormalizer(root.arguments["path"])

        // --init
        if(root.arguments["init"]) {
            root.commandExecuted = repositoryController?.gitInit(root.selectedPath)
        } else { // --open
            root.commandExecuted = repositoryController?.openRepository(root.selectedPath)
        }

        // --page=page name
        if(root.arguments["page"]) {
            pageController.switchToPage(root.arguments["page"])
        }
    }

    /* Functions
     * ****************************************************************************************/
}
