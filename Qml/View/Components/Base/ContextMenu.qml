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
    //! Format: [{ text: "Checkout", icon: "\uf00c", action: function(){}, enabled: true,
    //!            color: "#DC3545",      // optional: tints both label and icon
    //!            iconColor: "#DC3545" }] // optional: tints the icon only
    property var menuModel: []

    /* Object Properties
     * ****************************************************************************************/
    modal: false
    focus: true
    dim: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    implicitWidth: 200
    padding: 6

    background: Rectangle {
        color: Style.colors.contextMenuBackground
        radius: 4
        border.color: Style.colors.contextMenuBorder
        border.width: 1
    }

    onClosed: {
        subMenuPopup.subModel = []
    }

    Popup {
        id: subMenuPopup
        property var subModel: []
        visible: subMenuPopup.subModel.length > 0
        width: 240
        padding: 6
        x: root.width - 4
        y: -padding
        modal: false
        focus: false
        dim: false

        background: Rectangle {
            color: Style.colors.contextMenuBackground
            radius: 4
            border.color: Style.colors.contextMenuBorder
            border.width: 1
        }

        contentItem: Column {
            spacing: 1
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
            height: modelData.separator ? 9 : Style.dp(25)
            visible: modelData.visible !== false
            readonly property bool isSep:     !!modelData.separator
            readonly property bool isEnabled: !isSep && modelData.enabled !== false
            readonly property bool hasSub:    !isSep && !!modelData.subItems && modelData.subItems.length > 0

            //! Per-item tinting: "color" applies to label and icon, "iconColor" overrides the icon.
            readonly property bool  hasColor:  !isSep && modelData.color !== undefined && modelData.color !== ""
            readonly property color textColor: hasColor ? modelData.color : Style.colors.foreground
            readonly property color iconColor: (!isSep && modelData.iconColor !== undefined && modelData.iconColor !== "")
                                               ? modelData.iconColor
                                               : (hasColor ? modelData.color
                                                           : (itemMouse.containsMouse ? Style.colors.accent
                                                                                      : Style.colors.foreground))

            // Separator line
            Rectangle {
                visible: isSep
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                height: 1
                color: Style.colors.contextMenuSeparator
            }

            // Normal item background
            Rectangle {
                visible: !isSep
                anchors.fill: parent
                radius: 4
                color: (itemMouse.containsMouse && isEnabled) ? Style.colors.contextMenuHover : "transparent"
            }

            RowLayout {
                visible: !isSep
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10
                opacity: isEnabled ? 1.0 : 0.4

                // Icon
                Text {
                    text: modelData.icon || ""
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.appFont.mediumPt
                    color: menuOption.iconColor
                    visible: text !== ""
                    Layout.preferredWidth: 16
                }

                // Label
                ScrollingText {
                    text: modelData.text || ""
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                    color: menuOption.textColor
                    Layout.fillWidth: true
                }

                CheckBox {
                    id: checkBox
                    text: modelData.checkBoxText
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                    Layout.preferredHeight: Style.dp(25)
                    checked: false
                    visible: modelData.hasCheckBox === true && modelData.enabled
                }

                // Shortcut hint
                Text {
                    text: modelData.shortcut || ""
                    visible: !hasSub && modelData.shortcut !== undefined && modelData.shortcut !== ""
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt
                    color: Style.colors.mutedText
                }

                Text {
                    text: "❯"
                    visible: hasSub
                    font.pixelSize: Style.appFont.smallPt
                    color: Style.colors.foreground
                }
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: isEnabled
                z: -1
                onEntered: {
                    if (hasSub) {
                        subMenuPopup.subModel = modelData.subItems
                        subMenuPopup.y = menuOption.mapToItem(root.contentItem, 0, 0).y - 6
                    } else if (parent.parent === mainMenuColumn) {
                        subMenuPopup.subModel = []
                    }
                }
                onClicked: {
                    if (isEnabled && !hasSub) {
                        modelData.action(checkBox.checked);
                        subMenuPopup.close();
                        root.close();
                    }
                }
            }
        }
    }

    contentItem: Column {
        id: mainMenuColumn
        spacing: 1
        width: parent.width
        Repeater {
            model: root.menuModel
            delegate: menuDelegateComponent
        }
    }
}