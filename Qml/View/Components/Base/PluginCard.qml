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
    property var  plugin:     null
    property bool hovered:    false
    property bool pluginBusy: root.plugin?.busy ?? false

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

    /* Signals
     * ****************************************************************************************/
    signal installClicked  (string pluginId)
    signal uninstallClicked(string pluginId)
    signal updateClicked   (string pluginId)
    signal enableToggled   (string pluginId, bool enabled)

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.pluginCardBackground
    radius: 7
    border {
        width: 1
        color: Style.colors.pluginCardBorder
    }

    scale: root.hovered ? 1.01 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    /* Children
     * ****************************************************************************************/

    // Mouse area handling the hovered property
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

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
                    visible: root.plugin && !root.plugin.isInstalled
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

                // Busy indicator
                BusyIndicator {
                    visible: root.pluginBusy
                    running: root.pluginBusy
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Material.accent: Style.colors.accent
                }

                // Uninstall (installed plugins) — design: padding 3px 9px, 11px text
                Button {
                    id: uninstallButton
                    visible: root.plugin?.isInstalled ?? false
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
                    visible: root.plugin?.updateAvailable ?? false
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
                    visible: !(root.plugin?.isInstalled ?? false)
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
                    visible: root.plugin?.isInstalled ?? false
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