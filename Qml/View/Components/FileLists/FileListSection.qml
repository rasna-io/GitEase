import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * FileListSection
 * Collapsible section containing a file list:
 * - Header: title, count badge
 * - Body: ListView, empty-state text, scrollbar
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string title: ""
    property string emptyText: ""
    property var model: []
    property string selectedFilePath: ""
    property bool expanded: true
    property int headerHeight: 32
    property int emptyExpandedHeight: 32
    readonly property bool needsVScroll: listView.contentHeight > (listView.height + 1)
    readonly property bool wantsFillHeight: expanded && !(listView.count === 0)

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: headerHeight + ((expanded && (listView.count === 0)) ? emptyExpandedHeight : 0)

    /* Signals
     * ****************************************************************************************/
    signal fileSelected(string filePath)
    signal toggled(bool expanded)

    /* Children
     * ****************************************************************************************/

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 120
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            color: headerMouseArea.containsMouse ? Qt.darker("#F9F9F9", 1.03) : "#F9F9F9"

            MouseArea {
                id: headerMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.expanded = !root.expanded
                    root.toggled(root.expanded)
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: root.expanded ? Style.icons.caretDown : Style.icons.caretRight
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 17
                    color: Style.colors.mutedText
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 11
                    font.bold: true
                    color: Style.colors.foreground
                    elide: Text.ElideRight
                }

                // Count badge
                Rectangle {
                    implicitHeight: 18
                    implicitWidth: Math.max(18, countText.implicitWidth + 10)
                    radius: 9
                    color: Style.colors.surfaceMuted

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: listView.count
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 11
                        color: Style.colors.secondaryText
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Style.colors.primaryBorder
                opacity: 0.7
            }
        }

        // List area
        Rectangle {
            id: listArea
            Layout.fillWidth: true
            Layout.fillHeight: root.wantsFillHeight
            Layout.preferredHeight: !root.expanded ? 0 : ((listView.count === 0) ? root.emptyExpandedHeight : -1)
            visible: root.expanded
            opacity: root.expanded ? 1 : 0
            color: "#F9F9F9"
            clip: true

            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true
                    spacing: 0
                    boundsBehavior: Flickable.StopAtBounds

                    model: root.model

                    delegate: Item {
                        width: ListView.view.width
                        height: row.implicitHeight

                        FileListRow {
                            id: row
                            anchors.fill: parent

                            text: modelData && modelData.path ? modelData.path : ""
                            mode: modelData && modelData.mode ? modelData.mode : ""
                            selected: root.selectedFilePath !== "" && root.selectedFilePath === modelData.path

                            showSeparator: index < (listView.count - 1)

                            onClicked: {
                                if ((modelData && modelData.path ? modelData.path : "") !== "") {
                                    root.selectedFilePath = modelData.path
                                    root.fileSelected(modelData.path)
                                }
                            }
                        }
                    }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: listView.count === 0

                        text: root.emptyText
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 11
                        color: Style.colors.mutedText
                        opacity: 0.9
                    }

                    ScrollBar.vertical: vBar
                }

                Item {
                    id: scrollGutter
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.needsVScroll ? 5 : 0

                    Behavior on Layout.preferredWidth {
                        NumberAnimation {
                            duration: 120
                        }
                    }

                    ScrollBar {
                        id: vBar
                        anchors.fill: parent
                        policy: ScrollBar.AsNeeded
                        visible: root.needsVScroll
                    }
                }

            }
        }
    }
}
