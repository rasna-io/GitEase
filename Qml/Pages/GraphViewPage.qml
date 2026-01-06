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
            id: headerRow
            anchors.leftMargin: 20
            anchors.rightMargin: 5
            anchors.fill: parent
            spacing: 10

            // Local UI state for filtering
            property var filterColumns: ["Author Email", "Author", "Parent 1", "Branch"]
            property string filterColumn: "Author Email"
            property string filterStartDate: ""   // YYYY-MM-DD
            property string filterEndDate: ""     // YYYY-MM-DD
            property string filterText: ""

            function applyFilter() {
                if (!commitGraph)
                    return
                commitGraph.applyFilter(filterColumn, filterText, filterStartDate, filterEndDate)
            }

            // Date picker support (Qt 6.10 / MinGW compatible)
            property var activeDateField: null
            property bool activeIsStart: true

            function openDatePicker(field, isStart) {
                activeDateField = field
                activeIsStart = isStart

                var pos = field.mapToItem(parent, 0, field.height + 6)
                datePopup.x = Math.max(0, Math.min(pos.x, parent.width - datePopup.width))
                datePopup.y = Math.max(0, Math.min(pos.y, parent.height - datePopup.height))

                datePopup.open()
            }

            function formatDateYYYYMMDD(d) {
                function pad2(n) { return (n < 10) ? ("0" + n) : ("" + n) }
                return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate())
            }

            Popup {
                id: datePopup
                modal: true
                focus: true
                padding: 4
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                Overlay.modal: Rectangle {
                    color: "transparent"
                }

                Overlay.modeless: Rectangle {
                    color: "transparent"
                }

                background: Rectangle {
                    radius: 8
                    color: Style.colors.primaryBackground
                    border.width: 1
                    border.color: Style.colors.primaryBorder
                }

                implicitWidth: calendar.implicitWidth + padding * 2
                implicitHeight: calendar.implicitHeight + padding * 2

                contentItem: Column {
                    spacing: 4

                    Calendar {
                        id: calendar

                        function commitDate(date) {
                            if (!headerRow.activeDateField)
                                return

                            var formatted = headerRow.formatDateYYYYMMDD(date)

                            if (headerRow.activeIsStart)
                                headerRow.filterStartDate = formatted
                            else
                                headerRow.filterEndDate = formatted

                            headerRow.applyFilter()
                            datePopup.close()
                        }

                        onDateSelected: commitDate(calendar.selectedDate)

                        onClearRequested: {
                            if (headerRow.activeIsStart)
                                headerRow.filterStartDate = ""
                            else
                                headerRow.filterEndDate = ""

                            headerRow.applyFilter()
                            datePopup.close()
                        }
                    }
                }
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

            Item {
                Layout.preferredWidth: 77
                Layout.fillWidth: true
                Layout.preferredHeight: 25

                TextField {
                    id: startDateField
                    placeholderTextColor: Style.colors.descriptionText
                    backgroundColor: Style.colors.primaryBackground
                    anchors.fill: parent
                    minHeight: 25
                    placeholderText: "2025-08-30"
                    text: headerRow.filterStartDate
                    font.family: Style.fontTypes.roboto
                    font.weight: 400
                    font.pixelSize: 10
                    borderRadius: 5
                    borderWidth: 0
                    focusBorderWidth: 1
                    readOnly: true
                    enabled: text.trim().length > 0
                }

                RoniaTextIcon {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    text: Style.icons.caretDown
                    font.pixelSize: 15
                    color: Style.colors.descriptionText
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: headerRow.openDatePicker(startDateField, true)
                }
            }

            Label {
                color: Style.colors.descriptionText
                text: "To:"
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 12
            }

            Item {
                Layout.preferredWidth: 77
                Layout.fillWidth: true
                Layout.preferredHeight: 25

                TextField {
                    id: endDateField
                    placeholderTextColor: Style.colors.descriptionText
                    backgroundColor: Style.colors.primaryBackground
                    anchors.fill: parent
                    minHeight: 25
                    placeholderText: "2025-09-30"
                    text: headerRow.filterEndDate
                    font.family: Style.fontTypes.roboto
                    font.weight: 400
                    font.pixelSize: 10
                    borderRadius: 5
                    borderWidth: 0
                    focusBorderWidth: 1
                    readOnly: true
                    enabled: text.trim().length > 0
                }

                RoniaTextIcon {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    text: Style.icons.caretDown
                    font.pixelSize: 15
                    color: Style.colors.descriptionText
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: headerRow.openDatePicker(endDateField, false)
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
