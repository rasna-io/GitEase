import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style_Impl
import GitEase_Style
import GitEase

/*! ***********************************************************************************************
 * RepositoriesHistoryDock
 * ************************************************************************************************/

UtilitiesCard {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property RepositoryController repositoryController: null
    property GuideController      guideController:      null

    /* Object Properties
     * ****************************************************************************************/
    title: "Repositories History"
    icon: Style.icons.clock

    /* Children
     * ****************************************************************************************/
    content: ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 8

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "repositories_history_tutorial"
            guideName: "Repositories History"
            guideIcon: Style.icons.clock
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return scrollView },
                        icon: Style.icons.clock,
                        title: "Recently Opened",
                        description: "Every repository you've opened is listed here, even after restarting GitEase. Click one to reopen it instantly."
                    },
                    {
                        targetProvider: function() { return actionBtn },
                        icon: Style.icons.trash,
                        title: "Clear History",
                        description: "Removes every entry from this list. This only clears the list — it doesn't touch your actual repositories on disk."
                    }
                ]
            }
        }

        ListView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            model: root.repositoryController.appModel.repositoriesHistory
            delegate: RepositoryListItem {
                id: item
                implicitWidth: parent.width
                implicitHeight: 50
                name: modelData.split('/').pop() || modelData.split('\\').pop()
                path: modelData
                isExists: root.repositoryController.appModel.fileIO.isFileExist(modelData)
                onClicked: {
                    root.repositoryController.openRepository(item.path)
                }
            }

            onContentHeightChanged: root.pageScrollBlocking = scrollView.contentHeight > scrollView.height + 1
        }

        Button {
            id: actionBtn
            Layout.fillWidth: true
            implicitHeight: 44

            enabled: root.repositoryController.appModel.repositoriesHistory.length > 0

            background: Rectangle {
                radius: 8
                color: actionBtn.enabled ? Style.colors.error : (Style.colors.disabledButton)
            }

            contentItem: Item {
                anchors.fill: parent
                Row {
                    spacing: 10
                    anchors.centerIn: parent

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Style.icons.trash
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: Style.appFont.mediumPt
                        color: Style.colors.selectedText
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Clear history"
                        color: Style.colors.selectedText
                        font.pixelSize: Style.appFont.h3Pt
                    }
                }
            }

            onClicked: {
                root.repositoryController.appModel.repositoriesHistory = []
                root.repositoryController.appModel.recentRepositories = []
                root.repositoryController.appModel.save()
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
}
