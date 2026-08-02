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

    property real               headerHeight:       Style.dp(30)

    property real               contentBottomInset: Style.dp(10)

    /* Object Properties
     * ****************************************************************************************/
    width: Style.dp(279)
    height: (root.collapsed ? root.headerHeight
                            : mainColumn.implicitHeight + root.contentBottomInset) + topBorder.height

    color: Style.colors.utilitiesCardBackground
    border.width: 0

    Behavior on height {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/

    Rectangle {
        id: topBorder
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        color: Style.colors.utilitiesCardSeparator
    }

    ColumnLayout {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: topBorder.bottom
        height: implicitHeight
        spacing: 0

        // Header
        Rectangle {
            id: headerRectangle
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            color: hoverHandler.hovered ? Style.colors.utilitiesCardHeaderHoverBackground
                                        : Style.colors.utilitiesCardHeaderBackground

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                spacing: 10

                Label {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.icon
                    color: Style.colors.utilitiesCardHeaderIcon
                    font.family: Style.fontTypes.font6Pro
                    font.weight: 400
                    font.pixelSize: Style.appFont.largePt
                    verticalAlignment: Text.AlignVCenter
                }

                Label {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: root.title
                    color: Style.colors.utilitiesCardTitle
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.h4Pt
                    font.bold: true
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    id: badge
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.badgeCount >= 0
                    implicitHeight: 18
                    implicitWidth: Math.max(implicitHeight, badgeLabel.implicitWidth + 10)
                    radius: implicitHeight / 2
                    color: Style.colors.utilitiesCardBadgeBackground
                    border.width: 1
                    border.color: Style.colors.utilitiesCardBadgeBorder

                    Label {
                        id: badgeLabel
                        anchors.centerIn: parent
                        text: root.badgeCount
                        color: Style.colors.utilitiesCardBadgeText
                        font.family: Style.fontTypes.inter
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Label {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.collapsed ? Style.icons.caretDown : Style.icons.caretUp
                    color: Style.colors.utilitiesCardChevron
                    font.family: Style.fontTypes.inter
                    font.pixelSize: 10
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                TapHandler {
                    onTapped : root.collapsed = !root.collapsed
                }

                HoverHandler {
                    id: hoverHandler
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        Loader {
            id: contentLoader
            active: true
            visible: !root.collapsed
            sourceComponent: root.content
            Layout.fillWidth: true
            Layout.topMargin: 5
            Layout.preferredHeight: item ? item.implicitHeight : 0

            HoverHandler {
                id: contentHoverHandler
                enabled: root.pageScrollBlocking
            }
        }

    }

    /* Functions
     * ****************************************************************************************/
}
