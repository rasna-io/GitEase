import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailView
 * Marketplace-style plugin details: hero header with actions, tabbed content
 * (Overview / Features / Changelog) and a details sidebar. Collapses to a single
 * column on narrow widths.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    pluginController: null
    property var    plugin: root.pluginController ? root.pluginController.pluginDetail : null
    property int    selectedShot: 0
    property string currentTab: "overview"
    property string lastPluginId: ""
    property bool   idCopied: false

    readonly property bool wide: root.width >= Style.dp(920)
    readonly property real pageWidth: Math.min(root.width - Style.dp(48), Style.dp(1160))

    readonly property color categoryColor: root.plugin?.mainColor || Style.colors.accent
    readonly property color categorySoft: Qt.rgba(root.categoryColor.r, root.categoryColor.g,
                                                  root.categoryColor.b, 0.10)
    readonly property color categoryWash: Qt.rgba(root.categoryColor.r, root.categoryColor.g,
                                                  root.categoryColor.b, 0.16)
    readonly property color categoryEdge: Qt.rgba(root.categoryColor.r, root.categoryColor.g,
                                                  root.categoryColor.b, 0.28)

    readonly property var  screenshots: root.plugin?.screenshots || []
    readonly property bool hasScreenshots: root.screenshots.length > 0
    readonly property var  activeShot: root.hasScreenshots
                                       ? root.screenshots[Math.min(root.selectedShot, root.screenshots.length - 1)]
                                       : null

    readonly property var  features:  root.plugin?.features  || []
    readonly property var  changelog: root.plugin?.changelog || []
    readonly property var  tags:      root.plugin?.tags      || []
    readonly property int  downloadCount: root.plugin?.downloadsCount ?? root.plugin?.donwloadsCount ?? 0

    readonly property bool isInstalled:     root.plugin?.isInstalled ?? false
    readonly property bool isEnabled:       root.plugin?.isEnabled ?? false
    readonly property bool isCompatible:    root.plugin?.isCompatible ?? true
    readonly property bool updateAvailable: root.plugin?.updateAvailable ?? false

    readonly property bool isActiveInstall: !!(root.pluginController && root.plugin
                                               && root.pluginController.installingPluginId === root.plugin.pluginId)
    readonly property bool pluginBusy: (root.plugin?.busy ?? false) || root.isActiveInstall
    readonly property string installPhase: root.isActiveInstall ? root.pluginController.installPhase : ""
    readonly property real installProgress: root.isActiveInstall ? root.pluginController.installProgress : -1
    readonly property bool hasDeterminateProgress: root.installProgress >= 0
                                                   && (root.installPhase === "Downloading"
                                                       || root.installPhase === "Updating")
    readonly property bool isDestructiveBusy: root.installPhase === "Uninstalling"
    readonly property color busyAccent: root.isDestructiveBusy ? Style.colors.softCoralMist
                                                               : Style.colors.accent

    readonly property string busyLabel: {
        switch (root.installPhase) {
        case "Preparing":    return "Preparing…"
        case "Downloading":  return "Downloading…"
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

    readonly property bool hasOverviewContent: root.hasScreenshots
                                               || root.aboutText.length > 0
                                               || !!(root.plugin?.installGuide)
                                               || root.features.length > 0

    readonly property var tabModel: {
        let tabs = [{ id: "overview", label: "Overview", count: -1 }]
        if (root.features.length > 0)
            tabs.push({ id: "features", label: "Features", count: root.features.length })
        if (root.changelog.length > 0)
            tabs.push({ id: "changelog", label: "Changelog", count: root.changelog.length })
        return tabs
    }

    readonly property var detailRows: {
        if (!root.plugin)
            return []

        let rows = [
            { icon: Style.icons.tag,       label: "Version",
              value: root.plugin.latestVersion ? ("v" + root.plugin.latestVersion) : "", mono: true },
            { icon: Style.icons.calendar,  label: "Released",  value: root.plugin.releaseDate || "", mono: false },
            { icon: Style.icons.file,      label: "Size",      value: root.plugin.size || "", mono: false },
            { icon: Style.icons.download,  label: "Downloads",
              value: root.downloadCount > 0 ? root.formatCount(root.downloadCount) : "", mono: false },
            { icon: Style.icons.shield,    label: "Requires",
              value: root.plugin.minAppVersion ? ("GitEase " + root.plugin.minAppVersion + "+") : "", mono: false },
            { icon: Style.icons.plugins,   label: "Category",  value: root.plugin.category || "", mono: false }
        ]
        return rows.filter(function(r) { return r.value !== "" })
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

    onPluginChanged: {
        let id = root.plugin?.pluginId ?? ""
        if (id === root.lastPluginId)
            return

        root.lastPluginId = id
        root.selectedShot = 0
        root.currentTab = "overview"
        root.idCopied = false
        detailFlick.contentY = 0
    }

    onScreenshotsChanged: {
        if (root.selectedShot >= root.screenshots.length)
            root.selectedShot = Math.max(0, root.screenshots.length - 1)
    }

    onTabModelChanged: {
        let found = root.tabModel.some(function(t) { return t.id === root.currentTab })
        if (!found)
            root.currentTab = "overview"
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.dp(48)
            color: Style.colors.pluginCardBackground

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Style.colors.pluginDivider
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.dp(14)
                anchors.rightMargin: Style.dp(18)
                spacing: Style.dp(6)

                Button {
                    id: backButton
                    flat: true
                    hoverEnabled: true
                    topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0
                    topPadding: Style.dp(6); bottomPadding: Style.dp(6)
                    leftPadding: Style.dp(10); rightPadding: Style.dp(12)

                    background: Rectangle {
                        radius: Style.dp(7)
                        color: backButton.hovered ? Style.colors.pluginSidebarRowHoverBg : "transparent"
                    }

                    contentItem: Row {
                        spacing: Style.dp(8)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Style.icons.arrowLeft
                            font.family: Style.fontTypes.font6Pro
                            font.styleName: "Solid"
                            font.pixelSize: Style.appFont.captionPt
                            color: backButton.hovered ? Style.colors.pluginSidebarRowActiveText
                                                      : Style.colors.pluginSectionLabel
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Plugins"
                            color: backButton.hovered ? Style.colors.pluginSidebarRowActiveText
                                                      : Style.colors.pluginSectionLabel
                            font.pixelSize: Style.appFont.mediumPt
                            font.weight: Font.Medium
                            font.family: Style.fontTypes.inter
                        }
                    }

                    onClicked: root.backRequested()
                }

                Label {
                    text: "/"
                    color: Style.colors.pluginSectionMetaText
                    font.pixelSize: Style.appFont.mediumPt
                    font.family: Style.fontTypes.inter
                }

                Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: Style.dp(6)
                    text: root.plugin?.name || "Plugin details"
                    color: Style.colors.pluginCardTitle
                    font.pixelSize: Style.appFont.mediumPt
                    font.weight: Font.DemiBold
                    font.family: Style.fontTypes.inter
                    elide: Text.ElideRight
                }

                BusyIndicator {
                    visible: root.pluginController?.pluginDetailBusy ?? false
                    running: visible
                    Layout.preferredWidth: Style.dp(20)
                    Layout.preferredHeight: Style.dp(20)
                }
            }
        }

        // Error banner
        Rectangle {
            visible: !!(root.pluginController?.pluginDetailError)
            Layout.fillWidth: true
            implicitHeight: errorRow.implicitHeight + Style.dp(16)
            color: Qt.rgba(Style.colors.softCoralMist.r, Style.colors.softCoralMist.g,
                           Style.colors.softCoralMist.b, 0.10)

            RowLayout {
                id: errorRow
                anchors.fill: parent
                anchors.leftMargin: Style.dp(20)
                anchors.rightMargin: Style.dp(20)
                spacing: Style.dp(10)

                Text {
                    text: Style.icons.warning
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.appFont.smallPt
                    color: Style.colors.softCoralMist
                }

                Label {
                    Layout.fillWidth: true
                    text: root.pluginController?.pluginDetailError ?? ""
                    color: Style.colors.softCoralMist
                    font.pixelSize: Style.appFont.smallPt
                    font.family: Style.fontTypes.inter
                    wrapMode: Text.WordWrap
                }
            }
        }

        Flickable {
            id: detailFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: pageColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: pageColumn
                width: detailFlick.width
                spacing: 0

                // ── Hero band ───────────────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: heroColumn.implicitHeight + Style.dp(28)
                    color: Style.colors.pluginCardBackground

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: root.categoryWash }
                            GradientStop { position: 1.0; color: Qt.rgba(root.categoryColor.r,
                                                                         root.categoryColor.g,
                                                                         root.categoryColor.b, 0.0) }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: Style.colors.pluginDivider
                    }

                    ColumnLayout {
                        id: heroColumn
                        width: root.pageWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        spacing: Style.dp(22)

                        GridLayout {
                            id: heroGrid
                            Layout.fillWidth: true
                            columns: root.wide ? 3 : 2
                            columnSpacing: Style.dp(20)
                            rowSpacing: Style.dp(18)

                            // Icon tile
                            Rectangle {
                                Layout.preferredWidth: Style.dp(88)
                                Layout.preferredHeight: Style.dp(88)
                                Layout.alignment: Qt.AlignTop
                                radius: Style.dp(20)
                                color: Style.colors.pluginCardBackground
                                border.width: 1
                                border.color: root.categoryEdge

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: parent.radius - 1
                                    color: root.categorySoft
                                }

                                Image {
                                    id: heroIcon
                                    anchors.centerIn: parent
                                    width: parent.width - Style.dp(16)
                                    height: width
                                    source: root.plugin?.iconUrl ?? ""
                                    sourceSize.width: width * 2
                                    sourceSize.height: height * 2
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    smooth: true
                                    mipmap: true
                                    visible: status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: heroIcon.status !== Image.Ready
                                    text: Style.icons.plugins
                                    font.family: Style.fontTypes.font6Pro
                                    font.styleName: "Solid"
                                    font.pixelSize: Style.appFont.displaySmPt
                                    color: root.categoryColor
                                }
                            }

                            // Identity
                            ColumnLayout {
                                id: identityColumn
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                spacing: Style.dp(8)

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Style.dp(10)

                                    Label {
                                        Layout.maximumWidth: identityColumn.width
                                                             - (versionChip.visible ? versionChip.width + Style.dp(10) : 0)
                                        text: root.plugin?.name || "Plugin"
                                        color: Style.colors.pluginCardTitle
                                        font.pixelSize: Style.appFont.xlPt
                                        font.weight: Font.Bold
                                        font.family: Style.fontTypes.inter
                                        elide: Text.ElideRight
                                    }

                                    Chip {
                                        id: versionChip
                                        visible: !!(root.plugin?.latestVersion)
                                        text: "v" + (root.plugin?.latestVersion || "")
                                        tint: Style.colors.pluginSectionLabel
                                        mono: true
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: Style.dp(14)

                                    MetaItem {
                                        visible: !!(root.plugin?.author)
                                        iconText: Style.icons.user
                                        text: root.plugin?.author || ""
                                    }

                                    MetaItem {
                                        visible: root.downloadCount > 0
                                        iconText: Style.icons.download
                                        text: root.formatCount(root.downloadCount) + " downloads"
                                    }

                                    MetaItem {
                                        visible: !!(root.plugin?.releaseDate)
                                        iconText: Style.icons.calendar
                                        text: root.plugin?.releaseDate || ""
                                    }
                                }

                                Label {
                                    Layout.fillWidth: true
                                    Layout.topMargin: Style.dp(2)
                                    visible: text !== ""
                                    text: root.plugin?.description || ""
                                    color: Style.colors.pluginCardDescription
                                    font.pixelSize: Style.appFont.mediumPt
                                    font.family: Style.fontTypes.inter
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    lineHeight: 1.45
                                    lineHeightMode: Text.ProportionalHeight
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    Layout.topMargin: Style.dp(2)
                                    spacing: Style.dp(6)

                                    Chip {
                                        visible: !!(root.plugin?.category)
                                        text: root.plugin?.category || ""
                                        tint: root.categoryColor
                                    }

                                    Chip {
                                        visible: root.isInstalled && root.isEnabled
                                        iconText: Style.icons.circleCheck
                                        text: "Installed"
                                        tint: Style.colors.vibrantMint
                                    }

                                    Chip {
                                        visible: root.isInstalled && !root.isEnabled
                                        text: "Installed · Disabled"
                                        tint: Style.colors.pluginSectionLabel
                                    }

                                    Chip {
                                        visible: root.updateAvailable
                                        iconText: Style.icons.update
                                        text: "Update available"
                                        tint: Style.colors.marigold
                                    }

                                    Chip {
                                        visible: !root.isCompatible
                                        iconText: Style.icons.warning
                                        text: "Incompatible"
                                        tint: Style.colors.incompatible
                                    }
                                }
                            }

                            // Actions
                            ColumnLayout {
                                Layout.columnSpan: root.wide ? 1 : 2
                                Layout.fillWidth: !root.wide
                                Layout.preferredWidth: root.wide ? Style.dp(290) : -1
                                Layout.alignment: root.wide ? (Qt.AlignTop | Qt.AlignRight) : Qt.AlignTop
                                spacing: Style.dp(10)

                                // Buttons
                                Flow {
                                    visible: !root.pluginBusy
                                    Layout.fillWidth: true
                                    layoutDirection: root.wide ? Qt.RightToLeft : Qt.LeftToRight
                                    spacing: Style.dp(8)

                                    ActionButton {
                                        visible: !root.isInstalled
                                        enabled: root.isCompatible && !!(root.plugin?.pluginId)
                                        iconText: Style.icons.download
                                        label: "Install"
                                        fill: Style.colors.accent
                                        fillHover: Style.colors.accentHover
                                        onClicked: root.installClicked(root.plugin.pluginId)
                                    }

                                    ActionButton {
                                        visible: root.updateAvailable
                                        iconText: Style.icons.update
                                        label: root.plugin?.latestVersion ? ("Update to v" + root.plugin.latestVersion)
                                                                          : "Update"
                                        fill: Style.colors.updateButton
                                        fillHover: Qt.lighter(Style.colors.updateButton, 1.1)
                                        textColor: Style.colors.textButton
                                        onClicked: root.updateClicked(root.plugin.pluginId)
                                    }

                                    ActionButton {
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
                                                text: root.isEnabled ? "Active in all repositories"
                                                                     : "Turn on to activate this plugin"
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
                                                color: enableToggle.checked ? Style.colors.accent
                                                                            : Style.colors.switchTrackOff
                                                border.width: enableToggle.checked ? 0 : 1
                                                border.color: Style.colors.controlBorder
                                                Behavior on color { ColorAnimation { duration: 160 } }

                                                Rectangle {
                                                    width: Style.dp(16)
                                                    height: width
                                                    radius: width / 2
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

                                // Progress
                                Rectangle {
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
                                                running: root.pluginBusy
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
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 4
                                            clip: true

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 2
                                                color: Qt.rgba(root.busyAccent.r, root.busyAccent.g,
                                                               root.busyAccent.b, 0.16)
                                            }

                                            Rectangle {
                                                visible: root.hasDeterminateProgress
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                width: parent.width * Math.max(0.02, root.installProgress / 100.0)
                                                radius: 2
                                                color: root.busyAccent
                                                Behavior on width { NumberAnimation { duration: 160 } }
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
                                                    PauseAnimation { duration: 160 }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Tabs
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.dp(24)

                            Repeater {
                                model: root.tabModel

                                delegate: TabItem {
                                    label: modelData.label
                                    count: modelData.count
                                    active: root.currentTab === modelData.id
                                    tint: root.categoryColor
                                    onClicked: {
                                        root.currentTab = modelData.id
                                        detailFlick.returnToBounds()
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                // ── Body ────────────────────────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    implicitHeight: bodyGrid.implicitHeight + Style.dp(48)

                    GridLayout {
                        id: bodyGrid
                        width: root.pageWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: Style.dp(24)
                        columns: root.wide ? 2 : 1
                        columnSpacing: Style.dp(24)
                        rowSpacing: Style.dp(16)

                        // Main column
                        ColumnLayout {
                            id: mainColumn
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: Style.dp(16)

                            // Overview: gallery
                            SectionCard {
                                visible: root.currentTab === "overview" && root.hasScreenshots
                                title: "Preview"
                                iconText: Style.icons.star
                                tint: root.categoryColor
                                trailing: root.screenshots.length > 1
                                          ? ((root.selectedShot + 1) + " / " + root.screenshots.length) : ""

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Math.max(Style.dp(220), Math.min(Style.dp(440), width * 0.56))
                                    radius: Style.dp(10)
                                    color: "#0F1218"
                                    clip: true

                                    BusyIndicator {
                                        anchors.centerIn: parent
                                        running: shotLoader.status === Loader.Loading
                                                 || (shotLoader.item && shotLoader.item.status === Image.Loading)
                                        visible: running
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

                                    GalleryArrow {
                                        visible: root.screenshots.length > 1
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: Style.dp(10)
                                        iconText: Style.icons.arrowLeft
                                        onClicked: root.selectedShot = (root.selectedShot - 1 + root.screenshots.length)
                                                                       % root.screenshots.length
                                    }

                                    GalleryArrow {
                                        visible: root.screenshots.length > 1
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: parent.right
                                        anchors.rightMargin: Style.dp(10)
                                        iconText: Style.icons.arrowRight
                                        onClicked: root.selectedShot = (root.selectedShot + 1) % root.screenshots.length
                                    }

                                    Rectangle {
                                        visible: !!(root.activeShot?.caption) || !!(root.activeShot?.isGif)
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: captionRow.implicitHeight + Style.dp(24)
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
                                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
                                        }

                                        RowLayout {
                                            id: captionRow
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            anchors.margins: Style.dp(12)
                                            spacing: Style.dp(8)

                                            Label {
                                                Layout.fillWidth: true
                                                text: root.activeShot?.caption || ""
                                                color: "white"
                                                font.pixelSize: Style.appFont.smallPt
                                                font.family: Style.fontTypes.inter
                                                elide: Text.ElideRight
                                            }

                                            Rectangle {
                                                visible: !!(root.activeShot?.isGif)
                                                radius: 3
                                                color: Qt.rgba(1, 1, 1, 0.18)
                                                implicitWidth: gifLabel.implicitWidth + Style.dp(10)
                                                implicitHeight: gifLabel.implicitHeight + Style.dp(4)

                                                Label {
                                                    id: gifLabel
                                                    anchors.centerIn: parent
                                                    text: "GIF"
                                                    color: "white"
                                                    font.pixelSize: Style.appFont.microPt
                                                    font.weight: Font.DemiBold
                                                    font.family: Style.fontTypes.inter
                                                }
                                            }
                                        }
                                    }
                                }

                                ListView {
                                    id: thumbStrip
                                    visible: root.screenshots.length > 1
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Style.dp(58)
                                    orientation: ListView.Horizontal
                                    spacing: Style.dp(8)
                                    clip: true
                                    model: root.screenshots
                                    currentIndex: root.selectedShot
                                    highlightMoveDuration: 180

                                    delegate: Rectangle {
                                        width: Style.dp(92)
                                        height: thumbStrip.height
                                        radius: Style.dp(7)
                                        color: "#161A22"
                                        border.width: index === root.selectedShot ? 2 : 1
                                        border.color: index === root.selectedShot ? root.categoryColor
                                                                                  : Style.colors.pluginCardBorder
                                        opacity: index === root.selectedShot || thumbHover.hovered ? 1.0 : 0.7
                                        clip: true

                                        Behavior on opacity { NumberAnimation { duration: 120 } }

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
                                            source: modelData.isGif ? modelData.url : ""
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            playing: index === root.selectedShot
                                            visible: modelData.isGif
                                        }

                                        HoverHandler { id: thumbHover; cursorShape: Qt.PointingHandCursor }
                                        TapHandler { onTapped: root.selectedShot = index }
                                    }
                                }
                            }

                            // Overview: about
                            SectionCard {
                                visible: root.currentTab === "overview" && root.aboutText.length > 0
                                title: "About"
                                iconText: Style.icons.info
                                tint: root.categoryColor

                                RichBody { text: root.aboutText }
                            }

                            // Overview: feature highlights
                            SectionCard {
                                visible: root.currentTab === "overview" && root.features.length > 0
                                title: "Highlights"
                                iconText: Style.icons.circleCheck
                                tint: root.categoryColor
                                trailing: root.features.length > 4 ? ("+" + (root.features.length - 4) + " more") : ""

                                Repeater {
                                    model: root.features.slice(0, 4)

                                    delegate: RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Style.dp(10)

                                        Text {
                                            Layout.alignment: Qt.AlignTop
                                            Layout.topMargin: Style.dp(3)
                                            text: Style.icons.check
                                            font.family: Style.fontTypes.font6Pro
                                            font.styleName: "Solid"
                                            font.pixelSize: Style.appFont.captionPt
                                            color: root.categoryColor
                                        }

                                        Label {
                                            Layout.fillWidth: true
                                            text: root.featureTitle(modelData)
                                            color: Style.colors.pluginCardDescription
                                            font.pixelSize: Style.appFont.mediumPt
                                            font.family: Style.fontTypes.inter
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }

                                LinkButton {
                                    visible: root.features.length > 4
                                    text: "See all features"
                                    tint: root.categoryColor
                                    onClicked: root.currentTab = "features"
                                }
                            }

                            // Overview: install guide
                            SectionCard {
                                visible: root.currentTab === "overview" && !!(root.plugin?.installGuide)
                                title: "Getting started"
                                iconText: Style.icons.list
                                tint: root.categoryColor

                                RichBody { text: root.plugin?.installGuide || "" }
                            }

                            // Overview: empty
                            SectionCard {
                                visible: root.currentTab === "overview" && !root.hasOverviewContent

                                Label {
                                    Layout.fillWidth: true
                                    Layout.topMargin: Style.dp(12)
                                    Layout.bottomMargin: Style.dp(12)
                                    text: "The author hasn't provided a description for this plugin yet."
                                    color: Style.colors.pluginCardMetaText
                                    font.pixelSize: Style.appFont.mediumPt
                                    font.family: Style.fontTypes.inter
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                            }

                            // Features tab
                            GridLayout {
                                visible: root.currentTab === "features"
                                Layout.fillWidth: true
                                columns: mainColumn.width > Style.dp(560) ? 2 : 1
                                columnSpacing: Style.dp(12)
                                rowSpacing: Style.dp(12)

                                Repeater {
                                    model: root.features

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: 1
                                        implicitHeight: featureRow.implicitHeight + Style.dp(28)
                                        radius: Style.dp(10)
                                        color: Style.colors.pluginCardBackground
                                        border.width: 1
                                        border.color: Style.colors.pluginCardBorder

                                        RowLayout {
                                            id: featureRow
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: Style.dp(14)
                                            spacing: Style.dp(12)

                                            Rectangle {
                                                Layout.alignment: Qt.AlignTop
                                                Layout.preferredWidth: Style.dp(28)
                                                Layout.preferredHeight: Style.dp(28)
                                                radius: Style.dp(8)
                                                color: root.categorySoft

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: Style.icons.check
                                                    font.family: Style.fontTypes.font6Pro
                                                    font.styleName: "Solid"
                                                    font.pixelSize: Style.appFont.captionPt
                                                    color: root.categoryColor
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: Style.dp(4)

                                                Label {
                                                    Layout.fillWidth: true
                                                    text: root.featureTitle(modelData)
                                                    color: Style.colors.pluginCardTitle
                                                    font.pixelSize: Style.appFont.mediumPt
                                                    font.weight: root.featureDescription(modelData) !== ""
                                                                 ? Font.DemiBold : Font.Normal
                                                    font.family: Style.fontTypes.inter
                                                    wrapMode: Text.WordWrap
                                                }

                                                Label {
                                                    Layout.fillWidth: true
                                                    visible: text !== ""
                                                    text: root.featureDescription(modelData)
                                                    color: Style.colors.pluginCardDescription
                                                    font.pixelSize: Style.appFont.smallPt
                                                    font.family: Style.fontTypes.inter
                                                    wrapMode: Text.WordWrap
                                                    lineHeight: 1.4
                                                    lineHeightMode: Text.ProportionalHeight
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Changelog tab
                            SectionCard {
                                visible: root.currentTab === "changelog"

                                Repeater {
                                    id: changelogRepeater
                                    model: root.changelog

                                    delegate: RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Style.dp(14)

                                        // Timeline rail
                                        Item {
                                            Layout.preferredWidth: Style.dp(14)
                                            Layout.fillHeight: true

                                            Rectangle {
                                                visible: index < changelogRepeater.count - 1
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.top: parent.top
                                                anchors.topMargin: Style.dp(14)
                                                anchors.bottom: parent.bottom
                                                anchors.bottomMargin: -Style.dp(12)
                                                width: 2
                                                color: Style.colors.pluginDivider
                                            }

                                            Rectangle {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                y: Style.dp(4)
                                                width: Style.dp(12)
                                                height: width
                                                radius: width / 2
                                                color: index === 0 ? root.categoryColor : Style.colors.pluginCardBackground
                                                border.width: 2
                                                border.color: index === 0 ? root.categoryColor : Style.colors.pluginToggleTrackOffBorder
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.bottomMargin: index < changelogRepeater.count - 1 ? Style.dp(14) : 0
                                            spacing: Style.dp(6)

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: Style.dp(8)

                                                Label {
                                                    text: "v" + (modelData.version || "")
                                                    color: Style.colors.pluginCardTitle
                                                    font.pixelSize: Style.appFont.mediumPt
                                                    font.weight: Font.DemiBold
                                                    font.family: Style.fontTypes.jetBrainsMono
                                                }

                                                Chip {
                                                    visible: index === 0
                                                    text: "Latest"
                                                    tint: root.categoryColor
                                                }

                                                Item { Layout.fillWidth: true }

                                                Label {
                                                    text: modelData.date || ""
                                                    color: Style.colors.pluginCardMetaText
                                                    font.pixelSize: Style.appFont.smallPt
                                                    font.family: Style.fontTypes.inter
                                                }
                                            }

                                            RichBody {
                                                visible: text !== ""
                                                text: root.changeNotes(modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Sidebar
                        ColumnLayout {
                            Layout.fillWidth: !root.wide
                            Layout.preferredWidth: root.wide ? Style.dp(300) : -1
                            Layout.maximumWidth: root.wide ? Style.dp(300) : -1
                            Layout.alignment: Qt.AlignTop
                            spacing: Style.dp(16)

                            SectionCard {
                                visible: root.detailRows.length > 0
                                title: "Details"

                                Repeater {
                                    model: root.detailRows

                                    delegate: ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Style.dp(10)

                                        InfoRow {
                                            iconText: modelData.icon
                                            label: modelData.label
                                            value: modelData.value
                                            mono: modelData.mono
                                        }

                                        Rectangle {
                                            visible: index < root.detailRows.length - 1
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 1
                                            color: Style.colors.pluginCardFooterBorder
                                        }
                                    }
                                }
                            }

                            SectionCard {
                                visible: root.tags.length > 0
                                title: "Tags"

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: Style.dp(6)

                                    Repeater {
                                        model: root.tags

                                        delegate: Chip {
                                            text: modelData
                                            tint: Style.colors.pluginSectionLabel
                                        }
                                    }
                                }
                            }

                            SectionCard {
                                visible: !!(root.plugin?.pluginId)
                                title: "Resources"

                                LinkButton {
                                    visible: !!(root.plugin?.githubUrl)
                                    iconText: Style.icons.globe
                                    text: "Source repository"
                                    tint: Style.colors.accent
                                    onClicked: Qt.openUrlExternally(root.plugin.githubUrl)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Style.dp(4)

                                    Label {
                                        text: "Plugin ID"
                                        color: Style.colors.pluginCardMetaText
                                        font.pixelSize: Style.appFont.captionPt
                                        font.family: Style.fontTypes.inter
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: idRow.implicitHeight + Style.dp(12)
                                        radius: Style.dp(6)
                                        color: Style.colors.pluginPageBackground
                                        border.width: 1
                                        border.color: Style.colors.pluginCardFooterBorder

                                        RowLayout {
                                            id: idRow
                                            anchors.fill: parent
                                            anchors.leftMargin: Style.dp(10)
                                            anchors.rightMargin: Style.dp(4)
                                            spacing: Style.dp(6)

                                            Label {
                                                Layout.fillWidth: true
                                                text: root.plugin?.pluginId || ""
                                                color: Style.colors.pluginCardTitle
                                                font.pixelSize: Style.appFont.smallPt
                                                font.family: Style.fontTypes.jetBrainsMono
                                                elide: Text.ElideMiddle
                                            }

                                            Button {
                                                id: copyIdButton
                                                flat: true
                                                hoverEnabled: true
                                                topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0
                                                padding: Style.dp(6)

                                                ToolTip.visible: hovered
                                                ToolTip.text: root.idCopied ? "Copied" : "Copy plugin ID"
                                                ToolTip.delay: 400

                                                background: Rectangle {
                                                    radius: Style.dp(5)
                                                    color: copyIdButton.hovered ? Style.colors.pluginSidebarRowHoverBg
                                                                                : "transparent"
                                                }

                                                contentItem: Text {
                                                    text: root.idCopied ? Style.icons.check : Style.icons.copy
                                                    font.family: Style.fontTypes.font6Pro
                                                    font.styleName: "Solid"
                                                    font.pixelSize: Style.appFont.captionPt
                                                    color: root.idCopied ? Style.colors.vibrantMint
                                                                         : Style.colors.pluginSectionLabel
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                onClicked: root.copyText(root.plugin?.pluginId || "")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    TextEdit {
        id: clipboardHelper
        visible: false
    }

    Timer {
        id: copiedResetTimer
        interval: 1600
        onTriggered: root.idCopied = false
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

    /* Functions
     * ****************************************************************************************/
    function formatCount(n) {
        if (n >= 1000000)
            return (n / 1000000).toFixed(n >= 10000000 ? 0 : 1).replace(/\.0$/, "") + "M"
        if (n >= 1000)
            return (n / 1000).toFixed(n >= 10000 ? 0 : 1).replace(/\.0$/, "") + "k"
        return String(n)
    }

    function featureTitle(f) {
        if (typeof f === "string")
            return f
        return f?.title || f?.name || f?.description || ""
    }

    function featureDescription(f) {
        if (typeof f === "string" || !(f?.title || f?.name))
            return ""
        return f?.description || ""
    }

    function changeNotes(entry) {
        let notes = entry?.notes ?? entry?.changes ?? ""
        if (Array.isArray(notes))
            return notes.map(function(n) { return "- " + n }).join("\n")
        return notes
    }

    function copyText(text) {
        if (!text)
            return
        clipboardHelper.text = text
        clipboardHelper.selectAll()
        clipboardHelper.copy()
        root.idCopied = true
        copiedResetTimer.restart()
    }

    /* Inline components
     * ****************************************************************************************/
    component SectionCard: Rectangle {
        id: card

        property string title: ""
        property string iconText: ""
        property color  tint: Style.colors.pluginSectionLabel
        property string trailing: ""
        default property alias content: cardBody.data

        Layout.fillWidth: true
        radius: Style.dp(12)
        color: Style.colors.pluginCardBackground
        border.width: 1
        border.color: Style.colors.pluginCardBorder
        implicitHeight: cardColumn.implicitHeight + Style.dp(34)

        ColumnLayout {
            id: cardColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.dp(17)
            spacing: Style.dp(14)

            RowLayout {
                visible: card.title !== ""
                Layout.fillWidth: true
                spacing: Style.dp(8)

                Text {
                    visible: card.iconText !== ""
                    text: card.iconText
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.appFont.captionPt
                    color: card.tint
                }

                Label {
                    text: card.title
                    color: Style.colors.pluginCardTitle
                    font.pixelSize: Style.appFont.h4Pt
                    font.weight: Font.DemiBold
                    font.family: Style.fontTypes.inter
                }

                Item { Layout.fillWidth: true }

                Label {
                    visible: card.trailing !== ""
                    text: card.trailing
                    color: Style.colors.pluginCardMetaText
                    font.pixelSize: Style.appFont.smallPt
                    font.family: Style.fontTypes.jetBrainsMono
                }
            }

            ColumnLayout {
                id: cardBody
                Layout.fillWidth: true
                spacing: Style.dp(10)
            }
        }
    }

    component RichBody: Label {
        Layout.fillWidth: true
        color: Style.colors.pluginCardDescription
        linkColor: Style.colors.accent
        font.pixelSize: Style.appFont.mediumPt
        font.family: Style.fontTypes.inter
        wrapMode: Text.WordWrap
        lineHeight: 1.5
        lineHeightMode: Text.ProportionalHeight
        textFormat: /(^|\n)\s*(#{1,6}\s|[-*]\s|\d+\.\s|```)|\*\*[^*]+\*\*|\[[^\]]+\]\([^)]+\)/.test(text)
                    ? Text.MarkdownText : Text.PlainText
        onLinkActivated: (link) => Qt.openUrlExternally(link)

        HoverHandler {
            cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
    }

    component Chip: Rectangle {
        id: chip

        property string text: ""
        property string iconText: ""
        property color  tint: Style.colors.accent
        property bool   mono: false

        radius: height / 2
        color: Qt.rgba(chip.tint.r, chip.tint.g, chip.tint.b, 0.10)
        border.width: 1
        border.color: Qt.rgba(chip.tint.r, chip.tint.g, chip.tint.b, 0.26)
        implicitHeight: chipRow.implicitHeight + Style.dp(6)
        implicitWidth: chipRow.implicitWidth + Style.dp(18)

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: Style.dp(5)

            Text {
                visible: chip.iconText !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: chip.iconText
                font.family: Style.fontTypes.font6Pro
                font.styleName: "Solid"
                font.pixelSize: Style.appFont.captionPt
                color: chip.tint
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.text
                color: chip.tint
                font.pixelSize: Style.appFont.smallPt
                font.weight: Font.DemiBold
                font.family: chip.mono ? Style.fontTypes.jetBrainsMono : Style.fontTypes.inter
            }
        }
    }

    component MetaItem: Row {
        id: meta

        property string iconText: ""
        property string text: ""

        spacing: Style.dp(6)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: meta.iconText
            font.family: Style.fontTypes.font6Pro
            font.styleName: "Solid"
            font.pixelSize: Style.appFont.captionPt
            color: Style.colors.pluginCardMetaText
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: meta.text
            color: Style.colors.pluginSectionLabel
            font.pixelSize: Style.appFont.smallPt
            font.family: Style.fontTypes.inter
        }
    }

    component InfoRow: RowLayout {
        id: info

        property string iconText: ""
        property string label: ""
        property string value: ""
        property bool   mono: false

        Layout.fillWidth: true
        spacing: Style.dp(10)

        Text {
            Layout.preferredWidth: Style.dp(16)
            text: info.iconText
            font.family: Style.fontTypes.font6Pro
            font.styleName: "Solid"
            font.pixelSize: Style.appFont.captionPt
            color: Style.colors.pluginCardMetaText
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            Layout.fillWidth: true
            text: info.label
            color: Style.colors.pluginCardDescription
            font.pixelSize: Style.appFont.smallPt
            font.family: Style.fontTypes.inter
        }

        Label {
            Layout.maximumWidth: info.width * 0.6
            text: info.value
            color: Style.colors.pluginCardTitle
            font.pixelSize: Style.appFont.smallPt
            font.weight: Font.DemiBold
            font.family: info.mono ? Style.fontTypes.jetBrainsMono : Style.fontTypes.inter
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }
    }

    component ActionButton: Button {
        id: btn

        property string iconText: ""
        property string label: ""
        property color  fill: Style.colors.accent
        property color  fillHover: Style.colors.accentHover
        property color  textColor: Style.colors.onAccentText
        property bool   outlined: false
        property color  hoverTint: Style.colors.accent

        readonly property color foreground: btn.outlined && btn.hovered && btn.enabled ? btn.hoverTint
                                                                                        : btn.textColor

        hoverEnabled: true
        topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0
        topPadding: Style.dp(9); bottomPadding: Style.dp(9)
        leftPadding: Style.dp(16); rightPadding: Style.dp(16)
        opacity: btn.enabled ? 1.0 : 0.55

        background: Rectangle {
            radius: Style.dp(8)
            color: btn.outlined
                   ? (btn.hovered && btn.enabled ? Qt.rgba(btn.hoverTint.r, btn.hoverTint.g, btn.hoverTint.b, 0.10)
                                                 : "transparent")
                   : (!btn.enabled ? Style.colors.disabledButton
                                   : (btn.hovered ? btn.fillHover : btn.fill))
            border.width: btn.outlined ? 1 : 0
            border.color: btn.outlined && btn.hovered && btn.enabled ? btn.hoverTint
                                                                     : Style.colors.pluginBtnSecondaryBorder
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        contentItem: Row {
            spacing: Style.dp(8)

            Text {
                visible: btn.iconText !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: btn.iconText
                font.family: Style.fontTypes.font6Pro
                font.styleName: "Solid"
                font.pixelSize: Style.appFont.captionPt
                color: btn.foreground
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.label
                color: btn.foreground
                font.pixelSize: Style.appFont.mediumPt
                font.weight: Font.DemiBold
                font.family: Style.fontTypes.inter
            }
        }
    }

    component LinkButton: Item {
        id: link

        property string text: ""
        property string iconText: ""
        property color  tint: Style.colors.accent
        signal clicked()

        implicitWidth: linkRow.implicitWidth
        implicitHeight: linkRow.implicitHeight + Style.dp(4)

        Row {
            id: linkRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.dp(7)

            Text {
                visible: link.iconText !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: link.iconText
                font.family: Style.fontTypes.font6Pro
                font.styleName: "Solid"
                font.pixelSize: Style.appFont.captionPt
                color: link.tint
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: link.text
                color: link.tint
                font.pixelSize: Style.appFont.smallPt
                font.weight: Font.Medium
                font.family: Style.fontTypes.inter
                font.underline: linkHover.hovered
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Style.icons.arrowRight
                font.family: Style.fontTypes.font6Pro
                font.styleName: "Solid"
                font.pixelSize: Style.appFont.microPt
                color: link.tint
            }
        }

        HoverHandler { id: linkHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: link.clicked() }
    }

    component TabItem: Item {
        id: tab

        property string label: ""
        property int    count: -1
        property bool   active: false
        property color  tint: Style.colors.accent
        signal clicked()

        implicitWidth: tabRow.implicitWidth
        implicitHeight: tabRow.implicitHeight + Style.dp(22)

        Row {
            id: tabRow
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
            spacing: Style.dp(7)

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: tab.label
                color: tab.active || tabHover.hovered ? Style.colors.pluginCardTitle
                                                      : Style.colors.pluginSectionLabel
                font.pixelSize: Style.appFont.mediumPt
                font.weight: tab.active ? Font.DemiBold : Font.Medium
                font.family: Style.fontTypes.inter
            }

            Rectangle {
                visible: tab.count > 0
                anchors.verticalCenter: parent.verticalCenter
                radius: height / 2
                color: tab.active ? Qt.rgba(tab.tint.r, tab.tint.g, tab.tint.b, 0.14)
                                  : Style.colors.pluginCountPillBackground
                implicitWidth: Math.max(implicitHeight, countLabel.implicitWidth + Style.dp(12))
                implicitHeight: countLabel.implicitHeight + Style.dp(4)

                Label {
                    id: countLabel
                    anchors.centerIn: parent
                    text: tab.count
                    color: tab.active ? tab.tint : Style.colors.pluginCountPillText
                    font.pixelSize: Style.appFont.captionPt
                    font.weight: Font.DemiBold
                    font.family: Style.fontTypes.inter
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 2
            radius: 1
            color: tab.tint
            opacity: tab.active ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 140 } }
        }

        HoverHandler { id: tabHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: tab.clicked() }
    }

    component GalleryArrow: Button {
        id: arrow

        property string iconText: ""

        width: Style.dp(34)
        height: Style.dp(34)
        hoverEnabled: true
        opacity: arrow.hovered ? 1.0 : 0.85

        background: Rectangle {
            radius: width / 2
            color: arrow.hovered ? Qt.rgba(0, 0, 0, 0.65) : Qt.rgba(0, 0, 0, 0.45)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.18)
        }

        contentItem: Text {
            text: arrow.iconText
            font.family: Style.fontTypes.font6Pro
            font.styleName: "Solid"
            font.pixelSize: Style.appFont.captionPt
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
