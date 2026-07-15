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
    required property PageController         pageController
    required property RepositoryController   repositoryController
    required property UserProfileController  userProfileController
    required property NotificationController notificationController
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

    property real                          collapsedWidth:       50
    property real                          expandedWidth:        125
    property bool                          expanded:             hoverHandler.hovered || root._guideActiveHere
    property real                          animatedWidth:        collapsedWidth

    /* Signals
     * ****************************************************************************************/
    signal newRepositoryRequested()

    signal openSettingsRequested()
    
    signal openNotificationsRequested()


    // HoverHandler reliably tracks hover even with complex children.
    HoverHandler {
        id: hoverHandler
        margin: 6
    }

    states: [
        State {
            name: "expanded"
            when: root.expanded
            PropertyChanges {
                target: root;
                animatedWidth: root.expandedWidth
            }
        },
        State {
            name: "collapsed"
            when: !root.expanded
            PropertyChanges {
                target: root;
                animatedWidth: root.collapsedWidth
            }
        }
    ]

    transitions: [
        Transition {
            NumberAnimation {
                properties: "animatedWidth"
                duration: 100
                easing.type: Easing.InOutCubic
            }
        }
    ]

    implicitWidth: animatedWidth
    width: animatedWidth

    radius: 5
    Layout.preferredWidth: animatedWidth
    Layout.minimumWidth: collapsedWidth
    Layout.maximumWidth: expandedWidth

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.navigationRailBgColor

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        anchors.bottomMargin: 4

        // Pages Sidebar (Top section)
        PagesRail {
            Layout.fillWidth: true
            Layout.fillHeight: true

            color: "transparent"
            guideController: root.guideController
            model: root.appModel?.pages
            expanded: root.expanded
            currentId: root.appModel.currentPage.id
            onClicked:(modelData)=> {
                if (pageController && modelData) {
                    pageController.switchToPage(modelData.id)
                }
            }
        }

        // Repositories Sidebar (Middle section)
        RepositoriesSidebar {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            guideController: root.guideController
            expanded: root.expanded
            repositoryController: root.repositoryController
            repositories: root.appModel.repositories
            currentRepository: root.appModel.currentRepository
            recentRepositories: root.appModel.recentRepositories
            onNewRepositoryRequested: function () {
                root.newRepositoryRequested()
            }
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
                        font.pixelSize: Style.appFont.largePt
                        color: Style.colors.foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: "Settings"
                    visible: root.expanded
                    font.family: Style.fontTypes.roboto
                    font.weight: 400
                    font.pixelSize: Style.appFont.largePt
                    elide: Text.ElideRight
                    color: Style.colors.foreground
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    visible: root.expanded
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
                        font.pixelSize: Style.appFont.largePt
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
                            font.family: Style.fontTypes.roboto
                            font.weight: 700
                            font.pixelSize: Style.appFont.captionPt
                            color: Style.colors.notificationBadgeText
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: "Notification"
                    visible: root.expanded
                    font.family: Style.fontTypes.roboto
                    font.weight: 400
                    font.pixelSize: Style.appFont.largePt
                    elide: Text.ElideRight
                    color: Style.colors.foreground
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    visible: root.expanded
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

                Image {
                    id: icon
                    source: "qrc:/GitEase/Resources/Images/defaultUserIcon.svg"
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    width: 42
                    height: 42

                    ColorOverlay {
                        anchors.fill: icon
                        source: icon
                        color: Style.colors.mutedText
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: root.appModel?.currentUserProfile?.username ?? "username"
                    visible: root.expanded
                    font.family: Style.fontTypes.roboto
                    font.weight: 400
                    font.pixelSize: Style.appFont.largePt
                    elide: Text.ElideRight
                    color: Style.colors.foreground
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    visible: root.expanded
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


