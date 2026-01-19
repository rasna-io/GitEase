import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * BlankPage
 * Blank placeholder page.
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var page: null

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Children
     * ****************************************************************************************/
    Column {
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "BlankPage"
            font.pixelSize: 18
            font.weight: 600
            color: Style.colors.foreground
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: "title: " + (root.page ? root.page.title : "Blank Page")
            color: Style.colors.foreground
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: "id: " + (root.page ? root.page.id : "blank")
            color: Style.colors.foreground
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
