import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RepoForestLogs
 * Collapsible activity log of Repo Forest operations.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var  operationLogs:        []
    property bool showOperationLogs:    false

    readonly property int failedCount:  operationLogs.filter(l => l.status === "Failed").length

    /* Signals
    * ****************************************************************************************/
    signal clearLogsRequested()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: layout.implicitHeight + 16
    radius: 8
    color: Style.colors.utilitiesSurfaceBackground
    border.width: 1
    border.color: Style.colors.utilitiesSurfaceBorder

    /* Functions
    * ****************************************************************************************/
    function statusColor(status) {
        switch (status) {
        case "Success": return Style.colors.repoItemStatusDoneText
        case "Failed":  return Style.colors.repoItemStatusConflictText
        case "Skipped": return Style.colors.repoItemStatusDirtyText
        default:        return Style.colors.secondaryText
        }
    }

    /* Children
    * ****************************************************************************************/
    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        anchors.leftMargin: 12
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 24

                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.showOperationLogs = !root.showOperationLogs }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.showOperationLogs ? Style.icons.caretDown : Style.icons.caretUp
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: Style.appFont.microPt
                        color: Style.colors.secondaryText
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Activity log"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        font.weight: Font.DemiBold
                        color: Style.colors.foreground
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 16
                        width: Math.max(16, countText.implicitWidth + 10)
                        radius: 8
                        color: root.failedCount > 0 ? Style.colors.repoItemStatusConflictBg : Style.colors.controlBackground
                        border.width: 1
                        border.color: Style.colors.controlBorder

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: root.failedCount > 0 ? root.failedCount + " failed" : root.operationLogs.length
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.microPt
                            color: root.failedCount > 0 ? Style.colors.repoItemStatusConflictText : Style.colors.secondaryText
                        }
                    }
                }
            }

            ActionIconButton {
                iconText: Style.icons.trash
                tooltip: "Clear log"
                backgroundColor: "transparent"
                textColor: Style.colors.secondaryText
                onClicked: {
                    root.clearLogsRequested()
                    root.showOperationLogs = false
                }
            }
        }

        ListView {
            id: logList
            Layout.fillWidth: true
            Layout.preferredHeight: root.showOperationLogs ? 140 : 0
            visible: Layout.preferredHeight > 0
            clip: true
            spacing: 3
            boundsBehavior: Flickable.StopAtBounds
            model: root.operationLogs

            Behavior on Layout.preferredHeight { NumberAnimation { duration: Style.motionMedium; easing.type: Easing.OutCubic } }

            ScrollBar.vertical: ScrollBar {}

            delegate: RowLayout {
                required property var modelData

                width: ListView.view.width - 12
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: 6
                    radius: 3
                    color: root.statusColor(modelData.status)
                }

                Text {
                    text: modelData.timestamp
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.microPt
                    color: Style.colors.mutedText
                }

                Text {
                    Layout.preferredWidth: 120
                    visible: modelData.repoName.length > 0
                    text: modelData.repoName + (modelData.remoteName ? " @" + modelData.remoteName : "")
                    elide: Text.ElideRight
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.microPt
                    font.weight: Font.DemiBold
                    color: Style.colors.foreground
                }

                Text {
                    text: modelData.operation.toUpperCase()
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.microPt
                    font.weight: Font.Medium
                    color: modelData.operation === "fetch" ? Style.colors.repoItemStatusFetchingText
                         : modelData.operation === "pull" ? Style.colors.repoItemStatusPullingText
                                                          : Style.colors.secondaryText
                }

                Text {
                    Layout.fillWidth: true
                    text: modelData.message
                    elide: Text.ElideRight
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.microPt
                    color: modelData.status === "Failed" ? root.statusColor("Failed") : Style.colors.foreground
                }
            }

            onCountChanged: if (count > 0) positionViewAtEnd()
        }
    }
}
