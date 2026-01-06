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
    property AppModel appModel: null

    property BranchController branchController: null

    property CommitController commitController: null

    property StatusController statusController: null

    property RepositoryController repositoryController: null

    readonly property var currentRepo: appModel?.currentRepository ?? null

    property string selectedCommit: ""
    property string selectedFilePath: ""

    // Exposed to MainWindow's header area (see MainWindow.qml)
    property Component headerContent: Component {
        RowLayout {
            anchors.leftMargin: 20
            anchors.rightMargin: 5
            anchors.fill: parent
            spacing: 10

            // Local UI state for filtering
            property var filterColumns: ["Message", "Author"]
            property string filterColumn: "Message"
            property string filterStartDate: ""   // YYYY-MM-DD
            property string filterEndDate: ""     // YYYY-MM-DD
            property string filterText: ""

            function applyFilter() {
                if (!commitGraph)
                    return
                commitGraph.applyFilter(filterColumn, filterText, filterStartDate, filterEndDate)
            }

            TextField {
                id: textFilterField
                placeholderTextColor: Style.colors.descriptionText
                backgroundColor: Style.colors.primaryBackground
                Layout.fillWidth: true
                minHeight: 25
                placeholderText: {
                    var selectedItems = filterOptionsPopup.selectedItems
                    var selected = (selectedItems && selectedItems.length > 0)
                            ? selectedItems.map(function(it) { return it.text }).join(", ")
                            : ""
                    return selected.length > 0 ? ("Write Filter By " + selected) : "Write Filter By"
                }
                text: parent.filterText
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 9
                borderRadius: 5
                borderWidth: 0
                focusBorderWidth: 1
                onTextChanged: {
                    parent.filterText = text
                    parent.applyFilter()
                }
            }

            ToolButton {
                id: filterButton
                Layout.preferredWidth: 25
                Layout.preferredHeight: 25
                hoverEnabled: true

                text: Style.icons.filter
                font.family: (filterOptionsPopup.visible || filterButton.hovered)
                             ? Style.fontTypes.font6ProSolid
                             : Style.fontTypes.font6Pro
                font.pixelSize: 14

                contentItem: Text {
                    anchors.centerIn: parent
                    text: filterButton.text
                    font: filterButton.font
                    color: filterButton.enabled ? Style.colors.foreground : Style.colors.mutedText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 5
                    color: !filterButton.enabled ? Style.colors.primaryBackground :
                           filterButton.down ? Style.colors.surfaceMuted :
                           filterButton.hovered ? Style.colors.cardBackground : Style.colors.primaryBackground
                }

                onClicked: filterOptionsPopup.open()
            }

            ItemSelectorPopup {
                id: filterOptionsPopup

                // Position under the filter icon
                x: filterButton.x
                y: filterButton.y + filterButton.height + 6

                model: filterOptionsModel

                onOpened: {
                    x = Math.max(0, Math.min(x, parent.width - width))
                }
            }

            ListModel {
                id: filterOptionsModel
                ListElement { text: "Messages"; checked: false }
                ListElement { text: "Paths"; checked: false }
                ListElement { text: "Subjects"; checked: false }
                ListElement { text: "Authors"; checked: false }
                ListElement { text: "Emails"; checked: false }
                ListElement { text: "SHA-1"; checked: false }
            }

            Label {
                Layout.leftMargin: 40
                color: Style.colors.descriptionText
                text: "From:"
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 12
            }


            TextField {
                id: startDateField
                placeholderTextColor: Style.colors.descriptionText
                backgroundColor: Style.colors.primaryBackground
                Layout.preferredWidth: 77
                Layout.fillWidth: true
                minHeight: 25
                placeholderText: "2025/08/30"
                text: parent.filterStartDate
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 9
                borderRadius: 5
                borderWidth: 0
                focusBorderWidth: 1
                onEditingFinished: {
                    parent.filterStartDate = text.trim()
                    parent.applyFilter()
                }
            }

            Label {
                color: Style.colors.descriptionText
                text: "To:"
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 12
            }

            TextField {
                id: endDateField
                placeholderTextColor: Style.colors.descriptionText
                backgroundColor: Style.colors.primaryBackground
                Layout.preferredWidth: 77
                Layout.fillWidth: true
                minHeight: 25
                placeholderText: "2025/09/30"
                text: parent.filterEndDate
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 9
                borderRadius: 5
                borderWidth: 0
                focusBorderWidth: 1
                onEditingFinished: {
                    parent.filterEndDate = text.trim()
                    parent.applyFilter()
                }
            }

            ComboBox {
                id: columnCombo
                model: parent.filterColumns

                Layout.leftMargin: 20
                minHeight: 26
                borderWidth: 0
                focusBorderWidth: 1
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 10

                palette.base: Style.colors.primaryBackground
                palette.text: Style.colors.descriptionText

                Layout.preferredWidth: 90
                currentIndex: parent.filterColumns.indexOf(parent.filterColumn)
                onActivated: function(index) {
                    parent.filterColumn = parent.filterColumns[index]
                    parent.applyFilter()
                }
            }

            ToolButton {
                id: downButton
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26

                enabled: !!commitGraph
                hoverEnabled: true

                text: Style.icons.caretDown
                font.family: Style.fontTypes.font6ProSolid
                font.pixelSize: 15

                contentItem: Text {
                    anchors.centerIn: parent
                    text: downButton.text
                    font: downButton.font
                    color: downButton.enabled ? Style.colors.foreground : Style.colors.mutedText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 5
                    color: !downButton.enabled ? Style.colors.primaryBackground :
                           downButton.down ? Style.colors.surfaceMuted :
                           downButton.hovered ? Style.colors.cardBackground : Style.colors.primaryBackground
                }

                onClicked: commitGraph.selectNext()
            }

            ToolButton {
                id: upButton
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26

                enabled: !!commitGraph
                hoverEnabled: true

                text: Style.icons.caretUp
                font.family: Style.fontTypes.font6ProSolid
                font.pixelSize: 15

                contentItem: Text {
                    anchors.centerIn: parent
                    text: upButton.text
                    font: upButton.font
                    color: upButton.enabled ? Style.colors.foreground : Style.colors.mutedText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 5
                    color: !upButton.enabled ? Style.colors.primaryBackground :
                           upButton.down ? Style.colors.surfaceMuted :
                           upButton.hovered ? Style.colors.cardBackground : Style.colors.primaryBackground
                }

                onClicked: commitGraph.selectPrevious()
            }

            ToolButton {
                id: reloadButton
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                Layout.leftMargin: 10

                enabled: !!commitGraph
                hoverEnabled: true

                text: Style.icons.refresh
                font.family: Style.fontTypes.font6Pro
                font.pixelSize: 14

                contentItem: Text {
                    anchors.centerIn: parent
                    text: reloadButton.text
                    font: reloadButton.font
                    color: reloadButton.enabled ? Style.colors.foreground : Style.colors.mutedText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 5
                    color: !reloadButton.enabled ? Style.colors.primaryBackground :
                           reloadButton.down ? Style.colors.surfaceMuted :
                           reloadButton.hovered ? Style.colors.cardBackground : Style.colors.primaryBackground
                }

                onClicked: commitGraph.reloadAll()
            }
        }
    }

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
                id: commitGraph
                anchors.fill: parent
                repositoryController: root.repositoryController
                appModel: root.appModel
                branchController: root.branchController
                commitController: root.commitController

                onCommitClicked: function(commitId) {
                    root.selectedCommit = commitId
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: root.height / 2
            Layout.maximumHeight: root.height / 2
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                anchors.topMargin: 32
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: root.width / 2
                    Layout.fillHeight: true
                    color: "transparent"

                    FileChangesDock {
                        anchors.fill: parent

                        repositoryController : root.repositoryController
                        statusController: root.statusController
                        commitHash : root.selectedCommit

                        onFileSelected: function(filePath){
                            root.selectedFilePath = filePath
                            let parentHash = root.commitController.getParentHash(root.selectedCommit)
                            let res = root.statusController.getDiff(parentHash, root.selectedCommit, root.selectedFilePath)

                            if (res.success) {
                                diffView.diffData = res.data
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: root.width / 2
                    Layout.fillHeight: true
                    color: "transparent"

                    DiffView {
                        id: diffView
                        anchors.fill: parent
                    }
                }
            }
        }
    }
}
