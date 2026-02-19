import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style_Impl
import GitEase_Style
import GitEase

UtilitiesCard {
    id: root

    property ActivityController activityController: null

    title: "Recent Activity"
    icon: Style.icons.clock

    content: ColumnLayout {
        anchors.fill: parent
        spacing: 10

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
                    height: 50
                    radius: 5
                    color: Style.colors.primaryBackground

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: modelData.command
                            color: Style.colors.foreground
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Qt.formatDateTime(modelData.time, "MMM dd, yyyy hh:mm:ss") + " - " + modelData.source
                            color: Style.colors.mutedText
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: activityController.activities.length === 0
                text: "No recent activity yet"
                color: Style.colors.mutedText
                font.family: Style.fontTypes.roboto
                font.pixelSize: 11
            }
        }

        Button {
            Layout.fillWidth: true
            implicitHeight: 38
            enabled: activityController.activities.length > 0

            background: Rectangle {
                radius: 8
                color: enabled ? Style.colors.accent : Style.colors.disabledButton
            }

            contentItem: Text {
                text: "Clear"
                color: Style.colors.secondaryForeground
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
            }

            onClicked: activityController.activities = []
        }
    }
}
