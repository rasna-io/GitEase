import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * CommittingPageHeader
 * ************************************************************************************************/
RowLayout {
    id: headerRow

    /* Property Declarations
     * ****************************************************************************************/
    property          BranchController       branchController:          null
    property          NotificationController notificationController:    null
    property          RemoteController       remoteController:          null
    readonly property bool                   compact:                   parent.width < 550

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent
    anchors.leftMargin: parent.width < Style.appHeight ? 8 : 20
    anchors.rightMargin: parent.width < Style.appHeight ? 4 : 5
    spacing: parent.width < Style.appHeight ? 6 : 10

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/
    TextEdit {
        id: clipboardHelper
        visible: false
    }

    RButton {
        id: branchChip
        Layout.preferredHeight: 25
        maximumWidth: 150
        visible: !headerRow.compact
        icon.name: Style.icons.branch
        text: branchController ? branchController.getCurrentBranchName() : ""

        Connections {
            target: repositoryController
            function onCurrentRepoChanged() {
                headerBranchLabel.text = branchController ? branchController.getCurrentBranchName() : ""
            }
        }

        onClicked: {
            clipboardHelper.text = branchChip.text
            clipboardHelper.selectAll()
            clipboardHelper.copy()

            if (notificationController)
                notificationController.success(`brach name : ${branchChip.text} copied to clipboard`)
        }
    }

    // Separator
    Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 20
        color: Style.colors.primaryBorder
        visible: !headerRow.compact
    }

    RButton {
        id: pullBtn
        Layout.preferredHeight: 26

        icon.name: Style.icons.arrowDown
        text: "Pull"
        tooltip: "Pull from origin"
        compact: headerRow.compact

        onClicked: root.pullAndUpdate()
    }

    RButton {
        id: pushBtnHeader
        Layout.preferredHeight: 26
        Layout.minimumWidth: 30
        Material.accent: Style.colors.accent

        property bool isBusy: remoteController?.pushInProgress && !remoteController?.forcePush

        background: Rectangle {
            radius: 5
            color: pushBtnHeader.down ? Style.colors.surfaceMuted :
                   pushBtnHeader.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
        }

        BusyIndicator {
            id: pushBusyIndicator
            anchors.centerIn: parent
            width: 30
            height: 30
            running: pushBtnHeader.isBusy
            visible: pushBtnHeader.isBusy
        }

        enabled: !remoteController?.pushInProgress
        icon.name: !isBusy ? Style.icons.arrowUp : ""
        text: !isBusy ? "Push" : ""
        tooltip: !isBusy ? "Push to origin" : "Pushing..."
        compact: headerRow.compact

        onClicked: {
            root.pushAndUpdate()
        }
    }

    Item {
        Layout.fillWidth: true
    }

    RButton {
        id: fetchBtnHeader
        Layout.preferredHeight: 26

        enabled: !root.isFetching

        icon.name: Style.icons.download
        text: "Fetch"
        tooltip: root.isFetching ? "Fetching…" : "Fetch all remotes"
        compact: headerRow.compact

        onClicked: root.fetch()
    }

    RButton {
        id: pushForceBtnHeader
        Layout.preferredHeight: 26
        Layout.minimumWidth: 30
        Material.accent: Style.colors.accent

        property bool isBusy: remoteController?.pushInProgress && remoteController?.forcePush

        background: Rectangle {
            radius: 5
            color: pushForceBtnHeader.down ? Style.colors.surfaceMuted :
                   pushForceBtnHeader.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
        }

        BusyIndicator {
            id: pushForceBusyIndicator
            anchors.centerIn: parent
            width: 30
            height: 30
            running: pushForceBtnHeader.isBusy
            visible: pushForceBtnHeader.isBusy
        }

        enabled: !remoteController?.pushInProgress
        icon.name: !isBusy ? Style.icons.arrowUp : ""
        text: !isBusy ? "Push Force" : ""
        tooltip: !isBusy ? "Force push to origin" : "Force Pushing..."
        compact: headerRow.compact

        onClicked: {
            root.pushAndUpdate(true)
        }
    }
}
