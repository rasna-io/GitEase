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
    property string emptySubText: ""
    property var model: []
    property string selectedFilePath: ""
    property bool expanded: true
    property int headerHeight: 30
    property int emptyExpandedHeight: 110

    property color badgeTextColor: Style.colors.countBadgeText
    property color badgeBgColor:   Style.colors.countBadgeBg

    property bool fillWhenEmpty: false

    // Optional custom row delegate. If not set, a default delegate is used.
    property Component rowDelegate: null
    // Optional header actions content (rendered on the right side of the header)
    property Component headerActions: null

    readonly property bool needsVScroll: listView.contentHeight > (listView.height + 1)
    readonly property bool wantsFillHeight: expanded && (listView.count > 0 || root.fillWhenEmpty)
    readonly property int count: listView.count

    /* Object Properties
     * ****************************************************************************************/
    color: "transparent"
    implicitHeight: headerHeight + ((expanded && (listView.count === 0) && !root.fillWhenEmpty) ? emptyExpandedHeight : 0)

    /* Signals
     * ****************************************************************************************/
    signal fileSelected(string filePath, int fileStatus)
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
            color: Style.colors.sectionHeaderBg

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
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 7

                Text {
                    text: root.title.toUpperCase()
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.secondaryPt
                    font.bold: true
                    font.letterSpacing: 0.6
                    color: Style.colors.sectionLabel
                }

                // Count badge
                Rectangle {
                    implicitHeight: 15
                    implicitWidth: Math.max(15, countText.implicitWidth + 10)
                    radius: 3
                    color: root.badgeBgColor

                Text {
                        id: countText
                        anchors.centerIn: parent
                        text: listView.count
                        font.family: Style.fontTypes.jetBrainsMono
                        font.pixelSize: Style.appFont.secondaryPt
                        color: root.badgeTextColor
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Loader {
                    id: headerActionsLoader
                    Layout.alignment: Qt.AlignVCenter
                    active: root.headerActions !== null
                    sourceComponent: root.headerActions
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Style.colors.primaryBorder
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
            color: "transparent"
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
                        status: modelData && modelData.status ? modelData.status : GitFileStatus.Unknown
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
                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        visible: listView.count === 0
                        spacing: 8

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 36
                            height: 36
                            radius: 18
                            color: Style.colors.emptyCircleBg
                            border.width: 1
                            border.color: Style.colors.emptyCircleBorder

                            Text {
                                anchors.centerIn: parent
                                text: Style.icons.plus
                                font.family: Style.fontTypes.font6ProSolid
                                font.pixelSize: Style.appFont.mediumPt
                                color: Style.colors.emptyStateSubText
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                        text: root.emptyText
                            horizontalAlignment: Text.AlignHCenter
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.smallPt
                            color: Style.colors.emptyStateText
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: root.emptySubText !== ""
                            text: root.emptySubText
                            horizontalAlignment: Text.AlignHCenter
                        font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.secondaryPt
                            color: Style.colors.emptyStateSubText
                            elide: Text.ElideRight
                        }
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
    function selectFile(filePath, fileStatus) {
        if (!filePath || filePath === "")
            return

        root.selectedFilePath = filePath
        root.fileSelected(filePath, fileStatus)
    }
}
