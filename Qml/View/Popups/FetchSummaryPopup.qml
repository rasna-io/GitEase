import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * FetchSummaryPopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var        results:        []

    property string     titleText:      "Fetch Summary"

    property string     subtitleText:   ""

    readonly property color infoAccent:    Style.colors.notificationInfoIcon

    readonly property color successAccent: Style.colors.notificationSuccessIcon

    readonly property color errorAccent:   Style.colors.notificationErrorIcon

    readonly property int sectionSpacing: 12
    readonly property int elementSpacing: 2

property var updatedBranches: []
    property var newBranches    : []

    /* Object Properties
     * ****************************************************************************************/
    modal: true
    focus: true

    width: 500
    height: 420

    padding: 0

    onOpened: {
        buildFetchGroups()
        subtitleText = fetchSubtitle()
    }

    /* Children
     * ****************************************************************************************/

    contentItem: Rectangle {
        color: Style.colors.popupBackground
        radius: 8
        clip: true
        border.color: Style.colors.popupBorder
        border.width: 1

ColumnLayout {
anchors.fill: parent
        spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                spacing: 8

                // Title
                Text {
                    text: root.titleText

                    Layout.fillWidth: true

                    color: Style.colors.popupTitleText
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                    font.weight: Font.DemiBold
                }

                // Close Button
                Text {
                    text: "\u00d7"

                    color: closeMouse.containsMouse ? Style.colors.popupCloseButtonHover
                                                    : Style.colors.popupCloseButton

                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.h2Pt

                    width: 18
                    height: 18

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        id: closeMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: root.close()
                    }
                }
            }

            // Header separator
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Style.colors.popupHeaderSeparator
            }

            // Body
            ScrollView {
                id: bodyScroll

                    Layout.fillWidth: true
                Layout.fillHeight: true

                Layout.leftMargin: 18
                Layout.rightMargin: 18

                clip: true

                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    id: bodyColumn

                    width: bodyScroll.availableWidth

                    spacing: 0

                    // Body horizontal padding
                    Item {
                        Layout.preferredHeight: 14
                }

                    // Subtitle Text
                    RowLayout {
                        Layout.fillWidth: true
                    spacing: 8

                        Item {
                            width: 12
                            height: 12
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: "transparent"
                                border.color: Style.colors.popupCancelButtonText
                                border.width: 1
                            }

                            Rectangle {
                                width: 1
                                height: 10
                                anchors.centerIn: parent
                                color: Style.colors.popupCancelButtonText
                            }

                            Rectangle {
                                width: 10
                                height: 1
                                anchors.centerIn: parent
                                color: Style.colors.popupCancelButtonText
                            }

                            Rectangle {
                                width: 1
                                height: 10
                                anchors.centerIn: parent
                                rotation: 60
                                color: Style.colors.popupCancelButtonText
                                visible: false
                            }
                        }

                        Text {
                            text: root.subtitleText

                            Layout.fillWidth: true

                            color: Style.colors.popupCancelButtonText
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.defaultPt
                        }
                    }

                    Item {
                        Layout.preferredHeight: root.sectionSpacing
                    }

                    // Updated Section
                    Text {
                        text: "Updated branches(" +
                              root.updatedBranches.length +
                              ")"

                        Layout.fillWidth: true

                        color: Style.colors.popupSectionLabel

                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.defaultPt
                        font.weight: Font.DemiBold
                        font.capitalization: Font.AllUppercase
        }

                    // separator
        Rectangle {
            Layout.fillWidth: true
                        implicitHeight: 1
                        color: Style.colors.popupHeaderSeparator
                    }

                    Item {
                        Layout.preferredHeight: 6
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        visible: root.updatedBranches.length > 0

                    Repeater {
                        model: root.updatedBranches
                        delegate: FetchRow {}
}
                    }

                    // Updated empty state
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100

                        visible: root.updatedBranches.length === 0

                        EmptyStateView {
                            anchors.fill: parent

                            title: root.failureCount(root.results) > 0
                                   ? "Fetch failed"
                                   : "No updated branches"

                            details: root.failureCount(root.results) > 0
                                     ? "Check your credentials or network connection."
                                     : "No new updated branches were found."
                        }
                }

                    Item {
                        Layout.preferredHeight: 12
                    }

                    //New Section
                Text {
                        text: "New branches (" +
                              root.newBranches.length +
                              ")"

                        Layout.fillWidth: true

                        color: Style.colors.popupSectionLabel

                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.defaultPt
                        font.weight: Font.DemiBold
                    font.capitalization: Font.AllUppercase
                }

                    // separator
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Style.colors.popupHeaderSeparator
                    }

                    Item {
                        Layout.preferredHeight: 6
                    }

                    Repeater {
                        model: root.newBranches
                        delegate: FetchRow {}
                    }
            }
        }

            // Footer separator
            Rectangle {
            Layout.fillWidth: true
                implicitHeight: 1
                color: Style.colors.popupHeaderSeparator
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52

                color: Style.colors.popupFooterBackground

                            RowLayout {
                    anchors.fill: parent

                    anchors.leftMargin: 18
                    anchors.rightMargin: 18

                    spacing: 8

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Close"

                        Layout.preferredWidth: 100

                        leftPadding     : 14
                        rightPadding    : 14
                        topPadding      : 6
                        bottomPadding   : 6

                        background: Rectangle {
                            implicitHeight: 32

                            radius: 5

                            color: "transparent"

                            border.color: Style.colors.popupCancelButtonBorder

                            border.width: 1

                            opacity: closeFooterMouse.containsMouse ? 1.0 : 0.7
                        }

                        contentItem: Text {
                            text: parent.text

                            color: Style.colors.popupCancelButtonText

                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.defaultPt

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: closeFooterMouse

                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: root.close()
                                }
                            }

                    Button {
                        // TODO: Implement "Pull main now →" action.
                        //       Enable this button after connecting it to the pull operation
                        //       for the fetched main branch.
                        visible: false
                        id: actionBtn
                        Layout.preferredWidth: 130

                        topPadding      : 6
                        bottomPadding   : 6
                        leftPadding     : 16
                        rightPadding    : 16

                        enabled: false


                        background: Rectangle {
                            implicitHeight: 32

                            radius: 5

                            color: parent.enabled ? (actionBtn.hovered ? Style.colors.accentHover : Style.colors.accent)
                                                  : Style.colors.disabledButton

                            border.width: 1

                            opacity: enabled ? 1.0 : 0.5
                        }

                        contentItem: Text {
                            text: "Pull main now →"

                            color: Style.colors.secondaryForeground

                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.defaultPt
                            font.weight: Font.DemiBold

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: actionBtn.enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor

                            onClicked: {
                                // TODO: Implement "Pull main now →".
                                //       Trigger pull of the fetched main branch.
                            }
                        }
                    }
                }
            }
        }
    }

    component FetchRow: RowLayout {

        Layout.fillWidth: true
        Layout.preferredHeight: 28
        spacing: 8

        Text {
            text: modelData.icon

            Layout.preferredWidth: 14

            color: modelData.iconColor
                   || root.successAccent

            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.mediumPt
            font.weight: Font.Bold

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        ScrollingText {
            text: modelData.name

            Layout.fillWidth: true

            color: Style.colors.utilitiesRowMetaText

            font.family: Style.fontTypes.jetBrainsMono
            font.pixelSize: Style.appFont.defaultPt
        }

        ScrollingText {
            text: modelData.meta

            Layout.maximumWidth: 220


            color: Style.colors.utilitiesRowSubText
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.smallPt
        }

        Button {
            // TODO: Enable the Checkout button after implementing checkout for newly fetched remote branches.
            //       Replace `visible: false` with `visible: modelData.hasAction === true`
            //       and connect it to BranchController checkout logic.
            visible: false /*modelData.hasAction === true*/

            Layout.preferredWidth: 70

            leftPadding: 8
            rightPadding: 8
            topPadding: 2
            bottomPadding: 2

            contentItem: Text {
                text: "Checkout"

                color: checkoutButtonMouse.containsMouse
                       ? Style.colors.utilitiesRowText
                       : Style.colors.popupCancelButtonText

                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.smallPt

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                implicitHeight: 20

                radius: 4

                color: checkoutButtonMouse.containsMouse
                       ? Style.colors.controlBackgroundHover
                       : Style.colors.actionPillBg

                border.color: Style.colors.actionPillBorder
                border.width: 1
            }

            MouseArea {
                id: checkoutButtonMouse

                anchors.fill: parent

                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    // TODO: Implement checkout of newly fetched remote branch.
                    //       e.g. branchController.checkoutBranch(modelData.name)
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/

    function remoteSummary() {
        if (!results || results.length === 0)
            return ""

        let names = []

        for (let i = 0; i < results.length; ++i) {
            const remote = results[i] && results[i].remote
                         ? String(results[i].remote)
                         : ""

            if (remote.length > 0 && names.indexOf(remote) === -1)
                names.push(remote)
        }

        if (names.length === 0)
            return "origin"

        return names.join(", ")
    }

    function fetchSubtitle() {
        const remote = remoteSummary()

        if (remote.length === 0)
            return "fetched just now"

        if (remote.indexOf(",") === -1)
            return remote + " · fetched just now"

        return remote + " · fetched just now"
    }

    function buildFetchGroups() {
        let updatedBranches     = []
        let newBranches         = []

        for (let r = 0; r < results.length; ++r) {
            const result = results[r]

            if (!result || !result.data)
                continue

            const heads = result.data.heads || []

            for (let i = 0; i < heads.length; ++i) {
                const head = heads[i] || {}

                const branchName    = head.branch || head.ref || ""
                const oldCommit     = head.oldCommit || ""
                const newCommit     = head.newCommit || ""
                const summary       = String(head.summary || "").trim()

                if (branchName.length === 0 && summary.length === 0)
                    continue

                const shortOld = shortSha(oldCommit)
                const shortNew = shortSha(newCommit)

                const isNewBranch =
                        oldCommit.length === 0 ||
                        summary.indexOf("[new branch]") !== -1

                if (isNewBranch) {
                    newBranches.push({
                        icon: "+",
                        name: branchName.length > 0 ? remoteBranchName(result.remote, branchName) : summary,
                        meta: "",
                        hasAction: true
                    })

                    continue
                }

                let meta = ""

                if (shortOld.length > 0 && shortNew.length > 0) {
                    meta = shortOld + " → " + shortNew
                } else if (summary.length > 0) {
                    meta = summary
                }

                updatedBranches.push({
                    icon: "↓",
                    name: branchName.length > 0
                          ? branchName
                          : summary,
                    meta: meta,
                    hasAction: false
                })
            }
        }

        root.updatedBranches    = updatedBranches
        root.newBranches        = newBranches
    }

    function remoteBranchName(remote, branch) {
        if (!remote)
            return branch

        if (branch.indexOf(remote + "/") === 0)
            return branch

        return branch
    }

    function shortSha(value) {
        if (!value)
            return ""

        const text = String(value)

        if (text.length <= 7)
            return text

        return text.substring(0, 7)
    }

    function successCount(arr) {
        return arr ? arr.filter(function(item) {
            return item && item.success
        }).length : 0
    }

    function failureCount(arr) {
        return arr ? arr.filter(function(item) {
            return item && !item.success
        }).length : 0
    }
}