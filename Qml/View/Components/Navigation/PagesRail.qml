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
                    model: root.pageController?.pages

                    RowLayout {
                        spacing: 2
                        width: parent.width

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 30
                            height: 30
                            radius: 3

                            property bool isSelected: modelData.id === root.pageController?.currentPage?.id ?? false

                            Text {
                                anchors.centerIn: parent
                                text: Style.icons.download
                                font.pixelSize: 17
                                font.family: Style.fontTypes.font6Pro
                                font.weight: 500
                                color: Qt.darker(parent.color, 1.5)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            color: isSelected ? "#FFFFFF" : "#F9F9F9"
                            border.width: isSelected ? 1 : 0
                            border.color: isSelected ? "#f2f2f2" : "F9F9F9"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: {
                                    root.pageClicked(modelData)
                                    if (pageController && modelData) {
                                        pageController.switchToPage(modelData.id)
                                    }
                                }
                                onEntered: parent.color = Qt.darker(parent.color, 1.1)
                                onExited: parent.color = Qt.lighter(parent.color, 1.1)
                            }
                        }
                    }
                }
            }
        }
    }
}
