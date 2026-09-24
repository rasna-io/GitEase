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

Page {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    pageId: "blank"
    title: "Blank Page"
    icon: Style.icons.lightbulb

    /* Children
     * ****************************************************************************************/
    Column {
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "BlankPage"
            font.pixelSize: Style.appFont.xlPt
            font.weight: 600
            color: Style.colors.foreground
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: "title: " + root.title
            color: Style.colors.foreground
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: "id: " + root.pageId
            color: Style.colors.foreground
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
