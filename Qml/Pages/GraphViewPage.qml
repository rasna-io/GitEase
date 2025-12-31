import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * GraphViewPage
 * Initial main page shown after startup.
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
            text: "GraphViewPage"
            font.pixelSize: 18
            font.weight: 600
            color: "#222222"
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: "title: " + (root.page ? root.page.title : "Graph View")
            color: "#444444"
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: "id: " + (root.page ? root.page.id : "graph")
            color: "#666666"
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
