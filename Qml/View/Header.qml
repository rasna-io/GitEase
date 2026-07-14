import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * Header
 * Root is an Item with a ColumnLayout and a MouseArea (dragArea) that acts as the window
 * handle when the header is dragged or double-clicked.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property WindowController   windowController
    property Component          content
    property var                pluginManager: null

    /* Children
     * ****************************************************************************************/
    MouseArea {
        id: dragArea
        anchors.fill: parent

        acceptedButtons: Qt.LeftButton
        onPressed: windowController.startSystemMove()
        onDoubleClicked: windowController.toggleMaxRestore()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.dp(44)
            spacing: 0

            Item {
                Layout.preferredWidth: Style.dp(167)
                Layout.margins: Style.dp(14)

                Image {
                    anchors {
                        verticalCenter: parent.verticalCenter
                    }

                    width: Style.dp(80)
                    height: Style.dp(19)
                    fillMode: Image.PreserveAspectFit
                    source: Style.icons.appLogo
                }
            }

            Rectangle {
                Layout.preferredWidth: Style.dp(1)
                Layout.fillHeight: true
                color: Style.colors.primaryBorder
            }

            Loader {
                Layout.fillWidth: true
                Layout.leftMargin: Style.dp(14)
                Layout.rightMargin: Style.dp(14)
                clip: true
                sourceComponent: root.content
            }

            // Plugin toolbar actions
            Repeater {
                model: root.pluginManager ? root.pluginManager.registeredToolbarActions : []
                delegate: ToolButton {
                    text: modelData.icon
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: 14
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    ToolTip.text: modelData.tooltip
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                    onClicked: root.pluginManager.executeToolbarAction(modelData.pluginId, modelData.id, {})
             }
            Rectangle {
                Layout.preferredWidth: Style.dp(1)
                Layout.fillHeight: true
                color: Style.colors.primaryBorder
            }

            WindowsHeader {
                Layout.preferredWidth: Style.dp(120)

                windowController: root.windowController
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.dp(1)

            color: Style.colors.primaryBorder
        }
    }
}
