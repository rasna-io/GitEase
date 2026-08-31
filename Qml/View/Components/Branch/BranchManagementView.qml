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
    title: "Branches"
    icon: Style.icons.branch

    onVisibleChanged: {
        if (visible && root.contentItem)
            root.contentItem.update()
    }

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
                        description: "Every local and remote-tracking branch appears here. The current branch is marked HEAD. Right-click a branch to check it out, copy its name or delete it."
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
            Layout.margins: Style.dp(10)
            implicitHeight: Style.dp(28)
            radius: Style.dp(5)
            color: Style.colors.secondaryBackground

            border {
                width: Style.dp(1)
                color: Style.colors.utilitiesSegmentTrackBorder
            }

            RowLayout {
                anchors.fill: parent
                spacing: 2
                anchors.margins: 2

                Repeater {
                    model: ["Local", "Remote"]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 4
                        color: (index === 0 && content.currentIndex === 0) ||
                               (index === 1 && content.currentIndex === 1)
                               ? Style.colors.utilitiesSegmentSelectedBackground
                               : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.smallPt
                            color: (index === 0 && content.currentIndex === 0) ||
                                   (index === 1 && content.currentIndex === 1)
                                   ? Style.colors.utilitiesSegmentSelectedText
                                   : Style.colors.utilitiesSegmentText
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: content.currentIndex = index
                        }
                    }
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

        DashedButton {
            id: addBranchBtn
            Layout.fillWidth: true
            Layout.leftMargin: Style.dp(10)
            Layout.rightMargin: Style.dp(10)
            Layout.topMargin: Style.dp(2)
            visible: content.currentIndex === 0

            text: "Add Branch"

            onClicked: {
                openAddBranchPopup()
            }
        }

        function update() {
            root.currentBranch = branchController.getCurrentBranchName()
            let res = branchController.getBranches();

            content.localBranches = content.headFirst(res.filter(branch => branch["isLocal"]))
            content.remoteBranches = res.filter(branch => branch["isRemote"])

            content.updateModel(res)
            root.badgeCount = content.localBranches.length + content.remoteBranches.length
        }

        //! Moves the checked-out branch to the top; the rest keep the order git reported.
        function headFirst(branches) {
            let head = branches.findIndex(branch => branch["name"] === root.currentBranch)
            if (head > 0)
                branches.unshift(branches.splice(head, 1)[0])

            return branches
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

    function update() {
        if (root.contentItem)
            root.contentItem.update()
    }
}
