import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RepoItem
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property       int     index
    required property       var     modelData
    property                bool    isSelected: false

    /* Signals
     * ****************************************************************************************/
    signal clicked(index: int)
    signal fetchRequested(index: int)
    signal pullRequested(index: int)

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.preferredHeight: 70
    color: {
        if (msa.hovered) {
                return Qt.darker(Style.colors.surfaceLight, 1.05)
        } else {
            if (isSelected)
                return Style.colors.repoSelectectedItem
            else
                return Style.colors.secondaryBackground
        }
    }
    radius: 3

    /* Children
     * ****************************************************************************************/
    RowLayout {
        anchors.fill: parent
        spacing: 5

        Rectangle {
            Layout.preferredWidth: 3
            Layout.fillHeight: true
            Layout.margins: 7
            radius: 100
            color: root.isSelected ? Style.colors.accent : Style.colors.disabledButton
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 15
            Layout.topMargin: 5
            Layout.rightMargin: 15
            Layout.bottomMargin: 5
            spacing: 5

            // Name row
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: root.modelData.name
                    font.pixelSize: 12
                    font.family: Style.fontTypes.roboto
                    font.weight: 400
                    font.letterSpacing: 0
                    color: Style.colors.foreground
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: status
                    property color statusTextColor: {
                        switch(root.modelData.status) {
                            case "Canceled":
                                return Style.colors.repoItemStatusCanceledText
                            case "Pending":
                                return Style.colors.repoItemStatusPendingText
                            case "Fetching":
                                return Style.colors.repoItemStatusFetchingText
                            case "Pulling":
                                return Style.colors.repoItemStatusPullingText
                            case "Done":
                                return Style.colors.repoItemStatusDoneText
                            case "Dirty":
                                return Style.colors.repoItemStatusDirtyText
                            case "Conflict":
                                return Style.colors.repoItemStatusConflictText
                            default:
                                return Style.colors.repoItemStatusPendingText
                        }
                    }

                    property color statusBgColor: {
                        switch(root.modelData.status) {
                            case "Canceled":
                                return Style.colors.repoItemStatusCanceledBg
                            case "Pending":
                                return Style.colors.repoItemStatusPendingBg
                            case "Fetching":
                                return Style.colors.repoItemStatusFetchingBg
                            case "Pulling":
                                return Style.colors.repoItemStatusPullingBg
                            case "Done":
                                return Style.colors.repoItemStatusDoneBg
                            case "Dirty":
                                return Style.colors.repoItemStatusDirtyBg
                            case "Conflict":
                                return Style.colors.repoItemStatusConflictBg
                            default:
                                return Style.colors.repoItemStatusPendingBg
                        }
                    }

                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: statusText.contentWidth + 30
                    Layout.preferredHeight: 20
                    radius: 5
                    color: status.statusBgColor

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 4
                            Layout.preferredHeight: 4
                            radius: 4
                            color: status.statusTextColor
                        }

                        Text {
                            id: statusText
                            Layout.alignment: Qt.AlignVCenter
                            text: root.modelData.status
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 12
                            font.weight: 300
                            color: status.statusTextColor
                        }
                    }
                }

                ActionIconButton {
                    iconText: Style.icons.arrowDown
                    tooltip: "Pull"
                    backgroundColor: Qt.darker(Style.colors.surfaceLight, 1.4)
                    textColor: Style.colors.foreground
                    onClicked: root.pullRequested(root.index)
                }

                ActionIconButton {
                    iconText: Style.icons.download
                    tooltip: "Fetch"
                    backgroundColor: Qt.darker(Style.colors.surfaceLight, 1.4)
                    textColor: Style.colors.foreground
                    onClicked: root.fetchRequested(root.index)
                }
            }

            // Path + Branch row
            RowLayout {
                id: mainRow
                Layout.fillWidth: true
                spacing: 15

                RowLayout {
                    Layout.preferredWidth: (mainRow.width - mainRow.spacing) / 2
                    spacing: 5

                    Text {
                        text: Style.icons.folder
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: 12
                        color: Style.colors.foreground
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.modelData.path
                        font.pixelSize: 12
                        font.family: Style.fontTypes.roboto
                        color: Style.colors.mutedText
                        elide: Text.ElideMiddle
                        font.weight: 400
                        font.letterSpacing: 0
                    }
                }

                RowLayout {
                    Layout.preferredWidth: (mainRow.width - mainRow.spacing) / 2
                    spacing: 5

                    Text {
                        text: Style.icons.branch
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: 12
                        color: Style.colors.foreground
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.modelData.branchName
                        font.pixelSize: 12
                        font.family: Style.fontTypes.roboto
                        color: Style.colors.mutedText
                        elide: Text.ElideMiddle
                        font.weight: 400
                        font.letterSpacing: 0
                    }
                }
            }

            // Remotes
            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    text: Style.icons.cloud
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: 12
                    color: Style.colors.foreground
                }

                Text {
                    Layout.fillWidth: true
                    text: root.modelData.remote
                    font.pixelSize: 12
                    font.family: Style.fontTypes.roboto
                    color: Style.colors.mutedText
                    elide: Text.ElideMiddle
                    font.weight: 400
                    font.letterSpacing: 0
                }
            }
        }
    }

    HoverHandler {
        id: msa
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.clicked(root.index)
    }
}
