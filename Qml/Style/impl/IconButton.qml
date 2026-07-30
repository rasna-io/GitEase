
import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl
import Qt5Compat.GraphicalEffects

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * IconButton
 *
 * A T.Button whose icon can be either a Font Awesome glyph (icon.name) or an image/svg
 * (icon.source), laid out beside, instead of, or without any text according to `display`
 * (IconButton.IconOnly, IconButton.TextOnly, IconButton.TextBesideIcon). Colors follow
 * Style.colors so it matches the rest of the app's theme.
 *
 * Set `tooltip` for a hover tooltip, and `maximumWidth` to cap the label's width and have
 * it marquee-scroll on hover instead of eliding (handy for long branch/file names).
 * ************************************************************************************************/
T.Button {
    id: control

    /*! Whether the icon glyph should render in its "solid" Font Awesome weight (only applies
     * when icon.name is used). Defaults to solid while hovered/pressed, override per instance
     * for a different rule (e.g. always solid, or driven by some external active state). */
    property bool solidIcon: control.hovered || control.down

    property string tooltip:      ""
    property real   maximumWidth: -1

    property color  backgroundColor:      Style.colors.secondaryBackground
    property color  hoverBackgroundColor: Style.colors.cardBackground
    property color  borderColor:          "transparent"
    property real   borderWidth:          0

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 6
    spacing: 6
    hoverEnabled: true
    opacity: enabled ? 1.0 : 0.5

    icon.width: 16
    icon.height: 16
    icon.color: control.enabled ? Style.colors.foreground : Style.colors.mutedText

    contentItem: Item {
        id: contentRoot

        implicitWidth: contentGroup.implicitWidth
        implicitHeight: contentGroup.implicitHeight

        Item {
            id: contentGroup
            anchors.centerIn: parent
            implicitWidth: (iconItem.visible ? iconItem.width : 0) +
                           (iconItem.visible && (label.visible || scrollLabel.visible) ? control.spacing : 0) +
                           (label.visible ? label.implicitWidth : 0) +
                           (scrollLabel.visible ? scrollLabel.width : 0)
            implicitHeight: Math.max(iconItem.visible ? iconItem.height : 0,
                                     label.visible ? label.implicitHeight : 0,
                                     scrollLabel.visible ? scrollLabel.height : 0)

            Item {
                id: iconItem
                visible: control.display !== T.AbstractButton.TextOnly &&
                         (control.icon.name !== "" || control.icon.source.toString() !== "")
                width: control.icon.width
                height: control.icon.height
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.fill: parent
                    visible: control.icon.name !== ""
                    text: control.icon.name
                    font.family: control.solidIcon ? Style.fontTypes.font6ProSolid : Style.fontTypes.font6Pro
                    font.pixelSize: Math.min(width, height)
                    color: control.icon.color
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Image {
                    id: iconImage
                    anchors.fill: parent
                    visible: control.icon.name === "" && control.icon.source.toString() !== ""
                    source: control.icon.source
                    sourceSize: Qt.size(width, height)
                    fillMode: Image.PreserveAspectFit
                    smooth: true

                    ColorOverlay {
                        anchors.fill: iconImage
                        source: iconImage
                        color: control.icon.color
                        visible: iconImage.visible
                    }
                }
            }

            Text {
                id: label
                visible: control.display !== T.AbstractButton.IconOnly && control.text !== "" && control.maximumWidth <= 0
                anchors.left: iconItem.visible ? iconItem.right : parent.left
                anchors.leftMargin: iconItem.visible ? control.spacing : 0
                anchors.verticalCenter: parent.verticalCenter
                text: control.text
                font: control.font
                color: control.icon.color
            }

            Item {
                id: scrollLabel
                visible: control.display !== T.AbstractButton.IconOnly && control.text !== "" && control.maximumWidth > 0
                anchors.left: iconItem.visible ? iconItem.right : parent.left
                anchors.leftMargin: iconItem.visible ? control.spacing : 0
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(control.maximumWidth, scrollText.implicitWidth)
                height: scrollText.implicitHeight

                ScrollingText {
                    id: scrollText
                    anchors.fill: parent
                    text: control.text
                    font: control.font
                    color: control.icon.color
                }
            }
        }
    }

    background: Rectangle {
        radius: 5
        color: !control.enabled ? Style.colors.primaryBackground :
               control.down ? Style.colors.surfaceMuted :
               control.hovered ? control.hoverBackgroundColor : control.backgroundColor
        border.width: control.borderWidth
        border.color: control.borderColor
    }

    ToolTip {
        visible: control.hovered && control.tooltip !== ""
        text: control.tooltip
        delay: 600
        x: (parent.width - width) / 2
        y: -height - 6
        padding: 6
        background: Rectangle {
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.85)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
        }
    }

    /* Animations
     * ****************************************************************************************/
    states: [
        State {
            name: "pressed"
            PropertyChanges {
                target: control
                scale: 0.8
            }
        }
    ]

    transitions: [
        Transition {
            from: ""
            to: "pressed"
            NumberAnimation { properties: "scale"; duration: 100 }
        },
        Transition {
            from: "pressed"
            to: ""
            NumberAnimation {
                properties: "scale"
                duration: 200
                easing.type: Easing.OutElastic
                easing.amplitude: 0.6
            }
        }
    ]

    onPressed: state = "pressed"
    onReleased: state = ""
    onCanceled: state = ""
}
