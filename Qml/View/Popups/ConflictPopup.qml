import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ConflictPopup
 * ************************************************************************************************/

IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property MergeController        mergeController         : null
    property RebaseController       rebaseController        : null
    property ConflictController     conflictController      : null
    property CherryPickController   cherryPickController    : null
    property StatusController       statusController        : null
    property NotificationController notificationController  : null

    property var    conflicts       : []
    property var    selectedConflict: null
    property string selectedPath    : ""

    enum OperationType {
        None,
        Merge,
        Rebase,
        CherryPick
    }
    property int currentOperation: ConflictPopup.OperationType.None

    readonly property bool canContinue: {
        if (currentOperation === ConflictPopup.OperationType.Merge)
            return mergeController && conflicts.length === 0

        if (currentOperation === ConflictPopup.OperationType.Rebase)
            return rebaseController && conflicts.length === 0

        if (currentOperation === ConflictPopup.OperationType.CherryPick)
            return cherryPickController && conflicts.length === 0

        return false
    }

    readonly property string operationName: {
        if (currentOperation === ConflictPopup.OperationType.Merge)
            return "Merge"
        if (currentOperation === ConflictPopup.OperationType.Rebase)
            return "Rebase"
        if (currentOperation === ConflictPopup.OperationType.CherryPick)
            return "Cherry-pick"
        return ""
    }

    property string headerText: `${operationName} Conflicts`

    property string continueButtonText: `Continue ${operationName}`


    property var modifiedFiles: ({}) // path -> array of row objects

    /* Object Properties
     * ****************************************************************************************/
    width: 800
    height: 650
    padding: 12

    modal: true
    closePolicy: Popup.NoAutoClose

    onOpened: {
        modifiedFiles = ({}) // Clear all memory cache
        selectedPath = ""    // Reset selected path
        loadConflicts()
    }

    ListModel {
        id: displayModel
    }

    TextMetrics {
        id: widthCalculator
        font.family: "Cascadia Mono"
        font.pixelSize: 13
    }

    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            spacing: 8
            anchors.fill: parent
            anchors.margins: 20

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: root.headerText
                    color: Style.colors.secondaryText
                    font.family: Style.fontTypes.roboto
                    font.bold: true
                    font.pixelSize: 14
                }

                // Close Button
                WindowsButton {
                    id: closeButton
                    Material.accent: Style.colors.windowsClose
                    content: Item {
                        anchors.centerIn: parent
                        width: 10
                        height: 10

                        Rectangle {
                            width: 12
                            height: 2
                            radius: 1
                            color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                            anchors.centerIn: parent
                            rotation: 45
                        }

                        Rectangle {
                            width: 12
                            height: 2
                            radius: 1
                            color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                            anchors.centerIn: parent
                            rotation: -45
                        }
                    }
                    onClicked: {
                        var d = confirmationDialogComponent.createObject(root)

                        d.title = `Abort ${operationName}?`
                        d.message = "You have unresolved conflicts.\n" +
                                    `Closing this window will abort the ${operationName} and discard all progress.\n\n` +
                                    "Are you sure you want to abort?"

                        d.saved.connect(() => {
                            root.saveAllModifications()
                        })

                        d.aborted.connect(() => {
                            root.abortOperation()
                        })

                        d.open()
                    }
                }
            }

            // Content
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Left panel: file list
                Rectangle {
                    Layout.preferredWidth: 240
                    Layout.fillHeight: true
                    radius: 4
                    color: Style.colors.primaryBackground
                    border.width: 1
                    border.color: Style.colors.primaryBorder

                    ListView {
                        id: fileListView
                        anchors.fill: parent
                        model: conflicts
                        spacing: 1
                        currentIndex: {
                            for (let i = 0; i < conflicts.length; ++i)
                                if (conflicts[i].path === selectedPath)
                                    return i
                            return -1
                        }

                        delegate: Rectangle {
                            width: parent.width
                            height: 24
                            radius: 3
                            color: ListView.isCurrentItem ? Style.colors.hoverTitle : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8
                                Text {
                                    text: (index + 1) + "."
                                    color: Style.colors.lineNumberColor
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 12
                                    opacity: 0.7
                                }
                                ScrollingText {
                                    Layout.fillWidth: true
                                    text: modelData.path || ""
                                    font.family: Style.fontTypes.roboto
                                    color: Style.colors.lineNumberColor
                                    font.pixelSize: 13
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                ActionIconButton {
                                    property bool canSave: !modelData.blocks || modelData.blocks.length === 0

                                    iconText: Style.icons.plus
                                    textColor: Style.colors.mutedText

                                    opacity: canSave ? 1.0 : 0.5

                                    tooltip: canSave ? "Save and Stage" : "Resolve conflicts to stage"

                                    onClicked: {
                                        if(!modelData.blocks || modelData.blocks.length === 0){
                                            root.selectFile(modelData.path)
                                            root.saveAndStage(modelData.path)
                                        }

                                    }
                                }
                            }
                            TapHandler {
                                onTapped: root.selectFile(modelData.path)
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                            }
                        }
                    }
                }

                // Right panel: conflict editor
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Style.colors.editorBackgroound
                    border.width: 1
                    border.color: Style.colors.primaryBorder
                    radius: 4

                    ListView {
                        id: conflictListView
                        property real horizontalScrollOffset: 0
                        property real maxContentWidth: 0

                        anchors.fill: parent
                        clip: true
                        model: displayModel

                        cacheBuffer: 5000
                        reuseItems: true
                        anchors.bottomMargin: hScrollBar.visible ? hScrollBar.height : 0
                        ScrollBar.vertical: ScrollBar
                        {
                            active: true
                        }

                        delegate: Item {
                            id: rowRoot
                            width: conflictListView.width

                            readonly property bool isButtonRow: model.type === "blockButton"
                            readonly property bool isBlockLine: model.type === "blockLine"
                            readonly property bool isMarker: isBlockLine && (model.role === "marker-start" ||
                                                                              model.role === "separator" ||
                                                                              model.role === "marker-end")
                            property bool isCurrentItem: ListView.isCurrentItem

                            height: Math.max(isButtonRow ? 32 : 24,
                                             isButtonRow ? buttonRow.implicitHeight + 8 : lineEditor.contentHeight + 4)

                            onIsCurrentItemChanged: {
                                if (isCurrentItem && !isButtonRow && !isMarker)
                                    lineEditor.forceActiveFocus()
                            }

                            Row {
                                anchors.fill: parent
                                spacing: 0

                                // Line number panel
                                Label {
                                    width: 45
                                    height: parent.height
                                    text: isButtonRow ? "" : model.lineNumber
                                    color: Style.colors.linePanelForeground
                                    font.family: "Cascadia Mono"
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignRight
                                    rightPadding: 10
                                    topPadding: 4

                                    background: Rectangle {
                                        color: Style.colors.linePanelBackgroound
                                    }
                                }

                                // Content panel
                                Item {
                                    id: contentPanel
                                    height: parent.height
                                    width: parent.width - 45
                                    clip: true

                                    Rectangle {
                                        anchors.fill: parent
                                        z: -1
                                        color: {
                                            if (isButtonRow) return Style.colors.secondaryBackground
                                            if (!isBlockLine) return "transparent"

                                            if (model.role === "marker-start") return Style.colors.conflictMarkerStartBg
                                            if (model.role === "ours") return Style.colors.conflictOursBg
                                            if (model.role === "theirs") return Style.colors.conflictTheirsBg
                                            if (model.role === "marker-end") return Style.colors.conflictMarkerEndBg
                                            if (model.role === "separator") return Style.colors.conflictSeparatorBg
                                            return "transparent"
                                        }
                                    }

                                    // 1. Read-only Label exclusively for markers
                                    Label {
                                        visible: isMarker
                                        x: -conflictListView.horizontalScrollOffset
                                        width: 2000

                                        text: {
                                            if (model.role === "marker-start") {
                                                let branchName = model.text.replace("<<<<<<<", "").trim()
                                                return "Current Change (" + (branchName || "HEAD") + ")"
                                            }
                                            if (model.role === "marker-end") {
                                                let branchName = model.text.replace(">>>>>>>", "").trim()
                                                return "Incoming Change (" + branchName + ")"
                                            }
                                            if (model.role === "separator") {
                                                return "======================="
                                            }
                                            return ""
                                        }

                                        color: Style.colors.conflictMarkerText
                                        font.family: Style.fontTypes.roboto
                                        font.pixelSize: 13
                                        padding: 0
                                        leftPadding: 8
                                        topPadding: 2
                                    }

                                    // 2. Editable TextArea exclusively for actual code
                                    TextArea {
                                        id: lineEditor
                                        visible: !isButtonRow && !isMarker
                                        x: -conflictListView.horizontalScrollOffset
                                        width: 2000

                                        text: model.text // Simple, safe binding

                                        color: Style.colors.editorForeground
                                        font.family: Style.fontTypes.roboto
                                        font.pixelSize: 13
                                        padding: 0
                                        leftPadding: 8
                                        topPadding: 2
                                        selectionColor: Style.colors.accent
                                        selectedTextColor: Style.colors.secondaryForeground
                                        background: null
                                        selectByMouse: true
                                        wrapMode: TextArea.NoWrap

                                        Material.accent: Style.colors.accent

                                        onTextChanged: {
                                            if (!isMarker && !isButtonRow && model.text !== text) {
                                                model.text = text
                                                if (displayModel.get(index)) {
                                                    displayModel.setProperty(index, "text", text)
                                                }
                                            }
                                            root.updateMaxContentWidth(text)
                                        }

                                        Keys.onPressed: (event) => {
                                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                                event.accepted = true
                                                root.splitLine(index, cursorPosition)
                                            } else if (event.key === Qt.Key_Up) {
                                                if (cursorRectangle.y <= topPadding + 2) {
                                                    event.accepted = true
                                                    conflictListView.currentIndex = Math.max(0, index - 1)
                                                }
                                            } else if (event.key === Qt.Key_Down) {
                                                if (cursorRectangle.y + cursorRectangle.height >= height - bottomPadding) {
                                                    event.accepted = true
                                                    conflictListView.currentIndex = Math.min(displayModel.count - 1, index + 1)
                                                }
                                            } else if (event.key === Qt.Key_Backspace) {
                                                if (cursorPosition === 0) {
                                                    event.accepted = true
                                                    root.mergeLineUp(index)
                                                }
                                            }
                                        }
                                    }


                                    RowLayout {
                                        id: buttonRow
                                        visible: isButtonRow
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        spacing: 8

                                        Button {
                                            text: "Accept Current"
                                            flat: true
                                            font.pixelSize: 10
                                            font.family: Style.fontTypes.roboto
                                            Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                                            background: Rectangle {
                                                color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                                                border.color: Style.colors.accent
                                                radius: 3
                                            }
                                            MouseArea{
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor

                                                onClicked: root.acceptBlock(model.blockIndex, "ours")
                                            }
                                        }
                                        Button {
                                            text: "Accept Incoming"
                                            flat: true
                                            font.pixelSize: 10
                                            font.family: Style.fontTypes.roboto
                                            Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                                            background: Rectangle {
                                                color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                                                border.color: Style.colors.accent
                                                radius: 3
                                            }
                                            MouseArea{
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor

                                                onClicked: root.acceptBlock(model.blockIndex, "theirs")
                                            }
                                        }
                                        Button {
                                            text: "Accept Both"
                                            flat: true
                                            font.pixelSize: 10
                                            font.family: Style.fontTypes.roboto
                                            Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                                            background: Rectangle {
                                                color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                                                border.color: Style.colors.accent
                                                radius: 3
                                            }
                                            MouseArea{
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor

                                                onClicked: root.acceptBlock(model.blockIndex, "both")
                                            }
                                        }
                                        Item { Layout.fillWidth: true }
                                    }
                                }
                            }
                        }
                    }

                    ScrollBar {
                        id: hScrollBar
                        orientation: Qt.Horizontal
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        size: conflictListView.maxContentWidth === 0 ? 1 : (conflictListView.width * 0.5) / conflictListView.maxContentWidth
                        active: true
                        visible: size < 1.0

                        onPositionChanged: {
                            conflictListView.horizontalScrollOffset = position * conflictListView.maxContentWidth
                        }
                    }
                }
            }

            // Footer buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    flat: true
                    text: "Skip"
                    visible: currentOperation === ConflictPopup.OperationType.Merge ? 0 : 1
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                    }
                    MouseArea{
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: skipOperation()
                    }
                }

                Button {
                    id: continueBtn
                    flat: true
                    text: root.continueButtonText

                    Material.foreground: root.canContinue && mouse.containsMouse ? Style.colors.secondaryForeground : Style.colors.foreground

                    background: Rectangle {
                        color: root.canContinue && mouse.containsMouse ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                        opacity: root.canContinue ? 1.0 : 0.5
                    }

                    ToolTip{
                        id: tip
                        parent: continueBtn
                        visible: mouse.containsMouse
                        delay: 100
                        timeout: 2000
                        text: root.canContinue ? "Click to continue" : "Resolve all files to continue"

                        x: (continueBtn.width - width) / 2
                        y: -height - 6

                        padding: 6

                        contentItem: Text {
                            text: tip.text
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 11
                            color: "#ffffff"
                        }

                        background: Rectangle {
                            radius: 6
                            color: Qt.rgba(0, 0, 0, 0.85)
                            border.color: Qt.rgba(1, 1, 1, 0.12)
                            border.width: 1
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.canContinue ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                        onClicked: {
                            if (root.canContinue) {
                                continueOperation()
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: confirmationDialogComponent

        IPopup {
            id: dialog
            modal: true
            focus: true
            width: 580
            height: 280
            anchors.centerIn: Overlay.overlay
            closePolicy: Popup.NoAutoClose

            onClosed: destroy()

            // Customizable properties
            property string title: "Save modifications"
            property string message: "There are unsaved modifications!\n" +
                                     "Do you want to save your changes?"

            property string saveTitle: "Save"
            property string saveDescription: "The modifications will be saved"

            property string acceptTitle: "Abort Operation"
            property string acceptDescription: "Discard all changes and exit"
            property bool hasAbort: true

            property string cancelTitle: "Keep Resolving"
            property string cancelDescription: "Return to the conflict editor"

            // Signals
            signal saved()
            signal aborted()
            signal cancelled()

            contentItem: Rectangle {
                anchors.fill: parent
                color: Style.colors.primaryBackground
                radius: 16
                clip: true
                border.color: Style.colors.accent
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        // Main Icon
                        Text {
                            Layout.alignment: Qt.AlignTop
                            text: Style.icons.warning
                            font.family: Style.fontTypes.font6Pro
                            color: Style.colors.warning
                            font.pixelSize: 50
                        }

                        ColumnLayout{
                            Layout.fillWidth: true
                            spacing: 12

                            Text {
                                Layout.fillWidth: true
                                text: dialog.title
                                color: Style.colors.secondaryText
                                font.family: Style.fontTypes.roboto
                                font.bold: true
                                font.pixelSize: 18
                            }

                            Text {
                                Layout.fillWidth: true
                                text: dialog.message
                                wrapMode: Text.Wrap
                                color: Style.colors.secondaryText
                                font.family: Style.fontTypes.roboto
                                font.pixelSize: 14
                            }
                        }
                    }

                    // BUTTON 1: Save
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: saveRow.implicitHeight + 16
                        border.color: saveMouseArea.containsMouse ? Style.colors.accent : "transparent"
                        radius: 6
                        visible: false  //TODO, next version

                        MouseArea {
                            id: saveMouseArea
                            cursorShape: Qt.PointingHandCursor
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                dialog.saved()
                                dialog.close()
                            }
                        }

                        RowLayout {
                            id: saveRow
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Text {
                                text: Style.icons.arrowRight
                                Layout.alignment: Qt.AlignTop
                                color: Style.colors.accent
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: 16
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: dialog.saveTitle
                                    color: Style.colors.secondaryText
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                                Text {
                                    text: dialog.saveDescription
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                    color: Qt.darker(Style.colors.secondaryText, 1.2)
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }

                    // BUTTON 2: Abort
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: abortRow.implicitHeight + 16
                        border.color: abortMouseArea.containsMouse ? Style.colors.accent : "transparent"
                        radius: 6
                        visible: dialog.hasAbort

                        MouseArea {
                            id: abortMouseArea
                            cursorShape: Qt.PointingHandCursor
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                dialog.aborted()
                                dialog.close()
                            }
                        }

                        RowLayout {
                            id: abortRow
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Text {
                                text: Style.icons.arrowRight
                                Layout.alignment: Qt.AlignTop
                                color: Style.colors.accent
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: 16
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: dialog.acceptTitle
                                    color: Style.colors.secondaryText
                                    font.family: Style.fontTypes.roboto
                                    font.bold: true
                                    font.pixelSize: 14
                                }
                                Text {
                                    text: dialog.acceptDescription
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                    color: Qt.darker(Style.colors.secondaryText, 1.2)
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }

                    // BUTTON 3: Cancel
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: cancelRow.implicitHeight + 16
                        border.color: cancelMouseArea.containsMouse ? Style.colors.accent : "transparent"
                        radius: 6

                        MouseArea {
                            id: cancelMouseArea
                            cursorShape: Qt.PointingHandCursor
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                dialog.cancelled()
                                dialog.close()
                            }
                        }

                        RowLayout {
                            id: cancelRow
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Text {
                                text: Style.icons.arrowRight
                                Layout.alignment: Qt.AlignTop
                                color: Style.colors.accent
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: 16
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: dialog.cancelTitle
                                    color: Style.colors.secondaryText
                                    font.family: Style.fontTypes.roboto
                                    font.bold: true
                                    font.pixelSize: 14
                                }
                                Text {
                                    text: dialog.cancelDescription
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                    color: Qt.darker(Style.colors.secondaryText, 1.2)
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/

    function loadConflicts(keepSelection = false) {
        if (!conflictController)
            return

        let res = conflictController.getConflicts()
        if (!res.success) {
            if (notificationController)
                notificationController.error(res.errorMessage, "Conflicts", 4000)
            return
        }

        conflicts = res.data || []

        if (conflicts.length == 0){
            selectedConflict = null
            selectedPath = ""
            displayModel.clear()
            return
        }

        if (keepSelection && selectedPath) {
            let exists = conflicts.some(c => c.path === selectedPath)
            if (exists)
                selectFile(selectedPath, true)
            else
                selectFile(conflicts[0].path)
        } else {
            selectFile(conflicts[0].path)
        }
    }

    function selectFile(path, forceRebuild = false) {
        if (selectedPath === path && !forceRebuild)
            return

        // 1. Save current displayModel state before switching
        if (selectedPath && selectedPath !== path && displayModel.count > 0) {
            let currentState = []
            for (let i = 0; i < displayModel.count; ++i) {
                let row = displayModel.get(i)
                currentState.push({
                    type: row.type,
                    text: row.text || "",
                    lineNumber: row.lineNumber || 0,
                    blockIndex: row.blockIndex !== undefined ? row.blockIndex : -1,
                    role: row.role || ""
                })
            }
            let copy = Object.assign({}, modifiedFiles)
            copy[selectedPath] = currentState
            modifiedFiles = copy
        }

        // 2. Switch File
        for (let i = 0; i < conflicts.length; ++i) {
            if (conflicts[i].path === path) {
                selectedConflict = conflicts[i]
                selectedPath = path
                buildDisplayModel()
                break
            }
        }
    }

    function buildDisplayModel() {
        displayModel.clear()
        conflictListView.maxContentWidth = 0

        if (!selectedConflict)
            return

        // 1. Restore from memory if user previously modified it
        if (modifiedFiles[selectedPath]) {
            let savedState = modifiedFiles[selectedPath]
            for (let i = 0; i < savedState.length; ++i) {
                displayModel.append(savedState[i])
                if (savedState[i].text)
                    updateMaxContentWidth(savedState[i].text)
            }
            return
        }

        // 2. Otherwise build original fresh structure
        let lines = selectedConflict.lines || []
        let blocks = selectedConflict.blocks || []

        // Create a map for quick lookup: startLine → block
        let blockMap = {}
        for (let b of blocks)
            blockMap[b.startLine] = b

        let i = 0
        let runningLine = 1

        while (i < lines.length) {
            let lineNumber = i + 1

            // Check if this line starts a conflict block
            if (blockMap[lineNumber]) {
                let block = blockMap[lineNumber]

                // 1. Add button row
                displayModel.append({
                    type: "blockButton",
                    blockIndex: block.index
                })

                // 2. Add all lines inside the conflict block
                for (let j = 0; j < block.lines.length; ++j) {
                    let line = block.lines[j]
                    displayModel.append({
                        type: "blockLine",
                        text: line.text,
                        blockIndex: block.index,
                        role: line.role,
                        lineNumber: runningLine
                    })
                    updateMaxContentWidth(line.text)
                    runningLine++
                }
                i = block.endLine
            }
            // Regular (non-conflict) line
            else {
                displayModel.append({
                    type: "contextLine",
                    text: lines[i],
                    lineNumber: runningLine
                })
                updateMaxContentWidth(lines[i])
                runningLine++
                i++
            }
        }
    }


    function updateMaxContentWidth(newText) {
        if (newText === undefined || newText === null)
            return

        let visualText = newText.replace(/\t/g, "    ")
        widthCalculator.text = visualText

        var measuredWidth = widthCalculator.width + 200
        if (measuredWidth > conflictListView.maxContentWidth)
            conflictListView.maxContentWidth = measuredWidth
    }

    function splitLine(rowIndex, cursorPos) {
        var row = displayModel.get(rowIndex)

        if (!row || row.type === "blockButton")
            return

        if (row.type === "blockLine" && (row.role === "marker-start" || row.role === "separator" || row.role === "marker-end"))
            return

        var before = row.text.substring(0, cursorPos)
        var after = row.text.substring(cursorPos)

        displayModel.setProperty(rowIndex, "text", before)

        var newRow = { type: row.type, text: after, lineNumber: row.lineNumber + 1 }
        if (row.blockIndex !== undefined) newRow.blockIndex = row.blockIndex
        if (row.role !== undefined) newRow.role = row.role

        displayModel.insert(rowIndex + 1, newRow)
        recomputeLineNumbers()
        conflictListView.currentIndex = rowIndex + 1
    }

    function mergeLineUp(rowIndex) {
        if (rowIndex === 0)
            return

        var current = displayModel.get(rowIndex)
        var prev = displayModel.get(rowIndex - 1)
        if (!current || !prev)
            return

        if (current.type !== prev.type)
            return

        if (current.type === "blockLine") {
            if (current.blockIndex !== prev.blockIndex || current.role !== prev.role) return
            if (current.role === "marker-start" || current.role === "separator" || current.role === "marker-end") return
        }
        displayModel.setProperty(rowIndex - 1, "text", prev.text + current.text)
        displayModel.remove(rowIndex)
        recomputeLineNumbers()
        conflictListView.currentIndex = rowIndex - 1
    }

    function recomputeLineNumbers() {
        var lineNum = 1
        for (var i = 0; i < displayModel.count; ++i) {
            var row = displayModel.get(i)
            if (row.type === "blockButton") continue
            displayModel.setProperty(i, "lineNumber", lineNum)
            lineNum++
        }
    }

    function acceptBlock(blockIndex, mode) {
        if (!selectedPath || !conflictController)
            return

        let currentContent = buildFullContent()
        conflictController.writeWorkingFile(selectedPath, currentContent)

        let res
        if (mode === "ours")
            res = conflictController.acceptBlockOurs(selectedPath, blockIndex)
        else if (mode === "theirs")
            res = conflictController.acceptBlockTheirs(selectedPath, blockIndex)
        else if (mode === "both")
            res = conflictController.acceptBlockBoth(selectedPath, blockIndex)
        else
            return

        if (!res.success) {
            if (notificationController)
                notificationController.error(res.errorMessage, "Conflict Resolution", 4000)
        }
        else {
            if (notificationController)
                notificationController.success("Conflicts Resolved", "Conflict", 2500)

            // Clear memory state so fresh Git changes load
            let copy = Object.assign({}, modifiedFiles)
            delete copy[selectedPath]
            modifiedFiles = copy

            loadConflicts(true)
        }
    }

    function saveAndStage(path) {
        if (!path  || !conflictController || !statusController)
            return

        let selectedConflict
        for (let i = 0; i < conflicts.length; ++i) {
            if (conflicts[i].path === path)
                selectedConflict = conflicts[i]
        }

        if (selectedConflict && selectedConflict.blocks && selectedConflict.blocks.length > 0) {
            showConflictStageWarning(path)
            return
        }

        performStage(path)
    }

    function showConflictStageWarning(path) {
        const d = confirmationDialogComponent.createObject(root)

        d.title = "File Has Unresolved Conflicts"
        d.message = "This file still contains unresolved conflict markers.\n" +
                    "Stage it anyway?"

        d.saveTitle = "Stage Anyway"
        d.saveDescription = "The modification will be saved"

        d.cancelTitle = "Cancel"
        d.cancelDescription = "Don't save The modification"

        d.hasAbort = false

        d.saved.connect(() => {
            performStage(path)
        })

        d.open()
    }


    function performStage(path) {
        if (!path || !statusController)
            return

        let content = buildFullContent()

        let res = conflictController.writeWorkingFile(path, content)
        if (!res.success){
            if (notificationController)
                notificationController.error(res.errorMessage || "Save failed", "Conflict", 4000)
            return
        }

        res = statusController.stageFile(path)
        if (!res.success){
            if (notificationController)
                notificationController.error(res.errorMessage || "Stage failed", "Conflict", 4000)
            return
        }

        if (notificationController)
            notificationController.success("File staged", "Conflict", 2500)

        // Clear memory state since changes are successfully staged
        let copy = Object.assign({}, modifiedFiles)
        delete copy[path]
        modifiedFiles = copy

        loadConflicts(true)
    }

    function buildFullContent() {
        let lines = []
        for (let i = 0; i < displayModel.count; ++i) {
            let row = displayModel.get(i)
            if (row.type === "blockButton")
                continue

            lines.push(row.text)
        }
        return lines.join("\n")
    }

    function continueOperation() {
        if (currentOperation === ConflictPopup.OperationType.Merge) {
            if (!mergeController)
                return

            let res = mergeController.continueMerge()

            if (res.success) {
                if (notificationController)
                    notificationController.success("Merge completed", "Conflict", 2500)

                close()
            }
            else
                notificationController.error(res.errorMessage, "Merge", 4000)
        }
        else if (currentOperation === ConflictPopup.OperationType.CherryPick) {
            if (!cherryPickController)
                return

            let res = cherryPickController.continueCherryPick()

            if (res.success) {
                if (notificationController)
                    notificationController.success("Cherry-pick completed", "Conflict", 2500)

                close()
            } else {
                if (res && res.data && (res.data.status === "conflict" || res.data.hasConflicts)) {
                    if (notificationController)
                        notificationController.warning("Continuing... but new conflicts found.", "Cherry-Pick", 4000)

                    modifiedFiles = ({})
                    loadConflicts(true)
                } else {
                    notificationController.error(res.errorMessage, "Cherry-Pick", 4000)
                }
            }
        }
        else if (currentOperation === ConflictPopup.OperationType.Rebase) {
            if (!rebaseController)
                return

            let res = rebaseController.continueRebase()

            if (res.success){
                if (notificationController)
                    notificationController.success("Rebase completed", "Conflict", 2500)

                close()
            } else {
                    if (res.data && res.data.hasConflicts) {
                    if (notificationController)
                        notificationController.warning("Continuing... but new conflicts found.", "Rebase", 4000);

                    modifiedFiles = ({})
                    loadConflicts(true)
                } else {
                    if (notificationController)
                        notificationController.error(res.errorMessage, "Rebase", 4000);
                }
            }
        }
    }

    function skipOperation() {
        if (currentOperation === ConflictPopup.OperationType.Rebase) {
            if (!rebaseController)
                return

            let res = rebaseController.skipRebase()

            if (res.success) {
                notificationController.success("Commit skipped", "Rebase", 2500)
                close();
            } else {
                if (res.data && res.data.hasConflicts){
                    notificationController.warning("Skipped, but new conflicts found in the next commit.", "Rebase", 2500)

                    modifiedFiles = ({})
                    loadConflicts(true)
                }
                else{
                    notificationController.error(res.errorMessage, "Rebase", 4000)
                }
            }
        }
        else if (currentOperation === ConflictPopup.OperationType.CherryPick) {
            if(!cherryPickController)
                return

            let res = cherryPickController.skipCherryPick()

            if (res.success) {
                notificationController.success("Commit skipped", "Cherry-Pick", 2500)
                close();
            } else {
                if (res.data && res.data.hasConflicts){
                    notificationController.warning("Skipped, but new conflicts found in the next commit.", "Cherry-Pick", 2500)

                    modifiedFiles = ({})
                    loadConflicts(true)
                } else {
                    notificationController.error(res.errorMessage, "Cherry-Pick", 4000)
                }
            }
        }
    }

    function abortOperation() {
        let res

        if (currentOperation === ConflictPopup.OperationType.Merge && mergeController) {
            res = mergeController.abortMerge()
        }
        else if (currentOperation === ConflictPopup.OperationType.Rebase && rebaseController) {
            res = rebaseController.abortRebase()
        }
        else if (currentOperation === ConflictPopup.OperationType.CherryPick && cherryPickController) {
            res = cherryPickController.abortCherryPick()
        }

        if (res && res.success) {
            notificationController.success("Operation aborted", "Git", 2500)

            // WIPE CACHE AND VIEW
            modifiedFiles = ({})
            displayModel.clear()
            selectedPath = ""

            close()
        } else if (res) {
            notificationController.error(res.errorMessage, "Git", 4000)
        }
    }

    function quitOperation() {
        if (currentOperation === ConflictPopup.OperationType.Rebase && rebaseController) {
            let res = rebaseController.quitRebase()

            if (res.success) {
                notificationController.success("Rebase quit", "Rebase", 2500)

                // WIPE CACHE AND VIEW
                modifiedFiles = ({})
                displayModel.clear()
                selectedPath = ""

                close()
            } else {
                notificationController.error(res.errorMessage, "Rebase", 4000)
            }
        }
    }

    function saveAllModifications() {


        // 1. Save the currently active file on screen
        if (selectedPath) {
            let currentContent = buildFullContent()
            conflictController.writeWorkingFile(selectedPath, currentContent)
        }

        // 2. Save any other files cached in memory
        for (let path in modifiedFiles) {
            if (path === selectedPath)
                continue

            let lines = []
            let fileModel = modifiedFiles[path]
            for (let i = 0; i < fileModel.length; ++i) {
                let row = fileModel[i]
                if (row.type !== "blockButton") {
                    lines.push(row.text)
                }
            }
            let content = lines.join("\n")
            conflictController.writeWorkingFile(path, content)
        }

        if (notificationController)
            notificationController.success("All modifications saved locally", "Save", 2500)


        root.close()
    }

}
