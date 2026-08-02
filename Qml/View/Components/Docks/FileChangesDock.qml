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
DetachablePanel {
    id : root

    property RepositoryController repositoryController: null

    property StatusController statusController: null

    property string commitHash: ""

    /* Property Declarations
     * ****************************************************************************************/
    property var files: []
    property var selectedFile: null

    // Property to receive list of fileData objects
    property int filesColStatusWidth: root.activeItem.width * 0.13
    property int filesColPathWidth: root.activeItem.width * 0.46
    property int filesColExtensionWidth: root.activeItem.width * 0.10
    property int filesColAddedLinesWidth: root.activeItem.width * 0.16
    property int filesColRemovedLinesWidth: root.activeItem.width * 0.15

    /* Object Properties
     * ****************************************************************************************/
    title: qsTr("File Changes")

    /* Signals
     * ****************************************************************************************/
    signal fileSelected(string filePath)

    /* Children
     * ****************************************************************************************/
    Connections {
        target: repositoryController

        function onCurrentRepoChanged() {
            root.files = []
            root.selectedFile = null
            root.commitHash = ""
        }
    }

    EmptyStateView {
        title: "No files to show"
        details: "Select a commit to view the file changes"
        visible: !root.files || root.files.length === 0
    }

    Rectangle{
        id: filesContainer
        anchors.fill: parent
        color: Style.colors.primaryBackground
        visible: root.files && root.files.length > 0
        clip: true

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "file_changes_tutorial"
            guideName: "File Changes"
            guideIcon: Style.icons.list
            guidePage: "graph"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return header },
                        icon: Style.icons.list,
                        title: "File Changes",
                        description: "Every file touched by the selected commit is listed here, along with its extension, status, and how many lines were added or removed."
                    },
                    {
                        targetProvider: function() { return statusHeaderCol },
                        icon: Style.icons.info,
                        title: "Status",
                        description: "A color-coded badge shows whether the file was Added, Modified, Deleted, Renamed, or is Untracked."
                    },
                    {
                        targetProvider: function() { return filesListView },
                        icon: Style.icons.arrowRight,
                        title: "Preview a File",
                        description: "Click any row to preview that file's diff in the panel next to this list."
                    }
                ]
            }
        }

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
                        id: statusHeaderCol
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
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: "Status"
                            color: Style.colors.foreground
                            font.pixelSize: Style.appFont.defaultPt
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }

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
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            text: "Path"
                            color: Style.colors.foreground
                            font.pixelSize: Style.appFont.defaultPt
                            font.bold: true
                            elide: Text.ElideRight
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
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: "Extension"
                            color: Style.colors.foreground
                            font.pixelSize: Style.appFont.defaultPt
                            font.bold: true
                            elide: Text.ElideRight
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
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: "Lines Added"
                            color: Style.colors.foreground
                            font.pixelSize: Style.appFont.defaultPt
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: root.filesColRemovedLinesWidth
                        Layout.fillHeight: true
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
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: "Lines Removed"
                            color: Style.colors.foreground
                            font.pixelSize: Style.appFont.defaultPt
                            font.bold: true
                            elide: Text.ElideRight
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

                            // Column 1: File Status
                            RowLayout {
                                Layout.preferredWidth: root.filesColStatusWidth
                                Layout.fillWidth: false
                                Layout.fillHeight: true
                                spacing: 0

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
                                    font.pixelSize: Style.appFont.mediumPt
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 8
                                    Layout.rightMargin: 8
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    background: Rectangle {
                                        radius: 3
                                        color: root.getChangeColor(fileData.deltaStatus)
                                    }
                                }
                            }

                            // Column 2: File Path
                            RowLayout {
                                Layout.preferredWidth: root.filesColPathWidth
                                Layout.fillWidth: false
                                Layout.fillHeight: true
                                spacing: 0

                                Label {
                                    text: fileData.path || ""
                                    color: Style.colors.foreground
                                    font.pixelSize: Style.appFont.smallPt
                                    font.family: Style.fontTypes.roboto
                                    font.weight: 400
                                    font.letterSpacing: 0.2
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 8
                                    Layout.rightMargin: 8
                                    horizontalAlignment: Text.AlignLeft
                                    elide: Text.ElideLeft
                                }
                            }

                            // Column 3: File Extension
                            RowLayout {
                                Layout.preferredWidth: root.filesColExtensionWidth
                                Layout.fillWidth: false
                                Layout.fillHeight: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0

                                Label {
                                    text: root.getFileExtension(fileData.path) || ""
                                    color: Style.colors.foreground
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: Style.appFont.smallPt
                                    font.family: Style.fontTypes.roboto
                                    font.weight: 400
                                    font.letterSpacing: 0.2
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.leftMargin: 8
                                    Layout.rightMargin: 8
                                    elide: Text.ElideRight
                                }
                            }

                            // Column 4: Added Lines
                            RowLayout {
                                Layout.preferredWidth: root.filesColAddedLinesWidth
                                Layout.fillWidth: false
                                Layout.fillHeight: true
                                spacing: 0

                                Label {
                                    text: fileData.additionsCount  || "0"
                                    color: Style.colors.compatible
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: Style.appFont.smallPt
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.leftMargin: 8
                                    Layout.rightMargin: 8
                                    wrapMode: Text.NoWrap
                                }
                            }

                            // Column 5: Removed Lines
                            RowLayout {
                                Layout.preferredWidth: root.filesColRemovedLinesWidth
                                Layout.fillWidth: false
                                Layout.fillHeight: true
                                spacing: 0

                                Label {
                                    text: fileData.deletionsCount  || "0"
                                    color: Style.colors.incompatible
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: Style.appFont.smallPt
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.leftMargin: 8
                                    Layout.rightMargin: 8
                                    wrapMode: Text.NoWrap
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

        root.fileSelected(root.files.length > 0 ? root.files[0].path : "")
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
