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

    // Optional custom row delegate. If not set, a default delegate is used.
    property Component rowDelegate: null
    // Optional header actions content (rendered on the right side of the header)
    property Component headerActions: null

    readonly property bool needsVScroll: listView.contentHeight > (listView.height + 1)
    readonly property bool wantsFillHeight: expanded && !(listView.count === 0)
    readonly property int count: listView.count

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
            color: headerMouseArea.containsMouse ? Qt.darker(Style.colors.secondaryBackground, 1.03) : Style.colors.secondaryBackground

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

                Loader {
                    id: headerActionsLoader
                    Layout.alignment: Qt.AlignVCenter
                    active: root.headerActions !== null
                    sourceComponent: root.headerActions
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
            color: Style.colors.secondaryBackground
            clip: true

            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Component {
                    id: defaultRowDelegate

                    FileListRow {
                        width: ListView.view ? ListView.view.width : implicitWidth
                        rowModelData: modelData
                        rowIndex: index
                        text: modelData && modelData.path ? modelData.path : ""
                        mode: modelData && modelData.mode ? modelData.mode : ""
                        selected: root.selectedFilePath !== "" && root.selectedFilePath === (modelData && modelData.path ? modelData.path : "")
                        showSeparator: index < (listView.count - 1)

                        onClicked: {
                            root.selectFile(modelData.path)
                        }
                    }
                }

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
                        height: (rowLoader.item && rowLoader.item.implicitHeight) ? rowLoader.item.implicitHeight : 24

                        Loader {
                            id: rowLoader
                            anchors.fill: parent
                            sourceComponent: root.rowDelegate ? root.rowDelegate : defaultRowDelegate

                            onLoaded: {
                                if (!item)
                                    return

                                item.rowModelData = modelData
                                item.rowIndex = index

                                if (item.hasOwnProperty("showSeparator"))
                                    item.showSeparator = index < (listView.count - 1)
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

    /* Functions
     * ****************************************************************************************/
    function selectFile(filePath) {
        if (!filePath || filePath === "")
            return

        root.selectedFilePath = filePath
        root.fileSelected(filePath)
    }
}
