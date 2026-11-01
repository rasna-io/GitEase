import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import GitEase_Style

/*! ***********************************************************************************************
 * ImageDiffViewer
 * Host passes repositoryPath, filePath, oldImageUrl and newImageUrl.
 * Side by side is selected first. Each picture is fitted to its pane, then
 * zoom and pan stay in step. Swipe drags a divider to reveal the new picture.
 * Onion skin fades the new picture over the old one.
 * SVG and SVGZ are drawn as vectors, rasterized to the pane so they stay sharp.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string repositoryPath: ""
    property string filePath: ""
    property url    oldImageUrl: ""
    property url    newImageUrl: ""

    readonly property int modeSideBySide: 0
    readonly property int modeSwipe: 1
    readonly property int modeOnion: 2
    property int mode: modeSideBySide

    property real zoom: 1
    property real panX: 0
    property real panY: 0
    property real swipe: 0.5
    property real onion: 0.5

    readonly property string fileName: {
        const path = (root.filePath || "").replace(/\\/g, "/")
        const slash = path.lastIndexOf("/")
        const name = slash >= 0 ? path.substring(slash + 1) : path
        return name.replace(/ ●$/, "")
    }

    readonly property bool oldVector: root.isVectorUrl(root.oldImageUrl)
    readonly property bool newVector: root.isVectorUrl(root.newImageUrl)
    readonly property bool showsVector: root.oldVector || root.newVector

    readonly property bool oldReady: oldImage.status === Image.Ready
    readonly property bool newReady: newImage.status === Image.Ready
    readonly property bool bothReady: root.oldReady && root.newReady

    readonly property real oldLayoutWidth: root.mode === root.modeSideBySide ? oldClip.width : stage.width
    readonly property real oldLayoutHeight: stage.height
    readonly property real newLayoutWidth: root.mode === root.modeSideBySide ? newClip.width : stage.width
    readonly property real newLayoutHeight: stage.height

    readonly property color checkerBase: Style.colors.diffViewBackground
    readonly property color checkerAlt: Style.colors.secondaryBackground

    readonly property string sizeText: {
        const parts = []
        if (!root.oldVector && !root.newVector) {
            const oldPx = root.pixelSize(oldImage)
            const newPx = root.pixelSize(newImage)
            if (oldPx && newPx && oldPx !== newPx)
                parts.push(oldPx + "  →  " + newPx)
            else if (oldPx || newPx)
                parts.push(oldPx || newPx)
        }

        if (root.oldImageUrl.toString().length === 0 && root.newImageUrl.toString().length > 0)
            parts.push(qsTr("No earlier version"))
        else if (root.newImageUrl.toString().length === 0 && root.oldImageUrl.toString().length > 0)
            parts.push(qsTr("No new version"))

        if (oldImage.status === Image.Error || newImage.status === Image.Error)
            parts.push(qsTr("Not a readable image"))

        return parts.join("   ·   ")
    }

    readonly property string overlayMessage: {
        if (root.mode === root.modeSideBySide)
            return ""
        if (oldImage.status === Image.Error || newImage.status === Image.Error)
            return qsTr("Not a readable image")
        if (!root.oldReady && !root.newReady)
            return (root.oldImageUrl.toString().length === 0 && root.newImageUrl.toString().length === 0)
                    ? qsTr("No image")
                    : qsTr("Loading…")
        return ""
    }

    /* Object Properties
     * ****************************************************************************************/
    clip: true

    onFilePathChanged: root.resetView()
    onModeChanged: root.resetView()

    onZoomChanged: root.clampPan()
    onOldReadyChanged: root.clampPan()
    onNewReadyChanged: root.clampPan()
    onCheckerBaseChanged: checker.requestPaint()
    onCheckerAltChanged: checker.requestPaint()

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.dp(40)
            color: Style.colors.secondaryBackground

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.dp(8)
                anchors.rightMargin: Style.dp(8)
                spacing: Style.dp(8)

                Rectangle {
                    id: modeTrack
                    Layout.preferredWidth: modeRow.implicitWidth + Style.dp(4)
                    Layout.preferredHeight: Style.dp(28)
                    Layout.alignment: Qt.AlignVCenter
                    radius: Style.dp(5)
                    color: Style.colors.utilitiesSegmentTrackBackground
                    border.width: 1
                    border.color: Style.colors.utilitiesSegmentTrackBorder

                    Row {
                        id: modeRow
                        anchors.fill: parent
                        anchors.margins: Style.dp(2)
                        spacing: Style.dp(2)

                        ModeButton {
                            label: qsTr("Side by side")
                            chosen: root.mode === root.modeSideBySide
                            onActivated: root.mode = root.modeSideBySide
                        }
                        ModeButton {
                            label: qsTr("Swipe")
                            chosen: root.mode === root.modeSwipe
                            onActivated: root.mode = root.modeSwipe
                        }
                        ModeButton {
                            label: qsTr("Onion skin")
                            chosen: root.mode === root.modeOnion
                            onActivated: root.mode = root.modeOnion
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    visible: root.mode === root.modeOnion
                    spacing: Style.dp(8)

                    Text {
                        text: qsTr("Earlier")
                        color: Style.colors.diffRemovedText
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.smallPt
                    }

                    BlendSlider {
                        Layout.preferredWidth: Style.dp(120)
                        Layout.preferredHeight: Style.dp(18)
                        value: root.onion
                        onMoved: (next) => root.onion = next
                    }

                    Text {
                        text: qsTr("New")
                        color: Style.colors.diffAddedText
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.smallPt
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Style.colors.primaryBorder
            }
        }

        Item {
            id: stage
            Layout.fillWidth: true
            Layout.fillHeight: true

            Canvas {
                id: checker
                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d")
                    if (!ctx)
                        return
                    const cell = 12
                    ctx.fillStyle = root.checkerBase
                    ctx.fillRect(0, 0, width, height)
                    ctx.fillStyle = root.checkerAlt
                    const rows = Math.ceil(height / cell)
                    const cols = Math.ceil(width / cell)
                    for (let row = 0; row < rows; ++row) {
                        for (let col = (row % 2); col < cols; col += 2)
                            ctx.fillRect(col * cell, row * cell, cell, cell)
                    }
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Component.onCompleted: requestPaint()
            }

            Item {
                id: oldClip
                x: 0
                y: 0
                width: root.mode === root.modeSideBySide
                       ? Math.max(0, Math.floor((stage.width - 1) / 2))
                       : stage.width
                height: stage.height
                clip: true

                DiffPicture {
                    id: oldImage
                    sourceUrl: root.oldImageUrl
                    vector: root.oldVector
                    zoom: root.zoom
                    layoutWidth: root.oldLayoutWidth
                    layoutHeight: root.oldLayoutHeight
                    visible: root.oldReady
                    x: root.placed(oldImage, root.oldLayoutWidth, root.oldLayoutHeight).x
                    y: root.placed(oldImage, root.oldLayoutWidth, root.oldLayoutHeight).y
                    width: root.placed(oldImage, root.oldLayoutWidth, root.oldLayoutHeight).w
                    height: root.placed(oldImage, root.oldLayoutWidth, root.oldLayoutHeight).h
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - Style.dp(24)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    visible: root.mode === root.modeSideBySide && !root.oldReady
                    text: root.sideMessage(oldImage, root.oldImageUrl, qsTr("No earlier version"))
                    color: oldImage.status === Image.Error ? Style.colors.error : Style.colors.secondaryText
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                }
            }

            Item {
                id: newClip
                x: root.mode === root.modeSideBySide ? oldClip.width + 1 : 0
                y: 0
                width: {
                    if (root.mode === root.modeSideBySide)
                        return Math.max(0, stage.width - oldClip.width - 1)
                    if (root.mode === root.modeSwipe && root.bothReady)
                        return Math.max(0, stage.width * root.swipe)
                    return stage.width
                }
                height: stage.height
                clip: true

                DiffPicture {
                    id: newImage
                    sourceUrl: root.newImageUrl
                    vector: root.newVector
                    zoom: root.zoom
                    pictureOpacity: root.mode === root.modeOnion ? root.onion : 1
                    layoutWidth: root.newLayoutWidth
                    layoutHeight: root.newLayoutHeight
                    visible: root.newReady
                    x: root.placed(newImage, root.newLayoutWidth, root.newLayoutHeight).x
                    y: root.placed(newImage, root.newLayoutWidth, root.newLayoutHeight).y
                    width: root.placed(newImage, root.newLayoutWidth, root.newLayoutHeight).w
                    height: root.placed(newImage, root.newLayoutWidth, root.newLayoutHeight).h
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - Style.dp(24)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    visible: root.mode === root.modeSideBySide && !root.newReady
                    text: root.sideMessage(newImage, root.newImageUrl, qsTr("No new version"))
                    color: newImage.status === Image.Error ? Style.colors.error : Style.colors.secondaryText
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                }
            }

            Rectangle {
                visible: root.mode === root.modeSideBySide
                x: oldClip.width
                width: 1
                height: parent.height
                color: Style.colors.primaryBorder
            }

            VersionBadge {
                z: 1
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: Style.dp(8)
                visible: root.oldReady
                label: qsTr("Earlier")
                badgeColor: Style.colors.diffRemovedBg
                badgeBorder: Style.colors.diffRemovedBorder
                labelColor: Style.colors.diffRemovedText
            }

            VersionBadge {
                z: 1
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.dp(8)
                visible: root.newReady
                label: qsTr("New")
                badgeColor: Style.colors.diffAddedBg
                badgeBorder: Style.colors.diffAddedBorder
                labelColor: Style.colors.diffAddedText
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - Style.dp(32)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: root.overlayMessage !== ""
                text: root.overlayMessage
                color: (oldImage.status === Image.Error || newImage.status === Image.Error)
                       ? Style.colors.error
                       : Style.colors.secondaryText
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.mediumPt
            }

            MouseArea {
                id: panArea
                anchors.fill: parent
                z: 2
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                preventStealing: true

                property real lastX: 0
                property real lastY: 0

                onPressed: (mouse) => {
                    lastX = mouse.x
                    lastY = mouse.y
                }
                onPositionChanged: (mouse) => {
                    if (!pressed)
                        return
                    root.panX += mouse.x - lastX
                    root.panY += mouse.y - lastY
                    lastX = mouse.x
                    lastY = mouse.y
                    root.clampPan()
                }
                onDoubleClicked: root.resetView()

                WheelHandler {
                    onWheel: (event) => root.handleWheel(event)
                }
            }

            MouseArea {
                id: swipeHandle
                z: 4
                visible: root.mode === root.modeSwipe && root.bothReady
                x: newClip.width - width / 2
                width: Style.dp(22)
                height: parent.height
                hoverEnabled: true
                cursorShape: Qt.SplitHCursor
                preventStealing: true

                onPositionChanged: (mouse) => {
                    if (!pressed || stage.width <= 0)
                        return
                    const x = swipeHandle.mapToItem(stage, mouse.x, mouse.y).x
                    root.swipe = Math.max(0.02, Math.min(0.98, x / stage.width))
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 2
                    height: parent.height
                    color: Style.colors.accent
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Style.dp(14)
                    height: Style.dp(28)
                    radius: Style.dp(4)
                    color: Style.colors.secondaryForeground
                    border.width: 1
                    border.color: Style.colors.accent

                    Rectangle {
                        anchors.centerIn: parent
                        width: Style.dp(2)
                        height: Style.dp(12)
                        radius: 1
                        color: Style.colors.accent
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.dp(32)
            color: Style.colors.secondaryBackground

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: Style.colors.primaryBorder
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.dp(10)
                anchors.rightMargin: Style.dp(8)
                spacing: Style.dp(8)

                Text {
                    Layout.fillWidth: true
                    text: root.fileName
                    elide: Text.ElideMiddle
                    color: Style.colors.foreground
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt

                    HoverHandler { id: nameHover }
                    ToolTip.visible: nameHover.hovered && root.filePath !== ""
                    ToolTip.text: root.repositoryPath !== ""
                                  ? (root.repositoryPath + "/" + root.filePath)
                                  : root.filePath
                    ToolTip.delay: 400
                }

                Rectangle {
                    visible: root.showsVector
                    Layout.preferredWidth: vectorLabel.implicitWidth + Style.dp(10)
                    Layout.preferredHeight: Style.dp(18)
                    Layout.alignment: Qt.AlignVCenter
                    radius: Style.dp(4)
                    color: Style.colors.pluginBadgeBackground
                    border.width: 1
                    border.color: Style.colors.pluginBadgeBorder

                    Text {
                        id: vectorLabel
                        anchors.centerIn: parent
                        text: "SVG"
                        color: Style.colors.pluginBadgeText
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        font.weight: Font.DemiBold
                    }
                }

                Text {
                    visible: root.sizeText !== ""
                    text: root.sizeText
                    color: (oldImage.status === Image.Error || newImage.status === Image.Error)
                           ? Style.colors.error
                           : Style.colors.secondaryText
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.smallPt
                    elide: Text.ElideRight
                }

                ZoomButton {
                    label: qsTr("Fit")
                    tooltip: qsTr("Fit to view")
                    wide: true
                    onActivated: root.resetView()
                }
                ZoomButton {
                    iconText: Style.icons.minus
                    tooltip: qsTr("Zoom out")
                    onActivated: {
                        root.zoom = Math.max(1, root.zoom / 1.25)
                        root.clampPan()
                    }
                }
                Text {
                    text: Math.round(root.zoom * 100) + "%"
                    color: Style.colors.foreground
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.smallPt
                    horizontalAlignment: Text.AlignHCenter
                    Layout.preferredWidth: Style.dp(44)
                }
                ZoomButton {
                    iconText: Style.icons.plus
                    tooltip: qsTr("Zoom in")
                    onActivated: {
                        root.zoom = Math.min(8, root.zoom * 1.25)
                        root.clampPan()
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function isVectorUrl(url) {
        const path = (url || "").toString().split("?")[0].toLowerCase()
        return path.endsWith(".svg") || path.endsWith(".svgz")
    }

    function sideMessage(image, url, emptyText) {
        if (image.status === Image.Error)
            return qsTr("Not a readable image")
        if (!url || url.toString().length === 0)
            return emptyText
        return qsTr("Loading…")
    }

    function pixelSize(image) {
        if (image.status !== Image.Ready || image.sourceSize.width <= 0)
            return ""
        return Math.round(image.sourceSize.width) + " × " + Math.round(image.sourceSize.height)
    }

    function placed(image, paneW, paneH) {
        let sw = image.sourceSize.width
        let sh = image.sourceSize.height
        if (image.status !== Image.Ready || paneW <= 0 || paneH <= 0)
            return { x: 0, y: 0, w: 0, h: 0 }
        if (sw <= 0 || sh <= 0) {
            sw = paneW
            sh = paneH
        }

        const fit = Math.min(paneW / sw, paneH / sh)
        const w = sw * fit * root.zoom
        const h = sh * fit * root.zoom
        return {
            x: (paneW - w) / 2 + root.panX,
            y: (paneH - h) / 2 + root.panY,
            w: w,
            h: h
        }
    }

    function clampPan() {
        let maxX = 0
        let maxY = 0
        function consider(image, paneW, paneH) {
            let sw = image.sourceSize.width
            let sh = image.sourceSize.height
            if (image.status !== Image.Ready || paneW <= 0 || paneH <= 0)
                return
            if (sw <= 0 || sh <= 0) {
                sw = paneW
                sh = paneH
            }
            const fit = Math.min(paneW / sw, paneH / sh)
            const dw = sw * fit * root.zoom
            const dh = sh * fit * root.zoom
            maxX = Math.max(maxX, (dw - paneW) / 2)
            maxY = Math.max(maxY, (dh - paneH) / 2)
        }

        if (root.mode === root.modeSideBySide) {
            consider(oldImage, oldClip.width, oldClip.height)
            consider(newImage, newClip.width, newClip.height)
        } else {
            consider(oldImage, stage.width, stage.height)
            consider(newImage, stage.width, stage.height)
        }

        root.panX = Math.max(-maxX, Math.min(maxX, root.panX))
        root.panY = Math.max(-maxY, Math.min(maxY, root.panY))
    }

    function resetView() {
        root.zoom = 1
        root.panX = 0
        root.panY = 0
    }

    function handleWheel(event) {
        if (event.modifiers & Qt.ControlModifier) {
            const steps = event.angleDelta.y / 120
            root.zoom = Math.max(1, Math.min(8, root.zoom * Math.pow(1.15, steps)))
        } else {
            root.panX += event.angleDelta.x
            root.panY += event.angleDelta.y
        }
        root.clampPan()
    }

    component ModeButton: Rectangle {
        id: button
        property string label: ""
        property bool chosen: false
        signal activated()

        implicitWidth: caption.implicitWidth + Style.dp(16)
        implicitHeight: Style.dp(24)
        width: button.implicitWidth
        height: button.implicitHeight
        radius: Style.dp(4)
        color: button.chosen
               ? Style.colors.utilitiesSegmentSelectedBackground
               : (buttonArea.containsMouse ? Style.colors.utilitiesSegmentHoverBackground : "transparent")

        Behavior on color {
            ColorAnimation { duration: Style.motionFast }
        }

        Text {
            id: caption
            anchors.centerIn: parent
            text: button.label
            color: button.chosen
                   ? Style.colors.utilitiesSegmentSelectedText
                   : Style.colors.utilitiesSegmentText
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.smallPt
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.activated()
        }
    }

    component ZoomButton: Rectangle {
        id: zoomButton
        property string label: ""
        property string iconText: ""
        property string tooltip: ""
        property bool wide: false
        signal activated()

        Layout.preferredWidth: zoomButton.wide
                               ? zoomCaption.implicitWidth + Style.dp(14)
                               : Style.dp(22)
        Layout.preferredHeight: Style.dp(22)
        Layout.alignment: Qt.AlignVCenter
        radius: Style.dp(4)
        color: zoomArea.containsMouse ? Style.colors.surfaceMuted : "transparent"
        border.width: zoomButton.wide ? 1 : 0
        border.color: zoomArea.containsMouse ? Style.colors.controlBorderHover : Style.colors.controlBorder

        Text {
            id: zoomCaption
            anchors.centerIn: parent
            visible: zoomButton.label !== ""
            text: zoomButton.label
            color: zoomArea.containsMouse ? Style.colors.foreground : Style.colors.secondaryText
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.smallPt
        }

        Text {
            anchors.centerIn: parent
            visible: zoomButton.iconText !== ""
            text: zoomButton.iconText
            color: zoomArea.containsMouse ? Style.colors.foreground : Style.colors.secondaryText
            font.family: Style.fontTypes.font6Pro
            font.styleName: "Solid"
            font.pixelSize: Style.appFont.smallPt
        }

        MouseArea {
            id: zoomArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: zoomButton.activated()
        }

        ToolTip.visible: zoomArea.containsMouse && zoomButton.tooltip !== ""
        ToolTip.text: zoomButton.tooltip
        ToolTip.delay: 400
    }

    component VersionBadge: Rectangle {
        id: badge
        property string label: ""
        property color badgeColor: "transparent"
        property color badgeBorder: "transparent"
        property color labelColor: "white"

        width: badgeText.implicitWidth + Style.dp(12)
        height: Style.dp(20)
        radius: Style.dp(4)
        color: badge.badgeColor
        border.width: 1
        border.color: badge.badgeBorder

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: badge.label
            color: badge.labelColor
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.captionPt
        }
    }

    component BlendSlider: Item {
        id: blend
        property real value: 0.5
        signal moved(real next)

        readonly property color earlierColor: Style.colors.diffRemovedText
        readonly property color newerColor: Style.colors.diffAddedText
        readonly property color handleBorder: Style.theme === Style.Theme.Dark
                                               ? Style.colors.primaryBackground
                                               : Style.colors.foreground

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: Style.dp(4)
            radius: height / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: blend.earlierColor }
                GradientStop { position: 0.5; color: Style.colors.switchTrackOff }
                GradientStop { position: 1.0; color: blend.newerColor }
            }
        }

        Rectangle {
            x: (blend.width - width) * blend.value
            anchors.verticalCenter: parent.verticalCenter
            width: Style.dp(14)
            height: Style.dp(14)
            radius: width / 2
            color: Style.colors.switchHandle
            border.width: 2
            border.color: blend.handleBorder
        }

        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -Style.dp(6)
            anchors.bottomMargin: -Style.dp(6)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: (mouse) => blend.apply(mouse.x)
            onPositionChanged: (mouse) => {
                if (pressed)
                    blend.apply(mouse.x)
            }
        }

        function apply(x) {
            if (blend.width <= 0)
                return
            blend.moved(Math.max(0, Math.min(1, x / blend.width)))
        }
    }

    component DiffPicture: Item {
        id: picture

        property url sourceUrl
        property bool vector: false
        property real zoom: 1
        property real pictureOpacity: 1
        property real layoutWidth: 0
        property real layoutHeight: 0

        readonly property int wantedEdge: picture.vector
                                          ? picture.vectorEdgeFor(picture.layoutWidth, picture.layoutHeight)
                                          : 0

        property int shownIndex: 0

        readonly property int status: {
            const url = picture.sourceUrl.toString()
            if (url.length === 0)
                return Image.Null
            const frame = picture.shownIndex === 0 ? frameA : frameB
            if (frame.loadedUrl.toString() !== url)
                return frame.status === Image.Error ? Image.Error : Image.Loading
            if (frame.status === Image.Ready)
                return Image.Ready
            if (frame.status === Image.Error)
                return Image.Error
            if (frameA.status === Image.Error && frameB.status === Image.Error)
                return Image.Error
            return Image.Loading
        }

        readonly property size sourceSize: (picture.shownIndex === 0 ? frameA : frameB).sourceSize

        onSourceUrlChanged: picture.present()
        onWantedEdgeChanged: {
            if (frameA.source.toString().length === 0 && frameB.source.toString().length === 0)
                picture.present()
            else
                refineTimer.restart()
        }
        Component.onCompleted: picture.present()

        Timer {
            id: refineTimer
            interval: 60
            repeat: false
            onTriggered: picture.refine()
        }

        function vectorEdgeFor(paneW, paneH) {
            const pane = Math.max(paneW, paneH)
            if (pane < 8)
                return 0
            const dpr = Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1
            const raw = pane * Math.max(picture.zoom, 1) * dpr
            const stepped = Math.ceil(raw / 128) * 128
            return Math.max(256, Math.min(4096, stepped))
        }

        function clearFrames() {
            frameA.pendingShow = false
            frameB.pendingShow = false
            frameA.loadedUrl = ""
            frameB.loadedUrl = ""
            frameA.source = ""
            frameB.source = ""
            picture.shownIndex = 0
        }

        function present() {
            if (picture.sourceUrl.toString().length === 0) {
                picture.clearFrames()
                return
            }
            if (picture.vector && picture.wantedEdge <= 0) {
                picture.clearFrames()
                return
            }
            picture.request(frameA, 0, picture.vector ? picture.wantedEdge : 0)
            frameB.pendingShow = false
            frameB.loadedUrl = ""
            frameB.source = ""
        }

        function refine() {
            if (!picture.vector || picture.wantedEdge <= 0)
                return
            if (picture.sourceUrl.toString().length === 0)
                return
            const shown = picture.shownIndex === 0 ? frameA : frameB
            if (shown.pendingShow && shown.status !== Image.Ready) {
                picture.request(shown, picture.shownIndex, picture.wantedEdge)
                return
            }
            if (shown.requestedWidth === picture.wantedEdge && shown.status === Image.Ready)
                return
            const hiddenIndex = picture.shownIndex === 0 ? 1 : 0
            const hidden = hiddenIndex === 0 ? frameA : frameB
            picture.request(hidden, hiddenIndex, picture.wantedEdge)
        }

        function request(frame, index, edge) {
            const current = frame.source === picture.sourceUrl
                    && frame.requestedWidth === edge
                    && frame.loadedUrl.toString() === picture.sourceUrl.toString()
            if (current) {
                if (frame.status === Image.Ready)
                    picture.shownIndex = index
                frame.pendingShow = frame.status !== Image.Ready
                return
            }
            frame.pendingShow = true
            frame.loadedUrl = ""
            frame.requestedWidth = edge
            if (frame.source !== picture.sourceUrl)
                frame.source = picture.sourceUrl
            if (frame.sourceSize.width !== edge)
                frame.sourceSize = Qt.size(Math.max(0, edge), 0)
            frame.loadedUrl = picture.sourceUrl
            if (frame.status === Image.Ready
                    && frame.source === picture.sourceUrl
                    && frame.requestedWidth === edge) {
                picture.shownIndex = index
                frame.pendingShow = false
            }
        }

        function promote(index) {
            const frame = index === 0 ? frameA : frameB
            if (!frame.pendingShow || frame.status !== Image.Ready)
                return
            if (frame.loadedUrl.toString() !== picture.sourceUrl.toString())
                return
            if (picture.vector && picture.wantedEdge > 0 && frame.requestedWidth !== picture.wantedEdge) {
                picture.request(frame, index, picture.wantedEdge)
                return
            }
            picture.shownIndex = index
            frame.pendingShow = false
        }

        Image {
            id: frameA
            property bool pendingShow: false
            property int requestedWidth: -1
            property url loadedUrl
            anchors.fill: parent
            visible: picture.shownIndex === 0 && status === Image.Ready
            opacity: picture.pictureOpacity
            asynchronous: !picture.vector
            cache: false
            smooth: true
            mipmap: !picture.vector
            fillMode: Image.PreserveAspectFit
            onStatusChanged: picture.promote(0)
        }

        Image {
            id: frameB
            property bool pendingShow: false
            property int requestedWidth: -1
            property url loadedUrl
            anchors.fill: parent
            visible: picture.shownIndex === 1 && status === Image.Ready
            opacity: picture.pictureOpacity
            asynchronous: !picture.vector
            cache: false
            smooth: true
            mipmap: !picture.vector
            fillMode: Image.PreserveAspectFit
            onStatusChanged: picture.promote(1)
        }
    }
}
