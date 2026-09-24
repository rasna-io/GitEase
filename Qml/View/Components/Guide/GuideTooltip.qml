import QtQuick
import QtQuick.Layouts

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * GuideTooltip
 * Self-contained guide step card. Drop it anywhere; parent positions it.
 * ************************************************************************************************/
Item {
    id: root

    property var stepData:        null
    property var guideController: null

    readonly property var    _commands:    root.stepData?.commands ?? []
    readonly property string _mediaSource: root.stepData?.media ?? ""
    readonly property bool   _mediaIsGif:  root._mediaSource.toLowerCase().endsWith(".gif")

    /* Sizing — driven by card content; shadow bleeds below without clipping
     * ****************************************************************************************/
    implicitWidth: 300
    implicitHeight: card.height

    // Hidden TextEdit used solely for clipboard copy (see command chip's copy button below)
    TextEdit {
        id: _cmdClipboardHelper
        visible: false
    }

    /* Card
     * ****************************************************************************************/
    Rectangle {
        id: card
        y: 0
        width: parent.width
        height: _col.implicitHeight + _col.anchors.topMargin + 14
        radius: 12
        color: Style.colors.primaryBackground
        border {
            width: 1
            color: Style.colors.primaryBorder
        }
        clip: true

        ColumnLayout {
            id: _col
            anchors {
                top: parent.top
                topMargin: 18
                left: parent.left
                leftMargin: 16
                right: parent.right
                rightMargin: 16
            }
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing:          8

                // Icon badge
                Rectangle {
                    visible: (root.stepData?.icon?.length ?? 0) > 0
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 13
                    color: Qt.rgba(Style.colors.accent.r,
                                   Style.colors.accent.g,
                                   Style.colors.accent.b, 0.13)

                    Text {
                        anchors.centerIn: parent
                        text: root.stepData?.icon ?? ""
                        font.family: Style.fontTypes.font6Pro
                        font.styleName: "Solid"
                        font.pixelSize: 12
                        color: Style.colors.accent
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.stepData?.title ?? ""
                    font.family: Style.fontTypes.inter
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Style.colors.foreground
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    visible: (root.stepData?.totalSteps ?? 0) > 1
                    implicitWidth: _pillTxt.implicitWidth + 14
                    implicitHeight: 20
                    radius: 10
                    color: Qt.rgba(Style.colors.accent.r,
                                   Style.colors.accent.g,
                                   Style.colors.accent.b, 0.13)

                    Text {
                        id: _pillTxt
                        anchors.centerIn: parent
                        text: "%1 / %2".arg((root.stepData?.stepIndex ?? 0) + 1).arg(root.stepData?.totalSteps ?? 1)
                        font.family: Style.fontTypes.inter
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Style.colors.accent
                    }
                }

                RowLayout {
                    spacing: 3
                    visible: (root.stepData?.totalSteps ?? 0) > 1

                    Repeater {
                        model: root.stepData?.totalSteps ?? 0

                        delegate: Rectangle {
                            required property int index
                            readonly property bool _active: index === (root.stepData?.stepIndex ?? 0)

                            implicitWidth: _active ? 16 : 5
                            implicitHeight: 5
                            radius: 3
                            color: _active ? Style.colors.accent : Qt.rgba(Style.colors.accent.r,
                                             Style.colors.accent.g,
                                             Style.colors.accent.b, 0.22)

                            Behavior on implicitWidth {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                height: 1
                color: Style.colors.primaryBorder
                opacity: 0.55
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                visible: root._mediaSource.length > 0
                radius: 8
                color: Style.colors.secondaryBackground
                border {
                    width: 1
                    color: Style.colors.primaryBorder
                }
                clip: true

                Loader {
                    anchors.fill: parent
                    anchors.margins: 1
                    active: root._mediaSource.length > 0
                    sourceComponent: root._mediaIsGif ? _gifMediaComponent : _imageMediaComponent
                }
            }

            Component {
                id: _gifMediaComponent
                AnimatedImage {
                    source: root._mediaSource
                    fillMode: Image.PreserveAspectFit
                    playing: true
                    asynchronous: true
                }
            }

            Component {
                id: _imageMediaComponent
                Image {
                    source: root._mediaSource
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                height: 1
                color: Style.colors.primaryBorder
                opacity: 0.55
                visible: root._mediaSource.length > 0
            }

            Text {
                Layout.fillWidth: true
                text: root.stepData?.description ?? ""
                font.family: Style.fontTypes.inter
                font.pixelSize: 12
                color: Style.colors.secondaryText
                wrapMode: Text.WordWrap
                lineHeight: 1.55
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: root._commands.length > 0 ? 10 : 0
                spacing: 6

                Repeater {
                    model: root._commands

                    delegate: Rectangle {
                        id: _cmdChip
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: _cmdRow.implicitHeight + 14
                        radius: 6
                        color: Style.colors.editorBackgroound
                        border {
                            width: 1
                            color: Style.colors.primaryBorder
                        }

                        RowLayout {
                            id: _cmdRow
                            anchors {
                                left: parent.left
                                leftMargin:  10
                                right: parent.right
                                rightMargin: 6
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 6

                            Text {
                                visible: (_cmdChip.modelData.label?.length ?? 0) > 0
                                text: _cmdChip.modelData.label + ":"
                                font.family: Style.fontTypes.inter
                                font.weight: Font.DemiBold
                                font.pixelSize: 11
                                color: Style.colors.accent
                            }

                            Text {
                                Layout.fillWidth: true
                                text: _cmdChip.modelData.command ?? ""
                                font.family: Style.fontTypes.jetBrainsMono
                                font.pixelSize: 11
                                color: Style.colors.foreground
                                wrapMode: Text.WrapAnywhere
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Rectangle {
                                implicitWidth: 22
                                implicitHeight: 22
                                radius: 5
                                color: _copyMa.containsMouse ? Style.colors.primaryBorder : "transparent"
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 80
                                    }
                                }

                                property bool copied: false

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.copied ? "✓" : Style.icons.copy
                                    font.family: Style.fontTypes.font6Pro
                                    font.styleName: "Solid"
                                    font.pixelSize: 10
                                    color: parent.copied ? "#4caf50" : Style.colors.secondaryText
                                }

                                Timer {
                                    id: _copyResetTimer
                                    interval: 1500
                                    onTriggered: parent.copied = false
                                }

                                MouseArea {
                                    id: _copyMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        _cmdClipboardHelper.text = _cmdChip.modelData.command ?? ""
                                        _cmdClipboardHelper.selectAll()
                                        _cmdClipboardHelper.copy()
                                        parent.copied = true
                                        _copyResetTimer.restart()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 14
                spacing: 0

                Rectangle {
                    visible: root.stepData?.showBack ?? false
                    implicitWidth: _backInner.implicitWidth + 20
                    implicitHeight: 28
                    radius: 6
                    color: _backMa.containsMouse ? Style.colors.primaryBorder : "transparent"
                    border {
                        width: 1
                        color: Style.colors.primaryBorder
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 80
                        }
                    }

                    RowLayout {
                        id: _backInner
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "←"
                            font.family: Style.fontTypes.inter
                            font.pixelSize: 11
                            color: Style.colors.secondaryText
                        }
                        Text {
                            text: "Back"
                            font.family: Style.fontTypes.inter
                            font.pixelSize: 11
                            color: Style.colors.secondaryText
                        }
                    }

                    MouseArea {
                        id: _backMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.guideController)
                                root.guideController.back()
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 6

                    Rectangle {
                        visible: root.stepData?.showSkip ?? false
                        implicitWidth: _skipTxt.implicitWidth + 16
                        implicitHeight: 28
                        radius: 6
                        color: _skipMa.containsMouse
                                        ? Qt.rgba(Style.colors.foreground.r,
                                                  Style.colors.foreground.g,
                                                  Style.colors.foreground.b, 0.07)
                                        : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: 80
                            }
                        }

                        Text {
                            id: _skipTxt
                            anchors.centerIn: parent
                            text: "Skip"
                            font.family: Style.fontTypes.inter
                            font.pixelSize: 11
                            color: Style.colors.mutedText
                        }

                        MouseArea {
                            id: _skipMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.guideController)
                                    root.guideController.dismiss()
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: _nextInner.implicitWidth + 20
                        implicitHeight: 28
                        radius: 6
                        color: _nextMa.containsMouse ? Style.colors.accentHover : Style.colors.accent

                        Behavior on color {
                            ColorAnimation {
                                duration: 80
                            }
                        }

                        RowLayout {
                            id: _nextInner
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: {
                                    if (!root.stepData)
                                        return "Got it"

                                    return (root.stepData.stepIndex === root.stepData.totalSteps - 1) ? "Done" : "Next"
                                }
                                font.family: Style.fontTypes.inter
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Style.colors.onAccentText
                            }

                            Text {
                                visible: root.stepData
                                         ? root.stepData.stepIndex < root.stepData.totalSteps - 1
                                         : false
                                text: "→"
                                font.family: Style.fontTypes.inter
                                font.pixelSize: 11
                                color: Style.colors.onAccentText
                            }
                        }

                        MouseArea {
                            id: _nextMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.guideController)
                                    root.guideController.next()
                            }
                        }
                    }
                }
            }
        }
    }
}
