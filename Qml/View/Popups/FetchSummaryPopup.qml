import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * SettingsPopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property bool       showRawOutput: true

    property var        results:        []

    property string     titleText:      "Fetch Summary"

    property string     subtitleText:   ""

    readonly property color infoAccent:    Style.colors.notificationInfoIcon

    readonly property color successAccent: Style.colors.notificationSuccessIcon

    readonly property color errorAccent:   Style.colors.notificationErrorIcon

property var updatedBranches: []
    property var newBranches    : []

    /* Object Properties
     * ****************************************************************************************/
    modal: true
    focus: true

    width: 500
    height: 420

    padding: 0


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
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.preferredHeight: 44
            color: Style.colors.secondaryBackground
            border.color: Style.colors.primaryBorder
            border.width: 1


            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20

                CheckBox {
                    id: rawLogCheck
                    checked: root.showRawOutput
                    text: "Show Raw Terminal Output"
                    onCheckedChanged: root.showRawOutput = checked
                    Material.accent: Style.colors.accent
                    Material.foreground: Style.colors.foreground

                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "View: " + (root.showRawOutput ? "Standard" : "Compact")
                    font.pixelSize: Style.appFont.smallPt
                    color: Style.colors.mutedText
                    font.capitalization: Font.AllUppercase
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            spacing: 0

            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                ListView {
                    model: results; spacing: 10
                    topMargin: 20; bottomMargin: 20; leftMargin: 20; rightMargin: 20

                    delegate: Rectangle {
                        width: ListView.view.width - 40
                        implicitHeight: cardCol.implicitHeight + 24
                        radius: 12; color: Style.colors.secondaryBackground
                        border.color: Style.colors.primaryBorder

                        ColumnLayout {
                            id: cardCol; anchors.fill: parent; anchors.margins: 16; spacing: 10
                            RowLayout {
                                Text {
                                    text: modelData.remote; font.weight: Font.DemiBold
                                    font.pixelSize: Style.appFont.h3Pt; color: Style.colors.foreground
                                }
                                Rectangle {
                                    width: 4;
                                    height: 4;
                                    radius: 2;
                                    color: Style.colors.primaryBorder
                                }
                                Text {
                                    text: modelData.success ? "Successfully fetched" : "Fetch failed"
                                    font.pixelSize: Style.appFont.mediumPt;
                                    color: modelData.success ? root.successAccent : root.errorAccent
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: shortSha(modelData.data.timestamp);
                                    font.pixelSize: Style.appFont.defaultPt;
                                    color: Style.colors.mutedText
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 4
                                visible: modelData.data.heads.length > 0
                                Repeater {
                                    model: modelData.data.heads
                                    delegate: RowLayout {
                                        Text { text: "•"; color: root.infoAccent }
                                        Text {
                                            text: modelData.summary.trim()
                                            font.family: Style.fontTypes.jetBrainsMono; font.pixelSize: Style.appFont.defaultPt
                                            color: Style.colors.secondaryText; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true

                Layout.preferredWidth: root.showRawOutput ? 380 : 0
                color: Style.colors.secondaryBackground
                clip: true
                visible: root.showRawOutput

                Behavior on Layout.preferredWidth { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 12
                    Text { text: "RAW TERMINAL LOG"; font.pixelSize: Style.appFont.smallPt; font.weight: Font.Black; color: Style.colors.mutedText; font.letterSpacing: 1 }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Style.colors.primaryBorder }

                    ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        Text {
                            width: parent.width; text: logText(results)
                            font.family: Style.fontTypes.jetBrainsMono; font.pixelSize: Style.appFont.defaultPt; color: Style.colors.secondaryText; wrapMode: Text.Wrap; lineHeight: 1.4
                        }
                    }
                }
            }
        }
    }

    // --- SHARED COMPONENTS ---
    component StatChip : Rectangle {
        property string label; property string value; property color accent
        implicitWidth: statRow.implicitWidth + 20; implicitHeight: 28; radius: 6
        color: Qt.rgba(accent.r, accent.g, accent.b, 0.08)
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.15)
        RowLayout { id: statRow; anchors.centerIn: parent; spacing: 6
            Text { text: label; color: Style.colors.mutedText; font.pixelSize: Style.appFont.smallPt }
            Text { text: value; color: accent; font.pixelSize: Style.appFont.defaultPt; font.weight: Font.Bold }
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
    function successCount(arr) {
        return arr ? arr.filter(i => i.success).length : 0
    }

    function failureCount(arr) {
        return arr ? arr.filter(i => !i.success).length : 0
    }

    function shortSha(ts) {
        return ts ? ts.split('T')[1].substring(0,5) : ""
    }

    function logText(res) {
        let lines = [];
        res.forEach(r => { if(r.data && r.data.log) lines = lines.concat(r.data.log) });
        return lines.length ? lines.join("\n") : "No output recorded."
    }
}
