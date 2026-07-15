import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * BusyWaiter
 * Show animation and message
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property alias  message: messageText.text
    property bool   running: true

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent
    color: Style.colors.primaryBackground
    z: 999

    /* Internal SpinnerRing Component
     * ****************************************************************************************/
    Component {
        id: spinnerRingComponent

        Canvas {
            id: ringCanvas

            property real radius: 36
            property real lineWidth: 3
            property real globalAlpha: 0.9
            property real trackAlpha: 0.08
            property bool clockwise: true
            property real angle: 0
            property real arcSpan: Math.PI * 1.1
            property real spanFrom: Math.PI * 1.4
            property real spanTo: Math.PI * 0.8
            property int  rotateDuration: 2200
            property int  spanDuration: 1800
            property bool running: true

            onAngleChanged: requestPaint()
            onArcSpanChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                // Track
                ctx.beginPath()
                ctx.arc(width / 2, height / 2, radius, 0, Math.PI * 2)
                ctx.strokeStyle = Style.colors.accent
                ctx.globalAlpha = trackAlpha
                ctx.lineWidth = lineWidth
                ctx.stroke()

                // Arc
                var start = clockwise ? angle : -angle
                ctx.beginPath()
                ctx.arc(width / 2, height / 2, radius, start, start + arcSpan)
                ctx.strokeStyle = Style.colors.accent
                ctx.globalAlpha = globalAlpha
                ctx.lineWidth = lineWidth
                ctx.lineCap = "round"
                ctx.stroke()
            }

            NumberAnimation on angle {
                from: 0
                to: Math.PI * 2
                duration: ringCanvas.rotateDuration
                loops: Animation.Infinite
                easing.type: Easing.Linear
                running: ringCanvas.running && ringCanvas.visible
            }

            SequentialAnimation on arcSpan {
                running: ringCanvas.running && ringCanvas.visible
                loops: Animation.Infinite

                NumberAnimation {
                    to: ringCanvas.spanFrom
                    duration: ringCanvas.spanDuration
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: ringCanvas.spanTo
                    duration: ringCanvas.spanDuration
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    /* Children
     * ****************************************************************************************/
    Column {
        id: busyColumn
        anchors.centerIn: parent
        spacing: 10
        width: Math.min(parent.width, 360)

        Item {
            id: spinnerRoot
            width: 120
            height: 120
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.centerIn: parent
                width: 90
                height: 90
                radius: 45
                color: Style.colors.accent
                opacity: 0

                SequentialAnimation on opacity {
                    running: root.running && root.visible
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 0.08
                        duration: 1000
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 0.00
                        duration: 1000
                        easing.type: Easing.InOutSine
                    }
                }
            }

            Loader {
                anchors.fill: parent
                sourceComponent: spinnerRingComponent
                onLoaded: {
                    item.running = Qt.binding(function() {
                        return root.running && root.visible
                    })
                    item.radius = 36
                    item.lineWidth = 3
                    item.globalAlpha = 0.9
                    item.trackAlpha = 0.08
                    item.clockwise = true
                    item.arcSpan = Math.PI * 1.1
                    item.spanFrom = Math.PI * 1.4
                    item.spanTo = Math.PI * 0.8
                    item.rotateDuration = 2200
                    item.spanDuration = 1800
                }
            }

            Loader {
                anchors.fill: parent
                sourceComponent: spinnerRingComponent
                onLoaded: {
                    item.running = Qt.binding(function() {
                        return root.running && root.visible
                    })
                    item.radius = 27
                    item.lineWidth = 3
                    item.globalAlpha = 0.65
                    item.trackAlpha = 0.06
                    item.clockwise = false
                    item.arcSpan = Math.PI * 0.9
                    item.spanFrom = Math.PI * 0.6
                    item.spanTo = Math.PI * 1.1
                    item.rotateDuration = 1500
                    item.spanDuration = 1800
                }
            }

            Loader {
                anchors.fill: parent
                sourceComponent: spinnerRingComponent
                onLoaded: {
                    item.running = Qt.binding(function() {
                        return root.running && root.visible
                    })
                    item.radius = 17
                    item.lineWidth = 2.5
                    item.globalAlpha = 0.45
                    item.trackAlpha = 0.06
                    item.clockwise = true
                    item.arcSpan = Math.PI * 0.7
                    item.spanFrom = Math.PI * 1.0
                    item.spanTo = Math.PI * 0.5
                    item.rotateDuration = 1100
                    item.spanDuration = 1800
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: 5
                color: Style.colors.accent

                SequentialAnimation on scale {
                    running: root.running && root.visible
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 1.5
                        duration: 700
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 1.0
                        duration: 700
                        easing.type: Easing.InOutSine
                    }
                }

                SequentialAnimation on opacity {
                    running: root.running && root.visible
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 0.4
                        duration: 700
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 1.0
                        duration: 700
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }

        // Message text with animated dots
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 3

            Text {
                id: messageText
                text: "Loading"
                font.family: Style.fontTypes.roboto
                font.pixelSize: Style.appFont.h3Pt
                font.weight: 400
                color: Style.colors.mutedText
            }

            Row {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: 3
                    delegate: Text {
                        text: "."
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: Style.appFont.h3Pt
                        color: Style.colors.mutedText

                        SequentialAnimation on opacity {
                            running: root.running && root.visible
                            loops: Animation.Infinite

                            PauseAnimation  {
                                duration: index * 220
                            }
                            NumberAnimation {
                                to: 1.0
                                duration: 300
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: 0.1
                                duration: 300
                                easing.type: Easing.InOutSine
                            }
                            PauseAnimation  {
                                duration: (2 - index) * 220
                            }
                        }
                    }
                }
            }
        }
    }
}
