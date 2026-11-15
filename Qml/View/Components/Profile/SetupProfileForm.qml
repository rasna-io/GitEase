import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SetupProfileForm
 * The "Set Up Your Profile" step of the welcome flow. Optional: with no user yet it can be
 * skipped, and GitEase asks later, the first time a commit needs a name.
 *
 * - Git already has a user (global or system): keep it, or add a different name and email.
 * - Git has no user: type a name and email, or skip.
 * A new name and email is used for all repositories (global config) or only for the repository
 * opened in the next step.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property UserProfileController userProfileController: null

    property var  existingUser: null

    readonly property bool hasExistingUser: root.existingUser !== null

    readonly property bool useExisting: root.hasExistingUser && existingUserRadio.checked

    readonly property int  scope: nextRepositoryRadio.checked ? Config.Local : Config.Global
    readonly property bool asksForName: !root.hasExistingUser || !root.useExisting

    property string fullName: fullNameField.text
    property string email: emailField.text
    property bool showHint: true
    property string errorMessage: ""

    onUserProfileControllerChanged: root.refresh()
    Component.onCompleted: root.refresh()

    /* Children
     * ****************************************************************************************/
    ButtonGroup { id: userChoiceGroup }
    ButtonGroup { id: scopeGroup }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 420)
        spacing: 0

        // Description text
        Text {
            Layout.fillWidth: true
            Layout.bottomMargin: root.hasExistingUser ? 14 : 18
            Layout.alignment: Qt.AlignHCenter
            text: root.hasExistingUser
                  ? "Git on this computer already has a user, and your commits will use it. "
                    + "You can also add a different name and email."
                  : "This information will be used for your Git commits and identify you in the repository history"
            wrapMode: Text.WordWrap
            color: Style.colors.secondaryText
            horizontalAlignment: Text.AlignHCenter
            font.family: Style.fontTypes.inter
            font.weight: 400
            font.pixelSize: Style.appFont.h3Pt
            font.letterSpacing: 0.1
            lineHeight: 1.45
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: root.useExisting ? 0 : 10
            visible: root.hasExistingUser
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RepoRadio {
                    id: existingUserRadio
                    Layout.fillWidth: true
                    ButtonGroup.group: userChoiceGroup
                    text: root.existingUser ? root.existingUser.name + " <" + root.existingUser.email + ">" : ""
                    checked: true
                    onClicked: root.errorMessage = ""
                }

                // Where git found this user
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: 18
                    Layout.preferredWidth: levelText.implicitWidth + 12
                    radius: 9
                    color: root.existingUser?.level === Config.System ? Style.colors.levelSystemBadge
                                                                      : Style.colors.levelGlobalBadge

                    Text {
                        id: levelText
                        anchors.centerIn: parent
                        text: root.existingUser?.level === Config.System ? "System" : "Global"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        font.weight: 600
                        color: Style.colors.onColorText
                    }
                }
            }

            RepoRadio {
                Layout.fillWidth: true
                ButtonGroup.group: userChoiceGroup
                text: "Add a different name and email"
                onClicked: {
                    root.errorMessage = ""
                    fullNameField.field.forceActiveFocus()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: root.hasExistingUser ? 23 : 0
            visible: root.asksForName
            spacing: root.hasExistingUser ? 10 : 14

            GridLayout {
                Layout.fillWidth: true
                columns: root.hasExistingUser ? 2 : 1
                columnSpacing: 12
                rowSpacing: 14

                // First input section: Full Name
                FormInputField {
                    id: fullNameField
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: "Full Name"
                    placeholderText: "John Doe"
                    icon: Style.icons.user
                    helperText: root.hasExistingUser ? "" : "This will appear as the author on all your commits"
                }

                // Second input section: Email Address
                FormInputField {
                    id: emailField
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: "Email Address"
                    placeholderText: "john@example.com"
                    icon: Style.icons.envelope
                    helperText: root.hasExistingUser ? "" : "Use the same email as your GitHub/GitLab account to link commits"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: "Use for:"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt
                    font.weight: 600
                    color: Style.colors.secondaryText
                }

                RepoRadio {
                    ButtonGroup.group: scopeGroup
                    text: "All repositories (Global)"
                    checked: true
                }

                RepoRadio {
                    id: nextRepositoryRadio
                    ButtonGroup.group: scopeGroup
                    text: "Only the repository I open next (Local)"
                }
            }
        }

        // Hint row
        Rectangle {
            id: hintRectangle
            visible: root.showHint && root.errorMessage.length === 0 && !root.asksForName
            Layout.fillWidth: true
            Layout.topMargin: 16
            Layout.preferredHeight: hintRow.implicitHeight + 20
            radius: 8
            color: Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.12)
            border.width: 1
            border.color: Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.25)

            RowLayout {
                id: hintRow
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: Style.icons.lightbulb
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: Style.appFont.smallPt
                    color: Style.colors.secondaryText
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: "You can add more users or switch between them later, from your profile at the bottom-left"
                    wrapMode: Text.WordWrap
                    font.pixelSize: Style.appFont.smallPt
                    font.family: Style.fontTypes.inter
                    font.weight: 400
                    font.letterSpacing: 0
                    color: Style.colors.secondaryText
                }
            }
        }

        // Error row
        Rectangle {
            id: errorRectangle
            visible: root.errorMessage.length > 0
            Layout.fillWidth: true
            Layout.topMargin: 14
            Layout.preferredHeight: errorRow.implicitHeight + 20
            radius: 8
            color: Qt.rgba(Style.colors.error.r, Style.colors.error.g, Style.colors.error.b, 0.12)
            border.width: 1
            border.color: Qt.rgba(Style.colors.error.r, Style.colors.error.g, Style.colors.error.b, 0.4)

            RowLayout {
                id: errorRow
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: Style.icons.circleExclamation
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: Style.appFont.smallPt
                    color: Style.colors.error
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: root.errorMessage
                    wrapMode: Text.WordWrap
                    font.pixelSize: Style.appFont.smallPt
                    font.family: Style.fontTypes.inter
                    font.weight: 400
                    font.letterSpacing: 0
                    color: Style.colors.error
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/

    //! Reads who git already commits as. No repository is open yet, so that is the global
    //! (or system) user.
    function refresh() {
        const identity = root.userProfileController?.refreshIdentity() ?? null
        root.existingUser = identity && identity.found
                            ? { name: identity.name, email: identity.email, level: identity.level }
                            : null
        existingUserRadio.checked = true
    }

    /**
     * Saves the choice made on this step. Returns "" on success, otherwise what to fix.
     * Skipping doesn't call this: nothing is saved then.
     */
    function save() : string {
        const profiles = root.userProfileController

        if (root.asksForName) {
            const problem = profiles.identityProblem(root.fullName, root.email)
            if (problem !== "")
                return problem
        }

        if (root.hasExistingUser) {
            profiles.createUserProfile(root.existingUser.name, "", root.existingUser.email, Config.App, "")

            if (root.useExisting) {
                profiles.loadAllProfiles()
                return ""
            }
        }

        if (root.scope === Config.Local)
            return profiles.rememberForNextRepository(root.fullName, root.email)

        return profiles.saveUser(root.fullName, root.email, Config.Global, "")
    }
}
