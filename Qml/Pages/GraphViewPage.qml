import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * GraphViewPage
 * Graph View Page shown Commit Graph Dock, File Changes and Diff View
 * ************************************************************************************************/

Item {
    id: root
    anchors.fill: parent

    // Provided by MainWindow Loader (current Page model)
    property var page: null

    // Provided by MainWindow Loader (UiSession context)
    property RepositoryController repositoryController: null

    readonly property var currentRepo: repositoryController?.appModel?.currentRepository ?? null

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: commitGraphDock
            Layout.fillWidth: true
            Layout.minimumHeight: root.height / 2
            Layout.maximumHeight: root.height / 2
            color: "transparent"

            CommitGraphDock {
                anchors.fill: parent
                repositoryController: root.repositoryController

                onCommitClicked: function(commitId) {
                    console.log("Commit clicked:", commitId)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: root.height / 2
            Layout.maximumHeight: root.height / 2
            color: "transparent"

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                anchors.topMargin: 32
                spacing: 12

                Label {
                    text: "File Changes";
                    font.bold: true;
                    opacity: 0.8;
                    elide: Text.ElideRight
                }

                Label {
                    text: "DiffView";
                    font.bold: true;
                    opacity: 0.8;
                    elide: Text.ElideRight
                }
            }
        }
    }
}
