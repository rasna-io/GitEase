import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * DetachedPanelPlaceholder
 * Fills the space of a DetachablePanel that lives in its own window, and offers to bring it back.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string title:   ""
    property string details: ""

    /* Signals
     * ****************************************************************************************/
    signal reattachRequested()

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.primaryBackground

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Style.dp(32), 360)
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: Style.icons.detach
            font.family: Style.fontTypes.font6Pro
            font.styleName: "Solid"
            font.pixelSize: Style.appFont.displayLgPt
            color: Style.colors.mutedText
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            text: root.title
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.h2Pt
            font.weight: 500
            color: Style.colors.mutedText
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        Text {
            Layout.fillWidth: true
            visible: root.details.length > 0
            text: root.details
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.mediumPt
            font.weight: 400
            color: Style.colors.placeholderText
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        IconButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            Layout.preferredHeight: 26
            backgroundColor: Style.colors.headerButtonBackground
            hoverBackgroundColor: Style.colors.headerButtonBackgroundHover
            borderColor: Style.colors.headerButtonBorder
            borderWidth: 1
            leftPadding: 12
            rightPadding: 12

            solidIcon: true
            icon.name: Style.icons.undo
            icon.width: Style.appFont.smallPt
            icon.height: Style.appFont.smallPt
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.smallPt
            font.weight: Font.Medium
            text: qsTr("Bring back")
            display: IconButton.TextBesideIcon

            onClicked: root.reattachRequested()
        }
    }
}
