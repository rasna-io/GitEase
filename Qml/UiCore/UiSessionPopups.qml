import QtQuick

import GitEase

/*! ***********************************************************************************************
 * UiSessionPopups holds popups that probabley one instance of them will serve to everywhere, like
 * about, close, confirm (yes, no, cancel, etc) popup, color select popup, etc
 *
 * \note This should be of type Item so Overlay.overlay (Window.window) is set for it and for its
 * Popups, since Popups will not open without this
 * ***********************************************************************************************/
Item {
    id: root

    property NotificationController notificationController: null

    SshKeyController {
        id: sshKeyCtrl
    }

    property RepositorySelectorPopup    repositorySelectorPopup:    RepositorySelectorPopup {}

    property SettingsPopup              settingsPopup:              SettingsPopup {
        notificationController: root.notificationController
        sshKeyController:       sshKeyCtrl
    }

    property UserAuthenticationPopup    userAuthenticationPopup:    UserAuthenticationPopup {}

    property UserInfoSelectionPopup     userInfoSelectionPopup:     UserInfoSelectionPopup {}

    property AddEditRemotePopup         addEditRemotePopup:         AddEditRemotePopup {
        notificationController: root.notificationController
    }

    property AddBranchPopup             addBranchPopup:             AddBranchPopup {
        notificationController: root.notificationController
    }

    property AddStashPopup              addStashPopup:              AddStashPopup {
        notificationController: root.notificationController
    }

    property NotificationCenterPopup    notificationCenterPopup:    NotificationCenterPopup {}

    property ManageStashPopup           manageStashPopup:           ManageStashPopup {}

    property FetchSummaryPopup          fetchSummaryPopup:          FetchSummaryPopup {}
}
