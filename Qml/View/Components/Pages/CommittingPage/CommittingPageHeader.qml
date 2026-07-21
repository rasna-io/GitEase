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
    property          GuideController        guideController:           null
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

    IconButton {
        id: branchChip
        Layout.preferredHeight: 25
        maximumWidth: 150
        visible: !headerRow.compact
        solidIcon: true
        icon.name: Style.icons.branch
        icon.width: Style.appFont.h3Pt
        icon.height: Style.appFont.h3Pt
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.defaultPt
        font.weight: Font.Medium
        text: branchController ? branchController.getDisplayBranchName() : ""

        Connections {
            target: repositoryController
            function onCurrentRepoChanged() {
                branchChip.text = branchController ? branchController.getDisplayBranchName() : ""
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

    IconButton {
        id: pullBtn
        Layout.preferredHeight: 26

        solidIcon: true
        icon.name: Style.icons.arrowDown
        icon.width: Style.appFont.h3Pt
        icon.height: Style.appFont.h3Pt
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.defaultPt
        font.weight: Font.Medium
        text: "Pull"
        tooltip: "Pull from origin"
        display: headerRow.compact ? IconButton.IconOnly : IconButton.TextBesideIcon

        onClicked: root.pullAndUpdate()
    }

    IconButton {
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
        solidIcon: true
        icon.name: !isBusy ? Style.icons.arrowUp : ""
        icon.width: Style.appFont.h3Pt
        icon.height: Style.appFont.h3Pt
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.defaultPt
        font.weight: Font.Medium
        text: !isBusy ? "Push" : ""
        tooltip: !isBusy ? "Push to origin" : "Pushing..."
        display: headerRow.compact ? IconButton.IconOnly : IconButton.TextBesideIcon

        onClicked: {
            root.pushAndUpdate()
        }
    }

    Item {
        Layout.fillWidth: true
    }

    IconButton {
        id: fetchBtnHeader
        Layout.preferredHeight: 26

        enabled: !root.isFetching

        solidIcon: true
        icon.name: Style.icons.download
        icon.width: Style.appFont.h3Pt
        icon.height: Style.appFont.h3Pt
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.defaultPt
        font.weight: Font.Medium
        text: "Fetch"
        tooltip: root.isFetching ? "Fetching…" : "Fetch all remotes"
        display: headerRow.compact ? IconButton.IconOnly : IconButton.TextBesideIcon

        onClicked: root.fetch()
    }

    IconButton {
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
        solidIcon: true
        icon.name: !isBusy ? Style.icons.arrowUp : ""
        icon.width: Style.appFont.h3Pt
        icon.height: Style.appFont.h3Pt
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.defaultPt
        font.weight: Font.Medium
        text: !isBusy ? "Push Force" : ""
        tooltip: !isBusy ? "Force push to origin" : "Force Pushing..."
        display: headerRow.compact ? IconButton.IconOnly : IconButton.TextBesideIcon

        onClicked: {
            root.pushAndUpdate(true)
        }
    }

    /* Guide
     * ****************************************************************************************/
    GuideHoverTrigger {
        guideController: headerRow.guideController
        guideId: "committing_header_tutorial"
        guideName: "Committing Header"
        guideIcon: Style.icons.arrowUp
        guidePage: "committing"
        stepsFactory: function() {
            var steps = []
            if (!headerRow.compact) {
                steps.push({
                    targetProvider: function() { return branchChip },
                    icon: Style.icons.branch,
                    title: "Current Branch",
                    description: "Shows the branch you are committing to. Click to copy the name to the clipboard — handy for PR titles or referencing in messages."
                })
            }
            steps.push({
                targetProvider: function() { return pullBtn },
                icon: Style.icons.arrowDown,
                title: "Pull",
                description: "Downloads commits from the remote and merges them into your current branch. Run this before starting work to stay in sync with your team.",
                commands: [{ command: "git pull" }]
            })
            steps.push({
                targetProvider: function() { return pushBtnHeader },
                icon: Style.icons.arrowUp,
                title: "Push",
                description: "Uploads your local commits to the remote so teammates can fetch or pull them. Only commits that are already saved locally will be sent.",
                commands: [{ command: "git push" }]
            })
            steps.push({
                targetProvider: function() { return fetchBtnHeader },
                icon: Style.icons.download,
                title: "Fetch",
                description: "Downloads all remote changes and updates your remote-tracking branches without touching your working tree or current branch. Always safe to run.",
                commands: [{ command: "git fetch --all" }]
            })
            steps.push({
                targetProvider: function() { return pushForceBtnHeader },
                icon: Style.icons.arrowUp,
                title: "Force Push",
                description: "Rewrites the remote branch with your local history. --force-with-lease is safer than --force: it aborts automatically if someone else has pushed since your last fetch, protecting their work.",
                commands: [{ command: "git push --force-with-lease" }]
            })
            return steps
        }
    }
}
