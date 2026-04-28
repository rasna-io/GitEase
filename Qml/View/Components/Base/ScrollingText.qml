import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * ScrollingText
 * Single-line text that scrolls horizontally when content is wider than available width.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string     text:               ""
    property font       font:               Qt.font({})
    property color      color:              Style.colors.foreground
    property bool       running:            true
    property int        edgePauseMs:        1000
    property real       pixelsPerSecond:    40
    property real       gap:                36

    readonly property bool needsScroll: mainText.paintedWidth > width

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: mainText.implicitWidth
    implicitHeight: mainText.implicitHeight
    clip: true

    /* Children
     * ****************************************************************************************/
    Item {
        id: contentItem

        x: 0
        y: (root.height - mainText.implicitHeight) / 2
        width: mainText.implicitWidth + (root.needsScroll ? root.gap + ghostText.implicitWidth : 0)
        height: mainText.implicitHeight

        Text {
            id: mainText

            text: root.text
            wrapMode: Text.NoWrap
            elide: Text.ElideNone
            color: root.color
            font: root.font
        }

        Text {
            id: ghostText

            visible: root.needsScroll
            x: mainText.implicitWidth + root.gap
            text: root.text
            wrapMode: Text.NoWrap
            elide: Text.ElideNone
            color: root.color
            font: root.font
        }
    }

    SequentialAnimation {
        id: marquee

        running: root.visible && root.running && root.needsScroll
        loops: Animation.Infinite

        PropertyAction {
            target: contentItem
            property: "x"
            value: 0
        }

        PauseAnimation {
            duration: root.edgePauseMs
        }

        NumberAnimation {
            target: contentItem
            property: "x"
            from: 0
            to: -(mainText.implicitWidth + root.gap)
            duration: Math.max(1, Math.round((mainText.implicitWidth + root.gap) / Math.max(1, root.pixelsPerSecond) * 1000))
            easing.type: Easing.Linear
        }
    }

    onNeedsScrollChanged: {
        if (!needsScroll) {
            contentItem.x = 0
        }
    }

    onWidthChanged: {
        if (!needsScroll) {
            contentItem.x = 0
        }
    }
}
