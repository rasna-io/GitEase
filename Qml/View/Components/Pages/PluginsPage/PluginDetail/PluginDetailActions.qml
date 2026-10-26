import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailActions
 * Install / update / uninstall buttons, the enable switch, and the install progress panel.
 * Only one of these three states is on screen at a time and each one eases in when it appears.
 * ************************************************************************************************/
ColumnLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var  plugin: null
    property var  installState: undefined
    property bool wide: true
    property bool isInstalled: false
    property bool isEnabled: false
    property bool isCompatible: true
    property bool updateAvailable: false

    readonly property bool isActiveInstall: !!root.installState
    readonly property bool pluginBusy: (root.plugin?.busy ?? false) || root.isActiveInstall
    readonly property string installPhase: root.installState?.phase ?? ""
    readonly property real installProgress: root.installState?.progress ?? -1
    readonly property bool hasDeterminateProgress: root.installProgress >= 0
                                                   && (root.installPhase === "Downloading"
                                                       || root.installPhase === "Updating")
    readonly property bool isDestructiveBusy: root.installPhase === "Uninstalling"
                                              || root.installPhase === "Waiting"
    readonly property bool isDone: root.installPhase === "Uninstalled"
    readonly property color busyAccent: root.isDone ? Style.colors.vibrantMint
                                                    : (root.isDestructiveBusy ? Style.colors.softCoralMist
                                                                              : Style.colors.accent)

    readonly property string busyLabel: {
        switch(root.installPhase) {
        case "Preparing":
            return "Preparing…"
        case "Downloading":
            return "Downloading…"
        case "Installing":
            return "Installing…"
        case "Updating":
            return "Updating…"
        case "Waiting":
            return "Waiting…"
        case "Uninstalling":
            return "Uninstalling…"
        case "Uninstalled":
            return "Uninstalled"
        default:
            return root.pluginBusy ? "Working…" : ""
        }
    }

    /* Signals
     * ****************************************************************************************/
    signal installClicked(string pluginId)
    signal uninstallClicked(string pluginId)
    signal updateClicked(string pluginId)
    signal enableToggled(string pluginId, bool enabled)

    /* Object Properties
     * ****************************************************************************************/
    spacing: Style.dp(10)

    /* Children
     * ****************************************************************************************/
    // Buttons
    Flow {
        id: buttonFlow
        visible: !root.pluginBusy
        Layout.fillWidth: true
        layoutDirection: root.wide ? Qt.RightToLeft : Qt.LeftToRight
        spacing: Style.dp(8)

        PluginDetailButton {
            visible: !root.isInstalled
            enabled: root.isCompatible && !!(root.plugin?.pluginId)
            iconText: Style.icons.download
            label: "Install"
            fill: Style.colors.accent
            fillHover: Style.colors.accentHover

            onClicked: root.installClicked(root.plugin.pluginId)
        }

        PluginDetailButton {
            visible: root.updateAvailable
            iconText: Style.icons.update
            label: root.plugin?.latestVersion ? ("Update to v" + root.plugin.latestVersion) : "Update"
            fill: Style.colors.updateButton
            fillHover: Qt.lighter(Style.colors.updateButton, 1.1)
            textColor: Style.colors.textButton

            onClicked: root.updateClicked(root.plugin.pluginId)
        }

        PluginDetailButton {
            visible: root.isInstalled
            iconText: Style.icons.trash
            label: "Uninstall"
            outlined: true
            textColor: Style.colors.pluginBtnSecondaryText
            hoverTint: Style.colors.softCoralMist

            onClicked: root.uninstallClicked(root.plugin.pluginId)
        }
    }

    // Enable toggle
    Rectangle {
        id: toggleCard
        visible: root.isInstalled && !root.pluginBusy
        Layout.fillWidth: true
        Layout.maximumWidth: root.wide ? -1 : Style.dp(320)
        implicitHeight: toggleRow.implicitHeight + Style.dp(16)
        radius: Style.dp(8)
        color: Style.colors.pluginPageBackground
        border.width: 1
        border.color: Style.colors.pluginCardFooterBorder

        RowLayout {
            id: toggleRow
            anchors.fill: parent
            anchors.leftMargin: Style.dp(12)
            anchors.rightMargin: Style.dp(10)
            spacing: Style.dp(10)

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    text: root.isEnabled ? "Enabled" : "Disabled"
                    color: Style.colors.pluginCardTitle
                    font.pixelSize: Style.appFont.smallPt
                    font.weight: Font.DemiBold
                    font.family: Style.fontTypes.inter
                }

                Label {
                    Layout.fillWidth: true
                    text: root.isEnabled ? "Active in all repositories" : "Turn on to activate this plugin"
                    color: Style.colors.pluginCardMetaText
                    font.pixelSize: Style.appFont.captionPt
                    font.family: Style.fontTypes.inter
                    elide: Text.ElideRight
                }
            }

            Switch {
                id: enableToggle
                checked: root.isEnabled
                padding: 0
                implicitWidth: Style.dp(38)
                implicitHeight: Style.dp(22)

                indicator: Rectangle {
                    implicitWidth: Style.dp(38)
                    implicitHeight: Style.dp(22)
                    radius: height / 2
                    color: enableToggle.checked ? Style.colors.accent : Style.colors.switchTrackOff
                    border.width: enableToggle.checked ? 0 : 1
                    border.color: Style.colors.controlBorder

                    Behavior on color {
                        ColorAnimation {
                            duration: 160
                        }
                    }

                    Rectangle {
                        width: Style.dp(16)
                        height: width
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: enableToggle.checked ? parent.width - width - 3 : 3
                        color: Style.colors.switchHandle

                        Behavior on x {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                onToggled: root.enableToggled(root.plugin.pluginId, checked)
            }
        }
    }

    // Progress
    Rectangle {
        id: progressCard
        visible: root.pluginBusy
        Layout.fillWidth: true
        Layout.maximumWidth: root.wide ? -1 : Style.dp(320)
        implicitHeight: progressColumn.implicitHeight + Style.dp(20)
        radius: Style.dp(8)
        color: Qt.rgba(root.busyAccent.r, root.busyAccent.g, root.busyAccent.b, 0.06)
        border.width: 1
        border.color: Qt.rgba(root.busyAccent.r, root.busyAccent.g, root.busyAccent.b, 0.25)

        ColumnLayout {
            id: progressColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Style.dp(12)
            anchors.rightMargin: Style.dp(12)
            spacing: Style.dp(8)

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.dp(8)

                BusyIndicator {
                    visible: !root.isDone
                    running: root.pluginBusy && !root.isDone
                    Layout.preferredWidth: Style.dp(16)
                    Layout.preferredHeight: Style.dp(16)
                }

                Label {
                    Layout.fillWidth: true
                    text: root.busyLabel
                    color: Style.colors.pluginCardTitle
                    font.pixelSize: Style.appFont.smallPt
                    font.weight: Font.Medium
                    font.family: Style.fontTypes.inter
                }

                Label {
                    visible: root.hasDeterminateProgress
                    text: Math.round(root.installProgress) + "%"
                    color: Style.colors.pluginCardMetaText
                    font.pixelSize: Style.appFont.smallPt
                    font.family: Style.fontTypes.jetBrainsMono
                }
            }

            Item {
                id: progressTrack
                visible: !root.isDone
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                clip: true

                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: Qt.rgba(root.busyAccent.r, root.busyAccent.g, root.busyAccent.b, 0.16)
                }

                Rectangle {
                    visible: root.hasDeterminateProgress
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.max(0.02, root.installProgress / 100.0)
                    radius: 2
                    color: root.busyAccent

                    Behavior on width {
                        NumberAnimation {
                            duration: 160
                        }
                    }
                }

                Rectangle {
                    visible: root.pluginBusy && !root.hasDeterminateProgress
                    width: progressTrack.width * 0.34
                    height: parent.height
                    radius: 2
                    color: root.busyAccent

                    SequentialAnimation on x {
                        running: root.pluginBusy && !root.hasDeterminateProgress
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
        }
    }
}
