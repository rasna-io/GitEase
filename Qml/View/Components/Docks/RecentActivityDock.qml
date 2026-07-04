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

    content: ColumnLayout {
        anchors.fill: parent
        spacing: 16

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
            Layout.fillHeight: true
            radius: 6
            color: Style.colors.secondaryBackground

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                clip: true
                model: activityController.activities

                delegate: Rectangle {
                    width: listView.width
                    height: 60
                    radius: 5
                    color: Style.colors.primaryBackground

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text  {
                                color: Style.colors.foreground
                                font.family: Style.fontTypes.roboto
                                font.pixelSize: Style.appFont.defaultPt
                                text: "$ "
                            }

                            ScrollingText  {
                                Layout.fillWidth: true
                                color: Style.colors.foreground
                                font.family: Style.fontTypes.roboto
                                font.pixelSize: Style.appFont.defaultPt
                                text: modelData.command
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Qt.formatDateTime(modelData.time, "MMM dd, yyyy hh:mm:ss")
                            color: Style.colors.mutedText
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: Style.appFont.smallPt
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
                color: Style.colors.mutedText
                font.family: Style.fontTypes.roboto
                font.pixelSize: Style.appFont.defaultPt
            }
        }
    }
}
