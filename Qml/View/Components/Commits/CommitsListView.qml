import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

import "qrc:/GitEase/Qml/Core/Scripts/GraphUtils.js" as GraphUtils

/*! ***********************************************************************************************
 * CommitsListView Component
 * Displays the commits list with Message, Author, and Date columns
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property var commits
    property string       selectedCommitHash:    ""
    property string       hoveredCommitHash:     ""

    property string       emptyStateDetailsText: ""

    // Column widths
    property int          messageWidth:          100
    property int          authorWidth:           20
    property int          dateWidth:             20

    // Minimum widths
    readonly property int minMessageWidth:       100
    readonly property int minAuthorWidth:        60
    readonly property int minDateWidth:          80

    // Display properties
    property int          commitItemHeight:      24
    property int          commitItemSpacing:     4

    /* Signals
     * ****************************************************************************************/
    signal scrollPositionChanged(real contentY, real contentHeight, real height)
    signal columnWidthResized(int newMessageWidth, int newAuthorWidth, int newDateWidth)
    signal commitSelected(string commitHash)
    signal commitHovered(string commitHash)

    /* Functions
     * ****************************************************************************************/
    function commitColor(commitObj) {
        if (!commitObj || !commitObj.colorKey)
            return GraphUtils.getCategoryColor()
        return GraphUtils.getCategoryColor(commitObj.colorKey)
    }

    function setContentY(y) {
        commitsListView.contentY = y
    }

    function positionViewAtIndex(index, mode) {
        commitsListView.positionViewAtIndex(index, mode)
    }

    /* Children
     * ****************************************************************************************/
    // Empty state (no commits to render)
    EmptyStateView {
        title: "no commit to show"
        details: emptyStateDetailsText
        visible: !root.commits || root.commits.length === 0
    }

    // Layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: Style.colors.primaryBackground
            visible: root.commits && root.commits.length > 0

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Message Column Header
                Rectangle {
                    Layout.preferredWidth: root.messageWidth
                    Layout.fillHeight: true
                    color: messageHeaderMouseArea.containsMouse ? Style.colors.hoverTitle : "transparent"
                    
                    MouseArea {
                        id: messageHeaderMouseArea
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
                        text: "Message"
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
                        color: messageDividerMouseArea.pressed ? Style.colors.resizeHandlePressed : Style.colors.resizeHandle

                        MouseArea {
                            id: messageDividerMouseArea
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
                                startWidth = root.messageWidth
                            }

                            onPositionChanged: function(mouse) {
                                if (!pressed) return

                                var currentX = mouseX + mapToItem(header, 0, 0).x
                                var delta = currentX - startX
                                
                                var newWidth = Math.max(root.minMessageWidth, startWidth + delta)
                                var actualDelta = newWidth - root.messageWidth
                                
                                var newAuthorWidth = root.authorWidth - actualDelta
                                
                                if (newAuthorWidth < root.minAuthorWidth) {
                                    newAuthorWidth = root.minAuthorWidth
                                    newWidth = root.messageWidth + (root.authorWidth - root.minAuthorWidth)
                                }
                                
                                if (newWidth !== root.messageWidth) {
                                    root.columnWidthResized(newWidth, newAuthorWidth, root.dateWidth)
                                }
                            }
                        }
                    }
                }

                // Author Column Header
                Rectangle {
                    Layout.preferredWidth: root.authorWidth
                    Layout.fillHeight: true
                    color: authorHeaderMouseArea.containsMouse ? Style.colors.hoverTitle : "transparent"
                    
                    MouseArea {
                        id: authorHeaderMouseArea
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
                        text: "Author"
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
                        color: authorDividerMouseArea.pressed ? Style.colors.resizeHandlePressed : Style.colors.resizeHandle

                        MouseArea {
                            id: authorDividerMouseArea
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
                                startWidth = root.authorWidth
                            }

                            onPositionChanged: function(mouse) {
                                if (!pressed) return

                                var currentX = mouseX + mapToItem(header, 0, 0).x
                                var delta = currentX - startX
                                
                                var newWidth = Math.max(root.minAuthorWidth, startWidth + delta)
                                var actualDelta = newWidth - root.authorWidth
                                
                                var newDateWidth = root.dateWidth - actualDelta
                                
                                if (newDateWidth < root.minDateWidth) {
                                    newDateWidth = root.minDateWidth
                                    newWidth = root.authorWidth + (root.dateWidth - root.minDateWidth)
                                }
                                
                                if (newWidth !== root.authorWidth) {
                                    root.columnWidthResized(root.messageWidth, newWidth, newDateWidth)
                                }
                            }
                        }
                    }
                }

                // Date Column Header
                Rectangle {
                    Layout.preferredWidth: root.dateWidth
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignRight
                    color: dateHeaderMouseArea.containsMouse ? Style.colors.hoverTitle : "transparent"
                    
                    MouseArea {
                        id: dateHeaderMouseArea
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
                        text: "Date"
                        color: Style.colors.foreground
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Commits ListView
        ListView {
            id: commitsListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.commits
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            property bool syncScroll: false

            onContentYChanged: {
                if (!syncScroll) {
                    root.scrollPositionChanged(contentY, contentHeight, height)
                }
            }

            ScrollBar.vertical: ScrollBar {
                id: verticalScrollBar
                policy: ScrollBar.AsNeeded
                interactive: true
                                
                contentItem: Rectangle {
                    implicitWidth: 10
                    implicitHeight: 10
                    radius: 5

                    color: Style.colors.surfaceMuted
                    opacity: verticalScrollBar.active ? 0.85 : 0.6
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                    
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }
                
                background: Rectangle {
                    implicitWidth: 12
                    implicitHeight: 12
                    color: Style.colors.secondaryBackground
                    opacity: 0.3
                    radius: 6
                }
            }

            delegate: Rectangle {
                width: ListView.view.width
                height: root.commitItemHeight + root.commitItemSpacing + root.commitItemSpacing

                property var commitData: modelData
                property bool isHovered: commitMouseArea.containsMouse
                                         || commitMouseArea.pressed
                                         || (root.hoveredCommitHash === commitData.hash)
                property bool isSelected: root.selectedCommitHash === commitData.hash

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
                    anchors.topMargin: root.commitItemSpacing
                    anchors.bottomMargin: root.commitItemSpacing

                    // Column 1: Commit Message
                    ColumnLayout {
                        Layout.fillWidth: false
                        Layout.preferredWidth: root.messageWidth
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

                            // Branch color indicator bar
                            Rectangle {
                                id: branchColorIndicator
                                Layout.preferredWidth: 3
                                Layout.preferredHeight: root.commitItemHeight * 0.8
                                Layout.alignment: Qt.AlignVCenter
                                radius: 6

                                color: {
                                    return root.commitColor(commitData)
                                }
                            }

                            Label {
                                text: commitData.summary || ""
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

                    // Column 2: Author
                    ColumnLayout {
                        Layout.preferredWidth: root.authorWidth
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
                                text: commitData.author || ""
                                color: Style.colors.foreground
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignLeft
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }
                        }
                    }

                    // Column 3: Date and Time (in one line)
                    ColumnLayout {
                        Layout.preferredWidth: root.dateWidth
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
                                text: GraphUtils.formatDate(commitData.authorDate) + " " + GraphUtils.formatTime(commitData.authorDate)
                                color: Style.colors.foreground
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 10
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignLeft
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
                        root.commitSelected(commitData.hash)
                    }

                    onEntered: {
                        root.commitHovered(commitData.hash)
                    }
                }
            }
        }
    }
}
