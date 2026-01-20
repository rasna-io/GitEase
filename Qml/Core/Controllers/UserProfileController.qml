import QtQuick

import GitEase

/*! ***********************************************************************************************
 * UserProfileController
 * Manages the creation, register, remove Profiles.
 * ************************************************************************************************/

QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property                var               userProfiles

    required property                UserProfile       currentUserProfile

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/

    /* Functions
     * ****************************************************************************************/
    function findProfile(username) {
        return root.userProfiles.find(profle => profle && profle.username === username) || null
    }

    function createUserProfile(username : string, password : string, email : string){
        // If already exists, just switch to it
        const existing = findProfile(username)
        if (existing) {
            root.currentUserProfile = existing
            return existing
        }

        var userProfileComponent = Qt.createComponent("qrc:/GitEase/Qml/Core/Models/UserProfile.qml")
        if (userProfileComponent.status !== Component.Ready) {
            console.error("[UserProfileController] Failed to create UserProfile component:", userProfileComponent.errorString())
            return null
        }

        var userProfile = userProfileComponent.createObject(root, {
            username: username,
            password: password,
            email: email,
        })

        root.userProfiles.push(userProfile)

        root.currentUserProfile = userProfile
        return userProfile
    }
}
