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
    property          BranchController branchController:    null
    readonly property bool             compact:             parent.width < 550

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
    RoniaButton {
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
    }

    // Separator
    Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 20
        color: Style.colors.primaryBorder
        visible: !headerRow.compact
    }

    RoniaButton {
        id: pullBtn
        Layout.preferredHeight: 26

        icon.name: Style.icons.arrowDown
        text: "Pull"
        tooltip: "Pull from origin"
        compact: headerRow.compact

        onClicked: root.pullAndUpdate()
    }

    RoniaButton {
        id: pushBtnHeader
        Layout.preferredHeight: 26

        icon.name: Style.icons.arrowUp
        text: "Push"
        tooltip: "Push to origin"
        compact:headerRow.compact

        onClicked: root.pushAndUpdate()
    }

    Item {
        Layout.fillWidth: true
    }

    RoniaButton {
        id: fetchBtnHeader
        Layout.preferredHeight: 26

        enabled: !root.isFetching

        icon.name: Style.icons.download
        text: "Fetch"
        tooltip: root.isFetching ? "Fetching…" : "Fetch all remotes"
        compact: headerRow.compact

        onClicked: root.fetch()
    }

    RoniaButton {
        id: pushForceBtnHeader
        Layout.preferredHeight: 26

        icon.name: Style.icons.arrowUp
        text: "Push Force"
        tooltip: "Force push to origin"
        compact: headerRow.compact

        onClicked: root.pushAndUpdate(true)
    }
}
