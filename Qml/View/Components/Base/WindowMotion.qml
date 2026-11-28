import QtQuick
import QtQuick.Window

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * WindowMotion
 * Handles minimize/restore window animations with opacity and scale transitions.
 * ***********************************************************************************************/
// Item (not QtObject): animations/Connections need a `data` default property;
// QtObject roots spam "Cannot find member data" under Qt 6.10+.
Item {
    id: root

    // Non-visual helper — never size/layout against parents.
    width: 0
    height: 0
    visible: false

    /* Property Declarations
     * ****************************************************************************************/
    property Window window: null
    property WindowController windowController: null

    property bool minimizing: false

    readonly property var fadeTarget: !root.window ? null
                                      : Style.windowOpacitySupported ? root.window
                                                                     : root.window.contentItem

    /* Functions
     * ****************************************************************************************/
    function toggleMaximize() {
        if (!root.window || !root.windowController)
            return

        if (!Style.motionEnabled) {
            root.windowController.toggleMaxRestore()
            return
        }

        root.window.contentItem.scale = root.window.visibility === Window.Maximized ? 0.985 : 1
        root.windowController.toggleMaxRestore()
        restoreAnimation.restart()
    }

    function minimize() {
        if (!root.window || !root.windowController)
            return

        if (!Style.motionEnabled) {
            root.windowController.minimize()
            return
        }

        if (root.fadeTarget)
            root.fadeTarget.opacity = 1
        root.window.contentItem.scale = 1
        root.minimizing = true
        minimizeOutAnimation.restart()
    }

    /* Animations
     * ****************************************************************************************/
    ParallelAnimation {
        id: minimizeOutAnimation

        // Fade out window opacity
        NumberAnimation {
            target: root.fadeTarget
            property: "opacity"
            to: 0
            duration: Style.motionMedium
            easing.type: Easing.InCubic
        }

        // Slightly shrink content
        NumberAnimation {
            target: root.window ? root.window.contentItem : null
            property: "scale"
            to: 0.985
            duration: Style.motionMedium
            easing.type: Easing.InCubic
        }

        onStopped: {
            if (root.windowController)
                root.windowController.minimize()
        }
    }

    ParallelAnimation {
        id: restoreAnimation

        // Fade in window opacity
        NumberAnimation {
            target: root.fadeTarget
            property: "opacity"
            to: 1
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }

        // Restore content scale
        NumberAnimation {
            target: root.window ? root.window.contentItem : null
            property: "scale"
            to: 1
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }
    }

    /* Connections
     * ****************************************************************************************/
    Connections {
        target: root.window

        // Restore animation when window is shown again after minimizing
        function onVisibilityChanged() {
            if (!root.minimizing || !root.window)
                return

            const visibility = root.window.visibility

            if (visibility === Window.Minimized || visibility === Window.Hidden)
                return

            root.minimizing = false
            if (root.fadeTarget)
                root.fadeTarget.opacity = 0
            root.window.contentItem.scale = 0.985
            restoreAnimation.restart()
        }
    }
}
