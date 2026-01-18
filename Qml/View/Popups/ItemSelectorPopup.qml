import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ItemSelectorPopup
 * Reusable popup for selecting multiple items (checkbox-like).
 * Expected model elements: { text: string, checked: bool }
 * ************************************************************************************************/
Popup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property alias model: itemsRepeater.model
    property var selectedItems: []
    property bool anySelected: false
    property bool allSelected: false

    /* Signals
     * ****************************************************************************************/
    signal selectionChanged(var selectedItems)

    /* Object Properties
     * ****************************************************************************************/
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    implicitWidth: 210
    padding: 10

    background: Rectangle {
        color: Style.colors.secondaryBackground
        radius: 4
        border.color: Style.colors.primaryBorder
        border.width: 1
    }

    // Use plain Column so implicit sizing works predictably
    contentItem: Column {
        width: root.availableWidth
        spacing: 6

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                id: itemsRepeater
                model: ListModel {}

                delegate: Item {
                    id: optionRow
                    width: parent.width
                    height: 28

                    readonly property string optionText: model.text
                    readonly property bool isChecked: model.checked

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: mouseArea.containsMouse ? Style.colors.surfaceLight : "transparent"
                    }

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 4
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter

                        color: optionRow.isChecked ? Style.colors.accent : Style.colors.primaryBackground
                        border.width: 1
                        border.color: optionRow.isChecked ? Style.colors.accent : Style.colors.primaryBorder

                        Text {
                            anchors.centerIn: parent
                            visible: optionRow.isChecked
                            text: "\uf00c" // fa-check
                            font.family: Style.fontTypes.font6ProSolid
                            font.pixelSize: 9
                            color: "white"
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 32
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter

                        text: optionRow.optionText
                        font.family: Style.fontTypes.roboto
                        font.weight: 400
                        font.pixelSize: 11
                        color: Style.colors.foreground
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            itemsRepeater.model.setProperty(index, "checked", !optionRow.isChecked)
                            root.updateSelection()
                        }
                    }
                }
            }
        }

        // Divider between fields and actions
        Rectangle {
            width: parent.width
            height: 1
            color: Style.colors.primaryBorder
        }

        // Bottom actions: Select all / Clear all
        Row {
            width: parent.width
            spacing: 8

            Item {
                id: selectAllBtn
                height: 26
                width: (parent.width - parent.spacing) / 2

                readonly property bool isEnabled: !root.allSelected

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: selectAllMouse.containsMouse ? Style.colors.surfaceLight : Style.colors.cardBackground
                    border.width: 1
                    border.color: Style.colors.primaryBorder
                    opacity: selectAllBtn.isEnabled ? 1.0 : 0.55
                }

                Text {
                    anchors.centerIn: parent
                    text: "Select all"
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 11
                    color: Style.colors.foreground
                    opacity: selectAllBtn.isEnabled ? 1.0 : 0.55
                }

                MouseArea {
                    id: selectAllMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: selectAllBtn.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: selectAllBtn.isEnabled
                    onClicked: root.setAllChecked(true)
                }
            }

            Item {
                id: clearAllBtn
                height: 26
                width: (parent.width - parent.spacing) / 2

                readonly property bool isEnabled: root.anySelected

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: clearAllMouse.containsMouse ? Style.colors.surfaceLight : Style.colors.cardBackground
                    border.width: 1
                    border.color: Style.colors.primaryBorder
                    opacity: clearAllBtn.isEnabled ? 1.0 : 0.55
                }

                Text {
                    anchors.centerIn: parent
                    text: "Clear all"
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 11
                    color: Style.colors.foreground
                    opacity: clearAllBtn.isEnabled ? 1.0 : 0.55
                }

                MouseArea {
                    id: clearAllMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: clearAllBtn.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: clearAllBtn.isEnabled
                    onClicked: root.setAllChecked(false)
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function setAllChecked(value) {
        if (!itemsRepeater.model || itemsRepeater.model.count === undefined)
            return
        for (var i = 0; i < itemsRepeater.model.count; ++i)
            itemsRepeater.model.setProperty(i, "checked", value)
        updateSelection()
    }

    function checkedItems() {
        if (!itemsRepeater.model || itemsRepeater.model.count === undefined)
            return []

        var out = []
        for (var i = 0; i < itemsRepeater.model.count; ++i) {
            var it = itemsRepeater.model.get(i)
            if (it.checked)
                out.push({ index: i, text: it.text })
        }

        return out
    }

    function updateSelection() {
        selectedItems = checkedItems()

        var count = selectedItems.length
        anySelected = count > 0

        if (!itemsRepeater.model || itemsRepeater.model.count === undefined)
            allSelected = false
        else
            allSelected = (count === itemsRepeater.model.count)

        root.selectionChanged(selectedItems)
    }
}
