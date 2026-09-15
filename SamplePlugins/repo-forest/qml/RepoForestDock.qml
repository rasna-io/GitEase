import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style_Impl
import GitEase_Style
import GitEase
import GitEaseRepoForest
import "qrc:/GitEase/Qml/View/Popups"

/*! ***********************************************************************************************
 * RepoForestDock
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

    /* Object Properties
     * ****************************************************************************************/
    title: "Repo Forest"
    icon: Style.icons.tree

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
                        targetProvider: function() { return actionBtn },
                        icon: Style.icons.folder,
                        title: "Browse a Root Folder",
                        description: "Pick a parent directory and GitEase discovers every git repository inside it, so you can fetch or pull across all of them at once."
                    }
                ]
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: infoRow.implicitHeight + 20
            radius: 6
            color: Style.colors.secondaryBackground
            border.width: 1
            border.color: Style.colors.secondaryBorder

            RowLayout {
                id: infoRow
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                Text {
                    text: Style.icons.info
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: 16
                    color: Style.colors.mutedText
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        text: "This tool helps you manage multiple repositories from a single root directory."
                        font.pixelSize: 13
                        color: Style.colors.mutedText
                        font.family: Style.fontTypes.inter
                        wrapMode: Text.WordWrap
                    }

                    // features
                    Text {
                        text:
                            "• Automatically discover all repositories\n" +
                            "• Fetch updates for all or selected repositorie\n" +
                            "• Pull changes for all or selected repositories"
                        font.pixelSize: 10
                        color: Style.colors.mutedText
                        font.family: Style.fontTypes.inter
                        lineHeight: 1.1
                    }
                }
            }
        }

        Button {
            id: actionBtn
            Layout.fillWidth: true
            implicitHeight: 44

            background: Rectangle {
                radius: 8
                color: actionBtn.enabled ? (actionBtn.hovered) ? Style.colors.accentHover : Style.colors.accent
                                            : (Style.colors.disabledButton)
            }

            contentItem: Item {
                anchors.fill: parent
                Row {
                    spacing: 10
                    anchors.centerIn: parent

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Style.icons.folder
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: 12
                        color: Style.colors.textButton
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Browse"
                        color: Style.colors.textButton
                        font.pixelSize: 13
                    }
                }
            }

            onClicked: folderDialog.open()
        }

        FolderDialog {
            id: folderDialog
            title: "Select Root Directory"

            onAccepted: {
                var selectedFolder = folderDialog.selectedFolder
                if (selectedFolder) {
                    var folderPath = selectedFolder.toString()
                    let path = root.repositoryController.appModel.fileIO.pathNormalizer(folderPath);

                    repoForestPopup.rootPath = path
                    repoForestPopup.open()
                }
            }
        }
    }

    IPopup {
        id: repoForestPopup

        property string rootPath
        property GitScanner gitScanner: GitScanner {}

        width: 800
        height: 650
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

        onAboutToHide: resetRepoForest()
        onClosed: resetRepoForest()

        function resetRepoForest() {
            repoForest.reposModel = []
            repoForest.pat = ""
            repoForest.pendingOperation = ""
            repoForest.selectedIndexes = []
            repoForest.isRunning = false
            repoForest.operationQueue = []
            repoForest.queueState = RepoForest.QueueState.Ready
            repoForestPopup.gitScanner.stop()
        }
    }

    /* Functions
     * ****************************************************************************************/
}
