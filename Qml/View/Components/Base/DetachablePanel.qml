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
    property string                 layoutId:               ""
    property string                 icon:                   ""
    property LayoutController       layoutController:       null
    property string                 currentRepositoryName
    property bool                   detached:               false
    property bool                   isMinimized:            false
    property bool                   minimizable:            false
    property string                 title:                  ""
    property int                    headerHeight:           32
    property int                    minWindowWidth:         420
    property int                    minWindowHeight:        320
    property bool                   showInlineHeader:       true
    property GuideController        guideController:        null

    // Optional elements in the middle of header
    property Component  middleAccessory: null

    // Default content slot for panel contents
    default property alias content: contentRoot.data

    readonly property Item activeItem: root.detached ? windowHost : inlineHost

    /* Internal State
     * ****************************************************************************************/
    property int lastWidth: 600
    property int lastHeight: 400
    property bool guideDetached: false
    property bool showLocalGuide: false

    /* Object Properties
     * ****************************************************************************************/
    visible: !root.isMinimized && !root.detached

    /* Functions
     * ****************************************************************************************/
    function updateWindowGeometry() {
        detachedWindow.width = Math.max(minWindowWidth, lastWidth)
        detachedWindow.height = Math.max(minWindowHeight, lastHeight)

        // Center on the screen the panel is currently displayed on, not always the primary one.
        let screenWidth  = root.Screen.width  || Qt.application.screens[0]?.width  || 0
        let screenHeight = root.Screen.height || Qt.application.screens[0]?.height || 0

        detachedWindow.x = root.Screen.virtualX + Math.max(0, (screenWidth  - detachedWindow.width)  / 2)
        detachedWindow.y = root.Screen.virtualY + Math.max(0, (screenHeight - detachedWindow.height) / 2)
    }

    function bindPopup(popup) {
        if (!popup || !popup.hasOwnProperty("hostItem"))
            return

        popup.hostItem = Qt.binding(function() { return root.activeItem })
    }

    /*! bindPopup() plus open(), for the common "show this shared popup here" case. */
    function openPopup(popup) {
        if (!popup)
            return

        root.bindPopup(popup)
        popup.open()
    }

    function moveContentTo(target) {
        if (!contentRoot)
            return

        contentRoot.parent = target
        contentRoot.anchors.fill = target
    }

    onDetachedChanged: {
        if (detached) {
            updateWindowGeometry()
        } else {
            showLocalGuide = false
            guideDetached = false
        }
        moveContentTo(detached ? windowHost : inlineHost)
    }

    onWidthChanged: {
        if (!detached && !isMinimized && width > 0) {
            lastWidth = width
        }
    }

    onHeightChanged: {
        if (!detached && height > 0) {
            lastHeight = height
        }
    }

    onLayoutControllerChanged: {
        if (root.layoutId && root.layoutController)
            root.layoutController.registerPanelLayout(root)
    }

    onIsMinimizedChanged: {
        if (root.minimizable && root.layoutController) {
            if (root.isMinimized)
                root.layoutController.register(root)
            else
                root.layoutController.unregister(root)
        }

        if (root.layoutId && root.layoutController)
            root.layoutController.persistPanelLayout(root)
    }

    Component.onDestruction: {
        if (root.minimizable && root.layoutController)
            root.layoutController.unregister(root)

        if (root.layoutId && root.layoutController)
            root.layoutController.persistPanelLayout(root)
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: inlineHeader
            Layout.fillWidth: true
            Layout.minimumHeight: 35
            Layout.maximumHeight: 35
            visible: root.showInlineHeader && !root.detached
            color: Style.colors.primaryBackground
            border {
                width: Style.dp(1)
                color: Style.colors.primaryBorder
            }

            GuideHoverTrigger {
                guideController: root.guideController
                guideId: "detachable_panel_tutorial"
                guideName: "Detachable Panels"
                guideIcon: Style.icons.arrowRight
                guidePage: "graph"
                stepsFactory: function() {
                    return [
                        {
                            targetProvider: function() { return inlineHeader },
                            icon: Style.icons.arrowRight,
                            title: "Detachable Panels",
                            description: "Each panel can be popped into its own floating window — ideal for multi-monitor setups or focusing on a single view."
                        },
                        {
                            targetProvider: function() { return detachButton },
                            icon: Style.icons.arrowRight,
                            title: "Detach to Window",
                            description: "Click this button to move the panel into its own floating window. You can drag, resize, and position it anywhere on screen.",
                            onNext: function() {
                                if (!root)
                                    return

                                root.guideDetached = true
                                root.showLocalGuide = true
                                root.detached = true
                                Qt.callLater(function() { localGuideCtrl.show() })
                            }
                        }
                    ]
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Label {
                    text: root.title
                    Layout.alignment: Qt.AlignLeft
                    color: Style.colors.foreground
                    font.family: Style.fontTypes.inter
                    font.weight: 500
                    font.pixelSize: Style.appFont.smallPt
                    elide: Text.ElideRight
                }

                Loader {
                    id: accessoryLoader
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    active: root.middleAccessory !== null
                    sourceComponent: root.middleAccessory
                }

                ActionIconButton {
                    id: minimizeButton
                    visible: root.minimizable
                    Layout.alignment: Qt.AlignRight
                    iconText: Style.icons.windowMinimize
                    tooltip: qsTr("Minimize")
                    textColor: Style.colors.foreground

                    onClicked: root.isMinimized = true
                }

                ToolButton {
                    id: detachButton
                    Layout.alignment: Qt.AlignRight
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    hoverEnabled: true

                    contentItem: Text {
                        anchors.centerIn: parent
                        text: Style.icons.detach
                        font {
                            family: Style.fontTypes.font6ProSolid
                            pixelSize: Style.appFont.smallPt
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
        transientParent: null
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
                color: Style.colors.primaryBackground
                border {
                    width: Style.dp(1)
                    color: Style.colors.primaryBorder
                }

                RowLayout {
                    z: 1
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Label {
                        Layout.alignment: Qt.AlignLeft
                        text: root.title  + ` [${root.currentRepositoryName}]`
                        color: Style.colors.foreground
                        font.family: Style.fontTypes.inter
                        font.weight: 500
                        font.pixelSize: Style.appFont.mediumPt
                        elide: Text.ElideRight
                    }

                    Loader {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        active: root.middleAccessory !== null
                        sourceComponent: root.middleAccessory
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
                                pixelSize: Style.appFont.largePt
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
                        Layout.alignment: Qt.AlignRight
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
                objectName: "windowHost"
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        WindowController {
            id: detachedWindowController
            window: detachedWindow
        }

        QtObject {
            id: localGuideCtrl
            signal guideStepChanged(var sd)
            signal guideDismissed()

            function next()    {
                guideDismissed()
                root.detached = false
            }

            function dismiss() {
                guideDismissed()
                root.detached = false
            }

            function back() {}

            function show() {
                guideStepChanged({
                    target: attachButton,
                    isInPopup: false,
                    icon: Style.icons.undo,
                    title: "Re-attach Panel",
                    description: "Use this button in the floating window header to snap the panel back into the main layout.",
                    showBack: false,
                    showSkip: true,
                    stepIndex: 0,
                    totalSteps: 1
                })
            }
        }

        GuideOverlay {
            anchors.fill: parent
            z: 100
            guideController: localGuideCtrl
        }
    }

    /* Guide
     * ****************************************************************************************/
    Connections {
        target: root.guideController
        ignoreUnknownSignals: true

        function onGuideDismissed() {
            if (root.guideDetached && !root.showLocalGuide) {
                root.detached = false
                root.guideDetached = false
            }
        }
    }
}
