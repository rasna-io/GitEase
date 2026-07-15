import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style_Impl
import GitEase_Style
import GitEase

/*! ***********************************************************************************************
 * UtilitiesCard
 * ************************************************************************************************/

Rectangle {
    id: root


    /* Property Declarations
     * ****************************************************************************************/
    required property Component content
    required property string    title
    required property string    icon
    property bool               pageScrollBlocking: true
    readonly property alias     hovered:            contentHoverHandler.hovered

    // Number of items shown as a header badge. -1 hides the badge.
    property int                badgeCount:         -1
    property bool               collapsed:          true
    // Height used while expanded; collapsing always shrinks to the header only.
    property int                expandedHeight:     370

    readonly property int       cardPadding:        16
    readonly property int       collapsedHeight:    31
    readonly property int       collapsedPadding:   5

    /* Object Properties
     * ****************************************************************************************/
    width: Style.dp(279)
    height: root.collapsed ? root.collapsedHeight : root.expandedHeight

    color: "#131316"
    border.width: 1
    border.color: Style.colors.primaryBorder

    Behavior on height {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.topMargin: root.collapsed ? root.collapsedPadding : root.cardPadding
        anchors.bottomMargin: root.collapsed ? root.collapsedPadding : root.cardPadding
        anchors.leftMargin: root.cardPadding
        anchors.rightMargin: root.cardPadding
        spacing: root.cardPadding

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: root.icon
                color: Style.colors.accent
                font.family: Style.fontTypes.font6Pro
                font.pixelSize: Style.appFont.largerPt
            }

            Label {
                Layout.fillWidth: true
                text: root.title
                color: Style.colors.foreground
                font.family: Style.fontTypes.roboto
                font.pixelSize: Style.appFont.h4Pt
                font.bold: true
                elide: Text.ElideRight
            }

            Rectangle {
                id: badge
                visible: root.badgeCount >= 0
                implicitHeight: 18
                implicitWidth: Math.max(implicitHeight, badgeLabel.implicitWidth + 10)
                radius: implicitHeight / 2
                color: Style.colors.secondaryBackground
                border.width: 1
                border.color: Style.colors.primaryBorder

                Label {
                    id: badgeLabel
                    anchors.centerIn: parent
                    text: root.badgeCount
                    color: Style.colors.mutedText
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Label {
                text: root.collapsed ? Style.icons.caretDown : Style.icons.caretUp
                color: Style.colors.mutedText
                font.family: Style.fontTypes.roboto
                font.pixelSize: 10
                font.bold: true
            }

            TapHandler {
                onTapped : root.collapsed = !root.collapsed
            }
        }


        Loader {
            active: true
            visible: !root.collapsed
            sourceComponent: root.content
            Layout.fillHeight: true
            Layout.fillWidth: true

            HoverHandler {
                id: contentHoverHandler
                enabled: root.pageScrollBlocking
            }
        }

    }

    /* Functions
     * ****************************************************************************************/
}
