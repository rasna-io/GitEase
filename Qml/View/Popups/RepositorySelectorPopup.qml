import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * RepositorySelectorPopup
 * ************************************************************************************************/
IPopup {
    id: root
    

    /* Property Declarations
     * ****************************************************************************************/
    property RepositoryController   repositoryController
    property NotificationController notificationController
    property AppModel               appModel
    property var                    recentRepositories

    property bool                   busy: false
    property real                   progress: 0

    property int                    currentTabIndex: Enums.RepositorySelectorTab.Recents

    /* Object Properties
     * ****************************************************************************************/
    width: 600
    height: Math.min(720, bodyColumn.implicitHeight)

    Behavior on height {
        NumberAnimation {
            duration: 170
            easing.type: Easing.OutCubic
        }
    }

    onClosed: root.reset()
    onCurrentTabIndexChanged: root.reset()

    onOpened: {
        root.currentTabIndex = Enums.RepositorySelectorTab.Recents
        recentsTab.selectedPath = root.appModel?.currentRepository?.path ?? ""
    }

    Overlay.modal: Rectangle {
        color: "#000000"
        opacity: 0.85
    }

    /* Functions
     * ****************************************************************************************/
    function primaryLabel() {
        switch (root.currentTabIndex) {
            case Enums.RepositorySelectorTab.Clone:
                return "Clone →"
            case Enums.RepositorySelectorTab.Init:
                return "Create →"
            default:
                return "Open →"
        }
    }

    function primaryEnabled() {
        if (root.busy)
            return false

        switch (root.currentTabIndex) {
            case Enums.RepositorySelectorTab.Recents:
                return recentsTab.selectedPath !== ""
            case Enums.RepositorySelectorTab.Open:
                return openTab.selectedPath !== ""
            case Enums.RepositorySelectorTab.Clone:
                return cloneTab.url !== "" && cloneTab.toPath !== ""
            case Enums.RepositorySelectorTab.Init:
                return initTab.location !== "" && initTab.name !== ""
            default:
                return false   // Worktrees is UI only.
        }
    }

    function submit() {
        switch (root.currentTabIndex) {
            case Enums.RepositorySelectorTab.Recents:
            case Enums.RepositorySelectorTab.Open: {
                let path = root.currentTabIndex === Enums.RepositorySelectorTab.Recents
                         ? recentsTab.selectedPath : openTab.selectedPath
                let ok = root.repositoryController.openRepository(path)
                if (!ok)
                    root.notificationController.error(`can't open ${path}, The .git directory is missing, corrupted, or not a valid repository.`, "Repository open failed", 5000)
                return ok
            }
            case Enums.RepositorySelectorTab.Clone: {
                let res = root.repositoryController.cloneRepository(cloneTab.toPath, cloneTab.url)
                root.busy = res.success
                if (!res.success && res.errorMessage)
                    root.notificationController.error(`can't clone ${cloneTab.url}, ${res.errorMessage}`, "Repository clone failed", 5000)
                return false
            }
            case Enums.RepositorySelectorTab.Init: {
                let path = initTab.location
                if (path && path.slice(-1) !== "/")
                    path += "/"
                path += initTab.name
                let ok = root.repositoryController.gitInit(path)
                if (!ok)
                    root.notificationController.error(`can't create repository at ${path}`, "Init failed", 5000)
                return ok
            }
            default:
                return false
        }
    }

    function reset() {
        root.busy = false
        root.progress = 0
        recentsTab.reset()
        openTab.reset()
        cloneTab.reset()
        initTab.reset()
    }

    /* Clone progress wiring
     * ****************************************************************************************/
    Connections {
        target: root.repositoryController

        function onCloneFinished(res) {
            if (!res.success)
                root.notificationController.error(`can't clone ${cloneTab.url}, ${res.error}`, "Repository clone failed", 5000)
            root.busy = false
            root.progress = 0
            if (res.success)
                root.close()
        }

        function onCloneProgress(p) {
            root.progress = p
        }
    }

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 12
        clip: true
        border.color: Style.colors.primaryBorder
        border.width: 1

        ColumnLayout {
            id: bodyColumn
            anchors.fill: parent
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 50

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Open a Repository"
                    font.family: Style.fontTypes.inter
                    font.weight: Font.DemiBold
                    font.pixelSize: 15
                    color: Style.colors.foreground
                }

                WindowsButton {
                    id: closeButton
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root.close()
                    Material.accent: Style.colors.windowsClose
                    content: Item {
                        anchors.centerIn: parent
                        width: 10
                        height: 10

                        Rectangle {
                            width: 12
                            height: 2
                            radius: 1
                            color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                            anchors.centerIn: parent
                            rotation: 45
                        }

                        Rectangle {
                            width: 12
                            height: 2
                            radius: 1
                            color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                            anchors.centerIn: parent
                            rotation: -45
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.primaryBorder
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 42

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 22

                    Repeater {
                        // TODO: Worktrees and Init new are hidden until their backend is implemented.
                        model: [
                            { title: "Recents",    icon: Style.icons.clock,      index: Enums.RepositorySelectorTab.Recents,   shown: true },
                            { title: "Open local", icon: Style.icons.laptop,     index: Enums.RepositorySelectorTab.Open,      shown: true },
                            { title: "Clone",      icon: Style.icons.download,   index: Enums.RepositorySelectorTab.Clone,     shown: true },
                            { title: "Worktrees",  icon: Style.icons.gitBranch,  index: Enums.RepositorySelectorTab.Worktrees, shown: false },
                            { title: "Init new",   icon: Style.icons.file,       index: Enums.RepositorySelectorTab.Init,      shown: false }
                        ]

                        Item {
                            id: tabDelegate
                            width: tabContent.width
                            height: 42
                            visible: modelData.shown

                            readonly property bool active: root.currentTabIndex === modelData.index

                            Row {
                                id: tabContent
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    font.family: Style.fontTypes.font6Pro
                                    font.pixelSize: 11
                                    color: tabDelegate.active ? Style.colors.accent
                                                              : (tabMouse.containsMouse ? Style.colors.foreground : Style.colors.mutedText)
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.title
                                    font.family: Style.fontTypes.inter
                                    font.weight: tabDelegate.active ? Font.DemiBold : Font.Normal
                                    font.pixelSize: 12
                                    color: tabDelegate.active ? Style.colors.accent
                                                              : (tabMouse.containsMouse ? Style.colors.foreground : Style.colors.mutedText)
                                }
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 2
                                radius: 1
                                color: Style.colors.accent
                                visible: tabDelegate.active
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentTabIndex = modelData.index
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.primaryBorder
            }

            StackLayout {
                id: stack
                Layout.fillWidth: true
                Layout.preferredHeight: {
                    var items = stack.children
                    var idx = root.currentTabIndex
                    return (idx >= 0 && idx < items.length && items[idx]) ? items[idx].implicitHeight : 300
                }
                currentIndex: root.currentTabIndex

                RecentsTab {
                    id: recentsTab
                    repositoryController: root.repositoryController
                    recentRepositories: root.recentRepositories
                    onAccepted: {
                        if (root.submit())
                            root.close()
                    }
                }

                OpenLocalTab {
                    id: openTab
                    appModel: root.appModel
                }

                CloneTab {
                    id: cloneTab
                    appModel: root.appModel
                }

                // TODO: unreachable while the Worktrees tab is hidden; kept so the stack
                //       indices stay aligned with Enums.RepositorySelectorTab.
                WorktreesTab {
                    id: worktreesTab
                    appModel: root.appModel
                }

                // TODO: unreachable while the Init new tab is hidden; kept so the stack
                //       indices stay aligned with Enums.RepositorySelectorTab.
                InitNewTab {
                    id: initTab
                    appModel: root.appModel
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.primaryBorder
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 54

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Button {
                        id: cancelButton
                        width: 84
                        height: 43
                        flat: true
                        text: "Cancel"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: 12

                        background: Rectangle {
                            radius: 6
                            color: cancelButton.hovered ? Style.colors.controlBackgroundHover : "transparent"
                            border.width: 1
                            border.color: Style.colors.controlBorder
                        }

                        contentItem: Text {
                            text: cancelButton.text
                            font: cancelButton.font
                            color: Style.colors.foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: root.close()
                    }

                    ProgressButton {
                        id: primaryButton
                        width: 116
                        height: 43
                        flat: false
                        Material.background: Style.colors.accent
                        Material.foreground: "white"
                        progress: root.progress
                        busy: root.busy
                        enabled: root.primaryEnabled()
                        idleText: root.busy ? (root.progress + " %") : root.primaryLabel()

                        background: Rectangle {
                            radius: 6
                            color: primaryButton.enabled
                                   ? (primaryButton.hovered ? Style.colors.accentHover : Style.colors.accent)
                                   : Style.colors.disabledButton

                            Rectangle {
                                anchors.fill: parent
                                visible: primaryButton.busy
                                radius: 6
                                color: "#CCCCCC"

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: parent.width * (primaryButton.progress / 100.0)
                                    radius: 6
                                    color: Style.colors.accent
                                    Behavior on width { NumberAnimation { duration: 100 } }
                                }
                            }
                        }

                        onClicked: {
                            if (root.submit())
                                root.close()
                        }
                    }
                }
            }
        }
    }
}
