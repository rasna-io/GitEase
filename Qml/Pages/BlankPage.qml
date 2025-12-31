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
    anchors.fill: parent

    // Provided by MainWindow Loader (current Page model)
    property var page: null

    Column {
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "BlankPage"
            font.pixelSize: 18
            font.weight: 600
            color: "#222222"
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: "title: " + (root.page ? root.page.title : "Blank Page")
            color: "#444444"
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: "id: " + (root.page ? root.page.id : "blank")
            color: "#666666"
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
