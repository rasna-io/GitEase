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
    property bool                   layoutVisible:           true
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
    property bool transitionInitialized: false

    /* Object Properties
     * ****************************************************************************************/
    visible: root.layoutVisible

    function syncPanelVisibility() {
        const shouldShow = !root.isMinimized && !root.detached

        if (!root.transitionInitialized) {
            root.transitionInitialized = true
            root.layoutVisible = shouldShow
            root.opacity = shouldShow ? 1 : 0
            root.scale = shouldShow ? 1 : 0.985
            return
        }

        if (shouldShow) {
            panelExitAnimation.stop()
            root.layoutVisible = true
            root.opacity = 0
            root.scale = 0.985
            panelEnterAnimation.restart()
            return
        }

        panelEnterAnimation.stop()
        root.opacity = 1
        root.scale = 1
        panelExitAnimation.restart()
    }

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
        syncPanelVisibility()

        if (detached) {
            if (Style.motionEnabled) {
                contentRoot.opacity = 0
                contentRoot.scale = 0.96
                detachedWindow.opacity = 0
                detachEnterAnimation.restart()
            } else {
                contentRoot.opacity = 1
                contentRoot.scale = 1
                detachedWindow.opacity = 1
            }
        } else {
            detachEnterAnimation.stop()
            contentRoot.opacity = 1
            contentRoot.scale = 1
            detachedWindow.opacity = 1
        }
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

        syncPanelVisibility()
    }

    Component.onDestruction: {
        if (root.minimizable && root.layoutController)
            root.layoutController.unregister(root)

        if (root.layoutId && root.layoutController)
            root.layoutController.persistPanelLayout(root)
    }

    Component.onCompleted: Qt.callLater(root.syncPanelVisibility)

    ParallelAnimation {
        id: detachEnterAnimation

        NumberAnimation {
            target: contentRoot
            property: "opacity"
            from: 0
            to: 1
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: contentRoot
            property: "scale"
            from: 0.96
            to: 1
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: detachedWindow
            property: "opacity"
            from: 0
            to: 1
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: panelEnterAnimation

        NumberAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "scale"
            to: 1
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: panelExitAnimation

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: Style.motionFast
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: root
                property: "scale"
                to: 0.985
                duration: Style.motionFast
                easing.type: Easing.InCubic
            }
        }

        ScriptAction {
            script: root.layoutVisible = false
        }
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
                            family: Style.fontTypes.font6Pro
                            styleName: "Solid"
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
                                family: Style.fontTypes.font6Pro
                                styleName: "Solid"
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
                    onDoubleClicked: detachedWindowMotion.toggleMaximize()
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

        WindowMotion {
            id: detachedWindowMotion
            window: detachedWindow
            windowController: detachedWindowController
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
