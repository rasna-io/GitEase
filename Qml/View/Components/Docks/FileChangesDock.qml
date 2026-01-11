import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * FileChangesDock
 * show changed files
 * ************************************************************************************************/
SimpleDock {
    id : root

    property RepositoryController repositoryController: null

    property StatusController statusController: null

    property string commitHash: ""

    /* Property Declarations
     * ****************************************************************************************/
    property var files: []
    property var selectedFile: null

    // Property to receive list of fileData objects
    property int filesColPathWidth: parent.width * 0.4
    property int filesColExtensionWidth: parent.width * 0.15
    property int filesColStatusWidth: parent.width * 0.15
    property int filesColAddedLinesWidth: parent.width * 0.15
    property int filesColRemovedLinesWidth: parent.width * 0.15
    
    // Minimum widths for each column
    readonly property int minColWidth: parent.width / 7

    /* Object Properties
     * ****************************************************************************************/
    title: "File Changes Dock"

    /* Signals
     * ****************************************************************************************/
    signal fileSelected(string filePath)

    /* Children
     * ****************************************************************************************/
    EmptyStateView {
        title: "No files to show"
        details: "Select a commit to view the file changes"
        visible: !root.files || root.files.length === 0
    }

    Rectangle{
        anchors.fill: parent
        color: Style.colors.primaryBackground
        visible: root.files && root.files.length > 0

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: header
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                color: Style.colors.primaryBackground

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.preferredWidth: root.filesColPathWidth
                        Layout.fillHeight: true
                        color: pathHeaderMouseArea.containsMouse ? Style.colors.hoverTitle : "transparent"
                        
                        MouseArea {
                            id: pathHeaderMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                        }

                        Label {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignLeft
                            anchors.leftMargin: 5
                            text: "Path"
                            color: Style.colors.foreground
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: pathDividerMouseArea.pressed ? Style.colors.resizeHandlePressed : Style.colors.resizeHandle

                            MouseArea {
                                id: pathDividerMouseArea
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 10
                                anchors.rightMargin: -5
                                hoverEnabled: true
                                cursorShape: Qt.SizeHorCursor

                                property real startX: 0
                                property int startWidth: 0

                                onPressed: function(mouse) {
                                    startX = mouseX + mapToItem(header, 0, 0).x
                                    startWidth = root.filesColPathWidth
                                }

                                onPositionChanged: function(mouse) {
                                    if (!pressed) return

                                    var currentX = mouseX + mapToItem(header, 0, 0).x
                                    var delta = currentX - startX
                                    
                                    // Calculate new width with minimum constraint
                                    var newWidth = Math.max(root.minColWidth, startWidth + delta)
                                    var actualDelta = newWidth - root.filesColPathWidth
                                    
                                    // Adjust next column (BranchTag) inversely
                                    var newBranchTagWidth = root.filesColExtensionWidth - actualDelta
                                    
                                    // Ensure next column doesn't go below minimum
                                    if (newBranchTagWidth < root.minColWidth) {
                                        newBranchTagWidth = root.minColWidth
                                        newWidth = root.filesColPathWidth + (root.filesColExtensionWidth - root.minColWidth)
                                    }
                                    
                                    if (newWidth !== root.filesColPathWidth) {
                                        root.filesColPathWidth = newWidth
                                        root.filesColExtensionWidth = newBranchTagWidth
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: root.filesColExtensionWidth
                        Layout.fillHeight: true
                        color: extensionHeaderMouseArea.containsMouse ?  Style.colors.hoverTitle : "transparent"
                        
                        MouseArea {
                            id: extensionHeaderMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                        }

                        Label {
                            anchors.left: parent.left
                            anchors.centerIn: parent
                            anchors.leftMargin: 5
                            text: "Extension"
                            color: Style.colors.foreground
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: extensionDividerMouseArea.pressed ? Style.colors.resizeHandlePressed : Style.colors.resizeHandle

                            MouseArea {
                                id: extensionDividerMouseArea
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 10
                                anchors.rightMargin: -5
                                hoverEnabled: true
                                cursorShape: Qt.SizeHorCursor

                                property real startX: 0
                                property int startWidth: 0

                                onPressed: function(mouse) {
                                    startX = mouseX + mapToItem(header, 0, 0).x
                                    startWidth = root.filesColExtensionWidth
                                }

                                onPositionChanged: function(mouse) {
                                    if (!pressed) return

                                    var currentX = mouseX + mapToItem(header, 0, 0).x
                                    var delta = currentX - startX
                                    
                                    // Calculate new width with minimum constraint
                                    var newWidth = Math.max(root.minColWidth, startWidth + delta)
                                    var actualDelta = newWidth - root.filesColExtensionWidth
                                    
                                    // Adjust next column (Message) inversely
                                    var newMessageWidth = root.filesColStatusWidth - actualDelta
                                    
                                    // Ensure next column doesn't go below minimum
                                    if (newMessageWidth < root.minColWidth) {
                                        newMessageWidth = root.minColWidth
                                        newWidth = root.filesColExtensionWidth + (root.filesColStatusWidth - root.minColWidth)
                                    }
                                    
                                    if (newWidth !== root.filesColExtensionWidth) {
                                        root.filesColExtensionWidth = newWidth
                                        root.filesColStatusWidth = newMessageWidth
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: root.filesColStatusWidth
                        Layout.fillHeight: true
                        color: statusHeaderMouseArea.containsMouse ?  Style.colors.hoverTitle : "transparent"
                        
                        MouseArea {
                            id: statusHeaderMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                        }

                        Label {
                            anchors.left: parent.left
                            anchors.centerIn: parent
                            anchors.leftMargin: 5
                            text: "Status"
                            color: Style.colors.foreground
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: statusDividerMouseArea.pressed ? Style.colors.resizeHandlePressed : Style.colors.resizeHandle

                            MouseArea {
                                id: statusDividerMouseArea
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 10
                                anchors.rightMargin: -5
                                hoverEnabled: true
                                cursorShape: Qt.SizeHorCursor

                                property real startX: 0
                                property int startWidth: 0

                                onPressed: function(mouse) {
                                    startX = mouseX + mapToItem(header, 0, 0).x
                                    startWidth = root.filesColStatusWidth
                                }

                                onPositionChanged: function(mouse) {
                                    if (!pressed) return

                                    var currentX = mouseX + mapToItem(header, 0, 0).x
                                    var delta = currentX - startX
                                    
                                    // Calculate new width with minimum constraint
                                    var newWidth = Math.max(root.minColWidth, startWidth + delta)
                                    var actualDelta = newWidth - root.filesColStatusWidth
                                    
                                    // Adjust next column (Author) inversely
                                    var newAuthorWidth = root.filesColAddedLinesWidth - actualDelta
                                    
                                    // Ensure next column doesn't go below minimum
                                    if (newAuthorWidth < root.minColWidth) {
                                        newAuthorWidth = root.minColWidth
                                        newWidth = root.filesColStatusWidth + (root.filesColAddedLinesWidth - root.minColWidth)
                                    }
                                    
                                    if (newWidth !== root.filesColStatusWidth) {
                                        root.filesColStatusWidth = newWidth
                                        root.filesColAddedLinesWidth = newAuthorWidth
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: root.filesColAddedLinesWidth
                        Layout.fillHeight: true
                        color: linesAddedHeaderMouseArea.containsMouse ?  Style.colors.hoverTitle : "transparent"
                        
                        MouseArea {
                            id: linesAddedHeaderMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                        }

                        Label {
                            anchors.left: parent.left
                            anchors.centerIn: parent
                            anchors.leftMargin: 5
                            text: "Lines Added"
                            color: Style.colors.foreground
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: linesAddedDividerMouseArea.pressed ? Style.colors.resizeHandlePressed : Style.colors.resizeHandle

                            MouseArea {
                                id: linesAddedDividerMouseArea
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 10
                                anchors.rightMargin: -5
                                hoverEnabled: true
                                cursorShape: Qt.SizeHorCursor

                                property real startX: 0
                                property int startWidth: 0

                                onPressed: function(mouse) {
                                    startX = mouseX + mapToItem(header, 0, 0).x
                                    startWidth = root.filesColAddedLinesWidth
                                }

                                onPositionChanged: function(mouse) {
                                    if (!pressed) return

                                    var currentX = mouseX + mapToItem(header, 0, 0).x
                                    var delta = currentX - startX
                                    
                                    // Calculate new width with minimum constraint
                                    var newWidth = Math.max(root.minColWidth, startWidth + delta)
                                    var actualDelta = newWidth - root.filesColAddedLinesWidth
                                    
                                    // Adjust next column (Date) inversely
                                    var newDateWidth = root.filesColRemovedLinesWidth - actualDelta
                                    
                                    // Ensure next column doesn't go below minimum
                                    if (newDateWidth < root.minColWidth) {
                                        newDateWidth = root.minColWidth
                                        newWidth = root.filesColAddedLinesWidth + (root.filesColRemovedLinesWidth - root.minColWidth)
                                    }
                                    
                                    if (newWidth !== root.filesColAddedLinesWidth) {
                                        root.filesColAddedLinesWidth = newWidth
                                        root.filesColRemovedLinesWidth = newDateWidth
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: root.filesColRemovedLinesWidth
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignRight
                        color: linesRemovedHeaderMouseArea.containsMouse ?  Style.colors.hoverTitle : "transparent"
                        
                        MouseArea {
                            id: linesRemovedHeaderMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                        }

                        Label {
                            anchors.left: parent.left
                            anchors.centerIn: parent
                            anchors.leftMargin: 5
                            text: "Lines Removed"
                            color: Style.colors.foreground
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                            wrapMode: "Wrap"
                        }
                    }
                }
            }

            RowLayout {
                id: mainRowLayout
                spacing: 0

                // Commits ListView
                ListView {
                    id: filesListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.files
                    clip: true

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 25

                        property var fileData: modelData
                        property bool isHovered: false
                        property bool isSelected: root.selectedFile && root.selectedFile.filePath === fileData.path

                        color: {
                            if (isSelected) {
                                return "#6088B2DF";
                            } else if (isHovered) {
                                return Style.colors.hoverTitle;
                            } else {
                                return Style.colors.primaryBackground;
                            }
                        }

                        radius: (isSelected || isHovered) ? 4 : 0


                        RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            anchors.topMargin: 5
                            anchors.bottomMargin: 5

                            // Column 1: File Path
                            ColumnLayout {
                                Layout.fillWidth: false
                                Layout.preferredWidth: root.filesColPathWidth
                                Layout.fillHeight: true
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true

                                    Rectangle {
                                        Layout.preferredWidth: 1
                                        Layout.fillHeight: true
                                        width: 1
                                        color: Style.colors.hoverTitle
                                    }

                                    Label {
                                        text: fileData.path || ""
                                        color: Style.colors.foreground
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 10
                                        font.family: Style.fontTypes.roboto
                                        font.weight: 400
                                        font.letterSpacing: 0.2
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 6
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            // Column 2: File Extension
                            ColumnLayout {
                                Layout.fillWidth: false
                                Layout.preferredWidth: root.filesColExtensionWidth
                                Layout.fillHeight: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true

                                    Rectangle {
                                        Layout.preferredWidth: 1
                                        Layout.fillHeight: true
                                        width: 1
                                        color: Style.colors.hoverTitle
                                    }

                                    Label {
                                        text: root.getFileExtension(fileData.path) || ""
                                        color: Style.colors.foreground
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        font.pixelSize: 10
                                        font.family: Style.fontTypes.roboto
                                        font.weight: 400
                                        font.letterSpacing: 0.2
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.leftMargin: 6
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            // Column 3: File Status
                            ColumnLayout {
                                Layout.preferredWidth: root.filesColStatusWidth
                                Layout.fillHeight: true
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true

                                    Rectangle {
                                        Layout.preferredWidth: 1
                                        Layout.fillHeight: true
                                        width: 1
                                        color: Style.colors.hoverTitle
                                    }

                                    Label {
                                        text: {
                                            switch(fileData.deltaStatus) {
                                                case GitFileStatus.ADDED:
                                                    return "Added"
                                                case GitFileStatus.DELETED:
                                                    return "Deleted"
                                                case GitFileStatus.MODIFIED:
                                                    return "Modified"
                                                case GitFileStatus.RENAMED:
                                                    return "Renamed"
                                                case GitFileStatus.UNTRACKED:
                                                    return "Untracked"
                                                default:
                                                    return "Untracked"
                                            }
                                        }

                                        color: Style.colors.titleText
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        background: Rectangle {
                                            radius: 3
                                            color: root.getChangeColor(fileData.deltaStatus)
                                        }
                                    }
                                }
                            }

                            // Column 4: Added Lines
                            ColumnLayout {
                                Layout.preferredWidth: root.filesColAddedLinesWidth
                                Layout.fillHeight: true
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true

                                    Rectangle {
                                        Layout.preferredWidth: 1
                                        Layout.fillHeight: true
                                        width: 1
                                        color: Style.colors.hoverTitle
                                    }

                                    Label {
                                        text: fileData.additionsCount  || "0"
                                        color: Style.colors.foreground
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 10
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.NoWrap
                                    }
                                }
                            }

                            // Column 4: Removed Lines
                            ColumnLayout {
                                Layout.preferredWidth: root.filesColRemovedLinesWidth
                                Layout.fillHeight: true
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true

                                    Rectangle {
                                        Layout.preferredWidth: 1
                                        Layout.fillHeight: true
                                        width: 1
                                        color: Style.colors.hoverTitle
                                    }

                                    Label {
                                        text: fileData.deletionsCount  || "0"
                                        color: Style.colors.foreground
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 10
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.NoWrap
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: commitMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.selectedFile = fileData
                                root.fileSelected(fileData.path)
                            }
                            onEntered: {
                                isHovered = true
                            }
                            onExited: {
                                isHovered = false
                            }
                        }
                    }
                }
            }
        }
    }

    onCommitHashChanged:{
        if(!statusController)
            return

        let res = statusController.getCommitFileChanges(root.commitHash)

        if (res.success)
            root.files = res.data

    }

    /* Functions
     * ****************************************************************************************/
    function getFileExtension(path) {
       // Ensure the path is a valid string
       if (typeof path !== "string" || path.length === 0) {
           console.log("Invalid file path");
           return "";
       }

       var extIndex = path.lastIndexOf(".");
       if (extIndex !== -1) {
           return path.substring(extIndex + 1); // Extract everything after the dot
       }
       return ""; // Return empty string if no extension found
   }

    function getChangeColor(type) : string {
        switch(type) {
        case GitFileStatus.ADDED:
            return Style.colors.addedFile
        case GitFileStatus.DELETED:
            return Style.colors.deletededFile
        case GitFileStatus.MODIFIED:
            return Style.colors.modifiediedFile
        case GitFileStatus.RENAMED:
            return Style.colors.renamedFile
        case GitFileStatus.UNTRACKED:
            return Style.colors.untrackedFile
        default:
            return Style.colors.untrackedFile
        }
    }
}
