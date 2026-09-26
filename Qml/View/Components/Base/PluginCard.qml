import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style_Impl
import GitEase_Style
import GitEase

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    plugin:          null
    property bool   hovered:         false
    property bool   pluginBusy:      root.plugin?.busy ?? false
    property string installPhase:    ""
    property real   installProgress: -1

    // Colors derived from the plugin's category color
    readonly property color categoryColor: root.plugin?.mainColor ?? Style.colors.accent
    readonly property color categoryIconBg: Qt.rgba(root.categoryColor.r,
                                                    root.categoryColor.g,
                                                    root.categoryColor.b, 0.13)
    readonly property color categoryBadgeBg: Qt.rgba(root.categoryColor.r,
                                                     root.categoryColor.g,
                                                     root.categoryColor.b, 0.09)

    // Compatibility dot: green = compatible, amber = update available, red = incompatible
    readonly property color compatDotColor: !(root.plugin?.isCompatible ?? true) ? Style.colors.incompatible
                                            : (root.plugin?.updateAvailable ? Style.colors.marigold
                                                                            : Style.colors.vibrantMint)
    readonly property string compatLabel: !(root.plugin?.isCompatible ?? true) ? "Incompatible"
                                          : (root.plugin?.updateAvailable ? "Needs update"
                                                                          : "Compatible")

    readonly property string busyLabel: {
        switch (root.installPhase) {
        case "Preparing":    return "Preparing"
        case "Downloading":  return "Downloading"
        case "Installing":   return "Installing"
        case "Updating":     return "Updating"
        case "Uninstalling": return "Uninstalling"
        default:             return root.pluginBusy ? "Working" : ""
        }
    }

    readonly property bool isDestructiveBusy: root.installPhase === "Uninstalling"
    readonly property color busyAccent: root.isDestructiveBusy
                                        ? Style.colors.softCoralMist
                                        : Style.colors.accent
    readonly property color busyAccentMuted: Qt.rgba(root.busyAccent.r,
                                                     root.busyAccent.g,
                                                     root.busyAccent.b, 0.14)

    readonly property bool hasDeterminateProgress: root.installProgress >= 0
                                                   && (root.installPhase === "Downloading"
                                                       || root.installPhase === "Updating")

    /* Signals
     * ****************************************************************************************/
    signal installClicked  (string pluginId)
    signal uninstallClicked(string pluginId)
    signal updateClicked   (string pluginId)
    signal enableToggled   (string pluginId, bool enabled)
    signal detailsClicked  (string pluginId)

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.pluginCardBackground
    radius: 7
    clip: true
    border {
        width: 1
        color: root.pluginBusy
               ? Qt.rgba(root.busyAccent.r, root.busyAccent.g, root.busyAccent.b, 0.35)
               : Style.colors.pluginCardBorder
    }

    Behavior on border.color {
        ColorAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    scale: root.pluginBusy ? 1.0 : (root.hovered ? 1.01 : 1.0)
    Behavior on scale {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    /* Children
     * ****************************************************************************************/

    MouseArea {
        id: cardClickArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.pluginBusy ? Qt.ArrowCursor : Qt.PointingHandCursor
        enabled: !root.pluginBusy
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: {
            let id = ""
            if (root.plugin) {
                if (root.plugin.pluginId !== undefined && root.plugin.pluginId !== null)
                    id = root.plugin.pluginId
                else if (root.plugin.id !== undefined && root.plugin.id !== null)
                    id = root.plugin.id
            }

            if (id !== "")
                root.detailsClicked(id)
        }
    }


    ColumnLayout {
        id: cardContent
        anchors.fill: parent
        spacing: 0
        opacity: root.pluginBusy ? 0.28 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        // Header: icon tile (top) + name/version/author/description
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Style.dp(12)
            Layout.leftMargin: Style.dp(14)
            Layout.rightMargin: Style.dp(14)
            Layout.bottomMargin: Style.dp(10)
            spacing: Style.dp(10)

            // Icon tile — 38x38, never stretched vertically (design: align-items:flex-start)
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                Layout.alignment: Qt.AlignTop
                Layout.fillHeight: false
                radius: 8
                color: root.categoryIconBg

                Image {
                    id: pluginIconImage
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: root.plugin?.iconUrl ?? ""
                    fillMode: Image.PreserveAspectFit
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: pluginIconImage.status !== Image.Ready
                    text: Style.icons.plugins
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: 16
                    color: root.categoryColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Name + version + author + description
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Name + version (design: baseline, gap 7px, margin-bottom 2px)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: Style.dp(2)
                    spacing: Style.dp(7)

                    Label {
                        text: root.plugin?.name ?? ""
                        color: Style.colors.pluginCardTitle
                        font.pixelSize: Style.appFont.h3Pt
                        font.weight: Font.DemiBold
                        font.family: Style.fontTypes.inter
                        elide: Text.ElideRight
                        Layout.fillWidth: false
                        Layout.maximumWidth: Math.max(60, root.width - Style.dp(150))
                    }

                    Label {
                        text: root.plugin?.latestVersion ?? ""
                        visible: text !== ""
                        color: Style.colors.pluginCardMetaText
                        font.pixelSize: Style.appFont.smallPt
                        font.family: Style.fontTypes.jetBrainsMono
                        elide: Text.ElideRight
                    }
                }

                // Author (design: 11px, margin-bottom 6px)
                Label {
                    text: "by " + (root.plugin?.author ?? "")
                    color: Style.colors.pluginCardMetaText
                    font.pixelSize: Style.appFont.h4Pt
                    font.family: Style.fontTypes.inter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.bottomMargin: Style.dp(6)
                }

                // Description (design: 12px, line-height 1.6)
                Label {
                    text: root.plugin?.description ?? ""
                    color: Style.colors.pluginCardDescription
                    font.pixelSize: Style.appFont.mediumPt
                    font.family: Style.fontTypes.inter
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }

        // Spacer pushing the footer to the bottom
        Item { Layout.fillHeight: true }

        // Footer: category badge, downloads count, actions
        Rectangle {
            id: footerBar
            Layout.fillWidth: true
            implicitHeight: footerRow.implicitHeight + Style.dp(18)
            color: "transparent"

            Rectangle {
                id: footerSeparator
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: Style.colors.pluginCardFooterBorder
            }

            RowLayout {
                id: footerRow
                anchors.fill: parent
                anchors.leftMargin: Style.dp(14)
                anchors.rightMargin: Style.dp(14)
                anchors.topMargin: Style.dp(8)
                anchors.bottomMargin: Style.dp(10)
                spacing: 8

                // Category badge (design: 10px semibold, padding 2px 7px, radius 3px)
                Rectangle {
                    radius: 3
                    color: root.categoryBadgeBg
                    implicitHeight: categoryBadgeLabel.implicitHeight + 4
                    implicitWidth: categoryBadgeLabel.implicitWidth + 14

                    Label {
                        id: categoryBadgeLabel
                        anchors.centerIn: parent
                        text: root.plugin?.category ?? ""
                        color: root.categoryColor
                        font.pixelSize: Style.appFont.smallPt
                        font.weight: Font.DemiBold
                        font.family: Style.fontTypes.inter
                        font.letterSpacing: 0.3
                    }
                }

                Item { Layout.fillWidth: true }

                // Downloads count (available plugins only, design: 10.5px)
                Row {
                    visible: root.plugin && !root.plugin.isInstalled && !root.pluginBusy
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Style.icons.download
                        font.family: Style.fontTypes.font6Pro
                        font.styleName: "Solid"
                        font.pixelSize: Style.appFont.smallPt
                        color: Style.colors.pluginCardMetaText
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.plugin?.donwloadsCount ?? ""
                        color: Style.colors.pluginCardMetaText
                        font.pixelSize: Style.appFont.smallPt
                        font.family: Style.fontTypes.inter
                    }
                }

                // Uninstall (installed plugins) — design: padding 3px 9px, 11px text
                Button {
                    id: uninstallButton
                    visible: (root.plugin?.isInstalled ?? false) && !root.pluginBusy
                    enabled: !root.pluginBusy
                    topInset: 0
                    bottomInset: 0
                    leftInset: 0
                    rightInset: 0
                    topPadding: 3
                    bottomPadding: 3
                    leftPadding: 9
                    rightPadding: 9
                    hoverEnabled: true

                    background: Rectangle {
                        radius: 5
                        color: "transparent"
                        border.width: 1
                        border.color: uninstallButton.hovered
                                      ? Style.colors.softCoralMist
                                      : Style.colors.pluginBtnSecondaryBorder
                    }

                    contentItem: Label {
                        text: "Uninstall"
                        color: uninstallButton.hovered ? Style.colors.softCoralMist
                                                       : Style.colors.pluginBtnSecondaryText
                        font.pixelSize: Style.appFont.h4Pt
                        font.family: Style.fontTypes.inter
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: root.uninstallClicked(root.plugin.pluginId)
                }

                // Update (installed plugins with pending update)
                Button {
                    visible: (root.plugin?.updateAvailable ?? false) && !root.pluginBusy
                    enabled: !root.pluginBusy
                    topInset: 0
                    bottomInset: 0
                    leftInset: 0
                    rightInset: 0
                    topPadding: 3
                    bottomPadding: 3
                    leftPadding: 12
                    rightPadding: 12

                    background: Rectangle {
                        radius: 5
                        color: enabled ? Style.colors.updateButton
                                       : Style.colors.disabledButton
                    }

                    contentItem: Label {
                        text: "Update"
                        color: Style.colors.textButton
                        font.pixelSize: Style.appFont.h4Pt
                        font.family: Style.fontTypes.inter
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: root.updateClicked(root.plugin.pluginId)
                }

                // Install (available plugins) — design: padding 4px 12px, 12px medium text
                Button {
                    visible: !(root.plugin?.isInstalled ?? false) && !root.pluginBusy
                    enabled: !root.pluginBusy
                             && (root.plugin?.isCompatible ?? true)
                    topInset: 0
                    bottomInset: 0
                    leftInset: 0
                    rightInset: 0
                    topPadding: 4
                    bottomPadding: 4
                    leftPadding: 12
                    rightPadding: 12

                    background: Rectangle {
                        radius: 5
                        color: enabled ? Style.colors.accent
                                       : Style.colors.disabledButton
                    }

                    contentItem: Label {
                        text: "Install"
                        color: Style.colors.onAccentText
                        font.pixelSize: Style.appFont.mediumPt
                        font.weight: Font.Medium
                        font.family: Style.fontTypes.inter
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: root.installClicked(root.plugin.pluginId)
                }

                // Enable/disable toggle (installed plugins) — same Switch style as CheckboxItem.qml
                Switch {
                    id: enableToggle
                    Layout.alignment: Qt.AlignVCenter
                    visible: (root.plugin?.isInstalled ?? false) && !root.pluginBusy
                    enabled: !root.pluginBusy
                    checked: root.plugin?.isEnabled ?? false
                    padding: 0

                    implicitWidth: 34
                    implicitHeight: 20

                    indicator: Rectangle {
                        implicitWidth: 34
                        implicitHeight: 20
                        x: enableToggle.leftPadding + (enableToggle.availableWidth - width) / 2
                        y: enableToggle.topPadding + (enableToggle.availableHeight - height) / 2
                        radius: height / 2

                        color: enableToggle.checked ? Style.colors.accent
                                                    : Style.colors.switchTrackOff
                        border.width: enableToggle.checked ? 0 : 1
                        border.color: enableToggle.hovered ? Style.colors.controlBorderHover
                                                           : Style.colors.controlBorder

                        Behavior on color       { ColorAnimation { duration: 160 } }
                        Behavior on border.color { ColorAnimation { duration: 160 } }

                        Rectangle {
                            id: toggleHandle
                            width: 14
                            height: 14
                            radius: height / 2
                            anchors.verticalCenter: parent.verticalCenter
                            x: enableToggle.checked ? parent.width - width - 3 : 3
                            color: Style.colors.switchHandle
                            border.width: 1
                            border.color: Qt.rgba(0, 0, 0, 0.08)

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
    }

    // Professional busy overlay — dims card content and shows a calm status strip
    Item {
        id: busyOverlay
        anchors.fill: parent
        visible: opacity > 0.01
        opacity: root.pluginBusy ? 1 : 0
        z: 20

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        // Soft frosted veil
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: Qt.rgba(Style.colors.pluginCardBackground.r,
                           Style.colors.pluginCardBackground.g,
                           Style.colors.pluginCardBackground.b, 0.55)
        }

        // Block interaction with the dimmed card while busy
        MouseArea {
            anchors.fill: parent
            enabled: root.pluginBusy
            hoverEnabled: true
            preventStealing: true
        }

        ColumnLayout {
            anchors.centerIn: parent
            anchors.margins: Style.dp(18)
            width: Math.min(parent.width - Style.dp(36), Style.dp(200))
            spacing: Style.dp(12)

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Style.dp(8)

                Item {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16

                    Canvas {
                        id: spinnerCanvas
                        anchors.fill: parent
                        property real sweep: 0

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            var cx = width / 2
                            var cy = height / 2
                            var r = Math.min(cx, cy) - 1.25

                            ctx.globalAlpha = 0.2
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, 0, Math.PI * 2)
                            ctx.strokeStyle = root.busyAccent
                            ctx.lineWidth = 2
                            ctx.stroke()

                            ctx.globalAlpha = 1.0
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, sweep, sweep + Math.PI * 1.25)
                            ctx.strokeStyle = root.busyAccent
                            ctx.lineWidth = 2
                            ctx.lineCap = "round"
                            ctx.stroke()
                        }

                        onSweepChanged: requestPaint()
                        Component.onCompleted: requestPaint()

                        Connections {
                            target: root
                            function onBusyAccentChanged() { spinnerCanvas.requestPaint() }
                            function onPluginBusyChanged() {
                                if (root.pluginBusy)
                                    spinnerCanvas.requestPaint()
                            }
                        }

                        NumberAnimation on sweep {
                            from: 0
                            to: Math.PI * 2
                            duration: 1000
                            loops: Animation.Infinite
                            running: root.pluginBusy
                            easing.type: Easing.Linear
                        }
                    }
                }

                Label {
                    text: root.busyLabel
                    color: Style.colors.pluginCardTitle
                    font.pixelSize: Style.appFont.mediumPt
                    font.weight: Font.Medium
                    font.family: Style.fontTypes.inter
                    horizontalAlignment: Text.AlignHCenter
                }

                Label {
                    visible: root.hasDeterminateProgress
                    text: Math.round(root.installProgress) + "%"
                    color: Style.colors.pluginCardMetaText
                    font.pixelSize: Style.appFont.smallPt
                    font.family: Style.fontTypes.jetBrainsMono
                }
            }

            // Slim progress track
            Item {
                id: progressTrack
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                clip: true

                Rectangle {
                    anchors.fill: parent
                    radius: 1.5
                    color: root.busyAccentMuted
                }

                // Determinate fill
                Rectangle {
                    visible: root.hasDeterminateProgress
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.max(0.02, root.installProgress / 100.0)
                    radius: 1.5
                    color: root.busyAccent

                    Behavior on width {
                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }
                }

                // Indeterminate shimmer
                Rectangle {
                    id: shimmer
                    visible: root.pluginBusy && !root.hasDeterminateProgress
                    width: progressTrack.width * 0.34
                    height: parent.height
                    radius: 1.5
                    color: root.busyAccent
                    opacity: 0.85
                    x: -width

                    SequentialAnimation on x {
                        running: root.pluginBusy && !root.hasDeterminateProgress
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: -progressTrack.width * 0.34
                            to: progressTrack.width
                            duration: 1100
                            easing.type: Easing.InOutCubic
                        }
                        PauseAnimation { duration: 160 }
                    }
                }
            }
        }

        // Bottom accent hairline
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 2
            color: root.busyAccent
            opacity: 0.85
        }
    }

    // Compatibility dot (top-right corner) — design: 8px, top 10px right 10px
    Rectangle {
        id: compatDot
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 10
        width: 8
        height: 8
        radius: 4
        color: root.compatDotColor
        visible: !root.pluginBusy
        z: 21

        HoverHandler {
            id: compatDotHover
        }

        ToolTip.visible: compatDotHover.hovered
        ToolTip.text: root.compatLabel
        ToolTip.delay: 500
    }

    /* Functions
     * ****************************************************************************************/

}