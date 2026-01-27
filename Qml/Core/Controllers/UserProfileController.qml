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

        let localProfile = root.appModel.userProfiles.find(p => p.level === Config.Local)
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
                    profiles[i].level,
                )
                // Restore profileId and isDefault state
                if (userProfile) {
                    // Restore the saved profileId if it exists, otherwise keep the generated one
                    if (profiles[i].profileId) {
                        userProfile.profileId = profiles[i].profileId
                    }
                    if (profiles[i].isDefault) {
                        userProfile.isDefault = true
                    }
                }
            }
        }
    }


    function generateProfileId() {
        return "profile_" + Date.now() + "_" + Math.floor(Math.random() * 1000000)
    }

    function findProfile(username, email, level) {
        return root.appModel.userProfiles.find(profile => profile
                                               && profile.username === username
                                               && profile.email === email
                                               && profile.level === level) || null
    }

    function findProfileById(profileId) {
        return root.appModel.userProfiles.find(profile => profile
                                               && profile.profileId === profileId) || null
    }

    function createUserProfile(username : string, password : string, email : string, level : int){
        const existing = findProfile(username, email, level)
        if (existing) {
            return existing
        }

        var userProfileComponent = Qt.createComponent("qrc:/GitEase/Qml/Core/Models/UserProfile.qml")
        if (userProfileComponent.status !== Component.Ready) {
            console.error("[UserProfileController] Failed to create UserProfile component:", userProfileComponent.errorString())
            return null
        }

        var userProfile = userProfileComponent.createObject(root, {
            profileId: generateProfileId(),
            username: username,
            password: password,
            email: email,
            level: level
        })

        root.appModel.userProfiles.push(userProfile)
        root.appModel.userProfiles = root.appModel.userProfiles.slice(0)

        if(level === Config.App)
            root.appModel.save()

        return userProfile
    }

    function remove(profileId) {
        if(profileId === "")
            return

        const idx = root.appModel.userProfiles.findIndex(profile => profile && profile.profileId === profileId)
        if (idx < 0)
            return

        const profile = root.appModel.userProfiles[idx]

        if(profile.level !== Config.App){
            var result = configController.setConfig(profile.level, "", "")
            if (!result.success) {
                console.error("[UserProfileController] Failed to update git config:", result.errorMessage)
                return
            }
        }

        root.appModel.userProfiles = root.appModel.userProfiles.slice(0, idx).concat(root.appModel.userProfiles.slice(idx + 1))

        let localProfile = root.appModel.userProfiles.find(p => p.level === Config.Local)
        if(!localProfile){
            localProfile = root.appModel.userProfiles.find(p => p.isDefault === true)
        }

        root.appModel.currentUserProfile = localProfile || null

        root.appModel.save()
    }

    function edit(profileId, newProfile) {
        if(profileId === "")
            return

        const idx = root.appModel.userProfiles.findIndex(profile => profile && profile.profileId === profileId)
        if (idx < 0)
            return

        if(newProfile.level !== Config.App){
            var result = configController.setConfig(newProfile.level, newProfile.username, newProfile.email)
            if (!result.success) {
                console.error("[UserProfileController] Failed to update git config:", result.errorMessage)
                return
            }
        }

        if(newProfile.isDefault)
            for(let i = 0; i < root.appModel.userProfiles.length; ++i){
                if(i !== idx)
                    root.appModel.userProfiles[i].isDefault = false
            }

        root.appModel.userProfiles[idx] = newProfile
        root.appModel.userProfiles = root.appModel.userProfiles.slice(0)

        root.appModel.save()
    }

    function applyUserToRepository(profileId){
        const profile = findProfileById(profileId)
        
        if (!profile) {
            console.warn("Profile with ID '" + profileId + "' not found. Please select a valid profile.")
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
