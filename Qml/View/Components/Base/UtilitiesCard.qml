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

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.primaryBackground
    radius: 7
    border.width: 1
    border.color: Style.colors.primaryBorder

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            spacing: 10

            Label {
                text: root.icon
                color: Style.colors.accent
                font.family: Style.fontTypes.font6Pro
                font.pixelSize: Style.appFont.largerPt
            }

            Label {
                text: root.title
                color: Style.colors.foreground
                font.family: Style.fontTypes.roboto
                font.pixelSize: Style.appFont.h3Pt
                font.bold: true
            }
        }


        Loader {
            active: true
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
