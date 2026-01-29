import QtQuick

import GitEase

/*! ***********************************************************************************************
 * UserProfileController
 * Manages the creation, register, remove Profiles from both Git config and Application storage.
 * ************************************************************************************************/

QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property            AppModel                         appModel
    required property            ConfigController                 configController

    /* Signals
     * ****************************************************************************************/
    property Connections configConnections: Connections {
        target: configController
        function onCurrentRepoChanged(){
            root.loadAllProfiles()
        }
    }

    /* Functions
     * ****************************************************************************************/
    function loadAllProfiles() {
        root.appModel.userProfiles = []

        loadAppProfiles()

        loadGitConfigProfiles()

        let localProfile = root.appModel.userProfiles.find(p => p.levels.includes(Config.Local))
        if(!localProfile){
            localProfile = root.appModel.userProfiles.find(p => p.isDefault === true)
        }

        root.appModel.currentUserProfile = localProfile || null
    }

    function loadGitConfigProfiles() {
        var result = configController.getAllConfigs()
        if (result.success) {           
            for (var i = 0; i < result.data.length; i++) {
                var config = result.data[i]
                if (config.name && config.email) {
                    let userProfile = createUserProfile(
                        config.name,
                        "",
                        config.email,
                        config.level
                    )
                }
            }
        } else {
            console.warn("[UserProfileController] Failed to load git configs:", result.errorMessage)
        }
    }

    function loadAppProfiles() {
        let path = root.appModel.fileIO.configFilePath + "/" + root.appModel.fileName

        if (root.appModel.fileIO.isFileExist(path)) {
            root.appModel.fileIO.fileName = path
            let res = root.appModel.fileIO.read()

            let jsonContent = JSON.parse(root.appModel.fileIO.fileContent)
            let profiles = jsonContent.userProfiles || []

            for (let i = 0; i < profiles.length; i++) {
                let userProfile = root.createUserProfile(
                    profiles[i].username,
                    profiles[i].password,
                    profiles[i].email,
                    profiles[i].levels
                )
                // Restore isDefault state
                if (userProfile) {
                    if (profiles[i].isDefault === true) {
                        for (let j = 0; j < root.appModel.userProfiles.length; j++) {
                            if (root.appModel.userProfiles[j] !== userProfile) {
                                root.appModel.userProfiles[j].isDefault = false
                            }
                        }
                        userProfile.isDefault = true
                    } else {
                        userProfile.isDefault = false
                    }
                }
            }
        }
    }


    function findProfileByKey(username, email) {
        return root.appModel.userProfiles.find(profile => profile
                                               && profile.username === username
                                               && profile.email === email) || null
    }

    function removeLevelFromOtherProfiles(level, exceptUsername, exceptEmail) {
        if (level === Config.App) {
            return
        }

        for (let i = 0; i < root.appModel.userProfiles.length; i++) {
            let profile = root.appModel.userProfiles[i]
            if (profile.username === exceptUsername && profile.email === exceptEmail) {
                continue
            }

            let levelIndex = profile.levels.indexOf(level)
            if (levelIndex !== -1) {
                profile.levels.splice(levelIndex, 1)
                profile.levels = profile.levels.slice(0)
            }
        }
        
        root.appModel.userProfiles = root.appModel.userProfiles.slice(0)
    }

    function createUserProfile(username : string, password : string, email : string, level){
        let levelsArray = []
        if (typeof level === 'number') {
            levelsArray = [level]
        } else if (Array.isArray(level)) {
            levelsArray = level
        }

        const existing = findProfileByKey(username, email)
        if (existing) {
            for (let i = 0; i < levelsArray.length; i++) {
                let levelToAdd = levelsArray[i]
                if (!existing.levels.includes(levelToAdd)) {
                    if (levelToAdd !== Config.App) {
                        removeLevelFromOtherProfiles(levelToAdd, username, email)
                    }
                    
                    existing.levels.push(levelToAdd)
                }
            }
            existing.levels = existing.levels.slice(0)
            
            if(levelsArray.includes(Config.App))
                root.appModel.save()
                
            return existing
        }

        var userProfileComponent = Qt.createComponent("qrc:/GitEase/Qml/Core/Models/UserProfile.qml")
        if (userProfileComponent.status !== Component.Ready) {
            console.error("[UserProfileController] Failed to create UserProfile component:", userProfileComponent.errorString())
            return null
        }

        for (let i = 0; i < levelsArray.length; i++) {
            if (levelsArray[i] !== Config.App) {
                removeLevelFromOtherProfiles(levelsArray[i], username, email)
            }
        }

        var userProfile = userProfileComponent.createObject(root, {
            username: username,
            password: password,
            email: email,
            levels: levelsArray
        })

        root.appModel.userProfiles.push(userProfile)
        root.appModel.userProfiles = root.appModel.userProfiles.slice(0)

        if(levelsArray.includes(Config.App))
            root.appModel.save()

        return userProfile
    }

    function remove(username, email) {
        if(username === "" || email === "")
            return

        const idx = root.appModel.userProfiles.findIndex(profile => profile && profile.username === username && profile.email === email)
        if (idx < 0)
            return

        const profile = root.appModel.userProfiles[idx]

        for (let i = 0; i < profile.levels.length; i++) {
            if(profile.levels[i] !== Config.App){
                var result = configController.setConfig(profile.levels[i], "", "")
                if (!result.success) {
                    console.error("[UserProfileController] Failed to update git config:", result.errorMessage)
                    return
                }
            }
        }

        root.appModel.userProfiles = root.appModel.userProfiles.slice(0, idx).concat(root.appModel.userProfiles.slice(idx + 1))

        let localProfile = root.appModel.userProfiles.find(p => p.levels.includes(Config.Local))
        if(!localProfile){
            localProfile = root.appModel.userProfiles.find(p => p.isDefault === true)
        }

        root.appModel.currentUserProfile = localProfile || null

        root.appModel.save()
    }

    function edit(oldUsername, oldEmail, newUsername, newEmail, setAsDefault) {
        if(oldUsername === "" || oldEmail === "")
            return

        const idx = root.appModel.userProfiles.findIndex(profile => profile && profile.username === oldUsername && profile.email === oldEmail)
        if (idx < 0)
            return

        const profile = root.appModel.userProfiles[idx]
        
        if (oldUsername !== newUsername || oldEmail !== newEmail) {
            const existingProfile = findProfileByKey(newUsername, newEmail)
            if (existingProfile && existingProfile !== profile) {
                console.error("[UserProfileController] Cannot update profile: username/email combination already exists")
                return
            }
            profile.username = newUsername
            profile.email = newEmail
        }

        if (setAsDefault !== undefined && setAsDefault !== null) {
            if (setAsDefault === true) {
                for (let i = 0; i < root.appModel.userProfiles.length; i++) {
                    root.appModel.userProfiles[i].isDefault = false
                }
                profile.isDefault = true
            } else {
                profile.isDefault = false
            }
        }

        for (let i = 0; i < profile.levels.length; i++) {
            if(profile.levels[i] !== Config.App){
                removeLevelFromOtherProfiles(profile.levels[i], newUsername, newEmail)
                var result = configController.setConfig(profile.levels[i], newUsername, newEmail)
                if (!result.success) {
                    console.error("[UserProfileController] Failed to update git config:", result.errorMessage)
                    return
                }
            }
        }

        root.appModel.userProfiles = root.appModel.userProfiles.slice(0)

        if(root.appModel.currentUserProfile && 
           root.appModel.currentUserProfile.username === oldUsername && 
           root.appModel.currentUserProfile.email === oldEmail){
            root.appModel.currentUserProfile = profile
        }

        root.appModel.save()
    }

    function applyUserToRepository(username, email){
        const profile = findProfileByKey(username, email)
        
        if (!profile) {
            console.warn("Profile with username '" + username + "' and email '" + email + "' not found. Please select a valid profile.")
            return
        }

        var result = configController.setConfig(Config.Local, profile.username, profile.email)
        
        if (result.success) {
            loadAllProfiles()
        } else {
            console.error("[UserProfileController] Failed to apply user to repository:", result.errorMessage)
        }
    }
}
