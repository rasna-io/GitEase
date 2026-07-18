import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PagesRail
 * Sidebar component show pages
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property alias model: rpt.model

    property var   currentId

    property GuideController   guideController: null

    /* Signals
     * ****************************************************************************************/

    signal clicked(var modelData);

    /* Guide
     * ****************************************************************************************/
    GuideHoverTrigger {
        guideController: root.guideController
        guideId: "pages_rail_tutorial"
        guideName: "Pages Rail"
        guideIcon: Style.icons.list
        stepsFactory: function() {
            return [
                {
                    targetProvider: function() { return root },
                    icon: Style.icons.list,
                    title: "Pages",
                    description: "Switch between the app's pages — like Committing and Graph View — from this list. Hover the rail to see full names, or click a page to jump to it."
                }
            ]
        }
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: 12

        // Pages list
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: pagesColumn.height
            clip: true

            Column {
                id: pagesColumn
                width: parent.width

                Repeater {
                    id: rpt

                    Column {
                        width: parent.width
                        spacing: 0

                        // Separator before first plugin page
                        Rectangle {
                            width: parent.width - 16
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 1
                            color: Style.colors.primaryBorder
                            visible: (modelData?.isPlugin === true) &&
                                     (index === 0 || !(rpt.model[index - 1]?.isPlugin === true))
                        }

                        // Spacer above separator
                        Item {
                            width: parent.width
                            height: 6
                            visible: (modelData?.isPlugin === true) &&
                                     (index === 0 || !(rpt.model[index - 1]?.isPlugin === true))
                        }

                        Rectangle {
                            id: item
                            width: parent.width
                            height: Style.dp(30)
                            radius: Style.dp(6)

                            property bool isSelected: (modelData)
                                                      ? (modelData.pageId === root.currentId)
                                                      : false

                            color: item.isSelected ? "#1F3B82F6" : "transparent"

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: Style.dp(12)
                                    rightMargin: Style.dp(8)
                                }
                                spacing: 8

                                // Icon
                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                                    width: Style.dp(14)
                                    height: Style.dp(14)
                                    color: "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: (modelData && modelData.icon && modelData.icon.length)
                                              ? modelData.icon
                                              : Style.icons.download
                                        font.pixelSize: 13
                                        font.family: Style.fontTypes.font6Pro
                                        font.weight: 500
                                        color: item.isSelected ? "#60A5FA" : "#363650"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                // Title
                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: (modelData && modelData.title) ? modelData.title : ""
                                    font.pixelSize: 13
                                    font.family: Style.fontTypes.roboto
                                    color: item.isSelected ? "#60A5FA" : "#363650"
                                    elide: Text.ElideRight
                                }

                                // Badge
                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter
                                    visible: (modelData?.badgeCount ?? -1) >= 0
                                    implicitHeight: 16
                                    implicitWidth: Math.max(implicitHeight, badgeLabel.implicitWidth + 8)
                                    radius: implicitHeight / 2
                                    color: modelData?.badgeColor ?? "#3B82F6"

                                    Label {
                                        id: badgeLabel
                                        anchors.centerIn: parent
                                        text: modelData?.badgeCount ?? ""
                                        color: "white"
                                        font.family: Style.fontTypes.roboto
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: root.clicked(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
