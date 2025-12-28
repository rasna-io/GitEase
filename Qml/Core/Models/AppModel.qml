import QtQuick

import GitEase

/*! ***********************************************************************************************
 * AppModel
 * Main application data model managing repositories, current repository state, and recent repositories list
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    readonly    property    string            fileName:                "GitEase.json"

    property                var               repositories:             []

    property                var               currentRepository:        null

    property                var               recentRepositories:       []

    property                FileIO            fileIO:                   FileIO {}


    /* Signals
     * ****************************************************************************************/


    /* Functions
     * ****************************************************************************************/
    
    /**
     * Save application state to persistent storage
     */
    function save() {
        console.log("[Config] Saving configuration to:", fileIO.configFilePath + "/" + root.fileName);

        let config = {
            recentRepositories: root.recentRepositories,
        }

        let jsonContent = JSON.stringify(config, null, 2);
        fileIO.fileName = fileIO.configFilePath + "/" + root.fileName
        fileIO.fileContent = jsonContent
        fileIO.write()
        console.info("[Config] Configuration successfully saved.");
    }

    /**
     * Load application state from persistent storage
     */
    function load() {
        let path = fileIO.configFilePath + "/" + root.fileName
        console.log("[Config] Attempting to load:", path);

        if (!fileIO.isFileExist(path)) {
            console.warn("[Config] File not found at path:", path);
            console.log("[Config] Creating config directory at:", fileIO.configFilePath);
            fileIO.createDir(fileIO.configFilePath)
            setDefaults()
            return
        }

        fileIO.fileName = path
        let res = fileIO.read()

        let jsonContent = JSON.parse(fileIO.fileContent)

        root.recentRepositories = jsonContent.recentRepositories

        console.info("[Config] Configuration successfully loaded.");
    }

    /**
     * Set default values for application state
     */
    function setDefaults() {

    }


    Component.onCompleted: load()

}
