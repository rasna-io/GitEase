import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * TabbedView
 * Reusable tabbed interface component with TabBar and StackLayout
 * Usage:
 *   TabbedView {
 *       tabs: [
 *           { title: "Tab1", icon: "\uf017" },
 *           { title: "Tab2", icon: "\uf660" }
 *       ]
 *       // Add Item components as children for each tab content
 *   }
 * ************************************************************************************************/
ColumnLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var tabs: []
    property int tabBarMaxWidth: 283
    property int currentIndex: 0
    property alias stackLayout: stackLayout
    default property alias content: stackLayout.children

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true

    /* Internal Components
     * ****************************************************************************************/
    ButtonGroup {
        id: tabButtonGroup
        exclusive: true
    }

    /* Children
     * ****************************************************************************************/
    // Custom TabBar
    Rectangle {
        width: tabBarMaxWidth
        Layout.preferredHeight: 45
        Layout.alignment: Qt.AlignHCenter
        color: Style.colors.surfaceLight
        radius: 8

        RowLayout {
            anchors.fill: parent
            spacing: 6
            anchors.leftMargin: 6
            anchors.rightMargin: 6

            Repeater {
                model: root.tabs

                Button {
                    id: tabButton
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 50
                    flat: true

                    property int tabIndex: index
                    property var tabData: modelData

                    contentItem: Item {
                        implicitWidth: tabRow.implicitWidth
                        implicitHeight: tabRow.implicitHeight

                        RowLayout {
                            id: tabRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: tabData.icon || ""
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: 16
                                color: tabButton.checked ? "white" : Style.colors.foreground
                                visible: tabData.icon !== undefined && tabData.icon !== ""
                            }

                            Text {
                                text: tabData.title || ""
                                font.pixelSize: Style.appFont.defaultPt * 0.8
                                font.bold: tabButton.checked
                                color: tabButton.checked ? "white" : Style.colors.foreground
                            }
                        }
                    }

                    background: Rectangle {
                        implicitWidth: 100
                        implicitHeight: 36
                        radius: 6
                        color: tabButton.checked ? Style.colors.accent : Style.colors.surfaceMuted
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    checkable: true
                    checked: index === root.currentIndex
                    ButtonGroup.group: tabButtonGroup

                    onClicked: {
                        root.currentIndex = tabIndex
                        stackLayout.currentIndex = tabIndex
                    }

                    Component.onCompleted: {
                        if (index === root.currentIndex) {
                            checked = true
                        }
                    }
                }
            }
        }
    }

    // StackLayout for tab content
    StackLayout {
        id: stackLayout
        Layout.fillWidth: true
        Layout.preferredHeight: 200
        currentIndex: root.currentIndex

        onCurrentIndexChanged: {
            root.currentIndex = currentIndex
        }
    }
}

