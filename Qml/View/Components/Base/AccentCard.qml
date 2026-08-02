import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * AccentCard
 * A card whose accent background peeks out from behind it on the left edge — the same shape used
 * by NotificationItem. Declare child items normally; they are placed inside the card body.
 *
 *   AccentCard {
 *       accentColor: "#3B82F6"
 *       RowLayout { anchors.fill: parent; ... }
 *   }
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property color accentColor:     Style.colors.accent
    property color cardColor:       Style.colors.secondaryBackground
    property color cardBorderColor: "transparent"
    property int   cardBorderWidth: 0

    //! How far the accent background sticks out on the left.
    property int   peek:            5
    property int   accentRadius:    8
    property int   cardRadius:      6
    property bool  cardClip:        false

    //! Optional tint painted over the opaque card background, beneath the content.
    property color tintColor:       "transparent"
    property bool  tintVisible:     false

    property alias card:   card
    property alias accent: accent

    //! Child items declared by the caller land inside the card body.
    default property alias content: body.data

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth:  200 + peek
    implicitHeight: 48

    /* Children
     * ****************************************************************************************/
    // Accent background — peeks out from behind the card on the left.
    Rectangle {
        id: accent
        anchors.fill: parent
        radius: root.accentRadius
        color: root.accentColor

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Rectangle {
        id: card
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width - root.peek
        radius: root.cardRadius
        color: root.cardColor
        border.color: root.cardBorderColor
        border.width: root.cardBorderWidth
        clip: root.cardClip

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        // Tint layered over the opaque card background, beneath the content.
        Rectangle {
            anchors.fill: parent
            radius: root.cardRadius
            visible: root.tintVisible
            color: root.tintColor
        }

        Item {
            id: body
            anchors.fill: parent
        }
    }
}
