import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * RepositorySelector
 * Reusable repository selector with tabs (Recents, Open, Clone)
 * Can be used in welcome flow or elsewhere
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property RepositoryController repositoryController

    property NotificationController notificationController

    property FileIO               fileIO

    property var recentRepositories

    property alias currentTabIndex: stackLayout.currentIndex

    property bool showDescription: true

    property string descriptionText: "Choose how you want to get started with your Git repository"

    property string selectedPath: ""

    property string selectedUrl: ""

    property bool busy: false

    property real progress: 0

    property string defaultPath: ""



    /* Signals
     * ****************************************************************************************/
    signal cloneFinished(var result)

    /* Children
     * ****************************************************************************************/

    onCurrentTabIndexChanged: {
        reset()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Description text
        Text {
            visible: root.showDescription
            Layout.fillWidth: true
            Layout.bottomMargin: 14
            Layout.topMargin: 4
            Layout.alignment: Qt.AlignHCenter
            text: root.descriptionText
            wrapMode: Text.WordWrap
            font.pixelSize: Style.appFont.defaultPt
            color: Style.colors.mutedText
            horizontalAlignment: Text.AlignHCenter
            font.family: Style.fontTypes.inter
            font.weight: 400
            font.letterSpacing: 0.1
            Layout.maximumWidth: 450
        }

        // Segmented tab bar
        Rectangle {
            Layout.fillWidth: true
            Layout.maximumWidth: 500
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 42
            color: "transparent"

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 22

                Repeater {
                    model: [
                        { title: "Recents",  icon: Style.icons.clock,    index: 0, shown: true },
                        { title: "Open",     icon: Style.icons.laptop,   index: 1, shown: true },
                        { title: "Clone",    icon: Style.icons.download, index: 2, shown: true }
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
            Layout.maximumWidth: 500
            Layout.alignment: Qt.AlignHCenter
            color: Style.colors.primaryBorder
        }

        // Tab content
        StackLayout {
            id: stackLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumWidth: 500
            Layout.alignment: Qt.AlignHCenter
            currentIndex: 0

            onCurrentIndexChanged: root.currentTabIndexChanged()

            // Recents tab
            RecentsTab {
                id: recentsTab
                repositoryController: root.repositoryController
                recentRepositories: root.recentRepositories
                onAccepted: root.selectedPath = Qt.binding(function() {
                    return recentsTab.selectedPath
                })
            }

            // Open local tab
            OpenLocalTab {
                id: openLocalTab
                appModel: root.repositoryController ? root.repositoryController.appModel : null
            }

            // Clone tab
            CloneTab {
                id: cloneTab
                appModel: root.repositoryController ? root.repositoryController.appModel : null
            }
        }

        Connections {
            target: recentsTab
            function onSelectedPathChanged() {
                root.selectedPath = Qt.binding(function() {
                    return recentsTab.selectedPath
                })

                root.selectedUrl = ""
            }
        }

        Connections {
            target: openLocalTab
            function onSelectedPathChanged() {
                root.selectedPath = Qt.binding(function() {
                    return openLocalTab.selectedPath
                })

                root.selectedUrl = ""
            }
        }

        Connections {
            target: cloneTab
            function onUrlChanged() {
                if (cloneTab.url !== "") {
                    root.selectedUrl = Qt.binding(function() {
                        return cloneTab.url
                    })

                    root.selectedPath = Qt.binding(function() {
                        return cloneTab.toPath
                    })
                }
            }

            function onToPathChanged() {
                if (cloneTab.url !== "") {
                    root.selectedPath = Qt.binding(function() {
                        return cloneTab.toPath
                    })
                }
            }
        }
    }


    Connections {
        target: root.repositoryController

        function onCloneCompleted(res) {
            if (res && res.stale === true)
                notificationController.info("Clone finished while you were switching repository", "Clone", 4000)
            else if(!res.success)
                notificationController.error(`can't clone ${root.selectedUrl}, ${res.errorMessage}`, ` Repository clone failed`, 5000)

            root.busy = false
            root.progress = 0
            root.cloneFinished(res)
        }

        function onCloneProgress (progress){
            root.progress = progress
        }
    }


    function submit() {
        switch(root.currentTabIndex) {
            case Enums.RepositorySelectorTab.Recents:
            case Enums.RepositorySelectorTab.Open:
                let result = root.repositoryController.openRepository(root.selectedPath)

                if(!result)
                    notificationController.error(`can't open ${root.selectedPath}, The .git directory is missing, corrupted, or not a valid repository.`, ` Repository open failed`, 5000)

                return result

            case Enums.RepositorySelectorTab.Clone: {
                let res = root.repositoryController.cloneRepository(root.selectedPath, root.selectedUrl)
                root.busy = res.success

                if (!res.success && res.errorMessage) {
                    notificationController.error(`can't clone ${root.selectedUrl}, ${res.errorMessage}`, ` Repository clone failed`, 5000)
                }

                return false;
            }

            default:
                return false;
        }
    }

    function reset() {
        root.busy = false
        root.progress = 0
        root.selectedPath = ""
        root.selectedUrl = ""
        recentsTab.reset()
        openLocalTab.reset()
        cloneTab.reset()
    }
}

