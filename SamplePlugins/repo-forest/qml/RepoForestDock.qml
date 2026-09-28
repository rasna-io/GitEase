import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style_Impl
import GitEase_Style
import GitEase
import GitEaseRepoForest

/*! ***********************************************************************************************
 * RepoForestDock
 * Utility card that opens Repo Forest on a chosen root folder and remembers recent roots.
 * ************************************************************************************************/

UtilitiesCard {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property RepositoryController repositoryController: null
    property BranchController     branchController:     null
    property RemoteController     remoteController:     null
    property UserAuthenticationPopup userAuthenticationPopup: null
    property var                  pluginManager:        null
    property string               pluginId:             "com.gitease.repo-forest"
    property GuideController      guideController:      null

    property var                  recentRoots:          []

    readonly property int         maxRecentRoots:       5

    /* Object Properties
     * ****************************************************************************************/
    title: "Repo Forest"
    icon: Style.icons.tree
    badgeCount: recentRoots.length

    onPluginManagerChanged: loadRecentRoots()
    Component.onCompleted: loadRecentRoots()

    /* Functions
     * ****************************************************************************************/
    function loadRecentRoots() {
        if (!root.pluginManager)
            return
        try {
            const saved = JSON.parse(root.pluginManager.pluginSetting(root.pluginId, "recentRoots", "[]") || "[]")
            root.recentRoots = Array.isArray(saved) ? saved.filter(p => typeof p === "string" && p.length > 0) : []
        } catch (e) {
            root.recentRoots = []
        }
    }

    function saveRecentRoots(list) {
        root.recentRoots = list
        if (root.pluginManager)
            root.pluginManager.setPluginSetting(root.pluginId, "recentRoots", JSON.stringify(list))
    }

    function removeRecentRoot(path) {
        root.saveRecentRoots(root.recentRoots.filter(p => p !== path))
    }

    function openRoot(path) {
        if (!path)
            return
        root.saveRecentRoots([path].concat(root.recentRoots.filter(p => p !== path)).slice(0, root.maxRecentRoots))
        repoForestPopup.rootPath = path
        repoForestPopup.open()
    }

    function pathExists(path) {
        return root.repositoryController ? root.repositoryController.appModel.fileIO.isFileExist(path) : true
    }

    /* Children
     * ****************************************************************************************/
    content: ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 8

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "repo_forest_tutorial"
            guideName: "Repo Forest"
            guideIcon: Style.icons.tree
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return root },
                        icon: Style.icons.tree,
                        title: "Repo Forest Dock",
                        description: "Manage multiple git repositories from a single parent folder. Click the header to expand this dock if it's collapsed.",
                        isInPopup: false,
                        activationDelay: 300,
                        onActivate: function() { root.collapsed = false }
                    },
                    {
                        targetProvider: function() { return actionBtn },
                        icon: Style.icons.folder,
                        title: "Choose a Root Folder",
                        description: "Pick a parent directory and GitEase discovers every git repository inside it, so you can fetch or pull across all of them at once. Recently used folders stay listed here for one-click access."
                    }
                ]
            }
        }

        // ── Intro ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: introRow.implicitHeight + Style.dp(20)
            radius: 8
            color: Style.colors.utilitiesSurfaceBackground
            border.width: 1
            border.color: Style.colors.utilitiesSurfaceBorder

            RowLayout {
                id: introRow
                anchors.fill: parent
                anchors.margins: Style.dp(10)
                spacing: Style.dp(10)

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: Style.dp(30)
                    Layout.preferredHeight: Style.dp(30)
                    radius: 7
                    color: Style.colors.accentWash

                    Text {
                        anchors.centerIn: parent
                        text: Style.icons.tree
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: Style.appFont.defaultPt
                        color: Style.colors.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.dp(4)

                    Text {
                        Layout.fillWidth: true
                        text: "Fetch & pull many repositories at once"
                        wrapMode: Text.WordWrap
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.smallPt
                        font.weight: Font.DemiBold
                        color: Style.colors.utilitiesRowText
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Choose a parent folder. Every Git repository inside it is discovered and can be fetched or fast-forwarded in one go."
                        wrapMode: Text.WordWrap
                        lineHeight: 1.15
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.utilitiesRowMetaText
                    }

                    Flow {
                        Layout.fillWidth: true
                        Layout.topMargin: Style.dp(2)
                        spacing: Style.dp(6)

                        Repeater {
                            model: [
                                { icon: Style.icons.search,    label: "Discover" },
                                { icon: Style.icons.download,  label: "Fetch" },
                                { icon: Style.icons.arrowDown, label: "Pull" }
                            ]

                            delegate: Rectangle {
                                required property var modelData

                                height: Style.dp(20)
                                width: chipRow.implicitWidth + Style.dp(14)
                                radius: height / 2
                                color: Style.colors.utilitiesRowBackground
                                border.width: 1
                                border.color: Style.colors.utilitiesRowBorder

                                Row {
                                    id: chipRow
                                    anchors.centerIn: parent
                                    spacing: Style.dp(5)

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.icon
                                        font.family: Style.fontTypes.font6Pro
                                        font.pixelSize: Style.appFont.microPt
                                        color: Style.colors.utilitiesRowIconAccent
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        font.family: Style.fontTypes.inter
                                        font.pixelSize: Style.appFont.microPt
                                        font.weight: Font.Medium
                                        color: Style.colors.utilitiesRowMetaText
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Recent folders ─────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Style.dp(2)
            visible: root.recentRoots.length > 0
            spacing: Style.dp(6)

            Text {
                Layout.fillWidth: true
                text: "RECENT FOLDERS"
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.microPt
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
                color: Style.colors.utilitiesRowMetaText
            }

            Text {
                text: "Clear"
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.microPt
                font.underline: clearHover.hovered
                color: clearHover.hovered ? Style.colors.error : Style.colors.utilitiesRowSubText

                HoverHandler {
                    id: clearHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.saveRecentRoots([])
                }
            }
        }

        ListView {
            id: recentList
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            visible: root.recentRoots.length > 0
            interactive: false
            spacing: Style.dp(4)
            model: root.recentRoots

            delegate: Item {
                id: recentRow

                required property int    index
                required property string modelData

                readonly property bool exists: root.pathExists(modelData)

                width: ListView.view.width
                height: Style.dp(38)

                RepositoryListItem {
                    anchors.fill: parent
                    index: recentRow.index
                    modelData: ({ name: "", path: "" })
                    radius: 6
                    border.width: 1
                    border.color: Style.colors.utilitiesRowBorder

                    backgroundColor:      Style.colors.utilitiesRowBackground
                    hoverBackgroundColor: Style.colors.utilitiesRowHoverBackground
                    nameColor:            Style.colors.utilitiesRowText
                    pathColor:            Style.colors.utilitiesRowSubText
                    missingPathColor:     Style.colors.utilitiesRowMissingText

                    name: recentRow.modelData.split('/').pop() || recentRow.modelData
                    path: recentRow.modelData
                    isExists: recentRow.exists

                    onClicked: root.openRoot(recentRow.modelData)
                }

                ActionIconButton {
                    anchors.right: parent.right
                    anchors.rightMargin: Style.dp(6)
                    anchors.verticalCenter: parent.verticalCenter
                    iconText: Style.icons.close
                    tooltip: "Remove from recent folders"
                    backgroundColor: Style.colors.utilitiesRowBackground
                    textColor: Style.colors.utilitiesRowIcon
                    onClicked: root.removeRecentRoot(recentRow.modelData)
                }
            }
        }

        DashedButton {
            id: actionBtn
            Layout.fillWidth: true
            Layout.topMargin: Style.dp(2)

            iconText: Style.icons.folder
            text: root.recentRoots.length > 0 ? "Choose another folder" : "Choose root folder"

            textColor: actionBtn.hovered ? Style.colors.accent : Style.colors.dashedButtonText
            borderColor: actionBtn.hovered ? Style.colors.accent : Style.colors.dashedButtonBorder

            onClicked: folderDialog.open()
        }

        FolderDialog {
            id: folderDialog
            title: "Select Root Directory"

            onAccepted: {
                if (folderDialog.selectedFolder)
                    root.openRoot(root.repositoryController.appModel.fileIO.pathNormalizer(folderDialog.selectedFolder.toString()))
            }
        }
    }

    IPopup {
        id: repoForestPopup

        property string rootPath
        property GitScanner gitScanner: GitScanner {}

        width: 820
        height: 660
        padding: 12

        contentItem: RepoForest {
            id: repoForest
            repositoryController: root.repositoryController
            branchController: root.branchController
            remoteController: root.remoteController
            userAuthenticationPopup: root.userAuthenticationPopup
            rootPath: repoForestPopup.rootPath
            guideController: root.guideController
            gitScanner: repoForestPopup.gitScanner

            onCloseRequested: repoForestPopup.close()
        }

        onClosed: {
            repoForestPopup.gitScanner.stop()
            repoForest.reset()
        }
    }
}
