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

    /* Object Properties
     * ****************************************************************************************/
    width: Style.dp(279)
    height: root.collapsed ? headerRow.implicitHeight + 12 : mainColumn.implicitHeight

    color: Style.colors.primaryBackground
    border.width: 1
    border.color: Style.colors.primaryBorder

    Behavior on height {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/

    ColumnLayout {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 1
        height: implicitHeight
        spacing: 0

        // Header
        Rectangle {
            id: headerRectangle
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: headerRow.implicitHeight + 10
            color: hoverHandler.hovered ? Style.colors.secondaryBackground : "transparent"

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                anchors.topMargin: 5
                anchors.bottomMargin: 5
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
                    font.family: Style.fontTypes.inter
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
                        font.family: Style.fontTypes.inter
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
                    font.family: Style.fontTypes.inter
                    font.pixelSize: 10
                    font.bold: true
                }

                TapHandler {
                    onTapped : root.collapsed = !root.collapsed
                }

                HoverHandler {
                    id: hoverHandler
                }
            }
        }

        Loader {
            id: contentLoader
            active: true
            visible: !root.collapsed
            sourceComponent: root.content
            Layout.fillWidth: true
            Layout.margins: 10
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
