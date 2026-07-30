import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style_Impl
import GitEase_Style
import GitEase

UtilitiesCard {
    id: root

    property ActivityController activityController: null
    property GuideController    guideController:    null

    title: "Recent Activity"
    icon: Style.icons.clock
    badgeCount: activityController ? activityController.activities.length : 0

    content: ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.dp(10)
        anchors.rightMargin: Style.dp(10)
        spacing: 8

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "recent_activity_tutorial"
            guideName: "Recent Activity"
            guideIcon: Style.icons.clock
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return listView },
                        icon: Style.icons.clock,
                        title: "Command History",
                        description: "Every git command GitEase runs on your behalf is logged here with a timestamp — handy for auditing what happened or learning the underlying git commands."
                    }
                ]
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(listView.contentHeight, 220) + 12
            radius: 4
            color: Style.colors.utilitiesSurfaceBackground

            ListView {
                id: listView
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                height: Math.min(contentHeight, 220)
                spacing: Style.dp(2)
                clip: true
                model: activityController.activities

                delegate: Rectangle {
                    width: listView.width
                    height: Style.dp(35)
                    radius: Style.dp(4)
                    color: Style.colors.utilitiesRowBackground
                    border.width: 1
                    border.color: Style.colors.utilitiesRowBorder

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Style.dp(6)
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text  {
                                color: Style.colors.utilitiesRowIcon
                                font.family: Style.fontTypes.inter
                                font.pixelSize: Style.appFont.smallPt
                                text: "$ "
                            }

                            ScrollingText  {
                                Layout.fillWidth: true
                                color: Style.colors.utilitiesRowText
                                font.family: Style.fontTypes.inter
                                font.pixelSize: Style.appFont.smallPt
                                text: modelData.command
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Qt.formatDateTime(modelData.time, "MMM dd, yyyy hh:mm:ss")
                            color: Style.colors.utilitiesRowMetaText
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.captionPt
                            elide: Text.ElideRight
                        }
                    }
                }

                onContentHeightChanged: root.pageScrollBlocking = listView.contentHeight > listView.height + 1
            }

            Text {
                anchors.centerIn: parent
                visible: activityController.activities.length === 0
                text: "No recent activity yet"
                color: Style.colors.utilitiesEmptyStateText
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.smallPt
            }
        }
    }
}
