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

    /* Property Declarations
     * ****************************************************************************************/
    property var                    page: null
    property AppModel               appModel: null
    property BranchController       branchController: null
    property CommitController       commitController: null
    property StatusController       statusController: null
    property RepositoryController   repositoryController: null
    property NotificationController notificationController: null
    property UiSessionPopups        uiSessionPopups: null
    property StashController        stashController: null
    property string                 selectedCommit: ""
    property string                 selectedFilePath: ""
    property string                 headHash: ""
    property ConflictController conflictController: null
    property MergeController mergeController: null
    property RebaseController rebaseController: null
    property CherryPickController cherryPickController: null

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Children
     * ****************************************************************************************/

    onSelectedCommitChanged: {
        fileChangesDock.commitHash = root.selectedCommit
    }

    Connections {
        target: repositoryController

        function onRepositorySelected() {
            root.selectedCommit = ""
            root.selectedFilePath = ""
            diffView.diffData = null
        }
    }

    // Exposed to MainWindow's header area (see MainWindow.qml)
    property Component headerContent: Component {
        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.leftMargin: parent.width < Style.appHeight ? 8 : 20
            anchors.rightMargin: parent.width < Style.appHeight ? 4 : 5
            spacing: parent.width < Style.appHeight ? 6 : 10

            readonly property bool compact: parent.width < 650

            property var navigationRules: ["Author Email", "Author", "Parent 1", "Branch"]
            property string navigationRule: "Author Email"
            property string filterStartDate: ""   // YYYY-MM-DD
            property string filterEndDate: ""     // YYYY-MM-DD
            property string filterText: ""

            function applyFilter() {
                if (!commitGraph)
                    return
                
                var selectedModes = []
                for (var i = 0; i < filterOptionsModel.count; i++) {
                    var item = filterOptionsModel.get(i)
                    if (item.checked) {
                        selectedModes.push(item.text)
                    }
                }
                
                commitGraph.applyFilter(filterText, filterStartDate, filterEndDate, selectedModes)
            }

            property var activeDateField: null
            property bool activeIsStart: true

            function openDatePicker(field, isStart) {
                activeDateField = field
                activeIsStart = isStart

                // If we already have a selected date, open the calendar focused on it.
                var dateStr = isStart ? filterStartDate : filterEndDate
                calendar.setDate(dateStr)

                var pos = field.mapToItem(parent, 0, field.height + 6)
                calendar.errorMessage = ""
                datePopup.x = Math.max(0, Math.min(pos.x, parent.width - datePopup.width))
                datePopup.y = pos.y

                datePopup.open()
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

                            var formatted = calendar.dateToString(date)
                            calendar.errorMessage = ""

                            if (headerRow.activeIsStart) {
                                if (headerRow.filterEndDate && formatted > headerRow.filterEndDate) {
                                    calendar.errorMessage = "Start date cannot be greater than end date"
                                    return
                                }

                                headerRow.filterStartDate = formatted
                            } else {
                                if (headerRow.filterStartDate && formatted < headerRow.filterStartDate) {
                                    calendar.errorMessage = "End date cannot be less than start date"
                                    return
                                }

                                headerRow.filterEndDate = formatted
                            }

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
                backgroundColor: textFilterField.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
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
                           filterButton.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
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

                onSelectionChanged: function(items) {
                    headerRow.applyFilter()
                }
            }

            ListModel {
                id: filterOptionsModel
                ListElement { text: "Messages"; checked: false }
                ListElement { text: "Subjects"; checked: false }
                ListElement { text: "Authors"; checked: false }
                ListElement { text: "Emails"; checked: false }
                ListElement { text: "SHA-1"; checked: false }
            }

            Label {
                Layout.leftMargin: headerRow.compact ? 8 : 40
                color: Style.colors.descriptionText
                text: "From:"
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 12
            }

            Item {
                Layout.preferredWidth: headerRow.compact ? 22 : 90
                Layout.preferredHeight: 25

                TextField {
                    id: startDateField
                    placeholderTextColor: Style.colors.descriptionText
                    backgroundColor: startDateFieldMouseArea.containsMouse ? Style.colors.cardBackground : Style.colors.secondaryBackground
                    anchors.fill: parent
                    minHeight: 25
                    rightPadding: (startDateCaret.width + 5)
                    placeholderText: headerRow.compact ? "" : "2025-08-30"
                    text: headerRow.compact ? "" : headerRow.filterStartDate
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
                    id: startDateCaret
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
                    id: startDateFieldMouseArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
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
                Layout.preferredWidth: headerRow.compact ? 22 : 90
                Layout.preferredHeight: 25

                TextField {
                    id: endDateField
                    placeholderTextColor: Style.colors.descriptionText
                    backgroundColor: endDateFieldMouseArea.containsMouse ? Style.colors.cardBackground : Style.colors.secondaryBackground
                    anchors.fill: parent
                    minHeight: 25
                    rightPadding: (endDateCaret.width + 5)
                    placeholderText: headerRow.compact ? "" : "2025-09-30"
                    text: headerRow.compact ? "" : headerRow.filterEndDate
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
                    id: endDateCaret
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
                    id: endDateFieldMouseArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    onClicked: headerRow.openDatePicker(endDateField, false)
                }
            }

            ComboBox {
                id: columnCombo
                model: parent.navigationRules

                Layout.leftMargin: headerRow.compact ? 6 : 20
                minHeight: 26
                visible: !headerRow.compact
                borderWidth: 0
                focusBorderWidth: 1
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 10

                Material.background: Style.colors.primaryBackground
                Material.foreground: Style.colors.secondaryText

                background: Rectangle {
                    radius: 5
                    color: columnCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                Layout.preferredWidth: 90
                currentIndex: parent.navigationRules.indexOf(parent.navigationRule)
                onActivated: function(index) {
                    parent.navigationRule = parent.navigationRules[index]
                    parent.applyFilter()
                }
            }

            ToolButton {
                id: downButton
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26

                visible: !headerRow.compact
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
                           downButton.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                onClicked: commitGraph.selectNext(navigationRule)
            }

            ToolButton {
                id: upButton
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26

                visible: !headerRow.compact
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
                           upButton.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                onClicked: commitGraph.selectPrevious(navigationRule)
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
                           reloadButton.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                onClicked: {
                    commitGraph.reloadAll()
                    root.headHash = commitController.getHeadHash()
                }

            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        DropZone {
            id: commitGraphDock
            Layout.fillWidth: true

            CommitGraphDock {
                id: commitGraph
                repositoryController: root.repositoryController
                appModel: root.appModel
                branchController: root.branchController
                mergeController: root.mergeController
                rebaseController: root.rebaseController
                cherryPickController: root.cherryPickController
                addBranchPopup: uiSessionPopups.addBranchPopup
                addTagPopup: uiSessionPopups.addTagPopup
                commitController: root.commitController
                statusController: root.statusController
                notificationController: root.notificationController
                stashController: root.stashController
                conflictController: root.conflictController

                onCommitClicked: function(commitId) {
                    let node = commitGraph.commits.find(c => c.hash === commitId);

                    root.selectedCommit = commitId;

                    if (node && node.isUncommitted) {
                        let res = statusController.status()

                        if (!res.success || !res.data) {
                            console.log("status failed:", res);
                            fileChangesDock.files = [];
                            return;
                        }

                        fileChangesDock.files = res.data;

                        return;
                    }

                    let res = commitController.getCommitFileChanges(commitId);

                    if (!res.success) {
                        console.log("commit diff failed:", res);
                        fileChangesDock.files = [];
                        return;
                    }

                    let files = [];

                    if (res.data) {
                        if (res.data.staged)
                            files = files.concat(res.data.staged);

                        if (res.data.unstaged)
                            files = files.concat(res.data.unstaged);

                        if (Array.isArray(res.data))
                            files = res.data;
                    }

                    fileChangesDock.files = files;
                }
            }
        }

        DropZone {
            Layout.fillWidth: true

            FileChangesDock {
                id: fileChangesDock

                repositoryController : root.repositoryController
                statusController: root.statusController

                onFileSelected: function(filePath){
                    root.selectedFilePath = filePath

                    let selectedCommitObj = commitGraph.selectedCommit
                    let parentHash = ""
                    if (selectedCommitObj && selectedCommitObj.isStash && selectedCommitObj.stashParentId) {
                        parentHash = selectedCommitObj.stashParentId
                    } else {
                        parentHash = root.commitController.getParentHash(root.selectedCommit)
                    }

                        onFileSelected: function(filePath) {
                            root.selectedFilePath = filePath

                            let commitId = root.selectedCommit
                            let node = commitGraph.commits.find(c => c.hash === commitId)

                            let res = null

                            if (commitId === "__uncommitted__" || (node && node.isUncommitted)) { // UNCOMMITTED COMMITS
                                let headHash = statusController.getHeadHash()

                                if (!headHash) {
                                    console.log("HEAD is null -> cannot diff uncommitted")
                                    return
                                }

                                res = statusController.getWorkingDirectoryDiff(headHash, filePath)
                            }
                            else { // NORMAL COMMITS
                                let parentHash = ""

                                if (node && node.isStash && node.stashParentId) {
                                    parentHash = node.stashParentId
                                } else {
                                    parentHash = commitController.getParentHash(commitId)
                                }

                                if (!parentHash || !commitId) {
                                    console.log("Invalid diff inputs:", parentHash, commitId)
                                    return
                                }

                                res = statusController.getDiff(parentHash, commitId, filePath)
                            }

                            if (res && res.success) {
                                diffView.diffData = res.data
                            }
                        }
                    }
                }
            }

            DiffView {
                id: diffView
                readOnly: true
            }
        }
    }
}
