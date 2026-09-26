import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailView
 * Modern marketplace-style plugin details with screenshot / GIF gallery.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var pluginController: null
    property var plugin: root.pluginController ? root.pluginController.pluginDetail : null
    property int selectedShot: 0

    readonly property color categoryColor: root.plugin?.mainColor || Style.colors.accent
    readonly property color categorySoft: Qt.rgba(root.categoryColor.r,
                                                  root.categoryColor.g,
                                                  root.categoryColor.b, 0.10)
    readonly property color categoryWash: Qt.rgba(root.categoryColor.r,
                                                  root.categoryColor.g,
                                                  root.categoryColor.b, 0.16)

    readonly property var screenshots: root.plugin?.screenshots || []
    readonly property bool hasScreenshots: root.screenshots.length > 0
    readonly property var activeShot: root.hasScreenshots
                                      ? root.screenshots[Math.min(root.selectedShot, root.screenshots.length - 1)]
                                      : null

    readonly property bool pluginBusy: (root.plugin?.busy ?? false)
                                       || (root.pluginController
                                           && root.plugin
                                           && root.pluginController.installingPluginId === root.plugin.pluginId)
    readonly property string installPhase: (root.pluginController
                                            && root.plugin
                                            && root.pluginController.installingPluginId === root.plugin.pluginId)
                                           ? root.pluginController.installPhase : ""
    readonly property real installProgress: (root.pluginController
                                             && root.plugin
                                             && root.pluginController.installingPluginId === root.plugin.pluginId)
                                            ? root.pluginController.installProgress : -1
    readonly property bool hasDeterminateProgress: root.installProgress >= 0
                                                   && (root.installPhase === "Downloading"
                                                       || root.installPhase === "Updating")
    readonly property bool isDestructiveBusy: root.installPhase === "Uninstalling"
    readonly property color busyAccent: root.isDestructiveBusy
                                        ? Style.colors.softCoralMist
                                        : Style.colors.accent

    readonly property string busyLabel: {
        switch (root.installPhase) {
        case "Preparing":    return "Preparing…"
        case "Downloading":  return root.hasDeterminateProgress
                                   ? ("Downloading " + Math.round(root.installProgress) + "%")
                                   : "Downloading…"
        case "Installing":   return "Installing…"
        case "Updating":     return "Updating…"
        case "Uninstalling": return "Uninstalling…"
        default:             return root.pluginBusy ? "Working…" : ""
        }
    }

    readonly property string aboutText: {
        if (root.plugin?.longDescription && root.plugin.longDescription.length > 0)
            return root.plugin.longDescription
        return root.plugin?.description || ""
    }

    /* Signals
     * ****************************************************************************************/
    signal backRequested()
    signal installClicked(string pluginId)
    signal uninstallClicked(string pluginId)
    signal updateClicked(string pluginId)
    signal enableToggled(string pluginId, bool enabled)

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.pluginPageBackground
    clip: true

    onPluginChanged: root.selectedShot = 0
    onScreenshotsChanged: {
        if (root.selectedShot >= root.screenshots.length)
            root.selectedShot = Math.max(0, root.screenshots.length - 1)
    }

    /* Children
     * ****************************************************************************************/
    // Soft category ambient background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.categorySoft }
            GradientStop { position: 0.38; color: Style.colors.pluginPageBackground }
            GradientStop { position: 1.0; color: Style.colors.pluginPageBackground }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top chrome
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: topBar.implicitHeight + Style.dp(20)
            color: Qt.rgba(Style.colors.pluginCardBackground.r,
                           Style.colors.pluginCardBackground.g,
                           Style.colors.pluginCardBackground.b, 0.86)
            border.width: 0

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Style.colors.pluginCardBorder
                opacity: 0.7
            }

            RowLayout {
                id: topBar
                anchors.fill: parent
                anchors.leftMargin: Style.dp(18)
                anchors.rightMargin: Style.dp(18)
                anchors.topMargin: Style.dp(12)
                anchors.bottomMargin: Style.dp(12)
                spacing: Style.dp(12)

                Button {
                    id: backButton
                    flat: true
                    topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0
                    padding: Style.dp(8)
                    hoverEnabled: true

                    background: Rectangle {
                        radius: 8
                        color: backButton.hovered ? root.categorySoft : "transparent"
                        border.width: 1
                        border.color: backButton.hovered ? Qt.rgba(root.categoryColor.r, root.categoryColor.g, root.categoryColor.b, 0.28)
                                                         : Style.colors.pluginCardBorder
                    }

                    contentItem: RowLayout {
                        spacing: 7
                        Text {
                            text: Style.icons.arrowLeft
                            font.family: Style.fontTypes.font6Pro
                            font.styleName: "Solid"
                            font.pixelSize: 12
                            color: Style.colors.pluginCardTitle
                        }
                        Label {
                            text: "Plugins"
                            color: Style.colors.pluginCardTitle
                            font.pixelSize: Style.appFont.mediumPt
                            font.weight: Font.Medium
                            font.family: Style.fontTypes.inter
                        }
                    }

                    onClicked: root.backRequested()
                }

                Label {
                    text: root.plugin?.name || "Plugin details"
                    color: Style.colors.pluginCardTitle
                    font.pixelSize: Style.appFont.h3Pt
                    font.weight: Font.DemiBold
                    font.family: Style.fontTypes.inter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                BusyIndicator {
                    visible: root.pluginController?.pluginDetailBusy ?? false
                    running: visible
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    Material.accent: root.categoryColor
                }
            }
        }

        Label {
            visible: !!(root.pluginController?.pluginDetailError)
            text: root.pluginController?.pluginDetailError ?? ""
            color: Style.colors.softCoralMist
            font.pixelSize: Style.appFont.mediumPt
            font.family: Style.fontTypes.inter
            Layout.fillWidth: true
            Layout.leftMargin: Style.dp(18)
            Layout.rightMargin: Style.dp(18)
            Layout.topMargin: Style.dp(10)
            wrapMode: Text.WordWrap
        }

        Flickable {
            id: detailFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: contentColumn.implicitHeight + Style.dp(28)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: contentColumn
                width: detailFlick.width
                spacing: Style.dp(16)

                // Hero + actions
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: Style.dp(18)
                    Layout.rightMargin: Style.dp(18)
                    Layout.topMargin: Style.dp(16)
                    radius: 14
                    color: Style.colors.pluginCardBackground
                    border.width: 1
                    border.color: Style.colors.pluginCardBorder
                    clip: true
                    implicitHeight: heroInner.implicitHeight

                    // Category accent ribbon
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: Style.dp(4)
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.categoryColor }
                            GradientStop { position: 1.0; color: Qt.rgba(root.categoryColor.r, root.categoryColor.g, root.categoryColor.b, 0.35) }
                        }
                    }

                    ColumnLayout {
                        id: heroInner
                        width: parent.width
                        anchors.top: parent.top
                        anchors.topMargin: Style.dp(18)
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Style.dp(18)
                        anchors.rightMargin: Style.dp(18)
                        anchors.bottomMargin: Style.dp(18)
                        spacing: Style.dp(16)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.dp(16)

                            // Icon tile
                            Rectangle {
                                Layout.preferredWidth: 72
                                Layout.preferredHeight: 72
                                Layout.alignment: Qt.AlignTop
                                radius: 16
                                color: root.categoryWash
                                border.width: 1
                                border.color: Qt.rgba(root.categoryColor.r, root.categoryColor.g, root.categoryColor.b, 0.22)

                                Image {
                                    id: detailIcon
                                    anchors.centerIn: parent
                                    width: 36
                                    height: 36
                                    source: root.plugin?.iconUrl ?? ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    visible: status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: detailIcon.status !== Image.Ready
                                    text: Style.icons.plugins
                                    font.family: Style.fontTypes.font6Pro
                                    font.styleName: "Solid"
                                    font.pixelSize: 28
                                    color: root.categoryColor
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Style.dp(8)

                                    Label {
                                        text: root.plugin?.name || "Plugin"
                                        color: Style.colors.pluginCardTitle
                                        font.pixelSize: Style.appFont.h2Pt
                                        font.weight: Font.DemiBold
                                        font.family: Style.fontTypes.inter
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        visible: !!(root.plugin?.category)
                                        radius: 999
                                        color: root.categorySoft
                                        border.width: 1
                                        border.color: Qt.rgba(root.categoryColor.r, root.categoryColor.g, root.categoryColor.b, 0.25)
                                        implicitHeight: categoryLabel.implicitHeight + 8
                                        implicitWidth: categoryLabel.implicitWidth + 16

                                        Label {
                                            id: categoryLabel
                                            anchors.centerIn: parent
                                            text: root.plugin?.category || ""
                                            color: root.categoryColor
                                            font.pixelSize: Style.appFont.smallPt
                                            font.weight: Font.DemiBold
                                            font.family: Style.fontTypes.inter
                                            font.capitalization: Font.AllUppercase
                                            font.letterSpacing: 0.4
                                        }
                                    }
                                }

                                Label {
                                    text: root.plugin?.author ? ("by " + root.plugin.author) : ""
                                    visible: text !== ""
                                    color: Style.colors.pluginCardMetaText
                                    font.pixelSize: Style.appFont.mediumPt
                                    font.family: Style.fontTypes.inter
                                }

                                Label {
                                    text: root.plugin?.description || ""
                                    visible: text !== "" && text !== root.aboutText
                                    color: Style.colors.pluginCardDescription
                                    font.pixelSize: Style.appFont.mediumPt
                                    font.family: Style.fontTypes.inter
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    lineHeight: 1.4
                                    lineHeightMode: Text.ProportionalHeight
                                }
                            }
                        }

                        // Meta strip
                        Flow {
                            Layout.fillWidth: true
                            spacing: Style.dp(8)

                            Repeater {
                                model: [
                                    { label: "Version", value: root.plugin?.latestVersion || "—" },
                                    { label: "Min app", value: root.plugin?.minAppVersion || "—" },
                                    { label: "Size", value: root.plugin?.size || "—" },
                                    { label: "Downloads", value: (root.plugin?.downloadsCount
                                                                  ?? root.plugin?.donwloadsCount
                                                                  ?? 0).toString() },
                                    { label: "Released", value: root.plugin?.releaseDate || "—" }
                                ]

                                delegate: Rectangle {
                                    radius: 10
                                    color: Style.colors.pluginPageBackground
                                    border.width: 1
                                    border.color: Style.colors.pluginCardFooterBorder
                                    implicitWidth: Math.max(Style.dp(86), metaCol.implicitWidth + Style.dp(22))
                                    implicitHeight: metaCol.implicitHeight + Style.dp(14)

                                    ColumnLayout {
                                        id: metaCol
                                        anchors.centerIn: parent
                                        spacing: 2

                                        Label {
                                            text: modelData.label
                                            color: Style.colors.pluginCardMetaText
                                            font.pixelSize: Style.appFont.smallPt
                                            font.family: Style.fontTypes.inter
                                            Layout.alignment: Qt.AlignHCenter
                                        }

                                        Label {
                                            text: modelData.value
                                            color: Style.colors.pluginCardTitle
                                            font.pixelSize: Style.appFont.mediumPt
                                            font.weight: Font.DemiBold
                                            font.family: Style.fontTypes.inter
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }

                        // Actions
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.bottomMargin: Style.dp(18)
                            spacing: Style.dp(8)

                            Button {
                                id: installBtn
                                visible: !(root.plugin?.isInstalled ?? false)
                                enabled: !root.pluginBusy && (root.plugin?.isCompatible ?? true)
                                         && !!(root.plugin?.pluginId)
                                topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0
                                topPadding: 10; bottomPadding: 10; leftPadding: 18; rightPadding: 18
                                hoverEnabled: true

                                background: Rectangle {
                                    radius: 9
                                    color: !installBtn.enabled ? Style.colors.disabledButton
                                           : (installBtn.hovered ? Style.colors.accentHover : Style.colors.accent)
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }
                                contentItem: Label {
                                    text: "Install plugin"
                                    color: Style.colors.onAccentText
                                    font.pixelSize: Style.appFont.mediumPt
                                    font.weight: Font.DemiBold
                                    font.family: Style.fontTypes.inter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                onClicked: root.installClicked(root.plugin.pluginId)
                            }

                            Button {
                                id: updateBtn
                                visible: root.plugin?.updateAvailable ?? false
                                enabled: !root.pluginBusy
                                topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0
                                topPadding: 10; bottomPadding: 10; leftPadding: 18; rightPadding: 18

                                background: Rectangle {
                                    radius: 9
                                    color: updateBtn.enabled ? Style.colors.updateButton : Style.colors.disabledButton
                                }
                                contentItem: Label {
                                    text: "Update"
                                    color: Style.colors.textButton
                                    font.pixelSize: Style.appFont.mediumPt
                                    font.weight: Font.DemiBold
                                    font.family: Style.fontTypes.inter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                onClicked: root.updateClicked(root.plugin.pluginId)
                            }

                            Button {
                                id: uninstallBtn
                                visible: root.plugin?.isInstalled ?? false
                                enabled: !root.pluginBusy
                                topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0
                                topPadding: 10; bottomPadding: 10; leftPadding: 16; rightPadding: 16
                                hoverEnabled: true

                                background: Rectangle {
                                    radius: 9
                                    color: uninstallBtn.hovered ? Qt.rgba(Style.colors.softCoralMist.r,
                                                                         Style.colors.softCoralMist.g,
                                                                         Style.colors.softCoralMist.b, 0.12)
                                                               : "transparent"
                                    border.width: 1
                                    border.color: uninstallBtn.hovered ? Style.colors.softCoralMist
                                                                       : Style.colors.pluginBtnSecondaryBorder
                                }
                                contentItem: Label {
                                    text: "Uninstall"
                                    color: uninstallBtn.hovered ? Style.colors.softCoralMist
                                                                : Style.colors.pluginBtnSecondaryText
                                    font.pixelSize: Style.appFont.mediumPt
                                    font.weight: Font.Medium
                                    font.family: Style.fontTypes.inter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                onClicked: root.uninstallClicked(root.plugin.pluginId)
                            }

                            Item { Layout.fillWidth: true }

                            RowLayout {
                                visible: root.plugin?.isInstalled ?? false
                                spacing: Style.dp(10)
                                enabled: !root.pluginBusy

                                Label {
                                    text: root.plugin?.isEnabled ? "Enabled" : "Disabled"
                                    color: Style.colors.pluginCardMetaText
                                    font.pixelSize: Style.appFont.mediumPt
                                    font.family: Style.fontTypes.inter
                                }

                                Switch {
                                    id: enableToggle
                                    checked: root.plugin?.isEnabled ?? false
                                    padding: 0
                                    implicitWidth: 38
                                    implicitHeight: 22

                                    indicator: Rectangle {
                                        implicitWidth: 38
                                        implicitHeight: 22
                                        radius: height / 2
                                        color: enableToggle.checked ? root.categoryColor
                                                                    : Style.colors.switchTrackOff
                                        border.width: enableToggle.checked ? 0 : 1
                                        border.color: Style.colors.controlBorder

                                        Rectangle {
                                            width: 16; height: 16; radius: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: enableToggle.checked ? parent.width - width - 3 : 3
                                            color: Style.colors.switchHandle
                                            Behavior on x {
                                                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                                            }
                                        }
                                    }

                                    onToggled: root.enableToggled(root.plugin.pluginId, checked)
                                }
                            }
                        }

                        RowLayout {
                            visible: root.pluginBusy
                            Layout.fillWidth: true
                            Layout.bottomMargin: Style.dp(18)
                            spacing: Style.dp(8)

                            BusyIndicator {
                                running: root.pluginBusy
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                                Material.accent: root.busyAccent
                            }

                            Label {
                                text: root.busyLabel
                                color: Style.colors.pluginCardTitle
                                font.pixelSize: Style.appFont.mediumPt
                                font.family: Style.fontTypes.inter
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Screenshot / GIF gallery
                Rectangle {
                    visible: root.hasScreenshots
                    Layout.fillWidth: true
                    Layout.leftMargin: Style.dp(18)
                    Layout.rightMargin: Style.dp(18)
                    radius: 14
                    color: Style.colors.pluginCardBackground
                    border.width: 1
                    border.color: Style.colors.pluginCardBorder
                    clip: true
                    implicitHeight: galleryCol.implicitHeight + Style.dp(28)

                    ColumnLayout {
                        id: galleryCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Style.dp(16)
                        spacing: Style.dp(12)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.dp(8)

                            Label {
                                text: "Preview"
                                color: Style.colors.pluginSectionLabel
                                font.pixelSize: Style.appFont.smallPt
                                font.weight: Font.DemiBold
                                font.family: Style.fontTypes.inter
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 0.6
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                visible: root.hasScreenshots
                                text: (root.selectedShot + 1) + " / " + root.screenshots.length
                                color: Style.colors.pluginCardMetaText
                                font.pixelSize: Style.appFont.smallPt
                                font.family: Style.fontTypes.jetBrainsMono
                            }

                            Rectangle {
                                visible: !!(root.activeShot?.isGif)
                                radius: 999
                                color: root.categorySoft
                                border.width: 1
                                border.color: Qt.rgba(root.categoryColor.r, root.categoryColor.g, root.categoryColor.b, 0.28)
                                implicitHeight: gifBadge.implicitHeight + 4
                                implicitWidth: gifBadge.implicitWidth + 12

                                Label {
                                    id: gifBadge
                                    anchors.centerIn: parent
                                    text: "GIF"
                                    color: root.categoryColor
                                    font.pixelSize: Style.appFont.smallPt
                                    font.weight: Font.DemiBold
                                    font.family: Style.fontTypes.inter
                                }
                            }
                        }

                        // Main stage
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(Style.dp(220), Math.min(Style.dp(360), detailFlick.width * 0.42))
                            radius: 12
                            color: "#0F1218"
                            clip: true

                            // Loading
                            BusyIndicator {
                                anchors.centerIn: parent
                                running: shotLoader.status === Loader.Loading
                                         || (shotLoader.item && shotLoader.item.status === Image.Loading)
                                visible: running
                                Material.accent: "white"
                            }

                            Loader {
                                id: shotLoader
                                anchors.fill: parent
                                anchors.margins: Style.dp(2)
                                active: root.hasScreenshots && !!root.activeShot
                                sourceComponent: (root.activeShot && root.activeShot.isGif)
                                                 ? gifShotComponent : imageShotComponent
                            }

                            Component {
                                id: imageShotComponent
                                Image {
                                    source: root.activeShot?.url || ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: true
                                }
                            }

                            Component {
                                id: gifShotComponent
                                AnimatedImage {
                                    source: root.activeShot?.url || ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    playing: true
                                    cache: true
                                }
                            }

                            // Prev / next
                            RoundButton {
                                visible: root.screenshots.length > 1
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                width: 34
                                height: 34
                                flat: true
                                text: Style.icons.arrowLeft
                                font.family: Style.fontTypes.font6Pro
                                font.styleName: "Solid"
                                opacity: 0.92
                                onClicked: root.selectedShot = (root.selectedShot - 1 + root.screenshots.length) % root.screenshots.length

                                background: Rectangle {
                                    radius: width / 2
                                    color: Qt.rgba(0, 0, 0, 0.45)
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.18)
                                }
                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            RoundButton {
                                visible: root.screenshots.length > 1
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                width: 34
                                height: 34
                                flat: true
                                opacity: 0.92
                                onClicked: root.selectedShot = (root.selectedShot + 1) % root.screenshots.length

                                background: Rectangle {
                                    radius: width / 2
                                    color: Qt.rgba(0, 0, 0, 0.45)
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.18)
                                }
                                contentItem: Text {
                                    text: Style.icons.arrowRight
                                    font.family: Style.fontTypes.font6Pro
                                    font.styleName: "Solid"
                                    font.pixelSize: 12
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Label {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: Style.dp(12)
                                visible: !!(root.activeShot?.caption)
                                text: root.activeShot?.caption || ""
                                color: "white"
                                font.pixelSize: Style.appFont.mediumPt
                                font.family: Style.fontTypes.inter
                                elide: Text.ElideRight
                                opacity: 0.9
                            }
                        }

                        // Thumbnails
                        ListView {
                            id: thumbStrip
                            visible: root.screenshots.length > 1
                            Layout.fillWidth: true
                            Layout.preferredHeight: Style.dp(64)
                            orientation: ListView.Horizontal
                            spacing: Style.dp(8)
                            clip: true
                            model: root.screenshots
                            currentIndex: root.selectedShot
                            highlightMoveDuration: 180

                            delegate: Item {
                                width: Style.dp(96)
                                height: thumbStrip.height

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: "#161A22"
                                    border.width: index === root.selectedShot ? 2 : 1
                                    border.color: index === root.selectedShot
                                                  ? root.categoryColor
                                                  : Style.colors.pluginCardBorder
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        source: modelData.url
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        visible: !modelData.isGif
                                    }

                                    AnimatedImage {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        source: modelData.url
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        playing: index === root.selectedShot
                                        visible: modelData.isGif
                                    }

                                    Rectangle {
                                        visible: modelData.isGif
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 4
                                        radius: 3
                                        color: Qt.rgba(0, 0, 0, 0.55)
                                        implicitWidth: thumbGif.implicitWidth + 8
                                        implicitHeight: thumbGif.implicitHeight + 4

                                        Label {
                                            id: thumbGif
                                            anchors.centerIn: parent
                                            text: "GIF"
                                            color: "white"
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            font.family: Style.fontTypes.inter
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectedShot = index
                                    }
                                }
                            }
                        }
                    }
                }

                // About
                DetailCard {
                    visible: root.aboutText.length > 0
                    title: "About"
                    body: root.aboutText
                }

                // Features
                DetailCard {
                    visible: !!(root.plugin?.features && root.plugin.features.length > 0)
                    title: "Features"

                    content: ColumnLayout {
                        spacing: Style.dp(8)

                        Repeater {
                            model: root.plugin?.features || []

                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.dp(10)

                                Rectangle {
                                    Layout.preferredWidth: 8
                                    Layout.preferredHeight: 8
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: 5
                                    radius: 4
                                    color: root.categoryColor
                                }

                                Label {
                                    text: typeof modelData === "string" ? modelData
                                          : (modelData.title || modelData.name || modelData.description || "")
                                    color: Style.colors.pluginCardDescription
                                    font.pixelSize: Style.appFont.mediumPt
                                    font.family: Style.fontTypes.inter
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    lineHeight: 1.35
                                    lineHeightMode: Text.ProportionalHeight
                                }
                            }
                        }
                    }
                }

                // Install guide
                DetailCard {
                    visible: !!(root.plugin?.installGuide)
                    title: "Install guide"
                    body: root.plugin?.installGuide || ""
                }

                // Changelog
                DetailCard {
                    visible: !!(root.plugin?.changelog && root.plugin.changelog.length > 0)
                    title: "Changelog"

                    content: ColumnLayout {
                        spacing: Style.dp(14)

                        Repeater {
                            model: root.plugin?.changelog || []

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                radius: 10
                                color: Style.colors.pluginPageBackground
                                border.width: 1
                                border.color: Style.colors.pluginCardFooterBorder
                                implicitHeight: changeCol.implicitHeight + Style.dp(20)

                                ColumnLayout {
                                    id: changeCol
                                    anchors.fill: parent
                                    anchors.margins: Style.dp(12)
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Style.dp(8)

                                        Rectangle {
                                            radius: 999
                                            color: root.categorySoft
                                            implicitHeight: verLabel.implicitHeight + 6
                                            implicitWidth: verLabel.implicitWidth + 12

                                            Label {
                                                id: verLabel
                                                anchors.centerIn: parent
                                                text: "v" + (modelData.version || "")
                                                color: root.categoryColor
                                                font.pixelSize: Style.appFont.smallPt
                                                font.weight: Font.DemiBold
                                                font.family: Style.fontTypes.inter
                                            }
                                        }

                                        Label {
                                            text: modelData.date || ""
                                            color: Style.colors.pluginCardMetaText
                                            font.pixelSize: Style.appFont.smallPt
                                            font.family: Style.fontTypes.jetBrainsMono
                                        }

                                        Item { Layout.fillWidth: true }
                                    }

                                    Label {
                                        text: modelData.notes || ""
                                        color: Style.colors.pluginCardDescription
                                        font.pixelSize: Style.appFont.mediumPt
                                        font.family: Style.fontTypes.inter
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                        lineHeight: 1.4
                                        lineHeightMode: Text.ProportionalHeight
                                    }
                                }
                            }
                        }
                    }
                }

                // Tags
                DetailCard {
                    visible: !!(root.plugin?.tags && root.plugin.tags.length > 0)
                    title: "Tags"

                    content: Flow {
                        Layout.fillWidth: true
                        spacing: Style.dp(8)

                        Repeater {
                            model: root.plugin?.tags || []

                            delegate: Rectangle {
                                radius: 999
                                color: root.categorySoft
                                border.width: 1
                                border.color: Qt.rgba(root.categoryColor.r, root.categoryColor.g, root.categoryColor.b, 0.22)
                                implicitHeight: tagLabel.implicitHeight + 8
                                implicitWidth: tagLabel.implicitWidth + 16

                                Label {
                                    id: tagLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: root.categoryColor
                                    font.pixelSize: Style.appFont.smallPt
                                    font.weight: Font.Medium
                                    font.family: Style.fontTypes.inter
                                }
                            }
                        }
                    }
                }

                // Technical
                DetailCard {
                    visible: !!(root.plugin?.pluginId)
                    title: "Technical"

                    content: ColumnLayout {
                        spacing: Style.dp(8)

                        Label {
                            text: "ID  " + (root.plugin?.pluginId || "")
                            color: Style.colors.pluginCardMetaText
                            font.pixelSize: Style.appFont.smallPt
                            font.family: Style.fontTypes.jetBrainsMono
                            wrapMode: Text.WrapAnywhere
                            Layout.fillWidth: true
                        }

                        Label {
                            visible: !!(root.plugin?.githubUrl)
                            text: root.plugin?.githubUrl || ""
                            color: Style.colors.accent
                            font.pixelSize: Style.appFont.mediumPt
                            font.family: Style.fontTypes.inter
                            wrapMode: Text.WrapAnywhere
                            Layout.fillWidth: true
                        }
                    }
                }

                Item { Layout.preferredHeight: Style.dp(8) }
            }
        }
    }

    /* Section card helper
     * ****************************************************************************************/
    component DetailCard: Rectangle {
        id: card

        property string title: ""
        property string body: ""
        default property alias content: extraColumn.data

        Layout.fillWidth: true
        Layout.leftMargin: Style.dp(18)
        Layout.rightMargin: Style.dp(18)
        radius: 14
        color: Style.colors.pluginCardBackground
        border.width: 1
        border.color: Style.colors.pluginCardBorder
        implicitHeight: cardColumn.implicitHeight + Style.dp(28)

        ColumnLayout {
            id: cardColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.dp(16)
            spacing: Style.dp(12)

            Label {
                text: card.title
                color: Style.colors.pluginSectionLabel
                font.pixelSize: Style.appFont.smallPt
                font.weight: Font.DemiBold
                font.family: Style.fontTypes.inter
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 0.6
            }

            Label {
                visible: card.body.length > 0
                text: card.body
                color: Style.colors.pluginCardDescription
                font.pixelSize: Style.appFont.mediumPt
                font.family: Style.fontTypes.inter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                lineHeight: 1.5
                lineHeightMode: Text.ProportionalHeight
            }

            ColumnLayout {
                id: extraColumn
                Layout.fillWidth: true
                spacing: Style.dp(8)
            }
        }
    }

    Connections {
        target: root.pluginController?.appModel ?? null

        function onPluginsChanged() {
            if (!root.plugin || !root.pluginController?.appModel)
                return

            let list = root.pluginController.appModel.plugins || []
            for (let i = 0; i < list.length; i++) {
                if (list[i].pluginId !== root.plugin.pluginId)
                    continue

                root.pluginController.pluginDetail = Object.assign({}, root.plugin, {
                    isInstalled: list[i].isInstalled,
                    isEnabled: list[i].isEnabled,
                    isCompatible: list[i].isCompatible,
                    updateAvailable: list[i].updateAvailable,
                    busy: list[i].busy,
                    latestVersion: list[i].latestVersion || root.plugin.latestVersion,
                    screenshots: root.plugin.screenshots
                })
                break
            }
        }
    }
}
