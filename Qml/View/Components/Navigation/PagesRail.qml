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
    required property PageController pageController
    property bool expanded: false

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: 12

        spacing: 8

        // Pages list
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: pagesColumn.height
            clip: true

            Column {
                id: pagesColumn
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.pageController?.appModel?.pages

                    Item {
                        width: parent.width
                        height: 36
                        
                        property bool isSelected: (modelData && root.pageController && root.pageController?.appModel?.currentPage)
                                                  ? (modelData.id === root.pageController?.appModel?.currentPage?.id)
                                                  : false
                        property bool isHovered: false

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: 2
                            anchors.rightMargin: 2
                            radius: 4

                            color: {
                                if (parent.isSelected) {
                                    return "#FFFFFF"
                                }
                                return parent.isHovered ? Qt.darker(root.color, 1.05) : "transparent"
                            }

                            border.width: parent.isSelected ? 1 : 0
                            border.color: parent.isSelected ? "#F2F2F2" : "transparent"

                            RowLayout {
                                anchors.centerIn: parent
                                width: parent.width - 12
                                spacing: 8

                                // Icon
                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                                    width: 20
                                    height: 20
                                    radius: 3
                                    color: "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: (modelData && modelData.icon && modelData.icon.length)
                                              ? modelData.icon
                                              : Style.icons.download
                                        font.pixelSize: 16
                                        font.family: Style.fontTypes.font6Pro
                                        font.weight: 500
                                        color: parent.parent.parent.parent.isSelected ? "#484848" : "#9D9D9D"
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
                                    color: parent.parent.parent.isSelected ? "#484848" : "#9D9D9D"
                                    elide: Text.ElideRight
                                    visible: root.expanded
                                    opacity: root.expanded ? 1 : 0
                                    
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 100
                                            easing.type: Easing.InOutQuad
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: {
                                if (pageController && modelData) {
                                    pageController.switchToPage(modelData.id)
                                }
                            }
                            onEntered: parent.isHovered = true
                            onExited: parent.isHovered = false
                        }
                    }
                }
            }
        }
    }
}
