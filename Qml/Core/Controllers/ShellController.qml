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
    required property RepositoryController      repositoryController
    required property NotificationController    notificationController

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

        if(!root.commandExecuted) {
            let action = root.arguments["init"] ? "init" : "open"
            notificationController.error(`can't ${action} ${root.arguments["path"]}`, ` Repository ${action} failed`, 5000)
        }

        // --page=page name is read directly by MainWindow.qml once its pages exist.

        // Handle stash commands
        if (root.arguments["stash-pop"])
            repositoryController?.gitStash?.pop(0)

        if (root.arguments["stash-apply"])
            repositoryController?.gitStash?.apply(0)

        if (root.arguments["stash-drop"])
            repositoryController?.gitStash?.remove(0)
    }

    /* Functions
     * ****************************************************************************************/
}
