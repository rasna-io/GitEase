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
    property var _wrappedModel: []

    /* Object Properties
     * ****************************************************************************************/
    modal: false
    focus: true
    dim: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    implicitWidth: 180
    padding: 6

    onMenuModelChanged: {
        var out = []
        for (var i = 0; i < menuModel.length; i++) {
            var item = menuModel[i]
            var origAction = item.action
            out.push({
                text: item.text,
                icon: item.icon,
                enabled: item.enabled !== false,
                visible: item.visible !== false,
                subItems: item.subItems || [],
                action: (function(fn) {
                    return function() {
                        if (typeof fn === "function")
                            fn()
                        if (root && typeof root.close === "function")
                            root.close()
                    }
                })(origAction)
            })
        }
        _wrappedModel = out
    }

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
            model: root._wrappedModel

            delegate: Item {
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

                    Text {
                        text: modelData.icon || ""
                        font.family: Style.fontTypes.font6ProSolid
                        font.pixelSize: 12
                        color: itemMouse.containsMouse ? Style.colors.accent : Style.colors.foreground
                        visible: text !== ""
                        Layout.preferredWidth: 16
                    }

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
                    cursorShape: isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (isEnabled && typeof modelData.action === "function")
                            modelData.action()
                    }
                }
            }
        }
    }
}
