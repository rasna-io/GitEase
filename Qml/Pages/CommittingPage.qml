import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * CommittingPage
 * Committing Page shown commit actions placeholder, file list placeholder and diff placeholder
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var                  page:                 null
    property RepositoryController repositoryController: null

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Children
     * ****************************************************************************************/
    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        anchors.topMargin: 32
        spacing: 12

        // Left panel: two stacked placeholders
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: root.width / 3
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "(commit actions) (placeholder)"
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 13
                        color: Style.colors.placeholderText
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "(file lists) (placeholder)"
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 13
                        color: Style.colors.placeholderText
                    }
                }
            }
        }

        // Right panel: diff placeholder
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: root.width * 2 / 3
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: "Diff (placeholder)"
                font.family: Style.fontTypes.roboto
                font.pixelSize: 13
                color: Style.colors.placeholderText
            }
        }
    }
}
