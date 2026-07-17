
import QtQuick
import QtQuick.Templates as T
import Qt5Compat.GraphicalEffects

import GitEase_Style

/*! ***********************************************************************************************
 * IconButton
 *
 * A T.Button whose icon can be either a Font Awesome glyph (icon.name) or an image/svg
 * (icon.source), laid out beside, instead of, or without any text according to `display`
 * (IconButton.IconOnly, IconButton.TextOnly, IconButton.TextBesideIcon). Colors follow
 * Style.colors so it matches the rest of the app's theme.
 * ************************************************************************************************/
T.Button {
    id: control

    /*! Whether the icon glyph should render in its "solid" Font Awesome weight (only applies
     * when icon.name is used). Defaults to solid while hovered/pressed, override per instance
     * for a different rule (e.g. always solid, or driven by some external active state). */
    property bool solidIcon: control.hovered || control.down

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 6
    spacing: 6
    hoverEnabled: true

    icon.width: 16
    icon.height: 16
    icon.color: control.enabled ? Style.colors.foreground : Style.colors.mutedText

    contentItem: Item {
        implicitWidth: (iconItem.visible ? iconItem.width : 0) +
                       (iconItem.visible && label.visible ? control.spacing : 0) +
                       (label.visible ? label.implicitWidth : 0)
        implicitHeight: Math.max(iconItem.visible ? iconItem.height : 0,
                                 label.visible ? label.implicitHeight : 0)

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
            visible: control.display !== T.AbstractButton.IconOnly && control.text !== ""
            anchors.left: iconItem.visible ? iconItem.right : parent.left
            anchors.leftMargin: iconItem.visible ? control.spacing : 0
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: control.text
            font: control.font
            color: control.icon.color
            elide: Text.ElideRight
            horizontalAlignment: iconItem.visible ? Text.AlignLeft : Text.AlignHCenter
        }
    }

    background: Rectangle {
        radius: 5
        color: !control.enabled ? Style.colors.primaryBackground :
               control.down ? Style.colors.surfaceMuted :
               control.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
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
