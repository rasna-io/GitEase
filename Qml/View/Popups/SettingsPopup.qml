import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SettingsPopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property AppModel               appModel

    property AppSettings            appSettings:            appModel?.appSettings ?? null

    property FileIO                 fileIO

    property int                    currentPage:            0
    
    property NotificationController notificationController: null

    property SshKeyController       sshKeyController:       null

    property UpdateController       updateController:       null

    property GuideController        guideController:        null

    property var                    switchToPageById:       function() {}

    /* Private state
     * ****************************************************************************************/
    // Set by playTutorial() when the chosen tutorial's target lives outside this popup — the
    // popup must close (its Popup layer would otherwise sit above the guide overlay) before the
    // guide can actually be seen, and possibly navigate to that tutorial's page first.
    property string _pendingTutorialId:   ""
    property string _pendingTutorialPage: ""

    // Guide ids whose targets live inside this popup — forceShow runs immediately for these
    // (no close-then-reopen), same treatment NavigationRail gives its own guides.
    readonly property var _ownGuideIds: [
        "settings_popup_tutorial",
        "settings_general_tutorial",
        "settings_ssh_tutorial",
        "settings_appearance_tutorial",
        "settings_help_tutorial"
    ]

    /* Object Properties
     * ****************************************************************************************/
    width: parent.width * 0.8
    height: parent.height * 0.8

    onClosed: {
        load()

        if (_pendingTutorialId.length === 0)
            return

        let id = _pendingTutorialId
        let pageId = _pendingTutorialPage
        _pendingTutorialId = ""
        _pendingTutorialPage = ""

        if (pageId.length > 0 && typeof root.switchToPageById === "function")
            root.switchToPageById(pageId)

        Qt.callLater(function() {
            if (!root.guideController || !root.guideController.forceShow(id)) {
                if (root.notificationController)
                    root.notificationController.warning(
                                "Open the relevant page, then try this tutorial again from Settings.",
                                "Help", 3500)
            }
        })
    }
    onOpened: load()

    /**
     * Play a tutorial selected from the Help tab. Tutorials whose target lives inside this
     * popup (isInPopup steps) run immediately; everything else needs the popup closed first
     * (and possibly a page switch) so the guide overlay isn't hidden behind it.
     */
    function playTutorial(entry) {
        if (root._ownGuideIds.indexOf(entry.id) !== -1) {
            if (!root.guideController || !root.guideController.forceShow(entry.id)) {
                if (root.notificationController)
                    root.notificationController.warning("Couldn't start this tutorial.", "Help", 3000)
            }
            return
        }

        _pendingTutorialId = entry.id
        _pendingTutorialPage = entry.page || ""
        root.close()
    }

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        /* Guide
         * ****************************************************************************************/
        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "settings_popup_tutorial"
            guideName: "Settings Dialog"
            guideIcon: Style.icons.slider
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return settingsTabs },
                        icon: Style.icons.slider,
                        title: "Settings Tabs",
                        description: "Switch between General, SSH, Appearance, and Help using this list. The Help tab is also where you can replay any of the app's guided tours.",
                        isInPopup: true
                    },
                    {
                        targetProvider: function() { return actionButtonsRow },
                        icon: Style.icons.check,
                        title: "Save Your Changes",
                        description: "Apply saves your changes without closing. Save applies and closes the dialog. Cancel discards anything you've changed.",
                        isInPopup: true
                    }
                ]
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 15


            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true

                PagesRail {
                    id: settingsTabs
                    Layout.preferredWidth: parent.width * 0.15
                    Layout.fillHeight: true
                    currentId: root.currentPage
                    radius: 5
                    color: Style.colors.secondaryBackground
                    model: [
                        {pageId: 0, title: "General", icon: Style.icons.slider},
                        {pageId: 1, title: "SSH", icon: Style.icons.terminal},
                        {pageId: 2, title: "Appearence", icon: Style.icons.palette},
                        {pageId: 3, title: "Updates", icon: Style.icons.refresh},
                        {pageId: 4, title: "Help",        icon: Style.icons.info},
                    ]
                    onClicked: (modelData) => {
                        root.currentPage = modelData.pageId
                    }
                }

                Rectangle {
                    id: settingsContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Style.colors.secondaryBackground
                    radius: 5
                    clip: true

                    SwipeView {
                        anchors.fill: parent
                        currentIndex: root.currentPage
                        interactive: false

                        Item {
                            GuideHoverTrigger {
                                guideController: root.guideController
                                guideId: "settings_general_tutorial"
                                guideName: "General Settings"
                                guideIcon: Style.icons.slider
                                stepsFactory: function() {
                                    return [
                                        {
                                            targetProvider: function() { return displayAvatar },
                                            icon: Style.icons.slider,
                                            title: "Display Avatar",
                                            description: "Show or hide profile avatars next to commits in the graph view.",
                                            isInPopup: true,
                                            activationDelay: 300,
                                            onActivate: function() { root.currentPage = 0 }
                                        },
                                        {
                                            targetProvider: function() { return displayStashNodes },
                                            icon: Style.icons.archive,
                                            title: "Display Stash",
                                            description: "Show or hide stash entries as nodes in the graph view timeline.",
                                            isInPopup: true
                                        },
                                        {
                                            targetProvider: function() { return defaultPath },
                                            icon: Style.icons.folder,
                                            title: "Default Path",
                                            description: "Set the folder GitEase opens to by default when opening or cloning a repository.",
                                            isInPopup: true
                                        }
                                    ]
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.topMargin: 10
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20

                                spacing: 20

                                CheckboxItem {
                                    id: displayAvatar
                                    Layout.fillWidth: true
                                    title: "Display Avatar"
                                    description: "Show profile Avatar on graph view"
                                    checked: root.appSettings?.generalSettings?.showAvatar ?? false
                                }

                                CheckboxItem {
                                    id: displayStashNodes
                                    Layout.fillWidth: true
                                    title: "Display Stash"
                                    description: "Show stash nodes on graph view"
                                    checked: root.appSettings?.generalSettings?.showStashNodes ?? false
                                }

                                PathSelectorItem {
                                    id: defaultPath
                                    Layout.fillWidth: true
                                    fileIO: root.fileIO
                                    title: "Default Path"
                                    description: "Select Default path to open or clone location"
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 2
                                    Layout.alignment: Qt.AlignHCenter
                                    color: Qt.darker(settingsContainer.color, 1.2)
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }

                            }
                        }

                        Item {
                            GuideHoverTrigger {
                                guideController: root.guideController
                                guideId: "settings_ssh_tutorial"
                                guideName: "SSH Keys"
                                guideIcon: Style.icons.terminal
                                stepsFactory: function() {
                                    return [
                                        {
                                            targetProvider: function() { return sshScrollView },
                                            icon: Style.icons.terminal,
                                            title: "SSH Keys",
                                            description: "Manage the SSH keys used to authenticate with your git remotes — generate a new key pair, copy the public key, or import an existing one.",
                                            isInPopup: true,
                                            activationDelay: 300,
                                            onActivate: function() { root.currentPage = 1 }
                                        }
                                    ]
                                }
                            }

                            SshKeyController { id: sshKeyFallback }

                            SshKeyCard {
                                id: sshScrollView
                                anchors.fill: parent
                                anchors.topMargin: 10
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                sshKeyController: root.sshKeyController ?? sshKeyFallback
                                notificationController: root.notificationController
                                currentUserProfile: root.appModel?.currentUserProfile ?? null
                            }
                        }

                        Item {
                            GuideHoverTrigger {
                                guideController: root.guideController
                                guideId: "settings_appearance_tutorial"
                                guideName: "Appearance"
                                guideIcon: Style.icons.palette
                                stepsFactory: function() {
                                    return [
                                        {
                                            targetProvider: function() { return theme },
                                            icon: Style.icons.palette,
                                            title: "Theme",
                                            description: "Switch between light and dark visual themes for the whole app.",
                                            isInPopup: true,
                                            activationDelay: 300,
                                            onActivate: function() { root.currentPage = 2 }
                                        },
                                        {
                                            targetProvider: function() { return displayRealtimeNotifications },
                                            icon: Style.icons.bell,
                                            title: "Real-time Notifications",
                                            description: "Choose whether notifications also pop up as floating windows, or only appear in the notification center.",
                                            isInPopup: true
                                        },
                                        {
                                            targetProvider: function() { return maxVisibleNotifications },
                                            icon: Style.icons.bell,
                                            title: "Max Visible Notifications",
                                            description: "Limit how many floating notifications can be on screen at once.",
                                            isInPopup: true
                                        },
                                        {
                                            targetProvider: function() { return notificationPosition },
                                            icon: Style.icons.bell,
                                            title: "Notification Position",
                                            description: "Pick which corner of the screen floating notifications appear in.",
                                            isInPopup: true
                                        }
                                    ]
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.topMargin: 10
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20

                                spacing: 20

                                ComboboxItem {
                                    id: theme
                                    Layout.fillWidth: true
                                    title: "Theme"
                                    description: "Select theme"
                                    cmb.model: ["Modern Light", "Modern Dark"]
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 2
                                    Layout.alignment: Qt.AlignHCenter
                                    color: Qt.darker(settingsContainer.color, 1.2)
                                }

                                CheckboxItem {
                                    id: displayRealtimeNotifications
                                    Layout.fillWidth: true
                                    title: "Display Real-time Notifications"
                                    description: "Show notifications as floating windows. If disabled, notifications are only shown in the notification center"
                                    checked: root.appSettings?.notificationSettings?.displayRealtimeNotifications ?? true
                                }

                                SpinboxItem {
                                    id: maxVisibleNotifications
                                    Layout.fillWidth: true
                                    title: "Maximum Visible Notifications"
                                    description: "Number of notifications displayed at once"
                                    from: 1
                                    to: 10
                                    value: 5
                                }

                                ComboboxItem {
                                    id: notificationPosition
                                    Layout.fillWidth: true
                                    title: "Notification Position"
                                    description: "Where to display notifications on screen"
                                    cmb.model: ["Right Bottom", "Right Top", "Left Bottom", "Left Top"]
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 2
                                    Layout.alignment: Qt.AlignHCenter
                                    color: Qt.darker(settingsContainer.color, 1.2)
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }

                            }

                        }

                        Item {
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.topMargin: 10
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20

                                spacing: 20

                                RowLayout {
                                    Layout.fillWidth: true

                                    ColumnLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            Layout.fillWidth: true
                                            text: "GitEase Version"
                                            font.pointSize: Style.appFont.h4Pt
                                            color: Style.colors.foreground
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: "Installed version: " + (Qt.application.version || "0.0.0")
                                            font.pointSize: Style.appFont.secondaryPt
                                            color: Style.colors.mutedText
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 2
                                    Layout.alignment: Qt.AlignHCenter
                                    color: Qt.darker(settingsContainer.color, 1.2)
                                }

                                ButtonItem {
                                    id: checkUpdatesButton
                                    Layout.fillWidth: true
                                    title: "Application Updates"
                                    description: ""
                                    buttonTitle: root.updateController?.busy ? "Checking ..." : "Check"
                                    busy: root.updateController?.busy ?? false
                                    enabled: root.updateController !== null
                                             && !(root.updateController?.busy ?? false)
                                    onClicked: root.checkForApplicationUpdate()
                                }

                                ButtonItem {
                                    id: installUpdateButton
                                    Layout.fillWidth: true
                                    visible: root.updateController?.updateAvailable === true
                                    title: "Install Update"
                                    description: (root.updateController?.latestVersion ?? "") !== ""
                                                 ? "Download and install version " + root.updateController.latestVersion
                                                 : "Download and install the available update"
                                    buttonTitle: root.updateController?.busy ? "Updating ..." : "Update"
                                    busy: root.updateController?.busy ?? false
                                    enabled: root.updateController !== null
                                             && root.updateController.updateAvailable
                                             && !(root.updateController?.busy ?? false)
                                    onClicked: root.installApplicationUpdate()
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Math.max(96, updateReleaseContent.implicitHeight + 20)
                                    visible: (root.updateController?.latestVersion ?? "") !== ""
                                             || (root.updateController?.releaseNotes ?? "") !== ""
                                             || (root.updateController?.downloadSize ?? "") !== ""
                                    radius: 6
                                    color: Style.colors.cardBackground
                                    border.width: 1
                                    border.color: Style.colors.secondaryBorder

                                    RowLayout {
                                        id: updateReleaseContent
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 12

                                        readonly property bool isCritical: root.updateController?.isCritical ?? false

                                        Text {
                                            text: updateReleaseContent.isCritical ? Style.icons.warning : Style.icons.info
                                            font.family: Style.fontTypes.font6Pro
                                            font.pixelSize: updateReleaseContent.isCritical ? 13 : 16
                                            color: updateReleaseContent.isCritical ? Style.colors.notificationWarningText : Style.colors.mutedText
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Text {
                                                Layout.fillWidth: true
                                                text: updateReleaseContent.isCritical ? "Critical Update" : "Latest Release"
                                                font.pointSize: Style.appFont.h4Pt
                                                color: Style.colors.foreground
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: {
                                                    var parts = []
                                                    if ((root.updateController?.latestVersion ?? "") !== "") {
                                                        parts.push("Version " + root.updateController.latestVersion)
                                                    }
                                                    if ((root.updateController?.downloadSize ?? "") !== "") {
                                                        parts.push(root.updateController.downloadSize)
                                                    }
                                                    if (root.updateController?.updateAvailable === true) {
                                                        parts.push("Update available")
                                                    }
                                                    return parts.join(" | ")
                                                }
                                                font.pointSize: Style.appFont.secondaryPt
                                                color: Style.colors.mutedText
                                                wrapMode: Text.WordWrap
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                visible: (root.updateController?.releaseNotes ?? "") !== ""
                                                text: root.updateController?.releaseNotes ?? ""
                                                font.pointSize: Style.appFont.secondaryPt
                                                color: Style.colors.mutedText
                                                wrapMode: Text.WordWrap
                                                lineHeight: 1.1
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: updateStatusText.implicitHeight + 18
                                    radius: 5
                                    color: {
                                        switch (root.updateController?.statusType) {
                                            case "success":
                                                return Style.colors.notificationSuccess
                                            case "warning":
                                                return Style.colors.notificationWarning
                                            case "error":
                                                return Style.colors.notificationError
                                            default :
                                                return Style.colors.notificationInfo
                                        }
                                    }

                                    border.color: {
                                        switch (root.updateController?.statusType) {
                                            case "success":
                                                return Style.colors.notificationSuccessBorder
                                            case "warning":
                                                return Style.colors.notificationWarningBorder
                                            case "error":
                                                return Style.colors.notificationErrorBorder
                                            default :
                                                return Style.colors.notificationInfoBorder
                                        }
                                    }

                                    border.width: 1

                                    Text {
                                        id: updateStatusText
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        text: root.updateController?.statusText ?? "Not checked yet"
                                        color: {
                                            switch (root.updateController?.statusType) {
                                                case "success":
                                                    return Style.colors.notificationSuccessText
                                                case "warning":
                                                    return Style.colors.notificationWarningText
                                                case "error":
                                                    return Style.colors.notificationErrorText
                                                default :
                                                    return Style.colors.notificationInfoText
                                            }
                                        }

                                        font.pointSize: Style.appFont.secondaryPt
                                        verticalAlignment: Text.AlignVCenter
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }
                            }
                        }

                        Item {
                            GuideHoverTrigger {
                                guideController: root.guideController
                                guideId: "settings_help_tutorial"
                                guideName: "Help & Guides"
                                guideIcon: Style.icons.info
                                stepsFactory: function() {
                                    return [
                                        {
                                            targetProvider: function() { return guidesEnabled },
                                            icon: Style.icons.info,
                                            title: "Enable Guides",
                                            description: "Turn contextual tutorials on or off — when enabled, each one pops up automatically the first time you encounter it.",
                                            isInPopup: true,
                                            activationDelay: 700,
                                            onActivate: function() { root.currentPage = 4 }
                                        },
                                        {
                                            targetProvider: function() { return resetGuidesButton },
                                            icon: Style.icons.refresh,
                                            title: "Reset Guides",
                                            description: "Bring back every tutorial so they show again from the beginning, as if this were a fresh install.",
                                            isInPopup: true
                                        },
                                        {
                                            targetProvider : function() { return tutorialsList },
                                            icon: Style.icons.list,
                                            title: "Guided Tours",
                                            description: "Every tutorial in the app, in one place — click any card to replay it on demand.",
                                            isInPopup: true
                                        }
                                    ]
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.topMargin: 10
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20

                                spacing: 20

                                CheckboxItem {
                                    id: guidesEnabled
                                    Layout.fillWidth: true
                                    title: "Enable Guides"
                                    description: "Show contextual tutorials when using the app for the first time"
                                    checked: root.appSettings?.guidesEnabled ?? true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 2
                                    color: Qt.darker(settingsContainer.color, 1.2)
                                }

                                ButtonItem {
                                    id: resetGuidesButton
                                    Layout.fillWidth: true
                                    title: "Reset Guides"
                                    description: "Show all tutorials again from the beginning"
                                    buttonTitle: "Reset"
                                    onClicked: {
                                        if (root.guideController)
                                            root.guideController.resetShownGuides()

                                        if (root.notificationController)
                                            root.notificationController.success("Guide history cleared", "Help", 2000)
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 2
                                    color: Qt.darker(settingsContainer.color, 1.2)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 5

                                    Text {
                                        text: "Guided Tours"
                                        font.family: Style.fontTypes.roboto
                                        font.weight: Font.DemiBold
                                        font.pixelSize: 13
                                        color: Style.colors.foreground
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Replay any tutorial below. Tutorials tied to a specific page switch you there first."
                                        font.family: Style.fontTypes.roboto
                                        font.pixelSize: 11
                                        color: Style.colors.mutedText
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                GridView {
                                    id: tutorialsList
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    cellWidth: width / 3
                                    cellHeight: 104
                                    model: root.guideController ? root.guideController.catalog : []

                                    delegate: Item {
                                        width: tutorialsList.cellWidth
                                        height: tutorialsList.cellHeight

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            radius: 10
                                            color: tutorialMouseArea.containsMouse
                                                   ? Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.10)
                                                   : Style.colors.primaryBackground
                                            border.width: 1
                                            border.color: tutorialMouseArea.containsMouse ? Style.colors.accent : Style.colors.primaryBorder
                                            Behavior on color        { ColorAnimation { duration: 100 } }
                                            Behavior on border.color { ColorAnimation { duration: 100 } }

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: 10
                                                spacing: 8

                                                Rectangle {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    implicitWidth: 32
                                                    implicitHeight: 32
                                                    radius: 16
                                                    color: Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.13)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.icon
                                                        font.family: Style.fontTypes.font6ProSolid
                                                        font.pixelSize: 14
                                                        color: Style.colors.accent
                                                    }
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    text: modelData.name
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                    wrapMode: Text.WordWrap
                                                    maximumLineCount: 2
                                                    elide: Text.ElideRight
                                                    font.family: Style.fontTypes.roboto
                                                    font.pixelSize: 11
                                                    font.weight: Font.Medium
                                                    color: Style.colors.foreground
                                                }
                                            }

                                            MouseArea {
                                                id: tutorialMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.playTutorial(modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Row {
                id: actionButtonsRow
                spacing: 8
                Layout.alignment: Qt.AlignRight

                Button {
                    flat: true
                    text: "Cancel"
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                    }
                    onClicked: root.close()
                }

                Button {
                    flat: true
                    text: "Save"
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                    }
                    onClicked: {
                        root.apply()
                        root.close()
                    }
                }

                Button {
                    flat: true
                    text: "Apply"
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                    }
                    onClicked: root.apply()
                }
            }
        }
    }

    function apply() {
        root.appSettings.guidesEnabled = guidesEnabled.checked
        root.appSettings.generalSettings.showAvatar = displayAvatar.checked
        root.appSettings.generalSettings.showStashNodes = displayStashNodes.checked
        root.appSettings.generalSettings.defaultPath = defaultPath.text
        root.appSettings.appearanceSettings.currentTheme = theme.cmb.displayText
        root.appSettings.notificationSettings.displayRealtimeNotifications = displayRealtimeNotifications.checked
        root.appSettings.notificationSettings.maxVisibleNotifications = maxVisibleNotifications.value
        
        let positionMap = {
            "Right Bottom": "right-bottom",
            "Right Top": "right-top",
            "Left Bottom": "left-bottom",
            "Left Top": "left-top"
        }
        root.appSettings.notificationSettings.notificationPosition = positionMap[notificationPosition.cmb.displayText] || "right-bottom"

        root.appModel.save()
        
        if (notificationController) {
            notificationController.success("Settings saved successfully", "Settings", 3000)
        }
    }

    function load() {
        guidesEnabled.checked = root.appSettings?.guidesEnabled ?? true
        displayAvatar.checked = root.appSettings?.generalSettings?.showAvatar
        displayStashNodes.checked = root.appSettings?.generalSettings?.showStashNodes
        defaultPath.text = root.appSettings.generalSettings.defaultPath

        theme.cmb.currentIndex = theme.cmb.model.indexOf(root.appSettings.appearanceSettings.currentTheme)
        
        displayRealtimeNotifications.checked = root.appSettings?.notificationSettings?.displayRealtimeNotifications ?? true
        maxVisibleNotifications.value = root.appSettings?.notificationSettings?.maxVisibleNotifications ?? 5
        
        let positionMap = {
            "right-bottom": "Right Bottom",
            "right-top": "Right Top",
            "left-bottom": "Left Bottom",
            "left-top": "Left Top"
        }
        let positionDisplay = positionMap[root.appSettings?.notificationSettings?.notificationPosition] || "Right Bottom"
        notificationPosition.cmb.currentIndex = notificationPosition.cmb.model.indexOf(positionDisplay)
    }

    function checkForApplicationUpdate() {
        if (!root.updateController) {
            return
        }

        root.updateController.checkForUpdates()
    }

    function installApplicationUpdate() {
        if (!root.updateController) {
            return
        }

        root.updateController.installAvailableUpdate()
    }

}
