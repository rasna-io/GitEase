import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style_Impl
import GitEase_Style
import GitEase

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
    property RepoForestPopup      repoForestPopup:      null

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

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 6
            color: Style.colors.secondaryBackground
            border.width: 1
            border.color: Style.colors.secondaryBorder

            RowLayout {
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
                        font.family: Style.fontTypes.roboto
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
                        font.family: Style.fontTypes.roboto
                        lineHeight: 1.1
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
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

                    repoForestPopup.repositoryController = root.repositoryController
                    repoForestPopup.branchController = root.branchController
                    repoForestPopup.remoteController = root.remoteController
                    repoForestPopup.rootPath = path
                    repoForestPopup.open()
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
}
