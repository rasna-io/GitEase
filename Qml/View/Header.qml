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
            Layout.preferredHeight: 50
            spacing: 0

            Item {
                Layout.preferredWidth: 120

                Image {
                    anchors.centerIn: parent
                    width: 99
                    height: 28
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:/GitEase/Resources/Images/Logo.svg"
                }
            }

            Loader {
                Layout.fillWidth: true
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
                    onClicked: root.pluginManager.executeToolbarAction(
                                   modelData.pluginId, modelData.id, {})
                }
            }

            WindowsHeader {
                Layout.preferredWidth: 120

                windowController: root.windowController
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 2
            Layout.rightMargin: 4
            Layout.leftMargin: 4

            color: Style.colors.accent
            radius: 3
        }
    }
}
