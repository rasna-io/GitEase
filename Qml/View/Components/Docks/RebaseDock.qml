import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RebaseDock
 * ************************************************************************************************/

UtilitiesCard {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property BranchController       branchController:       null
    property RebaseController       rebaseController:       null
    property CommitController       commitController:       null
    property StatusController       statusController:       null
    property NotificationController notificationController: null
    property ConflictController     conflictController:     null
    property LayoutController       layoutController:       null
    property GuideController        guideController:        null

    /* Object Properties
     * ****************************************************************************************/
    title: "Rebase"
    icon: Style.icons.copy

    content: ColumnLayout {
        spacing: 6

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "rebase_dock_tutorial"
            guideName: "Rebase"
            guideIcon: Style.icons.copy
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return upstreamInput },
                        icon: Style.icons.copy,
                        title: "Upstream",
                        description: "The branch, tag, or commit you want to replay your commits onto."
                    },
                    {
                        targetProvider: function() { return branchCombo },
                        icon: Style.icons.branch,
                        title: "Branch to Rebase",
                        description: "Choose which local branch gets rebased. Defaults to your current branch."
                    },
                    {
                        targetProvider: function() { return advancedToggle },
                        icon: Style.icons.filter,
                        title: "Advanced: --onto",
                        description: "Enable this to move only a range of commits onto a different base, instead of replaying the whole upstream history.",
                        commands: [{ command: "git rebase --onto <newbase> <upstream> <branch>" }]
                    },
                    {
                        targetProvider: function() { return startRebaseBtn },
                        icon: Style.icons.copy,
                        title: "Preview & Run",
                        description: "Shows exactly which commits will be replayed before anything happens, so you can confirm the plan before committing to the rebase.",
                        commands: [{ command: "git rebase <upstream>" }]
                    }
                ]
            }
        }

        // Upstream field (required)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Upstream"
                font.pixelSize: Style.appFont.captionPt
                color: Style.colors.mutedText
            }
            TextField {
                id: upstreamInput
                Layout.fillWidth: true
                implicitHeight: Style.dp(25)
                placeholderText: "branch, tag, or commit SHA"
                selectByMouse: true
                font.pixelSize: Style.appFont.smallPt

                background: Rectangle {
                    implicitHeight: Style.dp(25)
                    color: Style.colors.secondaryBackground
                    radius: Style.dp(4)
                    border.color: upstreamInput.activeFocus ? Style.colors.accent : "transparent"
                }
            }
        }

        // Branch to rebase (optional)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Branch to rebase"
                font.pixelSize: Style.appFont.captionPt
                color: Style.colors.mutedText
            }

            ComboBox {
                id: branchCombo
                Layout.fillWidth: true
                minHeight: Style.dp(25)
                focusBorderWidth: 1
                font.family: Style.fontTypes.inter
                font.weight: 400
                font.pixelSize: Style.appFont.smallPt
                textRole: "label"
                model: branchModel
                currentIndex: 0

                Material.background: Style.colors.primaryBackground
                Material.foreground: Style.colors.secondaryText

                background: Rectangle {
                    radius: Style.dp(4)
                    color: branchCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                    border.color: branchCombo.activeFocus ? Style.colors.accent : "transparent"
                }
            }
        }

        // Advanced mode toggle
        CheckBox {
            id: advancedToggle
            Layout.fillWidth: false
            text: "Use --onto (advanced)"
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.smallPt
            implicitHeight: Style.dp(25)
            Material.accent: Style.colors.accent
            Material.foreground: Style.colors.foreground
            palette {
                text: Style.colors.foreground
            }

            checked: false
        }

        // Onto field (visible only in advanced mode)
        ColumnLayout {
            visible: advancedToggle.checked
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Onto (new base)"
                Layout.fillWidth: true
                font.pixelSize: Style.appFont.captionPt
                color: Style.colors.mutedText
            }
            TextField {
                id: ontoInput
                Layout.fillWidth: true
                implicitHeight: Style.dp(25)
                placeholderText: "branch, tag, or commit SHA"
                selectByMouse: true
                font.pixelSize: Style.appFont.smallPt

                background: Rectangle {
                    implicitHeight: Style.dp(25)
                    color: Style.colors.secondaryBackground
                    radius: Style.dp(4)
                    border.color: ontoInput.activeFocus ? Style.colors.accent : "transparent"
                }
            }
        }

        // Rebase button
        IconButton {
            id: startRebaseBtn
            Layout.fillWidth: true
            implicitHeight: Style.dp(25)
            enabled: upstreamInput.text.trim().length > 0

            display: IconButton.TextBesideIcon
            icon.name: Style.icons.copy
            icon.width: Style.appFont.smallPt
            icon.height: Style.appFont.smallPt
            icon.color: Style.colors.secondaryForeground
            text: "Start Rebase"
            font.pixelSize: Style.appFont.mediumPt

            background: Rectangle {
                radius: Style.dp(4)
                color: startRebaseBtn.enabled ? (startRebaseBtn.hovered ? Style.colors.accentHover : Style.colors.accent)
                                               : Style.colors.disabledButton
            }

            onClicked: previewRebase(upstreamInput.text, ontoInput.text, advancedToggle.checked, branchCombo.currentIndex)
        }
    }

    ListModel {
        id: branchModel
    }

    CommitPlanPopup {
        id: commitPlanPopup
        statusController: root.statusController
        commitController: root.commitController
        rebaseController: root.rebaseController
        conflictController: root.conflictController
        notificationController: root.notificationController
        layoutController: root.layoutController
        guideController: root.guideController
    }

    /* Functions
     * ****************************************************************************************/

    // Populate branch combo
    function refreshBranches() {
        branchModel.clear()

        if (!branchController)
            return

        var branches = branchController.getBranches()
        if (!branches)
            return

        for (var i = 0; i < branches.length; i++) {

            var b = branches[i]
            if (!b || !b.name)
                continue

            if (b.isRemote)
                continue

            if(b.isCurrent)
                branchModel.append({ label: b.name + " (Current branch)", value: b.name })
            else
                branchModel.append({ label: b.name, value: b.name })
        }
    }

    function previewRebase(upstream, onto, advanced, currentIndexBranchCombo) {
        if (!validateInputs(upstream, onto, advanced, currentIndexBranchCombo))
            return

        upstream    = upstream.trim()
        onto        = advanced ? onto.trim() : ""

        var branchValue = currentBranchValue(currentIndexBranchCombo)

        commitPlanPopup.open()

        rebaseController.startPreviewRebasePlan(onto, upstream, branchValue)
    }

    function validateInputs(upstream, onto, advanced, currentIndexBranchCombo) {
        upstream = upstream.trim()
        if (upstream.length === 0) {
            notificationController.error("Upstream is required.", "Rebase", 4000)
            return false
        }

        if (branchModel.count <= 0) {
            notificationController.error("No local branch is available to rebase.", "Rebase", 4000)
            return false
        }

        if (currentBranchValue(currentIndexBranchCombo).length === 0)
            return false

        if (advanced && onto.trim().length === 0) {
            notificationController.error("Onto is required in advanced mode.", "Rebase", 4000)
            return false
        }

        return true
    }

    function currentBranchValue(currentIndexBranchCombo) {
        if (branchModel.count <= 0 || currentIndexBranchCombo < 0 || currentIndexBranchCombo >= branchModel.count)
            return ""

        return branchModel.get(currentIndexBranchCombo).value
    }

    onBranchControllerChanged: refreshBranches()

    Component.onCompleted: refreshBranches()
}
