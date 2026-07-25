import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * DiffView
 * ************************************************************************************************/

DetachablePanel {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var diffData: []   // used when chunkMode = false
    property var chunkData: []  // used when chunkMode = true
    property var originalFileBuffer: []
    property var editedFileBuffer: [] // holds the value of the edited file

    property AppModel appModel: null

    /* Chunking configuration */
    property bool chunkMode     : false
    property int  contextLines  : 0         // how many unchanged lines to show around each hunk
    property int  expandLines   : 10        // lines to reveal when expanding a hidden block

    property bool readOnly: false
    property var  textColorizer: null   // JS function (text) => richHtml, set by host
    property int currentIndex: -1
    property bool fileIsEdited: false
    property string selectedFile: ""
    property int selectedFileStatus: -1
    property bool hasHeaderMiddleComponent: false

    // Properties used for selection
    property bool selectEnabled: true // used to disable mouse area so that it does not block editing file
    property int selectionStart: -1
    property int selectionEnd: -1
    enum DiffViewSelectionSide {
        None,
        Left,
        Right
    }
    property int selectedSide: DiffView.DiffViewSelectionSide.None
    property bool dragging: false

    property alias scrollPosition: diffListView.contentY

    /* Object Properties
     * ****************************************************************************************/
    title: qsTr("Diff View")
    middleAccessory: root.hasHeaderMiddleComponent ? headerMiddleComp : null

    /* Signals
     * ****************************************************************************************/
    signal requestStage(int start, int end, int type)
    signal requestRevert(int start, int end, int type)
    signal requestStash(int start, int end, int type)
    signal fileEdited(bool isEdited)
    signal saveFile()

    /* Children
     * ****************************************************************************************/
    ListModel {
        id: fileModel
    }

    ListModel {
        id: chunkModel
    }

    onAppModelChanged: {
        if (!root.appModel)
            return

        let gs = appModel.appSettings.generalSettings
        root.contextLines = gs.chunkContextLines
        root.expandLines = gs.chunkExpandLines
    }

    readonly property int addedLineCount: {
        let n = 0
        for (let i = 0; i < diffData.length; i++)
            if (diffData[i].type === GitDiff.Added || diffData[i].type === GitDiff.Modified)
                n++
        return n
    }
    readonly property int deletedLineCount: {
        let n = 0
        for (let i = 0; i < diffData.length; i++)
            if (diffData[i].type === GitDiff.Deleted || diffData[i].type === GitDiff.Modified)
                n++
        return n
    }

    onDiffDataChanged: {
        if (chunkMode)
            return

        fileModel.clear()

        for(var i = 0; i < diffData.length; i++) {
            var diff = diffData[i];

            var left = diff.content;
            var right = (diff.type === GitDiff.Modified) ? diff.newContent : diff.content;

            // Visual "Gaps"
            if (diff.type === GitDiff.Added)
                left = "";
            if (diff.type === GitDiff.Deleted)
                right = "";

            appendRow(fileModel, diff.type, left, right, diff.oldLine, diff.newLine);

            updateMaxContentWidth(left);
            updateMaxContentWidth(right);
        }

        root.fileIsEdited = false
        root.clearSelection()
    }

    onChunkDataChanged: {
        if (!chunkMode)
            return

        buildChunkModel()

        root.fileIsEdited = false
        root.clearSelection()
    }

    onChunkModeChanged: {
        if (!chunkMode)
        {
            fileModel.clear()

            for(var i = 0; i < diffData.length; i++) {
                var diff = diffData[i];

                var left = diff.content;
                var right = (diff.type === GitDiff.Modified) ? diff.newContent : diff.content;

                // Visual "Gaps"
                if (diff.type === GitDiff.Added)
                    left = "";
                if (diff.type === GitDiff.Deleted)
                    right = "";

                appendRow(fileModel, diff.type, left, right, diff.oldLine, diff.newLine);

                updateMaxContentWidth(left);
                updateMaxContentWidth(right);
            }
        }
        else {
            buildChunkModel()
        }

        root.fileIsEdited = false
        root.clearSelection()
    }

    onFileIsEditedChanged: {
        if(root.fileIsEdited)
        {
            if(!root.selectedFile.includes("●")) root.selectedFile += " ●"
        } else {
            if(root.selectedFile.slice(-1) === "●") root.selectedFile = root.selectedFile.slice(0, -2);
        }
    }

    onContextLinesChanged: {
        if (chunkMode)
            buildChunkModel()
    }

    TextMetrics {
        id: widthCalculator
        font.family: Style.fontTypes.jetBrainsMono
        font.pixelSize: Style.appFont.h3Pt
    }

    EmptyStateView {
        title: "No file changes to show"
        details: "Select a file to view the Diff"
        visible: chunkMode ? (!chunkData || chunkData.length === 0)
                           : (!root.diffData || root.diffData.length === 0)
    }

    Rectangle {
        id: diffContent
        anchors.fill: parent
        color: Style.colors.editorBackgroound
        visible: chunkMode ? (chunkData && chunkData.length > 0)
                           : (root.diffData && root.diffData.length > 0)

        ListView {
            id: diffListView
            property real horizontalScrollOffset: 0
            property real maxContentWidth: 0

            anchors.fill: parent
            clip: true
            model: chunkMode ? chunkModel : fileModel

            cacheBuffer: 0
            reuseItems: false
            anchors.bottomMargin: hScrollBar.visible ? hScrollBar.height : 0
            ScrollBar.vertical: ScrollBar {
                id: vScrollBar
                active: true
            }

            TextEdit {
                id: clipboardHelper
                visible: false
            }

            MouseArea {
                id: selectMsa
                height: parent.height
                width: parent.width - (vScrollBar.visible ? vScrollBar.width : 0)
                propagateComposedEvents: true
                z: 1
                focus: true
                Keys.enabled: true
                enabled: root.selectEnabled || root.readOnly || root.chunkMode
                visible: root.selectEnabled || root.readOnly || root.chunkMode

                onPressed: (mouse) => {
                   diffListView.interactive = false // Disable flicking during selection
                   var idx = diffListView.indexAt(mouse.x, mouse.y + diffListView.contentY)
                   var row = diffListView.model.get(idx)

                   if (idx < 0) {
                       root.clearSelection()
                       return
                   }

                   if(row.rowType === "hidden")
                       return

                    forceActiveFocus()

                    root.dragging = true

                   if (!(mouse.modifiers & Qt.ShiftModifier)) {
                       root.selectionStart = idx
                       root.selectionEnd = idx
                   } else {
                       root.selectionEnd = idx
                   }

                    // Checks which side of diffview is selected
                    root.selectedSide = mouse.x < selectMsa.width / 2 ? DiffView.DiffViewSelectionSide.Left : DiffView.DiffViewSelectionSide.Right
                }

                onPositionChanged: (mouse) => {
                    if (!root.dragging) return

                   var margin = 40

                   var maxScroll = Math.max(
                       0,
                       diffListView.contentHeight - diffListView.height
                   )

                   // Scroll up
                   if (mouse.y < margin && maxScroll > 0) {
                       diffListView.contentY = Math.max(
                           0,
                           diffListView.contentY - 10
                       )
                   }

                   // Scroll down
                   if (mouse.y > height - margin && maxScroll > 0) {
                       diffListView.contentY = Math.min(
                           maxScroll,
                           diffListView.contentY + 10
                       )
                   }

                   var idx = diffListView.indexAt(mouse.x, mouse.y + diffListView.contentY)
                   var row = diffListView.model.get(idx)

                    if (idx >= 0)
                    {
                        if(row.rowType === "hidden")
                            return
                        root.selectionEnd = idx
                    }
                }

                onReleased: {
                    diffListView.interactive = true
                    root.dragging = false
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_A &&
                        (event.modifiers & Qt.ControlModifier))
                    {
                        selectAll()

                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_C &&
                        (event.modifiers & Qt.ControlModifier))
                    {
                        copyRowsText()

                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Escape) {
                        clearSelection()
                        event.accepted = true
                        return
                    }
                }
            }

            delegate: Item{
                id: delegateItem
                width: diffListView.width
                implicitHeight: model.rowType === "hidden" ? 45 : diffLineItem.implicitHeight

                // Exposed so the guide can find a currently visible row's action buttons /
                // hidden-context bar (see findActionableDelegate / findHiddenBarDelegate below).
                property alias diffLineItem: diffLineItem
                property alias hiddenLoader: loader

                Loader {
                    id: loader
                    anchors.fill: parent
                    active: root.chunkMode && diffListView.model.count > 0 && model.rowType === "hidden"
                    sourceComponent: hiddenBarComponent

                    onLoaded: {
                        if (!item)
                            return

                        item.direction      = Qt.binding(function() { return model.direction })
                        item.remaining      = Qt.binding(function() { return model.remaining })
                        item.delegateIndex  = Qt.binding(function() { return index })
                    }
                }

                SideBySideDiff {
                    id: diffLineItem
                    anchors.fill: parent
                    visible: model.rowType !== "hidden"
                    horizontalOffset: diffListView.horizontalScrollOffset
                    textColorizer: root.textColorizer
                    readOnly: root.readOnly || root.chunkMode
                    diffModel: diffListView.model
                    diffType: (model.diffType !== undefined) ? model.diffType : GitDiff.Context
                    leftContent:  model.leftText  || ""
                    rightContent: model.rightText || ""
                    leftLineNum:  model.oldLineNum !== undefined ? model.oldLineNum : -1
                    rightLineNum: model.newLineNum !== undefined ? model.newLineNum : -1
                    isCurrentItem: index === root.currentIndex
                    selectionStart: root.selectionStart
                    selectionEnd: root.selectionEnd
                    selectedSide: root.selectedSide
                    hasAction: checkHasAction(diffListView.model, index, diffType)
                    selectedFileStatus: root.selectedFileStatus

                    onRequestTextChange: (newText) => root.changeText(index, newText)
                    onRequestSplit: (pos, txt) => root.splitLine(index, pos, txt)
                    onRequestMergeUp: root.mergeLineUp(index)
                    onRequestFocusNext: diffListView.currentIndex = index + 1
                    onRequestFocusPrev: diffListView.currentIndex = index - 1
                    onRequestStage: (start, end, type) => root.requestStage(start, end, type)
                    onRequestRevert: (start, end, type) => root.requestRevert(start, end, type)
                    onRequestStash: (start, end, type) => root.requestStash(start, end, type)
                }
            }
        }

        ScrollBar {
            id: hScrollBar
            orientation: Qt.Horizontal
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            size: diffListView.maxContentWidth === 0 ? 1 : (diffListView.width * 0.5) / diffListView.maxContentWidth
            active: true
            visible: size < 1.0

            onPositionChanged: {
                // Calculate the pixel offset based on scrollbar position
                diffListView.horizontalScrollOffset = position * diffListView.maxContentWidth
            }
        }
    }

    Component {
        id: headerMiddleComp

        Item {

            ScrollingText {
                text: root.selectedFile
                font.family: Style.fontTypes.jetBrainsMono
                font.pixelSize: Style.appFont.secondaryPt
                color: Style.colors.mutedText
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, parent.width * 0.55)
            }

            RowLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    visible: root.selectedFile !== "" && (root.addedLineCount > 0 || root.deletedLineCount > 0)
                    text: "+" + root.addedLineCount
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.smallPt
                    color: Style.colors.diffAddedCount
                }

                Text {
                    visible: root.selectedFile !== "" && (root.addedLineCount > 0 || root.deletedLineCount > 0)
                    text: "−" + root.deletedLineCount
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.smallPt
                    color: Style.colors.diffRemovedCount
                }

                ActionIconButton{
                    iconText: Style.icons.gear
                    textColor: Style.colors.secondaryText
                    hoverTextColor: Style.colors.openBlue
                    hoverBackgroundColor: Qt.rgba(Style.colors.openBlue.r, Style.colors.openBlue.g, Style.colors.openBlue.b, 0.1)
                    tooltip: "Diff settings"

                    onClicked: settingsPopup.open()
                }
            }

            Popup {
                id: settingsPopup
                y: parent.height + 4
                x: parent.width - width - 8
                width: 350
                padding: 12
                modal: false
                closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

                background: Rectangle {
                    color: Style.colors.secondaryBackground
                    border.color: Style.colors.primaryBorder
                    radius: 6
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    CheckboxItem {
                        id: chunkViewCheck
                        Layout.fillWidth: true
                        title: "Chunk View"
                        description: "Enable chunk-based diff display"
                        checked: root.chunkMode

                        onCheckedChanged: {
                            if (root.fileIsEdited) {
                                var d = unsavedChangesDialogComp.createObject(root)
                                d.title = "Unsaved Changes"
                                d.message = "You have unsaved changes in: " + root.selectedFile
                                d.saved.connect(() => {
                                    root.saveFile()
                                    root.chunkMode = checked
                                })
                                d.aborted.connect(() => {
                                    root.chunkMode = checked
                                })
                                d.cancelled.connect(() => {
                                    checked = Qt.binding(() => root.chunkMode)
                                })
                                d.open()
                            } else {
                                root.chunkMode = checked
                            }
                        }
                    }

                    SpinboxItem {
                        id: contextSpin
                        Layout.fillWidth: true
                        title: "Context Lines"
                        description: "Number of context lines around changes"
                        from: 0
                        to: 100
                        value: root.contextLines
                        enabled: root.chunkMode
                        onValueChanged:
                            if (root.contextLines !== value) {
                                root.contextLines = value
                                root.persistSettings()
                            }
                    }

                    SpinboxItem {
                        id: expandSpin
                        Layout.fillWidth: true
                        title: "Expand Step"
                        description: "Lines to show when expanding"
                        from: 1
                        to: 500
                        value: root.expandLines
                        enabled: root.chunkMode
                        onValueChanged:
                            if (root.expandLines !== value) {
                                root.expandLines = value
                                root.persistSettings()
                            }
                    }
                }
            }
        }
    }

    Component {
        id: hiddenBarComponent
        Item {
            property string direction: ""
            property int remaining: 0
            property int delegateIndex: -1

            anchors.fill: parent

            MouseArea {
                id: hiddenMarker
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expandHiddenBlock(delegateIndex, direction)
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 1
                color: hiddenMarker.containsMouse ? Style.colors.accent : Style.colors.primaryBorder
            }

            Row {
                anchors.centerIn: parent
                spacing: 6
                Label {
                    text: direction === "up" ? Style.icons.arrowUpToLine : Style.icons.arrowDownToLine
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: Style.appFont.mediumPt
                    color: hiddenMarker.containsMouse ? Style.colors.secondaryForeground : Style.colors.secondaryText
                    padding: 4
                    background: Rectangle {
                        color: hiddenMarker.containsMouse ? Style.colors.accent
                                                          : Qt.darker(Style.colors.linePanelBackgroound, 1.05)
                        radius: 4
                    }
                }
                Label {
                    text: remaining
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                    color: hiddenMarker.containsMouse ? Style.colors.secondaryForeground : Style.colors.secondaryText
                    padding: 3
                    background: Rectangle {
                        color: hiddenMarker.containsMouse ? Style.colors.accent
                                                          : Qt.darker(Style.colors.linePanelBackgroound, 1.05)
                        radius: 3
                    }
                }
            }
        }
    }

    Component {
        id: unsavedChangesDialogComp
        UnsavedChangesDialog { }
    }

    /* Guide
     * Two independent guides — one per mode — so seeing the read-only tour doesn't mark the
     * editable tour (or vice versa) as already shown.
     * ****************************************************************************************/
    GuideHoverTrigger {
        enabled: diffContent.visible
        guideController: root.guideController
        guideId: root.readOnly ? "diff_view_readonly_tutorial" : "diff_view_editable_tutorial"
        guideName: root.readOnly ? "Diff View (Read-only)" : "Diff View (Editable)"
        guideIcon: Style.icons.penToSquare
        guidePage: root.readOnly ? "graph" : "committing"
        stepsFactory: function() {
            var steps = [
                {
                    targetProvider: function() { return diffContent },
                    icon: Style.icons.penToSquare,
                    title: "Reading Diffs",
                    description:    "Green lines were added, red lines were removed, grey lines are unchanged context. You are always viewing the right-hand (new) version of the file."
                }
            ]
            if (root.readOnly) {
                steps.push({
                    targetProvider: function() { return diffContent },
                    icon: Style.icons.arrowRight,
                    title: "Read-only View",
                    description: "This diff shows a historical commit snapshot. You can read and copy lines but nothing can be staged, reverted, or edited from here."
                })
            } else if (root.chunkMode) {
                steps.push({
                    targetProvider: function() {
                        var item = root.findActionableDelegate()
                        return item ? item.stageButton : diffContent
                    },
                    icon: Style.icons.arrowRight,
                    title: "Stage a Block",
                    description: "Hover any green or red block and click the + button that appears on the right to stage only those lines. The rest of the file stays unstaged.",
                    commands: [{ command: "git add -p" }]
                })
                steps.push({
                    targetProvider: function() {
                        var item = root.findActionableDelegate()
                        return item ? item.revertButton : diffContent
                    },
                    icon: Style.icons.arrowRight,
                    title: "Revert a Block",
                    description: "Click the ↺ button on a changed block to discard those specific lines and restore them to the last committed state. Useful for undoing a mistake without losing other changes.",
                    commands: [{ command: "git checkout -p" }]
                })
                steps.push({
                    targetProvider: function() {
                        var item = root.findActionableDelegate()
                        return item ? item.stashButton : diffContent
                    },
                    icon: Style.icons.arrowRight,
                    title: "Stash a Block",
                    description: "Click the ↓ button to save just those lines aside without committing. They land in a stash entry you can reapply later — handy for parking half-finished work."
                })
                steps.push({
                    targetProvider: function() {
                        return root.findHiddenBarDelegate() || diffContent
                    },
                    icon: Style.icons.arrowRight,
                    title: "Expand Hidden Context",
                    description: "The dotted bar between hunks hides unchanged lines to keep the view focused. Click it to reveal more context around the changed code."
                })
            } else {
                steps.push({
                    targetProvider: function() { return diffContent },
                    icon: Style.icons.arrowRight,
                    title: "Chunk View",
                    description: "Enable Chunk View in the header to switch to per-block mode. Each changed block gets Stage, Revert, and Stash buttons — commit exactly the lines you want, nothing more."
                })
            }
            return steps
        }
    }

    /* Functions
     * ****************************************************************************************/
    function appendRow(model, type, lTxt, rTxt, lNum, rNum) {
        model.append({
                     "diffType": type,
                     "leftText": lTxt,
                     "rightText": rTxt,
                     "oldLineNum": lNum,
                     "newLineNum": rNum
                 })
    }

    function updateRowState(model, index)
    {
        let row = model.get(index)

        let modified = row.leftText !== row.rightText

        model.setProperty(index, "diffType", modified ? GitDiff.Modified : GitDiff.Context)
    }

    function checkHasAction(model, index, type) {
        if (readOnly || type === GitDiff.Context)
            return false;
        if (index === 0)
            return true;

        if (!model || !model.get)
            return false;

        let prevItem = model.get(index - 1);
        if (!prevItem)
            return false;

        return prevItem.diffType === GitDiff.Context;
    }

    /* Guide helpers — locate a currently visible delegate to spotlight a real button instead
     * of the whole diff panel. diffListView only instantiates visible (+ small buffer) delegates,
     * so these search the current viewport and fall back to null when nothing qualifies there. */
    function visibleDelegateRange() {
        if (!diffListView.count)
            return null

        var first = diffListView.indexAt(1, diffListView.contentY + 1)
        var last  = diffListView.indexAt(1, diffListView.contentY + diffListView.height - 1)
        if (first < 0)
            first = 0

        if (last < 0 || last < first)
            last = Math.min(diffListView.count - 1, first + 40)

        return { first: first, last: last }
    }

    function findActionableDelegate() {
        var range = root.visibleDelegateRange()
        if (!range)
            return null

        for (var i = range.first; i <= range.last; i++) {
            var d = diffListView.itemAtIndex(i)
            if (d && d.diffLineItem && d.diffLineItem.hasAction)
                return d.diffLineItem
        }
        return null
    }

    function findHiddenBarDelegate() {
        var range = root.visibleDelegateRange()
        if (!range)
            return null

        for (var i = range.first; i <= range.last; i++) {
            var d = diffListView.itemAtIndex(i)
            if (d && d.hiddenLoader && d.hiddenLoader.active)
                return d.hiddenLoader
        }
        return null
    }

    // Called when user interacts with the textEdit
    function changeText(index, newText)
    {
        if(chunkMode)
            return
        let model = fileModel
        let row = model.get(index)
        if (!row)
            return

        // Set the newText as the currentText of the textEdit
        model.setProperty(index, "rightText", newText)

        // Dont update the row state to modified if it is an added line
        if (row.diffType !== GitDiff.Added)
        {
            updateRowState(model, index)
        }

        root.fileIsEdited = isFileEdited()
        root.fileEdited(root.fileIsEdited)
    }

    // Called by Delegate when user presses Enter
    function splitLine(index, cursorPosition, textAfterCursor) {
        if(chunkMode)
            return
        let model = fileModel

        // Update the current row to contain only text BEFORE cursor
        var currentRow = model.get(index)
        var originalText = currentRow.rightText
        var textBefore = originalText.substring(0, cursorPosition)

        model.setProperty(index, "rightText", textBefore)
        if(currentRow.diffType !== GitDiff.Added)
            updateRowState(model, index)

        var newLineNum = currentRow.newLineNum + 1
        let nextRow = model.get(index + 1)

        // If nextRow is Deleted update its state, otherwise add a new row
        if(nextRow && nextRow.diffType === GitDiff.Deleted)
        {
            model.setProperty(index + 1, "rightText", textAfterCursor)
            updateRowState(model, index + 1)
        }
        else {
            model.insert(index + 1, {
                 "diffType": GitDiff.Added,
                 "leftText": "",
                 "rightText": textAfterCursor,
                 "oldLineNum": -1,
                 "newLineNum": newLineNum
            })
        }

        // Move focus to the new line (handled in Delegate via onAdded)
        root.currentIndex = index + 1

        for (var i = index + 2; i < model.count; i++) {
            var row = model.get(i);
            if (row.newLineNum !== -1) {
                model.setProperty(i, "newLineNum", row.newLineNum + 1);
            }
        }

        root.fileIsEdited = isFileEdited()
        root.fileEdited(root.fileIsEdited)
    }

    // Called by Delegate when user presses Backspace at start
    function mergeLineUp(index)
    {
        if(chunkMode)
            return
        let model = fileModel

        if (index === 0)
            return

        let currentRow = model.get(index)
        let prevRow = model.get(index - 1)

        if (!currentRow || !prevRow)
            return

        if (prevRow.diffType === GitDiff.Deleted)
            return

        let newRightText = prevRow.rightText + currentRow.rightText
        model.setProperty(index - 1, "rightText", newRightText)

        // Remove added lines, otherwise mark as deleted while preserving diff history.
        if (currentRow.diffType === GitDiff.Added)
        {
            model.remove(index)

            for (let i = index ; i < model.count; i++)
            {
                let row = model.get(i)
                if (row.newLineNum !== -1)
                    model.setProperty(i, "newLineNum", row.newLineNum - 1)
            }
        }
        else
        {
            model.setProperty(index, "diffType", GitDiff.Deleted)

            if (chunkMode)
                model.setProperty(index, "rowType", "diff")

            updateRowState(model, index - 1)

            for (let i = index + 1; i < model.count; i++)
            {
                let row = model.get(i)
                if (row.newLineNum !== -1)
                    model.setProperty(i, "newLineNum", row.newLineNum - 1)
            }
        }

        // Move focus up
        root.currentIndex = index - 1

        root.fileIsEdited = isFileEdited()
        root.fileEdited(root.fileIsEdited)
    }

    function updateMaxContentWidth(newText) {
        let visualText = newText.replace(/\t/g, "    ");

        widthCalculator.text = visualText;

        // Add a "safety buffer" so the cursor isn't flush against the edge
        var measuredWidth = widthCalculator.width + 200;

        if (measuredWidth > diffListView.maxContentWidth) {
            diffListView.maxContentWidth = measuredWidth;
        }
    }

    function buildChunkModel() {
        chunkModel.clear()

        if (!chunkData || chunkData.length === 0)
            return

        for (let c = 0; c < chunkData.length; c++) {
            let chunk = chunkData[c]

            if (chunk.chunkType === "changed") {
                let lines = chunk.lines
                for (let l = 0; l < lines.length; l++) {
                    let line    = lines[l]
                    let left    = (line.type === GitDiff.Added)     ? "" : line.content
                    let right   = (line.type === GitDiff.Deleted)   ? "" :
                                  (line.type === GitDiff.Modified   ? line.newContent : line.content)

                    chunkModel.append({
                        rowType     : "diff",
                        diffType    : line.type,
                        leftText    : left,
                        rightText   : right,
                        oldLineNum  : line.oldLine !== undefined ? line.oldLine : -1,
                        newLineNum  : line.newLine !== undefined ? line.newLine : -1
                    })
                    updateMaxContentWidth(left)
                    updateMaxContentWidth(right)
                }
            } else if (chunk.chunkType === "hidden") {
                chunk.visibleTop = 0
                chunk.visibleBottom = 0

                let prevChunk = (c > 0) ? chunkData[c-1] : null
                let nextChunk = (c < chunkData.length-1) ? chunkData[c+1] : null

                if (prevChunk && prevChunk.chunkType === "changed") {
                    chunkModel.append({
                        rowType: "hidden",
                        direction: "down",
                        hiddenCount: chunk.hiddenCount,
                        remaining: chunk.hiddenCount,
                        chunkIndex: c
                    })
                }

                if (nextChunk && nextChunk.chunkType === "changed") {
                    chunkModel.append({
                        rowType: "hidden",
                        direction: "up",
                        hiddenCount: chunk.hiddenCount,
                        remaining: chunk.hiddenCount,
                        chunkIndex: c
                    })
                }
            }
        }
        if (root.contextLines > 0) {
            let processedChunks = []
            for (let c = 0; c < chunkData.length; c++) {
                let chunk = chunkData[c]
                if (chunk.chunkType !== "hidden")
                    continue

                let downIdx = -1, upIdx = -1
                for (let i = 0; i < chunkModel.count; i++) {
                    let r = chunkModel.get(i)
                    if (r.rowType === "hidden" && r.chunkIndex === c) {
                        if (r.direction === "down") downIdx = i
                        else if (r.direction === "up") upIdx = i
                    }
                }
                if (downIdx !== -1) {
                    root.expandHiddenBlock(downIdx, "down", root.contextLines)
                    if (upIdx !== -1) {
                        upIdx = -1
                        for (let j = 0; j < chunkModel.count; j++) {
                            let r = chunkModel.get(j)
                            if (r.rowType === "hidden" && r.chunkIndex === c && r.direction === "up")
                                upIdx = j
                        }
                    }
                }
                if (upIdx !== -1) {
                    root.expandHiddenBlock(upIdx, "up", root.contextLines)
                }
            }
        }
    }

    function expandHiddenBlock(modelIndex, direction, customCount) {
        let bar = chunkModel.get(modelIndex)
        if (!bar || bar.rowType !== "hidden")
            return

        let chunk = chunkData[bar.chunkIndex]
        if (!chunk || chunk.chunkType !== "hidden" || !chunk.hiddenLines)
            return

        let totalHidden = chunk.hiddenCount
        let visibleTop = chunk.visibleTop || 0
        let visibleBottom = chunk.visibleBottom || 0
        let remaining = totalHidden - visibleTop - visibleBottom
        if (remaining <= 0)
            return

        let toShow = Math.min(customCount !== undefined ? customCount : root.expandLines, remaining)
        if (toShow <= 0)
            return

        let hiddenLines = chunk.hiddenLines
        let newLines = []
        let oldBarIndex = modelIndex
        let chunkIdx = bar.chunkIndex

        if (direction === "down") {
            for (let i = 0; i < toShow; i++) {
                let lineObj = hiddenLines[visibleTop + i]
                if (!lineObj) break
                newLines.push(makeContextLine(lineObj))
            }

            chunkModel.remove(oldBarIndex)
            for (let i = 0; i < newLines.length; i++)
                chunkModel.insert(oldBarIndex + i, newLines[i])

            chunk.visibleTop = visibleTop + toShow

            let newRemaining = totalHidden - chunk.visibleTop - chunk.visibleBottom
            chunkModel.insert(oldBarIndex + toShow, {
                rowType: "hidden",
                direction: "down",
                hiddenCount: totalHidden,
                remaining: newRemaining,
                chunkIndex: chunkIdx
            })

        } else { // "up"
            let endIdx = hiddenLines.length - 1 - visibleBottom
            for (let i = 0; i < toShow; i++) {
                let idx = endIdx - i
                if (idx < 0) break
                newLines.push(makeContextLine(hiddenLines[idx]))
            }
            newLines.sort((a, b) => a.oldLineNum - b.oldLineNum)

            chunkModel.remove(oldBarIndex)
            for (let i = 0; i < newLines.length; i++)
                chunkModel.insert(oldBarIndex + i, newLines[i])

            chunk.visibleBottom = visibleBottom + toShow

            let newRemaining = totalHidden - chunk.visibleTop - chunk.visibleBottom
            chunkModel.insert(oldBarIndex, {
                rowType: "hidden",
                direction: "up",
                hiddenCount: totalHidden,
                remaining: newRemaining,
                chunkIndex: chunkIdx
            })
        }

        let finalRemaining = totalHidden - chunk.visibleTop - chunk.visibleBottom
        for (let i = 0; i < chunkModel.count; i++) {
            let r = chunkModel.get(i)
            if (r.rowType === "hidden" && r.chunkIndex === chunkIdx) {
                chunkModel.setProperty(i, "remaining", finalRemaining)
            }
        }

        if (finalRemaining <= 0) {
            for (let i = chunkModel.count - 1; i >= 0; i--) {
                let r = chunkModel.get(i)
                if (r.rowType === "hidden" && r.chunkIndex === chunkIdx)
                    chunkModel.remove(i)
            }
        }

        for (let line of newLines)
            updateMaxContentWidth(line.leftText)
    }

    function makeContextLine(lineObj) {
        return {
            rowType: "context",
            diffType: GitDiff.Context,
            leftText: lineObj.content,
            rightText: lineObj.content,
            oldLineNum: lineObj.oldLine,
            newLineNum: lineObj.newLine
        }
    }

    function selectAll() {
        var first = -1
        var last = -1

        for (var i = 0; i < diffListView.model.count; ++i) {
            var row = diffListView.model.get(i)

            if (row.rowType === "hidden")
                continue

            if (first === -1)
                first = i

            last = i
        }

        if (first !== -1) {
            root.selectionStart = first
            root.selectionEnd = last
        }
    }

    function clearSelection() {
        root.selectionStart = -1
        root.selectionEnd = -1
    }

    function copyRowsText() {
        var min = Math.min(root.selectionStart, root.selectionEnd)
        var max = Math.max(root.selectionStart, root.selectionEnd)

        var copied = ""

        for (var i = min; i <= max; i++) {
            var row = diffListView.model.get(i)

            if (!row || row.rowType === "hidden")
                continue

            var text = ""
            if(root.selectedSide === DiffView.DiffViewSelectionSide.Left)
                text += row.leftText
            else if(root.selectedSide === DiffView.DiffViewSelectionSide.Right)
                text += row.rightText

            copied += text + "\n"
        }

        clipboardHelper.text = copied
        clipboardHelper.selectAll()
        clipboardHelper.copy()
    }

    // Checks if the selected file is edited
    function isFileEdited() {
        if(chunkMode)
            return false

        root.editedFileBuffer = []

        for (let i = 0; i < fileModel.count; i++) {
            let row = fileModel.get(i)
            if (row)
                root.editedFileBuffer.push(row.rightText || "")
        }

        if (root.editedFileBuffer.length !== root.originalFileBuffer.length) {
            return true
        }

        for (let i = 0; i < root.editedFileBuffer.length; i++) {
            if (root.editedFileBuffer[i] !== root.originalFileBuffer[i]) {
                return true
            }
        }

        return false
    }

    function persistSettings() {
        if (!appModel)
            return

        let gs = appModel.appSettings.generalSettings
        if (gs.chunkContextLines !== root.contextLines) {
            gs.chunkContextLines = root.contextLines
        }
        if (gs.chunkExpandLines !== root.expandLines) {
            gs.chunkExpandLines = root.expandLines
        }
        appModel.save()
    }
}
