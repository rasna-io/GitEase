import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ContextMenuWindow
 * One level of a context menu rendered in its own frameless window, like the floating
 * notifications. It places itself the way Windows does: below and to the right of the anchor, and
 * flipped above / to the left when the screen edge would cut it off. The open / close animation
 * grows from the corner that touches the anchor.
 * ************************************************************************************************/
Window {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! Same format as ContextMenu.menuModel
    property var    menuModel: []

    //! "cursor": the window's corner touches the anchor point (a context menu)
    //! "side":   the window sits beside the anchor rect (a submenu)
    property string placement: "cursor"

    property real   menuWidth: 200
    property real   contentPadding: 6
    property real   edgeMargin: 8
    property bool   acceptsFocus: true

    //! "side" placement only: open on the left of the anchor first (the parent menu opened leftwards)
    property bool   preferLeft: false

    //! Which corner touches the anchor after placement, drives the animation origin
    property bool   flippedX: false
    property bool   flippedY: false

    //! 0 = hidden, 1 = fully shown
    property real   progress: 0

    readonly property real panelHeight: menuColumn.implicitHeight + contentPadding * 2

    /* Signals
     * ****************************************************************************************/
    signal itemHovered(var item, rect itemRect)
    signal itemTriggered(var item, bool checked)
    signal dismissRequested()
    signal hidden()

    /* Functions
     * ****************************************************************************************/
    function screenAt(px, py) {
        const screens = Qt.application.screens
        for(let i = 0; i < screens.length; ++i) {
            const s = screens[i]
            if(px >= s.virtualX && px < s.virtualX + s.width && py >= s.virtualY && py < s.virtualY + s.height) {
                return s
            }
        }
        return screens.length > 0 ? screens[0] : null
    }

    /*!
     * Opens the window next to \a anchor, a rect in global coordinates. For the "cursor"
     * placement only anchor.x / anchor.y matter.
     */
    function openAt(anchor) {
        const w = menuWidth
        const h = panelHeight
        const scr = screenAt(anchor.x, anchor.y)

        let left = 0
        let top = 0
        let right = 100000
        let bottom = 100000
        if(scr) {
            left = scr.virtualX
            top = scr.virtualY
            //! Keep a small gap to the screen edge so a menu that only just fits flips instead
            right = scr.virtualX + scr.desktopAvailableWidth - edgeMargin
            bottom = scr.virtualY + scr.desktopAvailableHeight - edgeMargin
        }

        let px = 0
        let py = 0
        let fx = false
        let fy = false

        if(placement === "side") {
            //! Try the preferred side first, fall back to the other one when it doesn't fit
            const rightX = anchor.x + anchor.width - 4
            const leftX = anchor.x - w + 4
            const fitsRight = rightX + w <= right
            const fitsLeft = leftX >= left
            if(preferLeft ? (fitsLeft || !fitsRight) : (!fitsRight && fitsLeft)) {
                px = leftX
                fx = true
            } else {
                px = rightX
            }

            py = anchor.y - contentPadding
            if(py + h > bottom) {
                py = anchor.y + anchor.height + contentPadding - h
                fy = true
            }
        } else {
            px = anchor.x
            if(px + w > right) {
                px = anchor.x - w
                fx = true
            }

            py = anchor.y
            if(py + h > bottom) {
                py = anchor.y - h
                fy = true
            }
        }

        flippedX = fx
        flippedY = fy

        x = Math.max(left, Math.min(px, right - w))
        y = Math.max(top, Math.min(py, bottom - h))

        hideAnimation.stop()
        progress = 0
        visible = true
        showAnimation.restart()
    }

    function hideAnimated() {
        if(!visible) {
            return
        }

        showAnimation.stop()
        hideAnimation.restart()
    }

    function hideNow() {
        showAnimation.stop()
        hideAnimation.stop()
        progress = 0
        visible = false
    }

    /* Object Properties
     * ****************************************************************************************/
    width: menuWidth
    height: panelHeight

    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
           | (acceptsFocus ? 0 : Qt.WindowDoesNotAcceptFocus)
    color: "transparent"
    visible: false

    onVisibleChanged: {
        if(visible) {
            if(acceptsFocus) {
                requestActivate()
            }
        } else {
            hidden()
        }
    }

    /* Animations
     * ****************************************************************************************/
    NumberAnimation {
        id: showAnimation
        target: root
        property: "progress"
        to: 1
        duration: Style.motionFast
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: hideAnimation
        target: root
        property: "progress"
        to: 0
        duration: Style.motionFast
        easing.type: Easing.InCubic
        onFinished: {
            root.visible = false
        }
    }

    /* Children
     * ****************************************************************************************/
    Item {
        id: panel
        anchors.fill: parent
        focus: true
        opacity: root.progress

        transform: Scale {
            origin.x: root.flippedX ? panel.width : 0
            origin.y: root.flippedY ? panel.height : 0
            xScale: 0.94 + 0.06 * root.progress
            yScale: 0.85 + 0.15 * root.progress
        }

        Keys.onEscapePressed: {
            root.dismissRequested()
        }

        Rectangle {
            anchors.fill: parent
            color: Style.colors.contextMenuBackground
            radius: 4
            border.color: Style.colors.contextMenuBorder
            border.width: 1
        }

        Column {
            id: menuColumn
            x: root.contentPadding
            y: root.contentPadding
            width: parent.width - root.contentPadding * 2
            spacing: 1

            Repeater {
                model: root.menuModel
                delegate: menuDelegateComponent
            }
        }
    }

    Component {
        id: menuDelegateComponent
        Item {
            id: menuOption
            width: parent.width
            height: modelData.separator ? 9 : Style.dp(25)
            visible: modelData.visible !== false
            readonly property bool isSep:     !!modelData.separator
            readonly property bool isEnabled: !isSep && modelData.enabled !== false
            readonly property bool hasSub:    !isSep && !!modelData.subItems && modelData.subItems.length > 0

            //! Per-item tinting: "color" applies to label and icon, "iconColor" overrides the icon.
            readonly property bool  hasColor:  !isSep && modelData.color !== undefined && modelData.color !== ""
            readonly property color textColor: hasColor ? modelData.color : Style.colors.foreground
            readonly property color iconColor: (!isSep && modelData.iconColor !== undefined && modelData.iconColor !== "")
                                               ? modelData.iconColor
                                               : (hasColor ? modelData.color
                                                           : (itemMouse.containsMouse ? Style.colors.accent
                                                                                      : Style.colors.foreground))

            // Separator line
            Rectangle {
                visible: menuOption.isSep
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                height: 1
                color: Style.colors.contextMenuSeparator
            }

            // Normal item background
            Rectangle {
                visible: !menuOption.isSep
                anchors.fill: parent
                radius: 4
                color: (itemMouse.containsMouse && menuOption.isEnabled) ? Style.colors.contextMenuHover : "transparent"
            }

            RowLayout {
                visible: !menuOption.isSep
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10
                opacity: menuOption.isEnabled ? 1.0 : 0.4

                // Icon
                Text {
                    text: modelData.icon || ""
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.appFont.mediumPt
                    color: menuOption.iconColor
                    visible: text !== ""
                    Layout.preferredWidth: 16
                }

                // Label
                ScrollingText {
                    text: modelData.text || ""
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                    color: menuOption.textColor
                    Layout.fillWidth: true
                }

                CheckBox {
                    id: checkBox
                    text: modelData.checkBoxText
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                    Layout.preferredHeight: Style.dp(25)
                    checked: false
                    visible: modelData.hasCheckBox === true && modelData.enabled
                }

                // Shortcut hint
                Text {
                    text: modelData.shortcut || ""
                    visible: !menuOption.hasSub && modelData.shortcut !== undefined && modelData.shortcut !== ""
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt
                    color: Style.colors.mutedText
                }

                Text {
                    text: "❯"
                    visible: menuOption.hasSub
                    font.pixelSize: Style.appFont.smallPt
                    color: Style.colors.foreground
                }
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: menuOption.isEnabled
                z: -1
                onEntered: {
                    const topLeft = menuOption.mapToGlobal(0, 0)
                    root.itemHovered(modelData, Qt.rect(topLeft.x, topLeft.y, menuOption.width, menuOption.height))
                }
                onClicked: {
                    if(menuOption.isEnabled && !menuOption.hasSub) {
                        root.itemTriggered(modelData, checkBox.checked)
                    }
                }
            }
        }
    }
}
