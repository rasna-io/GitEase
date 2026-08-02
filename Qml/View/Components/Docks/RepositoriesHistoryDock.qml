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
    badgeCount: repositoryController ? repositoryController.appModel.repositoriesHistory.length : 0

    /* Children
     * ****************************************************************************************/
    content: ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 6

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
            Layout.preferredHeight: Math.min(contentHeight, 220)
            clip: true
            spacing: Style.dp(2)

            model: root.repositoryController.appModel.repositoriesHistory
            delegate: RepositoryListItem {
                id: item
                implicitWidth: parent.width
                implicitHeight: Style.dp(35)
                name: modelData.split('/').pop() || modelData.split('\\').pop()
                path: modelData
                isExists: root.repositoryController.appModel.fileIO.isFileExist(modelData)
                onClicked: {
                    root.repositoryController.openRepository(item.path)
                }
            }

            onContentHeightChanged: root.pageScrollBlocking = scrollView.contentHeight > scrollView.height + 1
        }

        IconButton {
            id: actionBtn
            Layout.fillWidth: true
            implicitHeight: Style.dp(25)

            enabled: root.repositoryController.appModel.repositoriesHistory.length > 0

            display: IconButton.TextBesideIcon
            icon.name: Style.icons.trash
            icon.width: Style.appFont.smallPt
            icon.height: Style.appFont.smallPt
            icon.color: Style.colors.selectedText
            text: "Clear history"
            font.pixelSize: Style.appFont.mediumPt

            background: Rectangle {
                radius: Style.dp(4)
                color: actionBtn.enabled ? Style.colors.error : Style.colors.disabledButton
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
