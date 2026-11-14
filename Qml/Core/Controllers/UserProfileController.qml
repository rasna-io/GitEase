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
    property                     NotificationController           notificationController: null

    property var identity: ({ found: false, name: "", email: "", level: -1, blankLevel: -1, reason: "" })

    property var pendingRepositoryUser: null

    property bool _loading: false

    /* Signals
     * ****************************************************************************************/
    property Connections configConnections: Connections {
        target: configController
        function onCurrentRepoChanged(){
            root.applyPendingRepositoryUser()
            root.loadAllProfiles()
        }
    }

    Component.onCompleted: root.loadAllProfiles()

    /* Functions
     * ****************************************************************************************/
    function loadAllProfiles() {
        root.appModel.userProfiles = []

        loadAppProfiles()

        loadGitConfigProfiles()

        refreshIdentity()
    }

    /**
     * Asks git who it will commit as and points currentUserProfile at that user.
     * Returns the new identity.
     */
    function refreshIdentity() {
        const result = root.configController.resolveIdentity()
        const data = result.data ?? {}

        root.identity = {
            found:      result.success,
            name:       data.name ?? "",
            email:      data.email ?? "",
            level:      data.level ?? -1,
            blankLevel: data.blankLevel ?? -1,
            reason:     result.success ? "" : (result.errorMessage ?? "")
        }

        root.appModel.currentUserProfile = result.success ? findProfileByKey(data.name, data.email)
                                                          : null
        return root.identity
    }

    function refreshFromGit() {
        const before = JSON.stringify(root.identity)
        root.refreshIdentity()

        if (JSON.stringify(root.identity) !== before)
            root.loadAllProfiles()
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

        if (!root.appModel.fileIO.isFileExist(path))
            return

        root.appModel.fileIO.fileName = path
        root.appModel.fileIO.read()

        let profiles = []
        try {
            profiles = JSON.parse(root.appModel.fileIO.fileContent).userProfiles || []
        } catch (error) {
            console.warn("[UserProfileController] Could not read saved users:", error)
            return
        }

        root._loading = true
        for (let i = 0; i < profiles.length; i++) {
            root.createUserProfile(
                profiles[i].username,
                profiles[i].password ?? "",
                profiles[i].email,
                Config.App,
                profiles[i].avatarColor ?? ""
            )
        }
        root._loading = false
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

    function createUserProfile(username : string, password : string, email : string, level, avatarColor){
        let levelsArray = []
        if (typeof level === 'number') {
            levelsArray = [level]
        } else if (Array.isArray(level)) {
            levelsArray = level
        }

        let color = avatarColor ?? ""

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

            if (color !== "" && existing.avatarColor === "")
                existing.avatarColor = color

            if(levelsArray.includes(Config.App) && !root._loading)
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
            levels: levelsArray,
            avatarColor: color
        })

        root.appModel.userProfiles.push(userProfile)
        root.appModel.userProfiles = root.appModel.userProfiles.slice(0)

        if(levelsArray.includes(Config.App))
            root.appModel.save()

        return userProfile
    }

    //! Why git would refuse this name and email, or "" when they are fine.
    function identityProblem(name, email) {
        const trimmedName  = (name ?? "").trim()
        const trimmedEmail = (email ?? "").trim()

        if (trimmedName.length === 0)
            return qsTr("Enter your full name.")
        if (trimmedEmail.length === 0)
            return qsTr("Enter your email address.")
        if (/[<>\n]/.test(trimmedName) || /[<>\n]/.test(trimmedEmail))
            return qsTr("The name and email can't contain < or >.")
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmedEmail))
            return qsTr("Enter a valid email address.")

        return ""
    }

    /**
     * Saves a user in the list and writes it to git config: Config.Global for all repositories,
     * Config.Local for the open repository only (Config.App keeps it in the list only).
     * Returns "" on success, otherwise what went wrong.
     */
    function saveUser(name, email, level, avatarColor) {
        const problem = root.identityProblem(name, email)
        if (problem !== "")
            return problem

        const trimmedName  = name.trim()
        const trimmedEmail = email.trim()

        if (!root.createUserProfile(trimmedName, "", trimmedEmail, Config.App, avatarColor ?? ""))
            return qsTr("The user couldn't be saved.")

        if (level === Config.Global || level === Config.Local) {
            const result = root.configController.setConfig(level, trimmedName, trimmedEmail)
            if (!result.success) {
                root.loadAllProfiles()
                return result.errorMessage || qsTr("Git config couldn't be changed.")
            }

            if (level === Config.Global)
                root.clearBlankRepositoryUser()
        }

        root.loadAllProfiles()
        return ""
    }

    /**
     * Welcome screen, "Only the repository I open next": saves the user in the list now and
     * writes it to the repository's own config as soon as one is opened or cloned.
     * Returns "" on success, otherwise what went wrong.
     */
    function rememberForNextRepository(name, email) {
        const problem = root.identityProblem(name, email)
        if (problem !== "")
            return problem

        if (!root.createUserProfile(name.trim(), "", email.trim(), Config.App, ""))
            return qsTr("The user couldn't be saved.")

        root.pendingRepositoryUser = { name: name.trim(), email: email.trim() }
        return ""
    }

    function applyPendingRepositoryUser() {
        const pending = root.pendingRepositoryUser
        if (!pending || !root.configController.currentRepo)
            return

        root.pendingRepositoryUser = null

        const result = root.configController.setConfig(Config.Local, pending.name, pending.email)
        if (!result.success && notificationController) {
            notificationController.error(result.errorMessage || "Failed to set the user for this repository",
                                         "Profile Error", 5000)
        }
    }

    /**
     * Older GitEase versions wrote empty values when a user was deleted. In the open repository
     * they hide the global user, so they are removed once there is a global user to fall back to.
     */
    function clearBlankRepositoryUser() {
        const resolved = root.configController.resolveIdentity()
        const blankLevel = resolved.data?.blankLevel ?? -1

        if (!resolved.success && (blankLevel === Config.Local || blankLevel === Config.Worktree))
            root.configController.unsetIdentity(blankLevel)
    }

    //! The open repository's own user, or null when it follows the global one.
    function repositoryUser() {
        if (!root.configController.currentRepo)
            return null

        const result = root.configController.getConfig(Config.Local)
        const config = result.success ? result.data : null
        if (!config || (config.name === "" && config.email === ""))
            return null

        return { name: config.name, email: config.email }
    }

    /**
     * "Use as default": writes the user to the global config, so every repository without its
     * own user commits as them. With alsoHere, the open repository's own user is removed, so the
     * repository follows the default as well.
     */
    function useAsDefault(username, email, alsoHere) {
        const profile = findProfileByKey(username, email)
        if (!profile)
            return

        let result = root.configController.setConfig(Config.Global, profile.username, profile.email)
        if (result.success && alsoHere)
            result = root.configController.unsetIdentity(Config.Local)
        if (result.success)
            root.clearBlankRepositoryUser()

        root.loadAllProfiles()

        if (!notificationController)
            return

        if (result.success)
            notificationController.success("'" + username + "' is now the default user", "Profile", 3000)
        else
            notificationController.error(result.errorMessage || "Failed to set the default user", "Profile Error", 5000)
    }

    //! The git config levels this user is written in, which Delete removes it from.
    function writableLevelsOf(username, email) {
        const profile = findProfileByKey(username, email)
        if (!profile)
            return []

        return profile.levels.filter(level => level === Config.Local
                                              || level === Config.Global
                                              || level === Config.Worktree)
    }

    function remove(username, email) {
        if(username === "" || email === "")
            return

        const idx = root.appModel.userProfiles.findIndex(profile => profile && profile.username === username && profile.email === email)
        if (idx < 0)
            return


        const levels = root.writableLevelsOf(username, email)
        for (let i = 0; i < levels.length; i++) {
            var result = configController.unsetIdentity(levels[i])
            if (!result.success) {
                console.error("[UserProfileController] Failed to update git config:", result.errorMessage)
                if (notificationController)
                    notificationController.error(result.errorMessage || "Failed to update git config", "Profile Error", 5000)
                return
            }
        }

        root.appModel.userProfiles = root.appModel.userProfiles.slice(0, idx).concat(root.appModel.userProfiles.slice(idx + 1))

        let localProfile = root.appModel.userProfiles.find(p => p.levels.includes(Config.Local))
        if(localProfile){
            root.appModel.currentUserProfile = localProfile
        }


        root.appModel.save()
        
        if (notificationController) {
            notificationController.success("User profile '" + username + "' deleted successfully", "Profile", 3000)
        }
    }

    function edit(oldUsername, oldEmail, newUsername, newEmail, avatarColor) {
        if(oldUsername === "" || oldEmail === "")
            return

        const idx = root.appModel.userProfiles.findIndex(profile => profile && profile.username === oldUsername && profile.email === oldEmail)
        if (idx < 0)
            return

        const profile = root.appModel.userProfiles[idx]

        if (avatarColor !== undefined && avatarColor !== "")
            profile.avatarColor = avatarColor

        if (oldUsername !== newUsername || oldEmail !== newEmail) {
            const existingProfile = findProfileByKey(newUsername, newEmail)
            if (existingProfile && existingProfile !== profile) {
                console.error("[UserProfileController] Cannot update profile: username/email combination already exists")
                return
            }
            profile.username = newUsername
            profile.email = newEmail
        }

        const levels = profile.levels.filter(level => level === Config.Local
                                                      || level === Config.Global
                                                      || level === Config.Worktree)
        for (let i = 0; i < levels.length; i++) {
            removeLevelFromOtherProfiles(levels[i], newUsername, newEmail)
            var result = configController.setConfig(levels[i], newUsername, newEmail)
            if (!result.success) {
                console.error("[UserProfileController] Failed to update git config:", result.errorMessage)
                return
            }
        }

        root.appModel.userProfiles = root.appModel.userProfiles.slice(0)

        root.appModel.save()
        root.loadAllProfiles()

        if (notificationController) {
            notificationController.success("User profile updated successfully", "Profile", 3000)
        }
    }

    function applyUserToRepository(username, email, level){
        const targetLevel = (level === undefined || level === null) ? Config.Local : level

        const profile = findProfileByKey(username, email)

        if (!profile) {
            console.warn("Profile with username '" + username + "' and email '" + email + "' not found. Please select a valid profile.")
            return
        }

        var result = configController.setConfig(targetLevel, profile.username, profile.email)

        if (result.success) {
            if (targetLevel === Config.Global)
                root.clearBlankRepositoryUser()

            loadAllProfiles()
            if (notificationController) {
                let scopeLabel = targetLevel === Config.Global ? "applied globally" : "applied to repository"
                notificationController.success("User profile '" + username + "' " + scopeLabel, "Profile", 3000)
            }
        } else {
            console.error("[UserProfileController] Failed to apply user to repository:", result.errorMessage)
            if (notificationController) {
                notificationController.error(result.errorMessage || "Failed to apply user to repository", "Profile Error", 5000)
            }
        }
    }
}
