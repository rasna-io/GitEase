import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * UpdateCard
 * Application-update panel used inside the Settings → Updates tab. Shows the installed and latest
 * versions, a single context-aware primary action, download progress, release notes and status.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property UpdateController updateController: null

    readonly property string phase:        root.updateController?.phase ?? "idle"
    readonly property bool   isDownloading: root.phase === "preparing" || root.phase === "downloading"
    readonly property real   progress:     root.updateController?.downloadProgress ?? -1
    readonly property bool   hasProgress:  root.phase === "downloading" && root.progress >= 0

    readonly property color statusColor: {
        switch (root.updateController?.statusType) {
            case "success":
                return Style.colors.notificationSuccessIcon
            case "warning":
                return Style.colors.notificationWarningIcon
            case "error":
                return Style.colors.notificationErrorIcon
            default:
                return Style.colors.mutedText
        }
    }

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: content.implicitHeight + 32
    radius: 10
    color: Style.colors.controlBackground
    border.width: 1
    border.color: root.updateController?.isCritical === true && root.updateController.updateAvailable
                  ? Style.colors.notificationWarningIcon
                  : Style.colors.controlBorder

    /* Functions
     * ****************************************************************************************/
    function formatBytes(bytes) {
        if (!bytes || bytes <= 0) {
            return "0 MB"
        }
        if (bytes < 1024 * 1024) {
            return Math.max(1, Math.round(bytes / 1024)) + " KB"
        }
        return (bytes / (1024 * 1024)).toFixed(1) + " MB"
    }

    function formatDuration(seconds) {
        if (seconds < 60) {
            return Math.max(1, Math.round(seconds)) + " s"
        }
        return Math.round(seconds / 60) + " min"
    }

    function downloadDetailsText() {
        var controller = root.updateController
        if (!controller || root.phase !== "downloading") {
            return ""
        }

        var text = root.formatBytes(controller.bytesReceived)
        if (controller.bytesTotal > 0) {
            text += " of " + root.formatBytes(controller.bytesTotal)
        }
        return text
    }

    function speedText() {
        var controller = root.updateController
        if (!controller || root.phase !== "downloading" || controller.downloadSpeed <= 0) {
            return ""
        }

        var text = root.formatBytes(controller.downloadSpeed) + "/s"
        var remaining = controller.bytesTotal - controller.bytesReceived
        if (controller.bytesTotal > 0 && remaining > 0) {
            text += "  ·  about " + root.formatDuration(remaining / controller.downloadSpeed) + " left"
        }
        return text
    }

    /* Inline Components
     * ****************************************************************************************/
    component CardButton: Button {
        id: cardButton

        property bool   primary: false
        property bool   loading: false
        property string label:   ""

        Layout.alignment: Qt.AlignVCenter
        flat: true
        implicitHeight: 34
        leftPadding: 16
        rightPadding: 16
        topPadding: 0
        bottomPadding: 0
        topInset: 0
        bottomInset: 0
        opacity: enabled || loading ? 1.0 : 0.5

        background: Rectangle {
            implicitHeight: 34
            radius: 6
            color: cardButton.primary
                   ? (cardButton.hovered && cardButton.enabled ? Style.colors.accentHover : Style.colors.accent)
                   : Style.colors.controlBackgroundHover
            border.width: cardButton.primary ? 0 : 1
            border.color: cardButton.hovered && cardButton.enabled
                          ? Style.colors.accent
                          : Style.colors.controlBorder

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        contentItem: RowLayout {
            spacing: 6

            BusyIndicator {
                visible: cardButton.loading
                running: cardButton.loading
                implicitWidth: 16
                implicitHeight: 16
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: cardButton.label
                font.family: Style.fontTypes.inter
                font.pixelSize: 12
                font.weight: cardButton.primary ? Font.DemiBold : Font.Normal
                color: cardButton.primary ? Style.colors.onAccentText : Style.colors.foreground
                Layout.alignment: Qt.AlignVCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // Versions and actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 36

            ColumnLayout {
                spacing: 4

                Text {
                    text: "INSTALLED"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: 9
                    font.letterSpacing: 1.5
                    color: Style.colors.mutedText
                }

                Text {
                    text: Qt.application.version || "0.0.0"
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: Style.colors.foreground
                }
            }

            ColumnLayout {
                spacing: 4

                Text {
                    text: "LATEST"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: 9
                    font.letterSpacing: 1.5
                    color: Style.colors.mutedText
                }

                RowLayout {
                    spacing: 8

                    Text {
                        text: (root.updateController?.latestVersion ?? "") !== ""
                              ? root.updateController.latestVersion
                              : "—"
                        font.family: Style.fontTypes.jetBrainsMono
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: root.updateController?.updateAvailable === true
                               ? Style.colors.accent : Style.colors.foreground
                    }

                    Rectangle {
                        id: versionBadge

                        readonly property color badgeColor: root.updateController?.isCritical === true
                                                            ? Style.colors.notificationWarningIcon
                                                            : Style.colors.accent

                        visible: root.updateController?.updateAvailable === true
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: badgeText.implicitWidth + 12
                        implicitHeight: 18
                        radius: 9
                        color: Qt.rgba(badgeColor.r, badgeColor.g, badgeColor.b, 0.15)
                        border.width: 1
                        border.color: Qt.rgba(badgeColor.r, badgeColor.g, badgeColor.b, 0.4)

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: root.updateController?.isCritical === true ? "CRITICAL" : "NEW"
                            font.family: Style.fontTypes.inter
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            font.letterSpacing: 1
                            color: versionBadge.badgeColor
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            CardButton {
                id: secondaryButton
                visible: root.phase === "idle"
                         || root.phase === "upToDate"
                         || root.phase === "checking"
                         || root.isDownloading
                         || (root.phase === "error"
                             && root.updateController?.failedRequestType !== UpdateController.CheckApplicationUpdate)
                enabled: root.updateController !== null && root.phase !== "checking"
                loading: root.phase === "checking"
                label: root.isDownloading ? "Cancel"
                     : root.phase === "checking" ? "Checking…"
                     : "Check for Updates"

                onClicked: {
                    if (!root.updateController)
                        return

                    if (root.isDownloading)
                        root.updateController.cancelUpdate()
                    else
                        root.updateController.checkForUpdates(false)
                }
            }

            CardButton {
                id: primaryButton
                primary: true
                visible: root.phase === "available"
                         || root.phase === "ready"
                         || root.phase === "restarting"
                         || root.phase === "error"
                enabled: root.updateController !== null && root.phase !== "restarting"
                loading: root.phase === "restarting"
                label: {
                    switch (root.phase) {
                        case "ready":
                            return "Restart & Install"
                        case "restarting":
                            return "Restarting…"
                        case "error":
                            return "Retry"
                        default:
                            return "Download & Install"
                    }
                }

                onClicked: {
                    if (!root.updateController)
                        return

                    if (root.phase === "ready")
                        root.updateController.restartToInstall()
                    else if (root.phase === "error")
                        root.updateController.retry()
                    else
                        root.updateController.installAvailableUpdate()
                }
            }
        }

        // Download progress
        Rectangle {
            visible: root.isDownloading
            Layout.fillWidth: true
            implicitHeight: progressColumn.implicitHeight + 20
            radius: 8
            color: Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.06)
            border.width: 1
            border.color: Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.25)

            ColumnLayout {
                id: progressColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: root.phase === "preparing"
                              ? "Preparing download…"
                              : "Downloading GitEase " + (root.updateController?.latestVersion ?? "")
                        font.family: Style.fontTypes.inter
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Style.colors.foreground
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: root.hasProgress
                        text: Math.round(root.progress * 100) + "%"
                        font.family: Style.fontTypes.jetBrainsMono
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Style.colors.accent
                    }
                }

                Item {
                    id: progressTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.16)
                    }

                    Rectangle {
                        visible: root.hasProgress
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0.02, root.progress)
                        radius: 3
                        color: Style.colors.accent

                        Behavior on width {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }

                    Rectangle {
                        visible: root.isDownloading && !root.hasProgress
                        width: progressTrack.width * 0.34
                        height: parent.height
                        radius: 3
                        color: Style.colors.accent

                        SequentialAnimation on x {
                            running: root.isDownloading && !root.hasProgress
                            loops: Animation.Infinite

                            NumberAnimation {
                                from: -progressTrack.width * 0.34
                                to: progressTrack.width
                                duration: 1100
                                easing.type: Easing.InOutCubic
                            }
                            PauseAnimation {
                                duration: 160
                            }
                        }
                    }
                }

                RowLayout {
                    visible: root.phase === "downloading"
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: root.downloadDetailsText()
                        font.family: Style.fontTypes.jetBrainsMono
                        font.pixelSize: 11
                        color: Style.colors.mutedText
                    }

                    Text {
                        text: root.speedText()
                        font.family: Style.fontTypes.jetBrainsMono
                        font.pixelSize: 11
                        color: Style.colors.mutedText
                    }
                }
            }
        }

        // Release notes
        ColumnLayout {
            visible: root.updateController?.updateAvailable === true
                     && (root.updateController?.releaseNotes ?? "") !== ""
                     && root.phase !== "restarting"
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "WHAT'S NEW IN " + (root.updateController?.latestVersion ?? "")
                font.family: Style.fontTypes.inter
                font.pixelSize: 9
                font.letterSpacing: 1.5
                color: Style.colors.mutedText
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(releaseNotesText.implicitHeight, 140)
                clip: true
                contentWidth: availableWidth

                Text {
                    id: releaseNotesText
                    width: parent.width
                    text: root.updateController?.releaseNotes ?? ""
                    textFormat: Text.MarkdownText
                    wrapMode: Text.WordWrap
                    font.family: Style.fontTypes.inter
                    font.pixelSize: 12
                    color: Style.colors.foreground
                    onLinkActivated: function(link) { Qt.openUrlExternally(link) }
                }
            }
        }

        // Status
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                radius: 4
                color: root.statusColor
            }

            Text {
                Layout.fillWidth: true
                text: root.updateController?.statusText ?? "Not checked yet"
                font.family: Style.fontTypes.inter
                font.pixelSize: 12
                color: root.statusColor
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                visible: root.updateController?.hasLastChecked === true
                Layout.alignment: Qt.AlignVCenter
                text: "Last checked " + Qt.formatTime(root.updateController?.lastCheckedAt ?? new Date(),
                                                      Locale.ShortFormat)
                font.family: Style.fontTypes.inter
                font.pixelSize: 11
                color: Style.colors.mutedText
            }
        }
    }
}
