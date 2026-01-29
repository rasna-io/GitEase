import QtQuick

import GitEase
import GitEase_Style

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

    property                Repository        currentRepository:        null

    property                var               recentRepositories:       []

    property                FileIO            fileIO:                   FileIO {}

    property                var               pages:                    []

    property                Page              currentPage:              null

    property                AppSettings       appSettings:              AppSettings {}

    property                var               userProfiles:             []

    property                UserProfile       currentUserProfile:       null


    /* Signals
     * ****************************************************************************************/

    /* Functions
     * ****************************************************************************************/
    
    /**
     * Save application state to persistent storage
     */
    function save() {
        console.log("[Config] Saving configuration to:", fileIO.configFilePath + "/" + root.fileName);

        let profilesSerialized = []
        for(let i = 0 ; i < root.userProfiles.length ; ++i){
            let profile = root.userProfiles[i]
            if(profile.levels.includes(Config.App)) {
                if (!profile.levels.includes(Config.App)) {
                    profile.levels.push(Config.App)
                }
                profilesSerialized.push(profile)
            }
        }

        let config = {
            recentRepositories: root.recentRepositories,
            userProfiles: profilesSerialized,
            settings: root.appSettings.serialize()
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
        root.appSettings.deserialize(jsonContent.settings)

        console.info("[Config] Configuration successfully loaded.");
    }

    /**
     * Set default values for application state
     */
    function setDefaults() {

    }


    Component.onCompleted: {
        Style.currentTheme = Qt.binding(function() { return appSettings.appearanceSettings.currentTheme})
        load()
    }

}
