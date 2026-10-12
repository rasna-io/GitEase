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
    readonly property int    _totalSteps:  root.stepData?.totalSteps ?? 0
    readonly property int    _stepIndex:   root.stepData?.stepIndex ?? 0
    readonly property bool   _isLast:      root.stepData ? root._stepIndex === root._totalSteps - 1 : false

    function _accentAlpha(a) {
        return Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, a)
    }

    /* Sizing — driven by card content
     * ****************************************************************************************/
    implicitWidth: 330
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
        height: _col.implicitHeight + _col.anchors.topMargin + 6
        radius: 14
        color: Style.colors.primaryBackground
        border {
            width: 1
            color: Style.colors.primaryBorder
        }

        ColumnLayout {
            id: _col
            anchors {
                top: parent.top
                topMargin: 18
                left: parent.left
                leftMargin: 18
                right: parent.right
                rightMargin: 18
            }
            spacing: 0

            /* Header
             * ************************************************************************************/
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    visible: (root.stepData?.icon?.length ?? 0) > 0
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 10
                    color: root._accentAlpha(0.14)
                    border {
                        width: 1
                        color: root._accentAlpha(0.28)
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.stepData?.icon ?? ""
                        font.family: Style.fontTypes.font6Pro
                        font.styleName: "Solid"
                        font.pixelSize: 15
                        color: Style.colors.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        visible: root._totalSteps > 1
                        text: "STEP %1 OF %2".arg(root._stepIndex + 1).arg(root._totalSteps)
                        font.family: Style.fontTypes.inter
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                        color: Style.colors.accent
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.stepData?.title ?? ""
                        font.family: Style.fontTypes.inter
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        color: Style.colors.foreground
                        wrapMode: Text.WordWrap
                    }
                }

                // Step progress dots, after the title
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    visible: root._totalSteps > 1
                    spacing: 4

                    Repeater {
                        model: root._totalSteps

                        delegate: Rectangle {
                            required property int index
                            readonly property bool _active: index === root._stepIndex

                            implicitWidth: _active ? 18 : 6
                            implicitHeight: 6
                            radius: 3
                            color: _active ? Style.colors.accent : root._accentAlpha(0.25)

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

            /* Media
             * ************************************************************************************/
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 14
                Layout.preferredHeight: 160
                visible: root._mediaSource.length > 0
                radius: 10
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

            /* Description
             * ************************************************************************************/
            Text {
                Layout.fillWidth: true
                Layout.topMargin: 12
                text: root.stepData?.description ?? ""
                font.family: Style.fontTypes.inter
                font.pixelSize: 12
                color: Style.colors.secondaryText
                wrapMode: Text.WordWrap
                lineHeight: 1.5
            }

            /* Commands
             * ************************************************************************************/
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: root._commands.length > 0 ? 12 : 0
                spacing: 6

                Repeater {
                    model: root._commands

                    delegate: Rectangle {
                        id: _cmdChip
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: _cmdRow.implicitHeight + 14
                        radius: 8
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
                                radius: 6
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

            /* Actions: Skip / Back / Next on the right
             * ************************************************************************************/
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 18
                spacing: 6

                Item {
                    Layout.fillWidth: true
                }

                // Skip
                Rectangle {
                    visible: root.stepData?.showSkip ?? false
                    implicitWidth: _skipTxt.implicitWidth + 16
                    implicitHeight: 30
                    radius: 8
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

                // Back
                Rectangle {
                    visible: root.stepData?.showBack ?? false
                    implicitWidth: _backInner.implicitWidth + 22
                    implicitHeight: 30
                    radius: 8
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
                        spacing: 5

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
                            font.weight: Font.Medium
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

                // Next / Done / Got it
                Rectangle {
                    implicitWidth: _nextInner.implicitWidth + 26
                    implicitHeight: 30
                    radius: 8
                    color: _nextMa.containsMouse ? Style.colors.accentHover : Style.colors.accent

                    Behavior on color {
                        ColorAnimation {
                            duration: 80
                        }
                    }

                    RowLayout {
                        id: _nextInner
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: !root.stepData ? "Got it" : (root._isLast ? "Done" : "Next")
                            font.family: Style.fontTypes.inter
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: Style.colors.onAccentText
                        }

                        Text {
                            visible: root.stepData ? !root._isLast : false
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

            /* Opt-out: quiet text link under a hairline divider
             * ************************************************************************************/
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 14
                implicitHeight: 1
                color: Style.colors.primaryBorder
                opacity: 0.6
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: 32

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    opacity: _disableMa.containsMouse ? 1.0 : 0.7

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Style.icons.eyeSlash
                        font.family: Style.fontTypes.font6Pro
                        font.styleName: "Solid"
                        font.pixelSize: 10
                        color: _disableMa.containsMouse ? Style.colors.accent : Style.colors.mutedText
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Don't show tutorials"
                        font.family: Style.fontTypes.inter
                        font.pixelSize: 11
                        color: _disableMa.containsMouse ? Style.colors.accent : Style.colors.mutedText
                    }
                }

                MouseArea {
                    id: _disableMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.guideController)
                            root.guideController.disableGuides()
                    }
                }
            }
        }
    }
}
