import QtQuick
import QtQuick.Controls
import QtQuick.Window

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * GuideOverlay
 * Drop-in overlay for any view. Pass any GuideController instance via guideController.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var guideController: null

    /* Private state
     * ****************************************************************************************/
    property var   _sd:          null               // current stepData (source of truth)
    property var   _displayedSd: null               // what popupContent actually shows (cross-fade target)
    property rect  _tr:          Qt.rect(0,0,0,0)   // target rect in root-local coords  (inline steps)
    property point _ptPos:       Qt.point(0,0)      // popup-step target pos in overlay coords
    property size  _ptSize:      Qt.size(0,0)       // popup-step target size

    readonly property int  _pad:      4
    readonly property int  _cr:       10
    readonly property real _alpha:    0.60   // dim strength

    /* Children
     * ****************************************************************************************/
    anchors.fill: parent
    visible: false
    opacity: 0

    /* Connections
     * ****************************************************************************************/
    Connections {
        target: root.guideController
        ignoreUnknownSignals: true

        function onGuideStepChanged(sd) {
            root._sd = sd
            root._applyStep(sd)
        }

        function onGuideDismissed() {
            root._dismiss()
        }
    }

    // Re-snap the spotlight whenever the current (non-popup) target moves or resizes — e.g. a
    // NavigationRail expanding from its collapsed width right as the guide starts. Without this,
    // _applyStep's one-time mapToItem() snapshot can capture the target mid-animation, leaving
    // the spotlight stuck at the collapsed size.
    Connections {
        target: (root._sd && !root._sd.isInPopup) ? root._sd.target : null
        ignoreUnknownSignals: true

        function onXChanged() { root._syncTargetRect() }
        function onYChanged() { root._syncTargetRect() }
        function onWidthChanged() { root._syncTargetRect() }
        function onHeightChanged() { root._syncTargetRect() }
    }

    /* Helpers
     * ****************************************************************************************/
    function _syncTargetRect() {
        var sd = root._sd
        if (sd && sd.target) {
            try {
                var q = sd.target.mapToItem(root, 0, 0)
                root._tr = Qt.rect(q.x, q.y, sd.target.width, sd.target.height)
            } catch(e) {
                root._tr = Qt.rect(0, 0, 0, 0)
            }
        } else {
            root._tr = Qt.rect(0, 0, 0, 0)
        }
        spotlightCanvas.requestPaint()
    }

    // Shared by spotlightCanvas (inline steps) and overlayBlockerCanvas (popup steps): fills the
    // dim color, then cuts a transparent rounded-rect hole via destination-out compositing so the
    // real target underneath shows through sharp, and strokes a ring around the hole.
    function _paintDimWithHole(canvas, rectX, rectY, rectW, rectH) {
        var ctx = canvas.getContext("2d")
        ctx.reset()

        ctx.fillStyle = Qt.rgba(0, 0, 0, root._alpha)
        ctx.fillRect(0, 0, canvas.width, canvas.height)

        if (rectW <= 0)
            return

        var x = rectX - root._pad, y = rectY - root._pad
        var w = rectW + root._pad * 2, h = rectH + root._pad * 2
        var r = root._cr

        ctx.globalCompositeOperation = "destination-out"
        ctx.beginPath()
        ctx.moveTo(x + r, y)
        ctx.lineTo(x + w - r, y)
        ctx.arcTo(x + w, y, x + w, y + r, r)
        ctx.lineTo(x + w, y + h - r)
        ctx.arcTo(x + w, y + h, x + w - r, y + h, r)
        ctx.lineTo(x + r, y + h)
        ctx.arcTo(x, y + h, x, y + h - r, r)
        ctx.lineTo(x, y + r)
        ctx.arcTo(x, y, x + r, y, r)
        ctx.closePath()
        ctx.fill()

        ctx.globalCompositeOperation = "source-over"
        ctx.lineWidth = 1.5
        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.22)
        ctx.stroke()
    }

    // True when `item` lives in the same top-level window as this overlay. A single shared
    // GuideController broadcasts to every GuideOverlay instance (MainWindow's plus one per
    // secondary Window, e.g. ConflictPopup) — only the instance whose window actually contains
    // the step's target should render it, otherwise both would show (one correct, one blank).
    function _inMyWindow(item) {
        var myWindow = root.Window ? root.Window.window : null
        return !!item && !!myWindow && !!item.Window && item.Window.window === myWindow
    }

    function _applyStep(sd) {
        // A single shared GuideController broadcasts to every GuideOverlay instance across every
        // window. If the step's target isn't in THIS window, this instance has nothing to show —
        // for either popup or inline steps, since isInPopup only means "inside a Qt Popup", not
        // "inside THIS window" (e.g. SettingsPopup lives in the main window's Overlay, which the
        // ConflictPopup window's own GuideOverlay must ignore).
        if (sd && sd.target && !root._inMyWindow(sd.target)) {
            if (root.visible) dismissAnim.restart()
            return
        }

        root.visible = true
        showAnim.restart()

        if (sd && sd.isInPopup) {
            // Snapshot target scene/overlay coords for the popup-tooltip binding
            if (sd.target) {
                try {
                    var p = sd.target.mapToItem(null, 0, 0)
                    root._ptPos = Qt.point(p.x, p.y)
                    root._ptSize = Qt.size(sd.target.width, sd.target.height)
                } catch(e) {
                    root._ptPos = Qt.point(0, 0)
                    root._ptSize = Qt.size(0, 0)
                }
            } else {
                root._ptPos = Qt.point(0, 0)
                root._ptSize = Qt.size(0, 0)
            }

            root._tr = Qt.rect(0, 0, 0, 0)
            inlineTooltip.visible = false
            overlayBlockerCanvas.requestPaint()

            if (!popupTooltip.visible) {
                root._displayedSd = sd
                popupTooltip.open()
            } else {
                _popupStepFade.restart()
            }
        } else {
            if (popupTooltip.visible)
                popupTooltip.close()

            root._syncTargetRect()
            inlineTooltip.visible = true
        }
    }

    function _dismiss() {
        dismissAnim.restart()
        popupTooltip.close()
    }

    /* Animations
     * ****************************************************************************************/
    NumberAnimation {
        id: showAnim
        target: root
        property: "opacity"
        from: 0
        to: 1
        duration: 220
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: dismissAnim

        NumberAnimation {
            target: root
            property: "opacity"
            to: 0
            duration: 170
            easing.type: Easing.InCubic
        }

        ScriptAction {
            script: {
                root.visible = false
                root._sd = null
                root._tr = Qt.rect(0, 0, 0, 0)
                root._ptPos = Qt.point(0, 0)
                root._ptSize = Qt.size(0, 0)
                inlineTooltip.visible = false
                spotlightCanvas.requestPaint()
                overlayBlockerCanvas.requestPaint()
            }
        }
    }

    /* Spotlight — a single Canvas dims the backdrop and cuts a real hole over the target so it
     * shows through at full sharpness (see _paintDimWithHole).
     * ****************************************************************************************/
    Canvas {
        id: spotlightCanvas
        anchors.fill: parent
        onPaint: root._paintDimWithHole(spotlightCanvas, root._tr.x, root._tr.y,
                                         root._tr.width, root._tr.height)
    }

    /* Main-window blocker — blocks content layer (below Overlay.overlay)
     * ****************************************************************************************/
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        propagateComposedEvents: false
        cursorShape: Qt.ArrowCursor

        onPressed: (e) => { e.accepted = true }
        onReleased: (e) => { e.accepted = true }
        onClicked: (e) => { e.accepted = true }
        onDoubleClicked: (e) => { e.accepted = true }
        onPressAndHold: (e) => { e.accepted = true }
        onPositionChanged:(e) => { e.accepted = true }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (event) => {
                event.accepted = true
            }
        }
    }

    /* Inline tooltip — for non-popup steps (positioned via binding)
     * ****************************************************************************************/
    GuideTooltip {
        id: inlineTooltip
        z: 1
        visible: false
        stepData: root._sd
        guideController: root.guideController

        // Binding-based x/y: re-evaluates after ColumnLayout polish → always correct position
        x: {
            var m = 14, tw = implicitWidth, w = root.width
            if (root._tr.width <= 0)
                return Math.max(m, (w - tw) / 2)

            var right = root._tr.x + root._tr.width + m
            if (right + tw <= w - m)
                return right

            var left  = root._tr.x - tw - m
            if (left >= m)
                return left

            return Math.max(m, w - tw - m)
        }

        y: {
            var m = 14, th = implicitHeight, h = root.height
            if (root._tr.width <= 0)
                return Math.max(m, (h - th) / 2)

            var preferred = root._tr.y + root._tr.height / 2 - th / 2
            return Math.max(m, Math.min(h - th - m, preferred))
        }
    }

    /* Overlay blocker — dims + blocks input to the Popup behind an isInPopup step. Lives in
     * Overlay.overlay (same layer as the target Popup) so it can actually render on top of it;
     * the inline spotlightCanvas above cannot, since it's one layer below Overlay.overlay.
     * ****************************************************************************************/
    Popup {
        id: overlayBlocker
        parent: Overlay.overlay
        z: 100
        modal: true
        dim: false
        closePolicy: Popup.NoAutoClose
        padding: 0
        background: Item {}
        visible: popupTooltip.visible

        x: 0
        y: 0
        width: Overlay.overlay ? Overlay.overlay.width : 0
        height: Overlay.overlay ? Overlay.overlay.height : 0

        contentItem: Item {
            Canvas {
                id: overlayBlockerCanvas
                anchors.fill: parent
                onPaint: root._paintDimWithHole(overlayBlockerCanvas, root._ptPos.x, root._ptPos.y,
                                                 root._ptSize.width, root._ptSize.height)
            }
        }
    }

    /* Popup tooltip — for popup steps
     * modal: true + dim: false — Qt's built-in modal mechanism blocks ALL input to items
     * behind this popup (including open app popups like UserInfoSelectionPopup) while
     * keeping the tooltip itself fully interactive. Sits above overlayBlocker (z=100).
     * x/y are bindings that depend on _ptPos/_ptSize + implicitHeight → self-correcting
     * ****************************************************************************************/
    Popup {
        id: popupTooltip
        parent: Overlay.overlay
        z: 200
        modal: true
        dim: false
        closePolicy: Popup.NoAutoClose
        padding: 0
        background: Item {}

        enter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 220
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.88
                    to: 1
                    duration: 260
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.1
                }
            }
        }

        exit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 160
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    property: "scale"
                    from: 1
                    to: 0.92
                    duration: 160
                    easing.type: Easing.InCubic
                }
            }
        }

        x: {
            var m = 14, tw = popupContent.implicitWidth
            var ow = Overlay.overlay ? Overlay.overlay.width : root.width
            if (root._ptSize.width <= 0)
                return Math.max(m, (ow - tw) / 2)

            var right = root._ptPos.x + root._ptSize.width + m
            if (right + tw <= ow - m)
                return right

            var left  = root._ptPos.x - tw - m
            if (left >= m)
                return left

            return Math.max(m, ow - tw - m)
        }

        y: {
            var m = 14, th = popupContent.implicitHeight
            var oh = Overlay.overlay ? Overlay.overlay.height : root.height
            if (root._ptSize.width <= 0)
                return Math.max(m, (oh - th) / 2)

            var preferred = root._ptPos.y + root._ptSize.height / 2 - th / 2
            return Math.max(m, Math.min(oh - th - m, preferred))
        }

        contentItem: GuideTooltip {
            id: popupContent
            stepData: root._displayedSd
            guideController: root.guideController
        }
    }

    // Fade out → swap content → fade in when popup is already open and step changes
    SequentialAnimation {
        id: _popupStepFade

        NumberAnimation {
            target: popupContent
            property: "opacity"
            to: 0
            duration: 80
            easing.type: Easing.InCubic
        }

        ScriptAction {
            script: root._displayedSd = root._sd
        }

        NumberAnimation {
            target: popupContent
            property: "opacity"
            to: 1
            duration: 130
            easing.type: Easing.OutCubic
        }
    }

    /* "Don't show tutorials" — always-on-top corner button, valid for both inline and popup
     * steps. Lives in Overlay.overlay above popupTooltip (z=200) so the dim/blocker layers
     * never cover or swallow clicks meant for it.
     * ****************************************************************************************/
    Popup {
        id: disableGuidesButton
        parent: Overlay.overlay
        z: 300
        modal: false
        dim: false
        closePolicy: Popup.NoAutoClose
        padding: 0
        background: Item {}

        visible: root.visible
        opacity: root.opacity
        x: 16
        y: 16

        contentItem: Rectangle {
            implicitWidth: disableTxt.implicitWidth + 20
            implicitHeight: 28
            radius: 6
            color: disableMa.containsMouse ? Style.colors.accentHover : Style.colors.accent

            Behavior on color {
                ColorAnimation {
                    duration: 80
                }
            }

            Text {
                id: disableTxt
                anchors.centerIn: parent
                text: "Don't show tutorials"
                font.family: Style.fontTypes.roboto
                font.pixelSize: 11
                font.weight: Font.Medium
                color: Style.colors.onAccentText
            }

            MouseArea {
                id: disableMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.guideController)
                        disableGuidesButton.close()
                        root.guideController.disableGuides()
                }
            }
        }
    }
}
