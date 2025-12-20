import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * WelcomeContent
 * First step of welcome flow - Introduction
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var controller: null

    ColumnLayout {
        anchors.fill: parent
        spacing: 7

        ColumnLayout {
            id: hero
            spacing: 20
            Layout.alignment: Qt.AlignHCenter

            Text {
                text: "Welcome to GitEase"
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 32
                color: Style.colors.foreground
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
            }

            Text {
                text: "The most advanced Git GUI designed for developers. Manage repositories, resolve conflicts, and collaborate with your team - all with AI-powered assistance."
                wrapMode: Text.WordWrap
                font.family: Style.fontTypes.roboto
                font.weight: 300
                font.pixelSize: 15
                font.italic: true
                font.letterSpacing: 0
                color: Style.colors.mutedText
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 360
            }
        }

        RowLayout {
            id: cardsRow
            spacing: 20
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 435
            Layout.preferredHeight: 149

            Repeater {
                model: [
                    { title: "Powerful & Fast", icon: "🚀", iconBackColor : "#B9D9FA",desc: "Lightning-fast Git operations with intelligent caching." },
                    { title: "AI-Powered", icon:  "🤖", iconBackColor : "#FAD0B9",desc: "Smart commit messages and conflict resolution." },
                    { title: "Team First", icon: "👥", iconBackColor : "#B9FAB9",desc: "Built-in collaboration and code review tools." }
                ]

                delegate: Rectangle {
                    width: 127
                    height: 127
                    radius: 4
                    color: Style.colors.cardBackground

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            width: 33
                            height : 33
                            color : modelData.iconBackColor ?? Style.colors.mutedText
                            radius: 4

                            Text {
                                width: parent.width
                                height : parent.height
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                text: modelData.icon ?? ""
                                font.family: Style.fontTypes.roboto
                                font.pixelSize: 20
                                color: Style.colors.accent
                            }
                        }

                        Text {
                            text: modelData.title ?? ""
                            wrapMode: Text.WordWrap
                            font.family: Style.fontTypes.roboto
                            font.weight: 400
                            font.pixelSize: 14
                            font.letterSpacing: 0
                            color: Style.colors.titleText
                            width: 106
                        }

                        Text {
                            id: descText
                            width: 98
                            wrapMode: Text.WordWrap
                            text: modelData.desc ?? ""
                            font.family: Style.fontTypes.roboto
                            font.weight: 400
                            font.pixelSize: 11
                            font.letterSpacing: 0
                            color: Style.colors.descriptionText
                        }

                    }
                }
            }
        }
    }
}

