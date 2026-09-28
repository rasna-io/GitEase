import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RepoItem
 * One discovered repository: selection, branch, remotes, operation status and the outcome detail.
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property int       index
    required property string    name
    required property string    path
    required property string    branchName
    required property string    remotesText
    required property string    status
    required property string    detail
    required property int       progress

    //! One of: idle, queued, fetching, pulling, done, warning, auth, error, muted.
    property string statusKind: "idle"
    property bool   isSelected: false
    property bool   isBusy:     false

    readonly property bool isActive: statusKind === "fetching" || statusKind === "pulling"

    readonly property color statusBg: {
        switch (statusKind) {
        case "queued":   return Style.colors.repoItemStatusPendingBg
        case "fetching": return Style.colors.repoItemStatusFetchingBg
        case "pulling":  return Style.colors.repoItemStatusPullingBg
        case "done":     return Style.colors.repoItemStatusDoneBg
        case "warning":  return Style.colors.repoItemStatusDirtyBg
        case "auth":     return Style.colors.repoItemStatusPATBg
        case "error":    return Style.colors.repoItemStatusConflictBg
        default:         return Style.colors.controlBackground
        }
    }

    readonly property color statusFg: {
        switch (statusKind) {
        case "queued":   return Style.colors.repoItemStatusPendingText
        case "fetching": return Style.colors.repoItemStatusFetchingText
        case "pulling":  return Style.colors.repoItemStatusPullingText
        case "done":     return Style.colors.repoItemStatusDoneText
        case "warning":  return Style.colors.repoItemStatusDirtyText
        case "auth":     return Style.colors.repoItemStatusPATText
        case "error":    return Style.colors.repoItemStatusConflictText
        default:         return Style.colors.secondaryText
        }
    }

    readonly property string statusIcon: {
        switch (statusKind) {
        case "queued":   return Style.icons.clock
        case "fetching": return Style.icons.download
        case "pulling":  return Style.icons.arrowDown
        case "done":     return Style.icons.check
        case "warning":  return Style.icons.warning
        case "auth":     return Style.icons.info
        case "error":    return Style.icons.circleExclamation
        case "muted":    return Style.icons.minus
        default:         return ""
        }
    }

    /* Signals
     * ****************************************************************************************/
    signal clicked()
    signal fetchRequested()
    signal pullRequested()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: content.implicitHeight + 22
    radius: 8
    color: hover.hovered ? Style.colors.utilitiesRowHoverBackground
         : isSelected ? Style.colors.utilitiesRowSelectedBackground
                      : Style.colors.utilitiesRowBackground
    border.width: 1
    border.color: isActive ? statusFg : Style.colors.utilitiesRowBorder

    Behavior on color { ColorAnimation { duration: Style.motionFast } }

    /* Children
     * ****************************************************************************************/
    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.clicked()
    }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 12

        // Selection box
        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 2
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            radius: 4
            color: root.isSelected ? Style.colors.accent : "transparent"
            border.width: root.isSelected ? 0 : 1
            border.color: Style.colors.controlBorder

            Text {
                anchors.centerIn: parent
                visible: root.isSelected
                text: Style.icons.check
                font.family: Style.fontTypes.font6Pro
                font.pixelSize: Style.appFont.microPt
                color: Style.colors.onAccentText
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            // Name, branch and status
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.maximumWidth: implicitWidth
                    Layout.fillWidth: true
                    text: root.name
                    elide: Text.ElideRight
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt
                    font.weight: Font.DemiBold
                    color: root.isSelected ? Style.colors.utilitiesRowSelectedText : Style.colors.utilitiesRowText
                }

                Rectangle {
                    Layout.preferredHeight: 18
                    Layout.preferredWidth: Math.min(branchRow.implicitWidth + 12, 180)
                    radius: 9
                    color: Style.colors.controlBackground
                    border.width: 1
                    border.color: Style.colors.controlBorder

                    Row {
                        id: branchRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        clip: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Style.icons.branch
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: Style.appFont.microPt
                            color: Style.colors.utilitiesRowIcon
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.branchName
                            font.family: Style.fontTypes.jetBrainsMono
                            font.pixelSize: Style.appFont.microPt
                            color: Style.colors.utilitiesRowMetaText
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Status pill
                Rectangle {
                    visible: root.statusKind !== "idle"
                    Layout.preferredHeight: 20
                    Layout.preferredWidth: statusRow.implicitWidth + 16
                    radius: 10
                    color: root.statusBg
                    clip: true

                    Rectangle {
                        visible: root.isActive && root.progress > 0 && root.progress < 100
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * root.progress / 100
                        color: root.statusFg
                        opacity: 0.15

                        Behavior on width { NumberAnimation { duration: 200 } }
                    }

                    Row {
                        id: statusRow
                        anchors.centerIn: parent
                        spacing: 5

                        BusyIndicator {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.isActive
                            running: visible
                            width: 12
                            height: 12
                            padding: 0
                            Material.accent: root.statusFg
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !root.isActive && root.statusIcon.length > 0
                            text: root.statusIcon
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: Style.appFont.microPt
                            color: root.statusFg
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.isActive && root.progress > 0 && root.progress < 100
                                  ? root.status + " " + root.progress + "%" : root.status
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.microPt
                            font.weight: Font.DemiBold
                            color: root.statusFg
                        }
                    }
                }
            }

            // Path and remotes
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    text: root.path
                    elide: Text.ElideMiddle
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.microPt
                    color: Style.colors.utilitiesRowSubText
                }

                Row {
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Style.icons.cloud
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: Style.appFont.microPt
                        color: root.remotesText.length > 0 ? Style.colors.utilitiesRowIcon : Style.colors.warning
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.remotesText.length > 0 ? root.remotesText : "no remotes"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.microPt
                        color: root.remotesText.length > 0 ? Style.colors.utilitiesRowMetaText : Style.colors.warning
                    }
                }
            }

            // Outcome detail
            Text {
                Layout.fillWidth: true
                visible: root.detail.length > 0
                text: root.detail
                elide: Text.ElideRight
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.microPt
                color: root.statusKind === "error" || root.statusKind === "warning" || root.statusKind === "auth"
                       ? root.statusFg : Style.colors.utilitiesRowMetaText
            }
        }

        ActionIconButton {
            Layout.alignment: Qt.AlignVCenter
            enabled: !root.isBusy
            opacity: enabled ? 1.0 : 0.4
            iconText: Style.icons.download
            tooltip: "Fetch this repository"
            backgroundColor: Style.colors.controlBackground
            textColor: Style.colors.foreground
            onClicked: root.fetchRequested()
        }

        ActionIconButton {
            Layout.alignment: Qt.AlignVCenter
            enabled: !root.isBusy
            opacity: enabled ? 1.0 : 0.4
            iconText: Style.icons.arrowDown
            tooltip: "Pull this repository"
            backgroundColor: Style.colors.controlBackground
            textColor: Style.colors.foreground
            onClicked: root.pullRequested()
        }
    }
}
