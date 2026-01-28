import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * UserInfoSelector
 * Modern user profile management component with add, edit, delete, and select functionality
 * ************************************************************************************************/
Item {
    id: root

    property UserProfileController userProfileController

    /* Property Declarations
     * ****************************************************************************************/
    property var    selectedProfile: userProfileController?.appModel?.currentUserProfile
    property bool   showAddEditForm: false
    property bool   isEditing:       false
    property string editingProfileId: ""
    property var    sortedProfiles:  getSortedProfiles()

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Header Section
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            spacing: 10

            Text {
                text: !root.showAddEditForm ? "User Profiles" :
                                              root.isEditing ? "Edit User Profile" : "Add New User Profile"
                font.pixelSize: 15
                font.family: Style.fontTypes.roboto
                font.weight: 600
                color: Style.colors.foreground
                verticalAlignment: Text.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            // Add User Button
            Button {
                visible: !root.showAddEditForm
                Layout.preferredHeight: 30
                Layout.preferredWidth: 95
                Layout.alignment: Qt.AlignVCenter

                contentItem: Item {
                    anchors.fill: parent

                    Row {
                        spacing: 5
                        anchors.centerIn: parent
                        
                        Text {
                            text: Style.icons.plus
                            font.family: Style.fontTypes.font6ProSolid
                            font.pixelSize: 11
                            color: Style.colors.secondaryForeground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            text: "Add User"
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 12
                            font.weight: 500
                            color: Style.colors.secondaryForeground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                background: Rectangle {
                    anchors.fill: parent
                    color: parent.hovered ? Style.colors.accentHover : Style.colors.accent
                    radius: 5
                }

                onClicked: {
                    root.showAddEditForm = true
                    root.isEditing = false
                    fullNameField.field.text = ""
                    emailField.field.text = ""
                    errorMessage.text = ""
                }
            }
        }

        ColumnLayout {
            id: formLayout
            visible: root.showAddEditForm
            Layout.fillHeight: true
            spacing: 12

            // Full Name Field
            FormInputField {
                id: fullNameField
                label: "Full Name"
                placeholderText: "Enter full name"
                icon: Style.icons.user
                field.readOnly: root.isEditing
            }

            // Email Field
            FormInputField {
                id: emailField
                label: "Email Address"
                placeholderText: "email@example.com"
                icon: Style.icons.envelope
            }

            // Error Message
            Rectangle {
                id: errorRectangle
                visible: errorMessage.text.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 5
                color: Qt.rgba(Style.colors.error.r, Style.colors.error.g, Style.colors.error.b, 0.15)
                border.color: Style.colors.error
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: Style.icons.circleExclamation
                        font.family: Style.fontTypes.font6ProSolid
                        font.pixelSize: 12
                        color: Style.colors.error
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        id: errorMessage
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        wrapMode: Text.WordWrap
                        font.pixelSize: 11
                        font.family: Style.fontTypes.roboto
                        color: Style.colors.error
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            // Action Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8

                Item { Layout.fillWidth: true }

                Button {
                    Layout.preferredWidth: 75
                    Layout.preferredHeight: 30
                    Layout.alignment: Qt.AlignVCenter

                    contentItem: Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 12
                        color: Style.colors.foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        anchors.fill: parent
                        color: parent.hovered ? Style.colors.surfaceMuted : "transparent"
                        radius: 5
                        border.color: Style.colors.primaryBorder
                        border.width: 1
                    }

                    onClicked: {
                        root.showAddEditForm = false
                        root.isEditing = false
                        fullNameField.field.text = ""
                        emailField.field.text = ""
                        errorMessage.text = ""
                    }
                }

                Button {
                    Layout.preferredWidth: 75
                    Layout.preferredHeight: 30
                    Layout.alignment: Qt.AlignVCenter

                    contentItem: Text {
                        anchors.centerIn: parent
                        text: root.isEditing ? "Save" : "Add"
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 12
                        font.weight: 500
                        color: Style.colors.secondaryForeground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        anchors.fill: parent
                        color: parent.hovered ? Style.colors.accentHover : Style.colors.accent
                        radius: 5
                    }

                    onClicked: {
                        if (fullNameField.field.text.trim().length === 0) {
                            errorMessage.text = "Full name cannot be empty"
                            return
                        }

                        if (emailField.field.text.trim().length === 0) {
                            errorMessage.text = "Email cannot be empty"
                            return
                        }

                        var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
                        if (!emailRegex.test(emailField.field.text.trim())) {
                            errorMessage.text = "Please enter a valid email address"
                            return
                        }

                        if (root.isEditing) {
                            // Edit existing profile
                            let profile = root.userProfileController.findProfileById(root.editingProfileId)
                            if (profile) {
                                profile.email = emailField.field.text.trim()
                                userProfileController.edit(root.editingProfileId, profile)
                            }
                        } else {
                            let userProfile = userProfileController.createUserProfile(
                                fullNameField.field.text.trim(),
                                "",
                                emailField.field.text.trim(),
                                Config.App
                            )
                            if (!userProfile) {
                                errorMessage.text = "Failed to create profile. User may already exist."
                                return
                            }
                        }

                        root.showAddEditForm = false
                        root.isEditing = false
                        fullNameField.field.text = ""
                        emailField.field.text = ""
                        errorMessage.text = ""
                    }
                }
            }
        }

        // Info Banner for Git Configs
        Rectangle {
            visible: !root.showAddEditForm
            Layout.fillWidth: true
            Layout.preferredHeight: 35
            radius: 5
            color: Style.colors.hintBackground
            border.color: Style.colors.primaryBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 2
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: "💡 Select a profile to apply it to the repository's .git/config."
                    font.pixelSize: 10
                    font.family: Style.fontTypes.roboto
                    color: Style.colors.hintText
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: "💡 Click the star ⭐ to set it as your default app user."
                    font.pixelSize: 10
                    font.family: Style.fontTypes.roboto
                    color: Style.colors.hintText
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // User List Section
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.showAddEditForm
            color: "transparent"
            radius: 6

            ScrollView {
                anchors.fill: parent
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.sortedProfiles

                        delegate: UserInfoSelectorItem {
                            property var parentRoot: root
                            
                            profileId: modelData.profileId
                            username: modelData.username
                            email: modelData.email
                            level: modelData.level
                            isDefault: modelData.isDefault
                            isSelected: {
                                return modelData.profileId === root.selectedProfile?.profileId
                            }

                            onSelectAsDefault: function(profileId) {
                                let profile = root.userProfileController.findProfileById(profileId)
                                if (profile) {
                                    profile.isDefault = true
                                    root.userProfileController.edit(profileId, profile)
                                }
                            }

                            onEditUser: function(profileId) {
                                let profile = parentRoot.userProfileController.findProfileById(profileId)
                                if (profile) {
                                    parentRoot.isEditing = true
                                    parentRoot.editingProfileId = profileId
                                    fullNameField.field.text = profile.username
                                    emailField.field.text = profile.email
                                    errorMessage.text = ""
                                    parentRoot.showAddEditForm = true
                                }
                            }

                            onDeleteUser: function(profileId) {
                                parentRoot.userProfileController.remove(profileId)
                            }

                            onSelectForRepository: function(profileId) {
                                parentRoot.userProfileController.applyUserToRepository(profileId)
                            }
                        }
                    }
                }
            }
        }

        // Empty State
        Item {
            visible: !root.showAddEditForm && (!root.sortedProfiles || root.sortedProfiles.length === 0)
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text: Style.icons.users
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: 42
                    color: Style.colors.mutedText
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: "No user profiles yet"
                    font.pixelSize: 13
                    font.family: Style.fontTypes.roboto
                    font.weight: 500
                    color: Style.colors.foreground
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: "Create your first user profile to get started"
                    font.pixelSize: 11
                    font.family: Style.fontTypes.roboto
                    color: Style.colors.mutedText
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function getSortedProfiles() {
        if (!userProfileController?.appModel?.userProfiles) {
            return []
        }
        
        let profiles = userProfileController.appModel.userProfiles.slice(0)
        
        profiles.sort(function(a, b) {
            if (a.level === Config.Local && b.level !== Config.Local) {
                return -1
            }

            if (a.level !== Config.Local && b.level === Config.Local) {
                return 1
            }
            
            const levelPriority = {}
            levelPriority[Config.Local] = 0
            levelPriority[Config.Global] = 1
            levelPriority[Config.System] = 2
            levelPriority[Config.Worktree] = 3
            levelPriority[Config.App] = 4
            
            return (levelPriority[a.level] || 999) - (levelPriority[b.level] || 999)
        })
        
        return profiles
    }
    
    Connections {
        target: userProfileController?.appModel
        function onUserProfilesChanged() {
            root.sortedProfiles = getSortedProfiles()
        }
    }
}

