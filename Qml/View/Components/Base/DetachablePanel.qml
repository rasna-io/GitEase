import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * DetachablePanel
 * Wraps a single panel and allows detaching it into a separate window.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string          currentRepositoryName
    property bool            detached: false
    property string          title: ""
    property int             headerHeight: 32
    property int             minWindowWidth: 420
    property int             minWindowHeight: 320
    property bool            showInlineHeader: true

    // Default content slot for panel contents
    default property alias content: contentRoot.data

    /* Internal State
     * ****************************************************************************************/
    property int lastWidth: 600
    property int lastHeight: 400

    /* Functions
     * ****************************************************************************************/
    function updateWindowGeometry() {
        detachedWindow.width = Math.max(minWindowWidth, lastWidth)
        detachedWindow.height = Math.max(minWindowHeight, lastHeight)

        let screens = Qt.application.screens
        if (screens.length > 0) {
            let screen = screens[0]
            detachedWindow.x = Math.max(0, (screen.width - detachedWindow.width) / 2)
            detachedWindow.y = Math.max(0, (screen.height - detachedWindow.height) / 2)
        }
    }

    function moveContentTo(target) {
        if (!contentRoot)
            return

        contentRoot.parent = target
        contentRoot.anchors.fill = target
    }

    onDetachedChanged: {
        if (detached)
            updateWindowGeometry()

        moveContentTo(detached ? windowHost : inlineHost)
    }

    onWidthChanged: {
        if (!detached && width > 0) {
            lastWidth = width
        }
    }

    onHeightChanged: {
        if (!detached && height > 0) {
            lastHeight = height
        }
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 20
            Layout.maximumHeight: 20
            visible: root.showInlineHeader && !root.detached
            color: Style.colors.secondaryBackground

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    text: root.title
                    color: Style.colors.foreground
                    font.family: Style.fontTypes.roboto
                    font.weight: 500
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }

                ToolButton {
                    id: detachButton
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    hoverEnabled: true

                    contentItem: Text {
                        anchors.centerIn: parent
                        text: Style.icons.arrowRight
                        font {
                            family: Style.fontTypes.font6ProSolid
                            pixelSize: 10
                        }
                        color: Style.colors.foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 5
                        color: detachButton.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                    }

                    onClicked: root.detached = true
                }
            }
        }

        Item {
            id: inlineHost
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: contentRoot
                anchors.fill: parent
            }
        }
    }

    Window {
        id: detachedWindow
        visible: root.detached
        width: root.lastWidth
        height: root.lastHeight
        color: Style.colors.primaryBackground
        title: root.title
        flags: Qt.Window | Qt.FramelessWindowHint

        onClosing: function(close) {
            close.accepted = false
            root.detached = false
        }

        onWidthChanged: {
            if (root.detached && width > 0) {
                root.lastWidth = width
            }
        }

        onHeightChanged: {
            if (root.detached && height > 0) {
                root.lastHeight = height
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: root.headerHeight
                Layout.maximumHeight: root.headerHeight
                color: Style.colors.secondaryBackground

                RowLayout {
                    z: 1
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Label {
                        Layout.fillWidth: true
                        text: root.title  + ` [${root.currentRepositoryName}]`
                        color: Style.colors.foreground
                        font.family: Style.fontTypes.roboto
                        font.weight: 500
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    ToolButton {
                        id: attachButton
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        hoverEnabled: true

                        contentItem: Text {
                            anchors.centerIn: parent
                            text: Style.icons.undo
                            font {
                                family: Style.fontTypes.font6ProSolid
                                pixelSize: 14
                            }
                            color: Style.colors.foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 5
                            color: attachButton.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                        }

                        onClicked: root.detached = false
                    }

                    WindowsHeader {
                        Layout.preferredWidth: 96
                        windowController: detachedWindowController
                    }
                }

                MouseArea {
                    z: 0
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onPressed: detachedWindowController.startSystemMove()
                    onDoubleClicked: detachedWindowController.toggleMaxRestore()
                }
            }

            Item {
                id: windowHost
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        WindowController {
            id: detachedWindowController
            window: detachedWindow
        }
    }
}
