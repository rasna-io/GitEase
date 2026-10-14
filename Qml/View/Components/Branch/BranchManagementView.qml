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

    property var              localBranches:    []
    property var              remoteBranches:   []

    readonly property var     filteredLocalBranches: root.filterItems(root.localBranches, branchName)
    readonly property var     filteredRemoteBranches: root.filterItems(root.remoteBranches, branchName)

    /* Object Properties
     * ****************************************************************************************/
    title: "Branches"
    icon: Style.icons.branch
    contentMatchesFilter: root.filteredLocalBranches.length > 0 || root.filteredRemoteBranches.length > 0
    filteredCount: root.filteredLocalBranches.length + root.filteredRemoteBranches.length

    content: ColumnLayout {
        id: content

        property int currentIndex: 0

        anchors.fill: parent
        spacing: 8

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "branch_management_tutorial"
            guideName: "Branches"
            guideIcon: Style.icons.branch
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return root },
                        icon: Style.icons.branch,
                        title: "Branches Dock",
                        description: "View and manage all local and remote branches. Click the header to expand this dock if it's collapsed.",
                        isInPopup: false,
                        activationDelay: 300,
                        onActivate: function() { root.collapsed = false }
                    },
                    {
                        targetProvider: function() { return viewControl },
                        icon: Style.icons.filter,
                        title: "Local / Remote Switch",
                        description: "Toggle between viewing local branches and remote-tracking branches.",
                    },
                    {
                        targetProvider: function() { return listView },
                        icon: Style.icons.branch,
                        title: "Branch List",
                        description: "Every local and remote-tracking branch appears here. The current branch is marked HEAD. Right-click a branch to check it out, copy its name or delete it."
                    },
                    {
                        targetProvider: function() { return addBranchBtn },
                        icon: Style.icons.branchPlus,
                        title: "Create Branch",
                        description: "Start a new branch from your current commit — useful for isolating a feature or fix from the branch you're on.",
                        commands: [{ command: "git branch <name>" }]
                    }
                ]
            }
        }

        Connections {
            target: root
            function onBranchControllerChanged() {
                content.reload()
            }

            function onFilterNeedleChanged() {
                if (!root.filterActive || root.titleMatchesFilter)
                    return

                if (content.currentIndex === 0 && root.filteredLocalBranches.length === 0
                        && root.filteredRemoteBranches.length > 0)
                    content.currentIndex = 1
                else if (content.currentIndex === 1 && root.filteredRemoteBranches.length === 0
                         && root.filteredLocalBranches.length > 0)
                    content.currentIndex = 0
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
            model: content.currentIndex === 0 ? root.filteredLocalBranches
                                              : root.filteredRemoteBranches
        }

        DashedButton {
            id: addBranchBtn
            Layout.fillWidth: true
            Layout.topMargin: Style.dp(2)
            visible: content.currentIndex === 0

            text: "Create Branch"

            onClicked: {
                openAddBranchPopup()
            }
        }

        function reload() {
            root.currentBranch = branchController.getCurrentBranchName()
            let res = branchController.getBranches();

            root.localBranches = content.headFirst(res.filter(branch => branch["isLocal"]))
            root.remoteBranches = res.filter(branch => branch["isRemote"])

            root.badgeCount = root.localBranches.length + root.remoteBranches.length
        }

        //! Moves the checked-out branch to the top; the rest keep the order git reported.
        function headFirst(branches) {
            let head = branches.findIndex(branch => branch["name"] === root.currentBranch)
            if (head > 0)
                branches.unshift(branches.splice(head, 1)[0])

            return branches
        }
    }

    /* Functions
     * ****************************************************************************************/
    function branchName(branch) {
        return branch.name
    }

    function openAddBranchPopup() {
        addBranchPopup.branchController = root.branchController
        addBranchPopup.open()
    }

    function reload() {
        if (root.contentItem)
            root.contentItem.reload()
    }
}
