import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * IdentityPromptPopup
 * "Who is making this commit?" Opens when an action needs a name and email and git has none for
 * the repository. Pick a saved user or type a new one, choose where it applies, and the action
 * runs again. Cancel changes nothing. Open it through IdentityGuard.
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property UserProfileController userProfileController: null

    //! What the button says after "Save and": "commit", "merge", "stash", ...
    property string action: "commit"

    //! Runs the action again once a user is saved.
    property var    retry:  null

    //! Config.Global for all repositories, Config.Local for this one. Read from the radio buttons,
    //! since clicking one would break a binding on its checked property.
    readonly property int scope: thisRepositoryRadio.checked ? Config.Local : Config.Global

    property string errorText: ""

    readonly property var savedUsers: (root.userProfileController?.appModel?.userProfiles ?? [])
                                      .filter(profile => profile && profile.username !== ""
                                                         && profile.email !== "")

    readonly property var identity: root.userProfileController?.identity ?? null

    //! Set but unusable (an empty value or a name with "<" in it) rather than not set at all.
    readonly property bool identityUnusable: !!root.identity && !root.identity.found
                                             && root.identity.reason !== ""
                                             && root.identity.name !== ""
                                             && root.identity.email !== ""

    readonly property string enteredName:  nameField.field.text.trim()
    readonly property string enteredEmail: emailField.field.text.trim()

    /* Object Properties
     * ****************************************************************************************/
    width: 500
    height: contentItem.implicitHeight
    padding: 0
    z: 1000

    closePolicy: Popup.CloseOnEscape

    onClosed: root.retry = null

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        implicitHeight: layout.implicitHeight
        color: Style.colors.popupBackground
        radius: 8
        clip: true
        border.color: Style.colors.popupBorder
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                spacing: 8

                Text {
                    text: Style.icons.user
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.appFont.mediumPt
                    color: Style.colors.accent
                }

                Text {
                    text: root.action === "tag"   ? qsTr("Who is making this tag?")
                        : root.action === "stash" ? qsTr("Who is making this stash?")
                                                  : qsTr("Who is making this commit?")
                    color: Style.colors.popupTitleText
                    font.family: Style.fontTypes.inter
                    font.weight: Font.DemiBold
                    font.pixelSize: Style.appFont.mediumPt
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: "×"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                    color: closeMouse.containsMouse ? Style.colors.popupCloseButtonHover
                                                    : Style.colors.popupCloseButton
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Style.colors.popupHeaderSeparator
            }

            // Body
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                Layout.topMargin: 16
                Layout.bottomMargin: 14
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    text: root.identityUnusable
                          ? qsTr("Git can't use the name and email set for this repository (%1 <%2>). "
                                 + "Git records a name and email with every commit.")
                            .arg(root.identity.name).arg(root.identity.email)
                          : qsTr("No user is set for this repository. Git records a name and email "
                                 + "with every commit.")
                    color: Style.colors.popupCheckboxLabelText
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.defaultPt
                    wrapMode: Text.WordWrap
                }

                // Saved users that are not set for this repository (yet)
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.savedUsers.length > 0
                    spacing: 6

                    Text {
                        text: qsTr("Your saved users:")
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.smallPt
                        font.weight: 600
                        color: Style.colors.secondaryText
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: root.savedUsers

                            delegate: Rectangle {
                                id: userChip

                                required property var modelData

                                readonly property bool chosen: root.enteredName === userChip.modelData.username
                                                               && root.enteredEmail === userChip.modelData.email

                                width: chipRow.implicitWidth + 16
                                height: 28
                                radius: 14
                                color: userChip.chosen ? Qt.rgba(Style.colors.accent.r,
                                                                 Style.colors.accent.g,
                                                                 Style.colors.accent.b, 0.14)
                                                       : chipMouse.containsMouse
                                                         ? Style.colors.controlBackgroundHover
                                                         : "transparent"
                                border.width: 1
                                border.color: userChip.chosen ? Style.colors.accent
                                                              : Style.colors.controlBorder

                                Row {
                                    id: chipRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    ProfileAvatar {
                                        anchors.verticalCenter: parent.verticalCenter
                                        size: 18
                                        username: userChip.modelData.username
                                        avatarColor: userChip.modelData.avatarColor ?? ""
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: userChip.modelData.username + "  <" + userChip.modelData.email + ">"
                                        font.family: Style.fontTypes.inter
                                        font.pixelSize: Style.appFont.smallPt
                                        color: Style.colors.foreground
                                    }
                                }

                                MouseArea {
                                    id: chipMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        nameField.field.text = userChip.modelData.username
                                        emailField.field.text = userChip.modelData.email
                                        root.errorText = ""
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.topMargin: 2
                        text: qsTr("or add a new one:")
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.smallPt
                        font.weight: 600
                        color: Style.colors.secondaryText
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    FormInputField {
                        id: nameField
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        label: qsTr("Full name")
                        placeholderText: "Jane Doe"
                        icon: Style.icons.user
                    }

                    FormInputField {
                        id: emailField
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        label: qsTr("Email")
                        placeholderText: "jane@example.com"
                        icon: Style.icons.envelope
                    }

                    Connections {
                        target: nameField.field
                        function onTextEdited() { root.errorText = "" }
                    }

                    Connections {
                        target: emailField.field
                        function onTextEdited() { root.errorText = "" }
                        function onAccepted()   { root.save() }
                    }
                }

                // Where the user applies
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: qsTr("Use for:")
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.smallPt
                        font.weight: 600
                        color: Style.colors.secondaryText
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 18

                        RepoRadio {
                            id: allRepositoriesRadio
                            text: qsTr("All repositories (Global)")
                            checked: true
                        }

                        RepoRadio {
                            id: thisRepositoryRadio
                            text: qsTr("Only this repository (Local)")
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                CommandPreview {
                    Layout.fillWidth: true
                    placeholder: qsTr("Enter a name and email to see the command")
                    command: root.enteredName === "" || root.enteredEmail === ""
                             ? ""
                             : GitCommandText.setUserIdentity(root.enteredName, root.enteredEmail,
                                                              root.scope === Config.Global ? "--global"
                                                                                           : "--local")
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.errorText !== ""
                    text: root.errorText
                    color: Style.colors.error
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Style.colors.popupHeaderSeparator
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                Layout.topMargin: 12
                Layout.bottomMargin: 12
                spacing: 8

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    id: cancelButton
                    text: qsTr("Cancel")
                    Layout.preferredWidth: 100
                    Layout.alignment: Qt.AlignVCenter
                    topPadding: 6
                    bottomPadding: 6
                    leftPadding: 14
                    rightPadding: 14

                    background: Rectangle {
                        implicitHeight: 32
                        color: "transparent"
                        border.color: Style.colors.popupCancelButtonBorder
                        border.width: 1
                        radius: 5
                        opacity: cancelButton.hovered ? 1.0 : 0.7
                    }

                    contentItem: Text {
                        text: cancelButton.text
                        color: Style.colors.popupCancelButtonText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    onClicked: root.close()
                }

                Button {
                    id: saveButton
                    text: qsTr("Save and %1").arg(root.action)
                    Layout.minimumWidth: 140
                    Layout.alignment: Qt.AlignVCenter
                    topPadding: 6
                    bottomPadding: 6
                    leftPadding: 16
                    rightPadding: 16

                    background: Rectangle {
                        implicitHeight: 32
                        color: saveButton.hovered ? Style.colors.accentHover : Style.colors.accent
                        radius: 5
                    }

                    contentItem: Text {
                        text: saveButton.text
                        color: Style.colors.onAccentText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    onClicked: root.save()
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/

    /**
     * Opens the dialog for \a actionName ("commit", "merge", ...); \a onSaved runs the action
     * again once a user is saved.
     */
    function ask(actionName, onSaved) {
        root.action    = actionName || "commit"
        root.retry     = onSaved ?? null
        root.errorText = ""
        allRepositoriesRadio.checked = true // the default, every time
        nameField.field.text  = ""
        emailField.field.text = ""
        root.open()
        nameField.field.forceActiveFocus()
    }

    function save() {
        const problem = root.userProfileController.saveUser(nameField.field.text, emailField.field.text,
                                                            root.scope, "")
        if (problem !== "") {
            root.errorText = problem
            return
        }

        // Saved, but git can still find nothing usable: a value in a more specific file wins.
        const identity = root.userProfileController.identity
        if (!identity.found) {
            root.errorText = identity.level === Config.Local
                    ? qsTr("This repository has its own name and email, and git can't use them. "
                           + "Choose “Only this repository (Local)” to replace them.")
                    : (identity.reason || qsTr("Git still has no name and email for this repository."))
            return
        }

        const retryAction = root.retry
        root.retry = null
        root.close()

        if (retryAction)
            Qt.callLater(retryAction)
    }
}
