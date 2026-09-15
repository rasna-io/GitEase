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
    property var    selectedProfile: root.userProfileController?.appModel?.currentUserProfile
    property bool   showAddEditForm: false
    property bool   isEditing:       false
    property string editingUsername: ""
    property string editingEmail:    ""

    //! Avatar color palette offered in the add/edit form.
    readonly property var avatarPalette: [
        "#3B82F6", "#A855F7", "#10B981", "#F97316", "#EC4899", "#F59E0B"
    ]
    property          string selectedAvatarColor: avatarPalette[0]
    property          int    selectedScope:       Config.App
    readonly property var    scopeOptions: [
        { level: Config.App,    title: "App only", desc: "store in GitEase, don't touch git" },
        { level: Config.Local,  title: "Local",    desc: "apply to current repo" },
        { level: Config.Global, title: "Global",   desc: "apply to all repos on this machine" }
    ]

    readonly property int profileCount: root.userProfileController?.appModel?.userProfiles?.length ?? 0
    readonly property int listContentHeight: root.profileCount > 0 ? listColumn.implicitHeight : 140
    readonly property int listMaxHeight: root.showAddEditForm ? 140 : 264

    readonly property alias guideAddButton:    addUserBtn
    readonly property alias guideProfilesList: profileListArea

    /* Signals
     * ****************************************************************************************/
    signal closeRequested()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: mainColumn.implicitHeight + 32

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header Section
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    text: "User Profiles"
                    font.pixelSize: Style.appFont.largePt
                    font.family: Style.fontTypes.inter
                    font.weight: 700
                    color: Style.colors.foreground
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: "Switch the active Git identity for commits"
                    font.pixelSize: Style.appFont.smallPt
                    font.family: Style.fontTypes.inter
                    color: Style.colors.mutedText
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Add User Button
            Button {
                id: addUserBtn
                Layout.preferredHeight: 28
                Layout.preferredWidth: 90
                Layout.alignment: Qt.AlignVCenter
                leftPadding: 0
                rightPadding: 0

                contentItem: Item {
                    anchors.fill: parent

                    Row {
                        spacing: 6
                        anchors.centerIn: parent
                        
                        Text {
                            text: Style.icons.plus
                            font.family: Style.fontTypes.font6Pro
                            font.styleName: "Solid"
                            font.pixelSize: Style.appFont.smallPt
                            color: Style.colors.onAccentText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Add User"
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.smallPt
                            font.weight: 600
                            color: Style.colors.onAccentText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                background: Rectangle {
                    anchors.fill: parent
                    color: parent.hovered ? Style.colors.accentHover : Style.colors.accent
                    radius: 6
                }

                onClicked: root.openAddForm()
            }

            WindowsButton {
                id: closeButton
                Layout.alignment: Qt.AlignVCenter
                Material.accent: Style.colors.windowsClose

                onClicked: root.closeRequested()

                content: Item {
                    anchors.centerIn: parent
                    width: 10
                    height: 10

                    Rectangle {
                        width: 12
                        height: 2
                        radius: 1
                        color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                        anchors.centerIn: parent
                        rotation: 45
                    }

                    Rectangle {
                        width: 12
                        height: 2
                        radius: 1
                        color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                        anchors.centerIn: parent
                        rotation: -45
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Style.colors.primaryBorder
        }

        // User List Section
        Rectangle {
            id: profileListArea
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(root.listContentHeight, root.listMaxHeight)
            color: "transparent"

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            ScrollView {
                anchors.fill: parent
                clip: true
                visible: root.profileCount > 0
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    id: listColumn
                    width: profileListArea.width
                    spacing: 6

                    Repeater {
                        model: root.userProfileController?.appModel?.userProfiles

                        delegate: UserInfoSelectorItem {
                            property var parentRoot: root
                            
                            username: modelData.username
                            email: modelData.email
                            levels: modelData.levels
                            avatarColor: modelData.avatarColor ?? ""
                            isSelected: {
                                return modelData.username === root.selectedProfile?.username
                                    && modelData.email === root.selectedProfile?.email
                            }

                            onEditUser: function(username, email) {
                                parentRoot.openEditForm(username, email)
                            }

                            onDeleteUser: function(username, email) {
                                parentRoot.userProfileController.remove(username, email)
                            }

                            onSelectForRepository: function(username, email) {
                                parentRoot.userProfileController.applyUserToRepository(username, email)
                            }
                        }
                    }
                }
            }

            // Empty State
            ColumnLayout {
                anchors.centerIn: parent
                visible: root.profileCount === 0
                spacing: 10

                Text {
                    text: Style.icons.users
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: Style.appFont.displayLgPt
                    color: Style.colors.mutedText
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    text: "No user profiles yet"
                    font.pixelSize: Style.appFont.h3Pt
                    font.family: Style.fontTypes.inter
                    font.weight: 600
                    color: Style.colors.foreground
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    text: "Create your first user profile to get started"
                    font.pixelSize: Style.appFont.smallPt
                    font.family: Style.fontTypes.inter
                    color: Style.colors.mutedText
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Item {
            id: formArea
            Layout.fillWidth: true
            Layout.preferredHeight: root.showAddEditForm ? formColumn.implicitHeight : 0
            clip: true
            opacity: root.showAddEditForm ? 1 : 0

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                id: formColumn
                width: formArea.width
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Style.colors.primaryBorder
                }

                Text {
                    text: root.isEditing ? "EDIT USER PROFILE" : "ADD USER PROFILE"
                    font.pixelSize: Style.appFont.smallPt
                    font.family: Style.fontTypes.inter
                    font.weight: 700
                    color: Style.colors.secondaryText
                }

                // Name + Email side by side
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    FormInputField {
                        id: fullNameField
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        label: "NAME"
                        placeholderText: "Full name..."
                        field.readOnly: root.isEditing
                    }

                    FormInputField {
                        id: emailField
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        label: "EMAIL"
                        placeholderText: "email@..."
                    }
                }

                // Avatar color picker
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "AVATAR COLOR"
                        font.pixelSize: Style.appFont.captionPt
                        font.family: Style.fontTypes.inter
                        font.weight: 700
                        color: Style.colors.secondaryText
                    }

                    RowLayout {
                        spacing: 10
                        Layout.leftMargin: Style.dp(8)

                        Repeater {
                            model: root.avatarPalette

                            delegate: Rectangle {
                                id: swatch
                                required property int index
                                required property var modelData

                                readonly property bool isChosen: root.selectedAvatarColor === modelData

                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: 13
                                color: modelData
                                border.width: isChosen ? 2 : 0
                                border.color: Style.colors.foreground

                                Rectangle {
                                    anchors.centerIn: parent
                                    visible: swatch.isChosen
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: "transparent"
                                    border.width: 2
                                    border.color: Style.colors.accent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectedAvatarColor = swatch.modelData
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                // Config scope (only for new profiles)
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: !root.isEditing
                    spacing: 6

                    Text {
                        text: "CONFIG SCOPE"
                        font.pixelSize: Style.appFont.captionPt
                        font.family: Style.fontTypes.inter
                        font.weight: 700
                        color: Style.colors.secondaryText
                    }

                    Repeater {
                        model: root.scopeOptions

                        delegate: Item {
                            id: scopeRow
                            required property var modelData

                            readonly property bool chosen: root.selectedScope === scopeRow.modelData.level

                            Layout.fillWidth: true
                            Layout.preferredHeight: 24

                            RowLayout {
                                anchors.fill: parent
                                spacing: 8

                                Rectangle {
                                    Layout.preferredWidth: 16
                                    Layout.preferredHeight: 16
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: 8
                                    color: "transparent"
                                    border.width: 2
                                    border.color: scopeRow.chosen ? Style.colors.accent
                                                                   : Style.colors.controlBorder

                                    Rectangle {
                                        anchors.centerIn: parent
                                        visible: scopeRow.chosen
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: Style.colors.accent
                                    }
                                }

                                Text {
                                    text: scopeRow.modelData.title
                                    font.pixelSize: Style.appFont.smallPt
                                    font.family: Style.fontTypes.inter
                                    font.weight: 600
                                    color: Style.colors.foreground
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: "— " + scopeRow.modelData.desc
                                    font.pixelSize: Style.appFont.captionPt
                                    font.family: Style.fontTypes.inter
                                    color: Style.colors.mutedText
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedScope = scopeRow.modelData.level
                            }
                        }
                    }
                }

                // Error Message
                Rectangle {
                    id: errorRectangle
                    visible: errorMessage.text.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 6
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
                            font.family: Style.fontTypes.font6Pro
                            font.styleName: "Solid"
                            font.pixelSize: Style.appFont.mediumPt
                            color: Style.colors.error
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            id: errorMessage
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            wrapMode: Text.WordWrap
                            font.pixelSize: Style.appFont.smallPt
                            font.family: Style.fontTypes.inter
                            color: Style.colors.error
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                // Action Buttons
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 8

                    Item { Layout.fillWidth: true }

                    Button {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignVCenter
                        leftPadding: 0
                        rightPadding: 0

                        contentItem: Text {
                            text: "Cancel"
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.smallPt
                            color: Style.colors.foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            anchors.fill: parent
                            color: parent.hovered ? Style.colors.surfaceLight : "transparent"
                            radius: 6
                            border.color: Style.colors.primaryBorder
                            border.width: 1
                        }

                        onClicked: root.closeForm()
                    }

                    Button {
                        Layout.preferredWidth: 110
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignVCenter
                        leftPadding: 0
                        rightPadding: 0

                        contentItem: Text {
                            text: "Save Profile"
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.smallPt
                            font.weight: 600
                            color: Style.colors.onAccentText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            anchors.fill: parent
                            color: parent.hovered ? Style.colors.accentHover : Style.colors.accent
                            radius: 6
                        }

                        onClicked: root.submitForm()
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function openAddForm() {
        root.isEditing = false
        root.editingUsername = ""
        root.editingEmail = ""
        root.selectedScope = Config.App
        root.selectedAvatarColor = root.avatarPalette[0]
        fullNameField.field.text = ""
        emailField.field.text = ""
        errorMessage.text = ""
        root.showAddEditForm = true
    }

    function openEditForm(username, email) {
        let profile = root.userProfileController.findProfileByKey(username, email)
        if (!profile)
            return

        root.isEditing = true
        root.editingUsername = username
        root.editingEmail = email
        root.selectedAvatarColor = profile.avatarColor !== ""
                                   ? profile.avatarColor
                                   : root.avatarPalette[0]
        fullNameField.field.text = profile.username
        emailField.field.text = profile.email
        errorMessage.text = ""
        root.showAddEditForm = true
    }

    function closeForm() {
        root.showAddEditForm = false
        root.isEditing = false
        root.editingUsername = ""
        root.editingEmail = ""
        fullNameField.field.text = ""
        emailField.field.text = ""
        errorMessage.text = ""
    }

    function submitForm() {
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
            root.userProfileController.edit(
                root.editingUsername,
                root.editingEmail,
                root.editingUsername,
                emailField.field.text.trim(),
                root.selectedAvatarColor
            )
        } else {
            let name = fullNameField.field.text.trim()
            let email = emailField.field.text.trim()

            let userProfile = root.userProfileController.createUserProfile(
                name,
                "",
                email,
                Config.App,
                root.selectedAvatarColor
            )
            if (!userProfile) {
                errorMessage.text = "Failed to create profile. User may already exist."
                return
            }

            if (root.selectedScope !== Config.App)
                root.userProfileController.applyUserToRepository(name, email, root.selectedScope)
        }

        root.closeForm()
    }
}
