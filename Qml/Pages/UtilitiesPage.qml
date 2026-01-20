import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * UtilitiesPage
 * Utilities Page : import export git bundle and etc.
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var page: null

    property BranchController branchController: null

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Children
     * ****************************************************************************************/
    RowLayout {
        anchors.fill: parent
        anchors.margins: 5
        anchors.topMargin: 5
        spacing: 12

        // Left Top: Import Export bundle
        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            Rectangle {
                Layout.preferredHeight: 315
                Layout.preferredWidth: 261
                color: "transparent"

                ImportExportBundleDock {
                    anchors.fill: parent

                    branchController: root.branchController
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
