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
Item {
    id : root

    property RepositoryController repositoryController: null
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

    /* Signals
     * ****************************************************************************************/
    signal fileSelected(string filePath)

    /* Children
     * ****************************************************************************************/
    Rectangle{
        anchors.fill: parent
        color : "#FFFFFF"

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: header
                Layout.fillWidth: true
                Layout.preferredHeight: 30

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.preferredWidth: root.filesColPathWidth
                        Layout.fillHeight: true
                        color: pathHeaderMouseArea.containsMouse ? "#E8E8E8" : "transparent"
                        
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
                            color: "#000000"
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: pathDividerMouseArea.containsMouse ? "#4A6FA5" : "#f2f2f2"

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
                        color: extensionHeaderMouseArea.containsMouse ? "#E8E8E8" : "transparent"
                        
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
                            color: "#000000"
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: extensionDividerMouseArea.containsMouse ? "#4A6FA5" : "#f2f2f2"

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
                        color: statusHeaderMouseArea.containsMouse ? "#E8E8E8" : "transparent"
                        
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
                            color: "#000000"
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: statusDividerMouseArea.containsMouse ? "#4A6FA5" : "#f2f2f2"

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
                        color: linesAddedHeaderMouseArea.containsMouse ? "#E8E8E8" : "transparent"
                        
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
                            color: "#000000"
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: linesAddedDividerMouseArea.containsMouse ? "#4A6FA5" : "#f2f2f2"

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
                        color: linesRemovedHeaderMouseArea.containsMouse ? "#E8E8E8" : "transparent"
                        
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
                            color: "#000000"
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
                        property bool isSelected: root.selectedFile && root.selectedFile.filePath === fileData.filePath

                        color: {
                            if (isSelected) {
                                return "#6088B2DF";
                            } else if (isHovered) {
                                return "#EFEFEF";
                            } else {
                                return "#FFFFFF";
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
                                        color: "#f2f2f2"
                                    }

                                    Label {
                                        text: fileData.filePath || ""
                                        color: "#000000"
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
                                        color: "#f2f2f2"
                                    }

                                    Label {
                                        text: root.getFileExtension(fileData.filePath) || ""
                                        color: "#000000"
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
                                        color: "#f2f2f2"
                                    }

                                    Label {
                                        text: {
                                            switch(fileData.status) {
                                                case "A": return "Added"
                                                case "D": return "Deleted"
                                                case "M": return "Modified"
                                                case "R": return "Renamed"
                                                case "U": return "Untracked"
                                                default: return "Untracked"
                                            }
                                        }

                                        color: "#000000"
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        background: Rectangle {
                                            radius: 3
                                            color: root.getChangeColor(fileData.status)
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
                                        color: "#f2f2f2"
                                    }

                                    Label {
                                        text: fileData.additions  || "0"
                                        color: "#000000"
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
                                        color: "#f2f2f2"
                                    }

                                    Label {
                                        text: fileData.deletions  || "0"
                                        color: "#000000"
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
                                root.fileSelected(fileData.filePath)
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
        if(!repositoryController)
            return

        root.files = repositoryController.getCommitFileChanges(root.commitHash)
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

    function getChangeColor(type : string) {
        switch(type) {
            case "A": return "#B9FAB9"
            case "D": return "#FF9898"
            case "M": return "#FFF398"
            case "R": return "#aafff8"
            case "U": return "#990000ff"
            default: return "#990000ff"
        }
    }
}
