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
    property ConflictPopup          conflictPopup:          null

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

    // Perform the rebase
    function startRebase(upstream, onto, advanced, currentIndexBranchCombo) {
        if (!rebaseController)
            return

        upstream = upstream.trim()
        if (upstream.length === 0) {
            if (notificationController)
                notificationController.error("Upstream is required.", "Rebase", 4000)
            return
        }

        if(!branchModel.count > 0)
            return

        var branchValue = branchModel.get(currentIndexBranchCombo).value

        var res
        if (advanced) {

            onto = onto.trim()
            if (onto.length === 0) {
                if (notificationController)
                    notificationController.error("Onto is required in advanced mode.", "Rebase", 4000)
                return
            }

            res = rebaseController.rebaseOnto(onto, upstream, branchValue)
        }
        else {
            res = rebaseController.rebase(upstream, branchValue)
        }

        if (res && res.success) {
            if (notificationController)
                notificationController.success("Rebase completed successfully", "Rebase", 3000)
            return
        }

        if (res && res.data && (res.data.status === "conflict" || res.data.hasConflicts)) {
            if (conflictPopup)
                conflictPopup.show()
            if (notificationController)
                notificationController.warning("Rebase conflicts detected. Please resolve them.", "Rebase", 4000)
            return
        }

        if (notificationController)
            notificationController.error(res?.errorMessage || "Rebase failed", "Rebase", 5000)
    }

    onBranchControllerChanged: refreshBranches()

    Component.onCompleted: refreshBranches()
}
