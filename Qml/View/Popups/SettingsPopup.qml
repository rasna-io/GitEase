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


    /* Object Properties
     * ****************************************************************************************/
    width: parent.width * 0.8
    height: parent.height * 0.8

    onClosed: load()
    onOpened: load()

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 15


            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true

                PagesRail {
                    Layout.preferredWidth: parent.width * 0.15
                    Layout.fillHeight: true
                    currentId: root.currentPage
                    radius: 5
                    color: Style.colors.secondaryBackground
                    model: [
                        {id: 0, title: "General", icon: Style.icons.slider},
                        {id: 1, title: "SSH", icon: Style.icons.terminal},
                        {id: 2, title: "Appearence", icon: Style.icons.palette},
                        {id: 3, title: "Updates", icon: Style.icons.refresh},
                    ]
                    expanded: true
                    onClicked: (modelData) => {
                        root.currentPage = modelData.id
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
                    }
                }
            }

            Row {
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
