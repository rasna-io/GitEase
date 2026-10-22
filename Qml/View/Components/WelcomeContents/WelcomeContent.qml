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
        width: Math.min(parent.width - 20, 600)
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
                text: "A lightweight, fast Git client with a layout you control, support for multiple users, and a plugin system to make it your own."
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
            id: cardsColumn
            Layout.fillWidth: true
            spacing: 12
            opacity: 0

            Component.onCompleted: cardsFadeIn.start()

            NumberAnimation {
                id: cardsFadeIn
                target: cardsColumn
                property: "opacity"
                from: 0; to: 1
                duration: 300
                easing.type: Easing.OutCubic
            }

            Repeater {
                id: cardRepeater
                model: [
                    { title: "Light & Fast",       icon: Style.icons.rocket,   accentColor: Style.colors.vibrantMint,    bgColor: Style.colors.vibrantMintBg,
                      desc: "A lightweight native app built on Qt and libgit2, quick to start and quick to respond." },
                    { title: "Dock & Detach",      icon: Style.icons.detach,   accentColor: Style.colors.cornflowerBlue, bgColor: Style.colors.cornflowerBlueBg,
                      desc: "Dock panels where you work, or detach any panel into its own window." },
                    { title: "Plugins & Profiles", icon: Style.icons.plugins,  accentColor: Style.colors.purple,         bgColor: Style.colors.purpleBg,
                      desc: "Extend GitEase with plugins and switch between multiple user profiles." }
                ]

                delegate: Item {
                    id: featureCard
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 200
                    opacity: 0

                    transform: Translate {
                        id: slide
                        y: 12
                    }

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
                        target: slide
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
                                      ? Qt.rgba(modelData.accentColor.r,
                                                modelData.accentColor.g,
                                                modelData.accentColor.b, 0.6)
                                      : Qt.rgba(Style.colors.primaryBorder.r,
                                                Style.colors.primaryBorder.g,
                                                Style.colors.primaryBorder.b, 0.35)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        // Accent bar on the top edge
                        Rectangle {
                            anchors.top: parent.top
                            anchors.topMargin: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 3
                            width: mouseArea.containsMouse ? parent.width * 0.6 : parent.width * 0.3
                            radius: 2
                            color: modelData.accentColor

                            Behavior on width {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            anchors.topMargin: 22
                            spacing: 12

                            // Icon badge
                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                Layout.alignment: Qt.AlignHCenter
                                radius: 14
                                color: modelData.bgColor
                                border.width: 1
                                border.color: Qt.rgba(modelData.accentColor.r,
                                                      modelData.accentColor.g,
                                                      modelData.accentColor.b, 0.35)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.family: Style.fontTypes.font6Pro
                                    font.pixelSize: 18
                                    color: modelData.accentColor
                                }
                            }

                            Text {
                                text: modelData.title
                                font.family: Style.fontTypes.inter
                                font.weight: Font.DemiBold
                                font.pixelSize: Style.appFont.mediumPt
                                color: Style.colors.foreground
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.desc
                                font.family: Style.fontTypes.inter
                                font.weight: 400
                                font.pixelSize: Style.appFont.smallPt
                                color: Style.colors.mutedText
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                lineHeight: 1.3
                                Layout.fillWidth: true
                                Layout.fillHeight: true
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
