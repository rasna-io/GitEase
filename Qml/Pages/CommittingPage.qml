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
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top bar placeholder (commit actions)
        // Styled like GraphViewPage: transparent, no borders/radius.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12

                Text {
                    Layout.alignment: Qt.AlignCenter
                    text: "Committing (placeholder)"
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 13
                    color: Style.colors.placeholderText
                }

            }
        }

        // Main content: left panel (file list) + right panel (diff viewer)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                anchors.topMargin: 32
                spacing: 12

                // Left panel placeholder (file lists)
                Rectangle {
                    Layout.preferredWidth: root.width / 2
                    Layout.fillHeight: true
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Files (placeholder)"
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 13
                        color: Style.colors.placeholderText
                    }
                }

                // Right panel placeholder (diff viewer)
                Rectangle {
                    Layout.preferredWidth: root.width / 2
                    Layout.fillHeight: true
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Diff viewer (placeholder)"
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 13
                        color: Style.colors.placeholderText
                    }
                }
            }
        }
    }
}
