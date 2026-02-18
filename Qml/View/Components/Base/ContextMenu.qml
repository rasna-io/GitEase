import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ContextMenu
 * ************************************************************************************************/
Popup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var menuModel: [] // Format: [{ text: "Checkout", icon: "\uf00c", action: function(){}, enabled: true }]

    /* Object Properties
     * ****************************************************************************************/
    modal: false
    focus: true
    dim: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    implicitWidth: 200
    padding: 6

    background: Rectangle {
        color: Style.colors.secondaryBackground
        radius: 4
        border.color: Style.colors.primaryBorder
        border.width: 1
    }

    onClosed: {
        subMenuPopup.close()
    }

    Popup {
        id: subMenuPopup
        property var subModel: []
        width: 200
        padding: 6
        x: root.width - 4
        y: -padding
        modal: false
        focus: false
        dim: false

        background: Rectangle {
            color: Style.colors.secondaryBackground
            radius: 4
            border.color: Style.colors.primaryBorder
            border.width: 1
        }

        contentItem: Column {
            spacing: 2
            width: parent.width

            Repeater {
                model: subMenuPopup.subModel
                delegate: menuDelegateComponent
            }
        }
    }

    Component {
        id: menuDelegateComponent
        Item {
            id: menuOption
            width: parent.width
            height: 30
            visible: modelData.visible !== false
            readonly property bool isEnabled: modelData.enabled !== false
            readonly property bool hasSub: !!modelData.subItems && modelData.subItems.length > 0

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 4
                color: (itemMouse.containsMouse && isEnabled) ? Style.colors.surfaceLight : "transparent"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10
                opacity: isEnabled ? 1.0 : 0.4

                // Icon
                Text {
                    text: modelData.icon || ""
                    font.family: Style.fontTypes.font6ProSolid
                    font.pixelSize: 12
                    color: itemMouse.containsMouse ? Style.colors.accent : Style.colors.foreground
                    visible: text !== ""
                    Layout.preferredWidth: 16
                }

                // Label
                Text {
                    text: modelData.text || ""
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 12
                    color: Style.colors.foreground
                    Layout.fillWidth: true
                }

                Text {
                    text: "❯"
                    visible: hasSub
                    font.pixelSize: 10
                    color: Style.colors.foreground
                }
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: isEnabled
                onEntered: {
                    if (hasSub) {
                        subMenuPopup.subModel = modelData.subItems
                        subMenuPopup.y = menuOption.mapToItem(root.contentItem, 0, 0).y - 6
                        subMenuPopup.open()
                    }
                }
                onClicked: {
                    if (isEnabled && !hasSub) {
                        modelData.action();
                        subMenuPopup.close();
                        root.close();
                    }
                }
            }
        }
    }

    contentItem: Column {
        spacing: 2
        width: parent.width
        Repeater {
            model: root.menuModel
            delegate: menuDelegateComponent
        }
    }
}
