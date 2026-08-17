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

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 20, 420)
        spacing: 0

        ColumnLayout {
            id: hero
            Layout.alignment: Qt.AlignHCenter
            spacing: 12
            opacity: 0

            Component.onCompleted: heroFadeIn.start()

            NumberAnimation {
                id: heroFadeIn
                target: hero
                property: "opacity"
                from: 0; to: 1
                duration: 400
                easing.type: Easing.OutCubic
            }

            Text {
                text: "Welcome to GitEase"
                font.family: Style.fontTypes.inter
                font.weight: Font.Bold
                font.pixelSize: Style.appFont.h1Pt
                color: Style.colors.foreground
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "The most advanced Git GUI designed for developers. Manage repositories, resolve conflicts, and collaborate with your team - all with AI-powered assistance."
                wrapMode: Text.WordWrap
                font.family: Style.fontTypes.inter
                font.weight: 400
                font.pixelSize: Style.appFont.defaultPt
                font.letterSpacing: 0.1
                color: Style.colors.secondaryText
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 360
                lineHeight: 1.4
            }
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 24
            Layout.bottomMargin: 24
            Layout.preferredWidth: 36
            Layout.preferredHeight: 2

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                radius: height / 2
                color: Style.colors.accent
                opacity: 0.45
            }
        }

        RowLayout {
            id: cardsRow
            Layout.alignment: Qt.AlignHCenter
            spacing: 12
            opacity: 0

            Component.onCompleted: cardsFadeIn.start()

            NumberAnimation {
                id: cardsFadeIn
                target: cardsRow
                property: "opacity"
                from: 0; to: 1
                duration: 300
                easing.type: Easing.OutCubic
            }

            Repeater {
                id: cardRepeater
                model: [
                    { title: "Powerful & Fast", icon: Style.icons.rocket, accentColor: Style.colors.vibrantMint,  bgColor: Style.colors.vibrantMintBg,  desc: "Lightning-fast operations with intelligent caching." },
                    { title: "AI-Powered",      icon: Style.icons.robot,  accentColor: Style.colors.amber,        bgColor: Style.colors.amberBg,        desc: "Smart commit messages and conflict resolution." },
                    { title: "Team First",      icon: Style.icons.users,  accentColor: Style.colors.purple,       bgColor: Style.colors.purpleBg,       desc: "Built-in collaboration and code review tools." }
                ]

                delegate: Item {
                    id: featureCard
                    width: 138
                    height: 162
                    opacity: 0

                    Timer {
                        id: staggerIn
                        interval: index * 130
                        running: false
                        repeat: false
                        onTriggered: {
                            entryAnim.start()
                            slideAnim.start()
                        }
                    }

                    NumberAnimation {
                        id: entryAnim
                        target: featureCard
                        property: "opacity"
                        from: 0; to: 1
                        duration: 400
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        id: slideAnim
                        target: featureCard
                        property: "y"
                        from: 12; to: 0
                        duration: 400
                        easing.type: Easing.OutCubic
                    }

                    Component.onCompleted: staggerIn.start()

                    Rectangle {
                        id: cardBg
                        anchors.fill: parent
                        radius: 12
                        color: mouseArea.containsMouse
                               ? Qt.lighter(Style.colors.cardBackground, 1.05)
                               : Style.colors.cardBackground
                        border.width: 1
                        border.color: mouseArea.containsMouse
                                      ? Qt.lighter(modelData.accentColor, 0.5)
                                      : Qt.rgba(Style.colors.primaryBorder.r,
                                                Style.colors.primaryBorder.g,
                                                Style.colors.primaryBorder.b, 0.35)

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        // Corner masks — square the top by covering only the rounded
                        // corners with the card's own fill color (bound, so hover syncs)
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            width: 12
                            height: 12
                            color: cardBg.color
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            width: 12
                            height: 12
                            color: cardBg.color
                        }

                        // Square top border line — drawn over the corner masks so it
                        // changes color on hover exactly like the rest of the border
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: cardBg.border.color
                        }

                        // Left/right border segments — restore the border over the masked
                        // top corners, continuing the card's side borders
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            width: 1
                            height: 13
                            color: cardBg.border.color
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            width: 1
                            height: 13
                            color: cardBg.border.color
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16
                            anchors.topMargin: 20
                            spacing: 0

                            // Icon badge
                            Rectangle {
                                width: 42
                                height: 42
                                radius: 11
                                color: modelData.bgColor

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.family: Style.fontTypes.font6Pro
                                    font.pixelSize: 17
                                    color: modelData.accentColor
                                }
                            }

                            // Title
                            Text {
                                text: modelData.title
                                font.family: Style.fontTypes.inter
                                font.weight: Font.DemiBold
                                font.pixelSize: Style.appFont.mediumPt
                                color: Style.colors.foreground
                                width: parent.width
                                wrapMode: Text.WordWrap
                                Layout.topMargin: 12
                            }

                            // Description
                            Text {
                                text: modelData.desc
                                font.family: Style.fontTypes.inter
                                font.weight: 400
                                font.pixelSize: Style.appFont.smallPt
                                color: Style.colors.mutedText
                                width: parent.width
                                wrapMode: Text.WordWrap
                                lineHeight: 1.35
                                Layout.topMargin: 6
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }
    }
}
