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

    /* Object Properties
     * ****************************************************************************************/
    title: "Rebase"
    icon: Style.icons.copy

    content: ColumnLayout {
        spacing: 10

        // Upstream field (required)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Upstream"
                font.pixelSize: 12
                color: Style.colors.mutedText
            }
            TextField {
                id: upstreamInput
                Layout.fillWidth: true
                placeholderText: "branch, tag, or commit SHA"
                selectByMouse: true


                background: Rectangle {
                    implicitHeight: 40
                    color: Style.colors.secondaryBackground
                    radius: 5
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
                font.pixelSize: 12
                color: Style.colors.mutedText
            }

            ComboBox {
                id: branchCombo
                Layout.fillWidth: true
                minHeight: 40
                focusBorderWidth: 1
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 12
                textRole: "label"
                model: branchModel
                currentIndex: 0

                Material.background: Style.colors.primaryBackground
                Material.foreground: Style.colors.secondaryText

                background: Rectangle {
                    radius: 5
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
            font.family: Style.fontTypes.roboto
            font.pixelSize: 12
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
                font.pixelSize: 12
                color: Style.colors.mutedText
            }
            TextField {
                id: ontoInput
                Layout.fillWidth: true
                placeholderText: "branch, tag, or commit SHA"
                selectByMouse: true

                background: Rectangle {
                    implicitHeight: 40
                    color: Style.colors.secondaryBackground
                    radius: 5
                    border.color: ontoInput.activeFocus ? Style.colors.accent : "transparent"
                }
            }
        }

        // Spacer
        Item {
            Layout.fillHeight: true
        }

        // Rebase button
        Button {
            Layout.fillWidth: true
            implicitHeight: 44
            enabled: upstreamInput.text.trim().length > 0

            background: Rectangle {
                radius: 8
                color: enabled ? (parent.hovered ? Style.colors.accentHover : Style.colors.accent)
                               : Style.colors.disabledButton
            }

            contentItem: Item {
                anchors.fill: parent
                Row {
                    spacing: 10
                    anchors.centerIn: parent

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Style.icons.copy
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: 12
                        color: Style.colors.secondaryForeground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Start Rebase"
                        color: Style.colors.secondaryForeground
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
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
