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
        anchors.leftMargin: Style.dp(10)
        anchors.rightMargin: Style.dp(10)
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
                        targetProvider: function() { return root },
                        icon: Style.icons.clock,
                        title: "Repositories History Dock",
                        description: "Quickly reopen recently accessed repositories. Click the header to expand this dock if it's collapsed.",
                        isInPopup: false,
                        activationDelay: 300,
                        onActivate: function() { root.collapsed = false }
                    },
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
                border.width: 1
                border.color: Style.colors.utilitiesRowBorder

                backgroundColor:      Style.colors.utilitiesRowBackground
                hoverBackgroundColor: Style.colors.utilitiesRowHoverBackground
                nameColor:            Style.colors.utilitiesRowText
                pathColor:            Style.colors.utilitiesRowSubText
                missingPathColor:     Style.colors.utilitiesRowMissingText

                name: modelData.split('/').pop() || modelData.split('\\').pop()
                path: modelData
                isExists: root.repositoryController.appModel.fileIO.isFileExist(modelData)
                onClicked: {
                    root.repositoryController.openRepository(item.path)
                }
            }

            onContentHeightChanged: root.pageScrollBlocking = scrollView.contentHeight > scrollView.height + 1
        }

        DashedButton {
            id: actionBtn
            Layout.fillWidth: true
            Layout.topMargin: Style.dp(2)

            enabled: root.repositoryController.appModel.repositoriesHistory.length > 0

            iconText: Style.icons.trash
            text: "Clear history"

            textColor: actionBtn.hovered && actionBtn.enabled ? Style.colors.dashedButtonTextDanger
                                                              : Style.colors.dashedButtonText
            borderColor: actionBtn.hovered && actionBtn.enabled ? Style.colors.dashedButtonBorderDanger
                                                                : Style.colors.dashedButtonBorder

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
