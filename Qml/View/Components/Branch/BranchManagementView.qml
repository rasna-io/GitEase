import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * BranchManagementView
 * ************************************************************************************************/
UtilitiesCard {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property BranchController branchController: null

    property AddBranchPopup   addBranchPopup: null

    property string           currentBranch:    ""
    
    property NotificationController notificationController: null

    property GuideController  guideController: null

    /* Object Properties
     * ****************************************************************************************/
    title: "Branch Management"
    icon: Style.icons.branch

    content: ColumnLayout {
        id: content

        property int currentIndex: 0
        property var localBranches: []
        property var remoteBranches: []

        onCurrentIndexChanged: content.updateModel()

        anchors.fill: parent
        spacing: 6

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "branch_management_tutorial"
            guideName: "Branch Management"
            guideIcon: Style.icons.branch
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return listView },
                        icon: Style.icons.branch,
                        title: "All Branches",
                        description: "Every local and remote-tracking branch appears here. Click Checkout to switch to one, or the trash icon to delete it."
                    },
                    {
                        targetProvider: function() { return addBranchBtn },
                        icon: Style.icons.branchPlus,
                        title: "Create a Branch",
                        description: "Start a new branch from your current commit — useful for isolating a feature or fix from the branch you're on.",
                        commands: [{ command: "git branch <name>" }]
                    }
                ]
            }
        }

        Connections {
            target: root
            function onBranchControllerChanged() {
                content.update()
            }
        }

        Connections {
            target: root.branchController

            function onCurrentRepoChanged() {
                content.update()
            }
        }


        Connections {
            target: root.addBranchPopup

            function onAboutToHide() {
                content.update()
            }
        }

        ButtonGroup {
            id: headerButtonGroup
            exclusive: true
        }

        // View Control
        Rectangle {
            id: viewControl
            Layout.fillWidth: true
            Layout.preferredHeight: Style.dp(25)
            radius: Style.dp(5)
            color: Style.colors.cardBackground

            border {
                width: Style.dp(1)
                color: Style.colors.primaryBorder
            }

            RowLayout {
                anchors.fill: parent
                spacing: 4
                anchors.margins: 2

                IconButton {
                    id: localBtn
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    topInset: 0
                    bottomInset: 0
                    verticalPadding: 6

                    checkable: true
                    checked: content.currentIndex === 0
                    ButtonGroup.group: headerButtonGroup

                    display: IconButton.TextBesideIcon
                    icon.name: Style.icons.laptop
                    icon.width: Style.appFont.smallPt
                    icon.height: Style.appFont.smallPt
                    icon.color: Style.colors.foreground
                    text: "Local"
                    font.pixelSize: Style.appFont.smallPt

                    background: Rectangle {
                        radius: viewControl.radius
                        color: localBtn.checked ? Style.colors.primaryBackground : "transparent"
                    }

                    onClicked: content.currentIndex = 0
                }

                IconButton {
                    id: remoteBtn
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    topInset: 0
                    bottomInset: 0
                    verticalPadding: 6

                    checkable: true
                    checked: content.currentIndex === 1
                    ButtonGroup.group: headerButtonGroup

                    display: IconButton.TextBesideIcon
                    icon.name: Style.icons.cloud
                    icon.width: Style.appFont.smallPt
                    icon.height: Style.appFont.smallPt
                    icon.color: Style.colors.foreground
                    text: "Remote"
                    font.pixelSize: Style.appFont.smallPt

                    background: Rectangle {
                        radius: viewControl.radius
                        color: remoteBtn.checked ? Style.colors.primaryBackground : "transparent"
                    }

                    onClicked: content.currentIndex = 1
                }
            }
        }

        BranchesList {
            id: branchesList
            isLocal: content.currentIndex === 0
            currentBranch: root.currentBranch
            branchController: root.branchController
            notificationController: root.notificationController
            onUpdateRequested: content.update()
        }

        IconButton {
            id: addBranchBtn
            Layout.fillWidth: true
            implicitHeight: Style.dp(25)
            visible: content.currentIndex === 0

            display: IconButton.TextBesideIcon
            icon.name: Style.icons.plus
            icon.width: Style.appFont.smallPt
            icon.height: Style.appFont.smallPt
            icon.color: Style.colors.textButton
            text: "Add New Branch"
            font.pixelSize: Style.appFont.mediumPt

            background: Rectangle {
                radius: Style.dp(4)
                color: enabled ? Style.colors.accent : Style.colors.disabledButton
            }

            onClicked: {
                openAddBranchPopup()
            }
        }

        function update() {
            if (branchController) {
                root.currentBranch = branchController.getCurrentBranchName()
                let res = branchController.getBranches();

                content.localBranches = res.filter(branch => branch["isLocal"])
                content.remoteBranches = res.filter(branch => branch["isRemote"])

                content.updateModel(res)
                root.badgeCount = content.localBranches.length + content.remoteBranches.length
            }
        }

        function updateModel(res) {
            branchesList.model = content.currentIndex === 0 ? content.localBranches : content.remoteBranches
        }
    }

    /* Functions
     * ****************************************************************************************/

    function openAddBranchPopup() {
        addBranchPopup.branchController = root.branchController
        addBranchPopup.open()
    }
}
