import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * NavigationRail
 * Vertical sidebar component for page and repository navigation.
 * Displays list of open pages and available repositories.
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property AppModel               appModel
    required property RepositoryController   repositoryController
    required property UserProfileController  userProfileController
    required property NotificationController notificationController

    // Pages hosted in MainWindow's SwipeView, and the id of the one currently shown.
    required property var                    pages
    required property string                 currentPageId

    required property GuideController        guideController
    required property UserInfoSelectionPopup userInfoSelectionPopup

    // Guide ids owned by this rail (including PagesRail / RepositoriesSidebar). While one of
    // these is active, force the rail open — otherwise it can collapse mid-guide (mouse over
    // the tooltip instead of the rail) and desync the spotlight from the now-collapsed button.
    readonly property var                  _ownGuideIds: [
        "profile_tutorial",
        "settings_tutorial",
        "notifications_tutorial",
        "pages_rail_tutorial",
        "repositories_sidebar_tutorial"
    ]
    readonly property bool                 _guideActiveHere: root.guideController
                                                               && root.guideController.activeGuide !== null
                                                               && root._ownGuideIds.indexOf(root.guideController.activeGuide.id) !== -1

    /* Signals
     * ****************************************************************************************/
    signal pageSelected(string pageId)

    signal newRepositoryRequested()

    signal openSettingsRequested()
    
    signal openNotificationsRequested()

    implicitWidth: Style.dp(196)

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.primaryBackground

    /* Children
     * ****************************************************************************************/
    RowLayout {
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            Layout.margins: Style.dp(4)

            // Pages Sidebar (Top section)
            PagesRail {
                Layout.fillWidth: true
                Layout.fillHeight: true

                color: "transparent"
                model: root.pages
                currentId: root.currentPageId
                guideController: root.guideController
                onClicked:(modelData)=> {
                    if (modelData)
                        root.pageSelected(modelData.pageId)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Style.dp(1)
                Layout.margins: Style.dp(4)
                color: Style.colors.primaryBorder
            }

            // Repositories Sidebar (Middle section)
            RepositoriesSidebar {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                repositoryController: root.repositoryController
                repositories: root.appModel.repositories
                currentRepository: root.appModel.currentRepository
                recentRepositories: root.appModel.recentRepositories
                guideController: root.guideController
                onNewRepositoryRequested: function () {
                    root.newRepositoryRequested()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Style.dp(1)
                Layout.margins: Style.dp(4)
                color: Style.colors.primaryBorder
            }

            // Settings button (Bottom section)
            Rectangle {
                id: settingsButton
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.topMargin: 3
                Layout.bottomMargin: 3
                Layout.preferredHeight: 33
                radius: 6
                color: "transparent"

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 8

                    Item {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        Layout.preferredWidth: 20
                        Layout.minimumWidth: 20
                        Layout.maximumWidth: 20
                        Layout.preferredHeight: 20

                        Text {
                            anchors.centerIn: parent
                            text: Style.icons.gear
                            font.family: settingButtonMouse.containsMouse ? Style.fontTypes.font6ProSolid : Style.fontTypes.font6Pro
                            font.weight: 400
                            font.pixelSize: 14
                            color: Style.colors.foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: "Settings"
                        font.family: Style.fontTypes.inter
                        font.weight: 400
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        color: Style.colors.foreground
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                // Make the whole row clickable
                MouseArea {
                    id: settingButtonMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: root.openSettingsRequested()
                    onEntered: parent.color = Qt.darker(Style.colors.navButton, 1.3)
                    onExited: parent.color = "transparent"
                }
                
                GuideHoverTrigger {
                    guideController: root.guideController
                    guideId: "settings_tutorial"
                    guideName: "Settings Button"
                    guideIcon: Style.icons.gear
                    delay: 600
                    stepsFactory: function() {
                        return [
                            {
                                targetProvider: function() { return settingsButton },
                                icon: Style.icons.gear,
                                title: "Settings",
                                description: "Configure general preferences, SSH keys, and appearance. The Help tab also lets you replay any of these guided tours."
                            }
                        ]
                    }
                }
            }

            // Notification button (Bottom section)
            Rectangle {
                id: notificationButton
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.topMargin: 3
                Layout.bottomMargin: 3
                Layout.preferredHeight: 33
                radius: 6
                color: "transparent"

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 8

                    Item {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        Layout.preferredWidth: 20
                        Layout.minimumWidth: 20
                        Layout.maximumWidth: 20
                        Layout.preferredHeight: 20

                        Text {
                            id: notificationIcon
                            anchors.centerIn: parent
                            text: Style.icons.bell
                            font.family: notificationButtonMouse.containsMouse ? Style.fontTypes.font6ProSolid : Style.fontTypes.font6Pro
                            font.weight: 400
                            font.pixelSize: 14
                            color: Style.colors.foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        // Badge for unread count
                        Rectangle {
                            visible: root.notificationController && root.notificationController.unreadCount > 0
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: -2
                            anchors.rightMargin: -2
                            width: Math.max(10, badgeText.width + 6)
                            height: 10
                            radius: 8
                            color: Style.colors.notificationBadge

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: root.notificationController ? Math.min(root.notificationController.unreadCount, 99) : 0
                                font.family: Style.fontTypes.inter
                                font.weight: 700
                                font.pixelSize: 9
                                color: Style.colors.notificationBadgeText
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: "Notification"
                        font.family: Style.fontTypes.inter
                        font.weight: 400
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        color: Style.colors.foreground
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: notificationButtonMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: root.openNotificationsRequested()
                    onEntered: parent.color = Qt.darker(Style.colors.navButton, 1.3)
                    onExited: parent.color = "transparent"
                }

                GuideHoverTrigger {
                    guideController: root.guideController
                    guideId: "notifications_tutorial"
                    guideName: "Notifications"
                    guideIcon: Style.icons.bell
                    delay: 600
                    stepsFactory: function() {
                        return [
                            {
                                targetProvider: function() { return notificationButton },
                                icon: Style.icons.bell,
                                title: "Notifications",
                                description: "Background git operations, errors, and other events show up here. The badge on the bell shows how many are unread."
                            }
                        ]
                    }
                }
            }

            // Profile button
            Rectangle {
                id: profileButton
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.topMargin: 3
                Layout.bottomMargin: 3
                Layout.preferredHeight: 33
                radius: 6
                color: "transparent"

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 8

                    ProfileAvatar {
                        id: profileAvatar
                        Layout.alignment: Qt.AlignVCenter
                        size: 24
                        username: root.appModel?.currentUserProfile?.username ?? "username"
                        avatarColor: root.appModel?.currentUserProfile?.avatarColor ?? ""
                        levels: root.appModel?.currentUserProfile?.levels ?? []
                        excludeLevels: [Config.Local]
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: root.appModel?.currentUserProfile?.username ?? "username"
                        font.family: Style.fontTypes.inter
                        font.weight: 400
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        color: Style.colors.foreground
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }

                    // Config-level indicator dot
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        visible: profileAvatar.hasLevel && (root.appModel?.currentUserProfile ?? null) !== null
                        Layout.preferredWidth: 7
                        Layout.preferredHeight: 7
                        radius: 5
                        color: profileAvatar.levelBadgeColor
                    }
                }

                // Make the whole row clickable
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        root.userInfoSelectionPopup.userProfileController = root.userProfileController
                        root.userInfoSelectionPopup.open()
                    }

                    onEntered: parent.color = Qt.darker(Style.colors.navButton, 1.3)
                    onExited: parent.color = "transparent"
                }

                GuideHoverTrigger {
                    guideController: root.guideController
                    guideId: "profile_tutorial"
                    guideName: "Your Profile"
                    guideIcon: Style.icons.user
                    delay: 600
                    stepsFactory: function() {
                        return [
                            // ── Step 0: Profile button intro (inline) ────────────────
                            {
                                targetProvider: function() { return profileButton },
                                icon: Style.icons.user,
                                title: "Your Profile",
                                description: "Manage your git identities here. Each profile holds a name and email used to sign commits. Let's take a quick tour!",
                                showNext: true,
                                showBack: false,
                                showSkip: true,
                                isInPopup: false,
                                // Close popup if user pressed Back to return here from step 1
                                onActivate: function() { root._closeProfilePopup() },
                                onNext: function() { root._openProfilePopup()}
                            },

                            // ── Step 1: Add a profile (popup) ────────────────────────
                            {
                                targetProvider: function() {
                                    var p = root.userInfoSelectionPopup
                                    return p ? p.guideAddButton : null
                                },
                                icon: Style.icons.plus,
                                title: "Add a Profile",
                                description: "Click '+ Add User' to create a new git identity. Each profile stores a name and email used to sign commits.",
                                showNext: true,
                                showBack: true,
                                showSkip: true,
                                isInPopup: true,
                                activationDelay: 350,
                                // Reopen popup when user navigates back here from step 2
                                onActivate: function() { root._openProfilePopup() }
                            },

                            // ── Step 2: Switch profile (popup) ───────────────────────
                            {
                                targetProvider: function() {
                                    var p = root.userInfoSelectionPopup
                                    return p ? p.guideProfilesList : null
                                },
                                icon: Style.icons.users,
                                title: "Switch Profile",
                                description: "Click any profile in this list to apply it to the current repository. The selected profile signs your git commits.",
                                showNext: true,
                                showBack: true,
                                showSkip: true,
                                isInPopup: true,
                                // Reopen popup when user navigates back here from step 3
                                onActivate: function() { root._openProfilePopup() }
                            },

                            // ── Step 3: Edit & Delete (popup) ────────────────────────
                            {
                                targetProvider: function() {
                                    var p = root.userInfoSelectionPopup
                                    return p ? p.guideProfilesList : null
                                },
                                icon: Style.icons.info,
                                title: "Edit & Delete",
                                description: "Hover over any profile row to reveal action buttons — pencil to edit, trash to delete. Changes apply immediately.",
                                showNext: true,
                                showBack: true,
                                showSkip: true,
                                isInPopup: true,
                                // Reopen popup when user navigates back here from step 4
                                onActivate: function() { root._openProfilePopup() },
                                onNext: function() { root._closeProfilePopup() }
                            },

                            // ── Step 4: Wrap-up (inline) ─────────────────────────────
                            {
                                targetProvider: function() { return profileButton },
                                icon: Style.icons.user,
                                title: "You're All Set!",
                                description: "Click this button anytime to switch identities, add new profiles, or manage existing ones across your repositories.",
                                showNext: false,
                                showBack: false,
                                showSkip: false,
                                isInPopup: false,
                                // Close popup in case user skipped here from a popup step
                                onActivate: function() { root._closeProfilePopup() }
                            }
                        ]
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: Style.dp(1)
            Layout.fillHeight: true
            color: Style.colors.primaryBorder
        }
    }

    /* Guide
     * ****************************************************************************************/
    Connections {
        target: root.guideController
        ignoreUnknownSignals: true
        function onGuideDismissed() {
            root._closeProfilePopup()
        }
    }

    function _openProfilePopup() {
        var p = root.userInfoSelectionPopup
        if (!p)
            return

        if (!p.visible) {
            p.userProfileController = root.userProfileController
            p.open()
        }
    }

    function _closeProfilePopup() {
        var p = root.userInfoSelectionPopup
        if (p && p.visible)
            p.close()
    }
}