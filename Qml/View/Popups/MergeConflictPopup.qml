import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * MergeConflictPopup
 * ************************************************************************************************/

IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property MergeController mergeController: null
    property ConflictController conflictController: null
    property NotificationController notificationController: null

    property var conflicts: []
    property var selectedConflict: null
    property string selectedPath: ""

    property int extraWidthSpace: 100

    /* Object Properties
     * ****************************************************************************************/

    width: 800
    height: 650
    padding: 12

    // modal: true
    // focus: true
    // closePolicy: Popup.CloseOnEscape



    // Flat list of rows to display in the editor
    property var displayRows: []

    // Edit buffers
    property var contextEdits: ({})
    property var blockEdits: ({})

    onOpened: loadConflicts()

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
            RowLayout{
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "Merge Conflicts"
                    color: Style.colors.secondaryText
                    font.family: Style.fontTypes.roboto
                    font.bold: true
                    elide: Text.ElideLeft
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
                    onClicked: root.close()
                }
            }

            // Content
            RowLayout{
                Layout.fillWidth: true
                spacing: 8

                // Left panel: file list
                Rectangle{
                    Layout.preferredWidth: 240
                    Layout.fillHeight: true

                    radius: 4
                    color: Style.colors.primaryBackground
                    border.width: 1
                    border.color: Style.colors.primaryBorder

                    ListView {
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

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.path || ""
                                font.family: Style.fontTypes.roboto
                                color: Style.colors.lineNumberColor
                                font.pixelSize: 13
                                elide: Text.ElideMiddle
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.selectFile(modelData.path)
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }

                // Right panel: conflict editor
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    radius: 4
                    color: Style.colors.primaryBackground
                    border.width: 1
                    border.color: Style.colors.primaryBorder

                    ScrollView {
                        anchors.fill: parent
                        clip: true

                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOn
                        ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                        contentItem: Flickable {
                            id: flickable
                            clip: true

                            // Track the maximum width needed
                            property real maxContentWidth: 0

                            Item {
                                id: contentContainer
                                width: Math.max(flickable.maxContentWidth, flickable.width)
                                height: listView.contentHeight

                                ListView {
                                    id: listView
                                    anchors.fill: parent
                                    model: displayRows
                                    clip: true
                                    spacing: 0

                                    onModelChanged: Qt.callLater(updateContentWidth)
                                    onCountChanged: Qt.callLater(updateContentWidth)

                                    delegate: RowLayout {
                                        id: delegateRow
                                        width: contentContainer.width
                                        spacing: 0

                                        // Track our implicit width
                                        property real rowImplicitWidth: 50 + 1 + contentLoader.implicitWidth + 4

                                        Component.onCompleted: {
                                            // Update max width if this row is wider
                                            if (rowImplicitWidth > flickable.maxContentWidth) {
                                                flickable.maxContentWidth = rowImplicitWidth
                                                contentContainer.width = Math.max(flickable.maxContentWidth, flickable.width)
                                                flickable.contentWidth = contentContainer.width
                                            }
                                        }

                                        // Line number column
                                        Rectangle {
                                            Layout.preferredWidth: 50
                                            Layout.fillHeight: true
                                            color: "transparent"

                                            Text {
                                                anchors.right: parent.right
                                                anchors.rightMargin: 8
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: Style.colors.foreground
                                                font.family: Style.fontTypes.roboto
                                                font.pixelSize: 12
                                                visible: text !== ""

                                                text: {
                                                    if (modelData.type === "contextLine")
                                                        return modelData.lineNumber
                                                    if (modelData.type === "blockLine")
                                                        return modelData.line.number
                                                    return ""
                                                }
                                            }
                                        }

                                        // Separator
                                        Rectangle {
                                            Layout.preferredWidth: 1
                                            Layout.fillHeight: true
                                            color: "#3c3c3c"
                                        }

                                        // Content
                                        Loader {
                                            id: contentLoader
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.minimumWidth: implicitWidth

                                            sourceComponent: {
                                                if (modelData.type === "contextLine")
                                                    return contextLineComponent
                                                if (modelData.type === "blockLine")
                                                    return blockLineComponent
                                                if (modelData.type === "blockButton")
                                                    return blockButtonComponent
                                                return null
                                            }
                                            onLoaded: {
                                                if (modelData.type === "contextLine") {
                                                    item.lineNumber = modelData.lineNumber
                                                    item.originalText = modelData.text
                                                } else if (modelData.type === "blockLine") {
                                                    item.blockIndex = modelData.blockIndex
                                                    item.lineData = modelData.line
                                                } else if (modelData.type === "blockButton") {
                                                    item.blockIndex = modelData.blockIndex
                                                }

                                                // Update width after item loads
                                                Qt.callLater(function() {
                                                    delegateRow.rowImplicitWidth = 50 + 1 + item.implicitWidth + 4
                                                    if (delegateRow.rowImplicitWidth > flickable.maxContentWidth) {
                                                        flickable.maxContentWidth = delegateRow.rowImplicitWidth
                                                        contentContainer.width = Math.max(flickable.maxContentWidth, flickable.width)
                                                        flickable.contentWidth = contentContainer.width
                                                    }
                                                })
                                            }
                                        }
                                    }
                                }
                            }
                            // Flickable properties
                            contentWidth: contentContainer.width
                            contentHeight: contentContainer.height
                            boundsBehavior: Flickable.StopAtBounds
                        }
                    }
                }
            }

            // Footer buttons
            RowLayout{
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    flat: true
                    text: "Save & Stage"
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                    }

                    onClicked: saveAndStage()
                }

                Button {
                    flat: true
                    text: "Continue Merge"
                    enabled: !displayRows.some(row => row.type === "blockButton")
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                    }

                    onClicked: continueMerge()
                }
            }
        }
    }

    // Context line component
    Component {
        id: contextLineComponent
        Item {
            property int lineNumber: 0
            property string originalText: ""

            implicitHeight: textInput.implicitHeight + 4
            implicitWidth: Math.max(textInput.implicitWidth + 20, 100)

            TextInput {
                id: textInput
                anchors.fill: parent
                anchors.margins: 2
                text: root.contextLineText(lineNumber)
                font.family: Style.fontTypes.roboto
                font.pixelSize: 13
                color: Style.colors.editorForeground
                selectByMouse: true
                verticalAlignment: TextInput.AlignTop
                wrapMode: TextInput.NoWrap
            }
        }
    }

    // Block line component (a line inside a conflict block)
    Component {
        id: blockLineComponent
        Item {
            property int blockIndex: 0
            property var lineData: null

            implicitHeight: textInput.implicitHeight + 4
            implicitWidth: Math.max(textInput.implicitWidth + 20, 100)

            readonly property bool isMarker: lineData.role === "marker-start" ||
                                             lineData.role === "separator" ||
                                             lineData.role === "marker-end"

            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                z: -1
                radius: 2
                color: {
                    if (lineData.role === "marker-start")
                        return Style.colors.conflictMarkerStartBg
                    if (lineData.role === "ours")
                        return Style.colors.conflictOursBg
                    if (lineData.role === "theirs")
                        return Style.colors.conflictTheirsBg
                    if (lineData.role === "marker-end")
                        return Style.colors.conflictMarkerEndBg
                    if (lineData.role === "separator")
                        return Style.colors.conflictSeparatorBg
                    return "transparent"
                }
            }

            TextInput {
                id: textInput
                anchors.fill: parent
                anchors.margins: 2
                text: root.blockLineText(blockIndex, lineData.number)
                font.family: Style.fontTypes.roboto
                font.pixelSize: 13
                color: isMarker ? Style.colors.conflictMarkerText : Style.colors.editorForeground
                selectByMouse: true
                readOnly: isMarker
                verticalAlignment: TextInput.AlignTop
                wrapMode: TextInput.NoWrap
                onTextChanged: {
                    if (!isMarker)
                        root.setBlockLineText(blockIndex, lineData.number, text)
                }
            }
        }
    }

    // Block button component (appears before each conflict block)
    Component {
        id: blockButtonComponent
        Item {
            property int blockIndex: 0

            implicitHeight: buttonRow.implicitHeight + 4
            implicitWidth: buttonRow.implicitWidth + 20

            RowLayout {
                id: buttonRow
                anchors.fill: parent
                anchors.margins: 2
                spacing:2

                Text {
                    text: "Accept Current |"
                    color: Style.colors.hintText
                    font.pixelSize: 10

                    MouseArea{
                        anchors.fill: parent
                        onClicked: root.acceptBlock(blockIndex, "ours")
                        cursorShape: Qt.PointingHandCursor

                        hoverEnabled: true
                        onEntered: parent.color = Style.colors.accentHover
                        onExited: parent.color = Style.colors.hintText
                    }
                }

                Text {
                    text: "Accept Incoming |"
                    color: Style.colors.hintText
                    font.pixelSize: 10

                    MouseArea{
                        anchors.fill: parent
                        onClicked: root.acceptBlock(blockIndex, "theirs")
                        cursorShape: Qt.PointingHandCursor

                        hoverEnabled: true
                        onEntered: parent.color = Style.colors.accentHover
                        onExited: parent.color = Style.colors.hintText
                    }
                }

                Text {
                    text: "Accept Both"
                    color: Style.colors.hintText
                    font.pixelSize: 10

                    MouseArea{
                        anchors.fill: parent
                        onClicked: root.acceptBlock(blockIndex, "both")
                        cursorShape: Qt.PointingHandCursor

                        hoverEnabled: true
                        onEntered: parent.color = Style.colors.accentHover
                        onExited: parent.color = Style.colors.hintText
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function loadConflicts() {
        if (!conflictController)
            return

        let res = conflictController.getMergeConflicts()
        if (!res.success) {
            if (notificationController)
                notificationController.error(res.errorMessage, "Conflicts", 4000)
            return
        }

        conflicts = res.data || []
        if (conflicts.length > 0) {
            selectFile(conflicts[0].path)
        } else {
            selectedConflict = null
            selectedPath = ""
            displayRows = []
        }
    }

    function selectFile(path) {
        for (let i = 0; i < conflicts.length; ++i) {
            if (conflicts[i].path === path) {

                contextEdits = {}
                blockEdits = {}

                selectedConflict = conflicts[i]
                selectedPath = path
                buildDisplayRows()
                break
            }
        }
    }

    function buildDisplayRows() {
        if (!selectedConflict) {
            displayRows = []
            return
        }

        let lines = selectedConflict.lines || []        // full file
        let blocks = selectedConflict.blocks || []      // conflict metadata
        let blockMap = {}
        for (let b of blocks)
            blockMap[b.startLine] = b

        let rows = []
        let i = 0
        while (i < lines.length) {
            let lineNumber = i + 1
            if (blockMap[lineNumber]) {
                let block = blockMap[lineNumber]
                // Button row
                rows.push({
                              type: "blockButton",
                              blockIndex: block.index,
                              block: block
                          })
                // All lines of the block
                for (let j = 0; j < block.lines.length; ++j) {
                    rows.push({
                                  type: "blockLine",
                                  blockIndex: block.index,
                                  line: block.lines[j]
                              })
                }
                i = block.endLine  // past block
            } else {
                rows.push({
                              type: "contextLine",
                              lineNumber: lineNumber,
                              text: lines[i]
                          })
                i++
            }
        }
        displayRows = rows
    }

    function contextLineText(lineNumber) {
        return contextEdits[lineNumber] !== undefined ? contextEdits[lineNumber] : selectedConflict.lines[lineNumber-1]
    }

    function blockLineText(blockIndex, lineNumber) {
        let key = blockIndex + ":" + lineNumber
        if (blockEdits[key] !== undefined)
            return blockEdits[key]
        // fallback: find original line text
        for (let b of selectedConflict.blocks) {
            if (b.index === blockIndex) {
                for (let l of b.lines) {
                    if (l.number === lineNumber)
                        return l.text
                }
            }
        }
        return ""
    }

    function acceptBlock(blockIndex, mode) {
        if (!selectedPath || !conflictController) return
        let res
        if (mode === "ours")
            res = conflictController.acceptBlockOurs(selectedPath, blockIndex)
        else if (mode === "theirs")
            res = conflictController.acceptBlockTheirs(selectedPath, blockIndex)
        else if (mode === "both")
            res = conflictController.acceptBlockBoth(selectedPath, blockIndex)
        else return

        if (!res.success) {
            if (notificationController)
                notificationController.error(res.errorMessage, "Conflict Resolution", 4000)
        } else {
            loadConflicts()
            selectFile(selectedPath)
        }
    }

    function continueMerge() {
        if (!mergeController) return
        let res = mergeController.continueMerge()
        if (res.success) {
            close()
        } else {
            if (notificationController)
                notificationController.error(res.errorMessage, "Merge", 4000)
        }
    }

    function updateContentWidth() {
        var maxWidth = 0
        for (var i = 0; i < count; i++) {
            var item = itemAtIndex(i)
            if (item) {
                maxWidth = Math.max(maxWidth, item.width)
            }
        }
        flickable.maxContentWidth = maxWidth
        contentContainer.width = Math.max(flickable.maxContentWidth, flickable.width)
        flickable.contentWidth = contentContainer.width
    }
}
