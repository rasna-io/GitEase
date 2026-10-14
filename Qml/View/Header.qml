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
    property bool               utilityPanelOpen: false

    /* Signals
     * ****************************************************************************************/
    signal utilityPanelToggleRequested()

    /* Children
     * ****************************************************************************************/
    WindowMotion {
        id: windowMotion

        window: root.Window.window
        windowController: root.windowController
    }

    Rectangle {
        anchors.fill: parent
        color: Style.colors.headerBackground
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent

        acceptedButtons: Qt.LeftButton
        onPressed: windowController.startSystemMove()
        onDoubleClicked: windowMotion.toggleMaximize()
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
                id: headerContentLoader
                Layout.fillWidth: true
                Layout.leftMargin: Style.dp(14)
                Layout.rightMargin: Style.dp(14)
                clip: true
                opacity: 0
                sourceComponent: root.content

                onLoaded: headerContentFadeIn.restart()

                NumberAnimation {
                    id: headerContentFadeIn

                    target: headerContentLoader
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Style.motionMedium
                    easing.type: Easing.OutCubic
                }
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
            }

            IconButton {
                id: utilityPanelToggleButton
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                Layout.leftMargin: Style.dp(6)
                Layout.rightMargin: Style.dp(10)

                display: IconButton.IconOnly
                icon.source: Style.icons.togglePanel
                icon.width: 14
                icon.height: 14
                icon.color: root.utilityPanelOpen ? Style.colors.accent : Style.colors.foreground
                tooltip: root.utilityPanelOpen ? "Hide utility panel" : "Show utility panel"

                background: Rectangle {
                    radius: 5
                    color: utilityPanelToggleButton.down ? Style.colors.surfaceMuted :
                           utilityPanelToggleButton.hovered ? Style.colors.headerButtonBackgroundHover :
                           root.utilityPanelOpen ? Style.colors.subtleAzureGlow
                                                 : Style.colors.headerButtonBackground
                    border.width: 1
                    border.color: Style.colors.headerButtonBorder
                }

                onClicked: root.utilityPanelToggleRequested()
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
