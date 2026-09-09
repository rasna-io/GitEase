import QtQuick
import QtQuick.Window

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * WindowMotion
 * Handles minimize/restore window animations with opacity and scale transitions.
 * ***********************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property Window window: null
    property WindowController windowController: null

    property bool minimizing: false

    /* Functions
     * ****************************************************************************************/
    function minimize() {
        if (!root.window || !root.windowController)
            return

        if (!Style.motionEnabled) {
            root.windowController.minimize()
            return
        }

        root.window.opacity = 1
        root.window.contentItem.scale = 1
        root.minimizing = true
        minimizeOutAnimation.restart()
    }

    /* Animations
     * ****************************************************************************************/
    property ParallelAnimation minimizeOutAnimation: ParallelAnimation {
        id: minimizeOutAnimation

        // Fade out window opacity
        NumberAnimation {
            target: root.window
            property: "opacity"
            to: 0
            duration: Style.motionMedium
            easing.type: Easing.InCubic
        }

        // Slightly shrink content
        NumberAnimation {
            target: root.window.contentItem
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

    property ParallelAnimation restoreAnimation: ParallelAnimation {
        id: restoreAnimation

        // Fade in window opacity
        NumberAnimation {
            target: root.window
            property: "opacity"
            to: 1
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }

        // Restore content scale
        NumberAnimation {
            target: root.window.contentItem
            property: "scale"
            to: 1
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }
    }

    /* Connections
     * ****************************************************************************************/
    property Connections visibilityConnections: Connections {
        target: root.window

        // Restore animation when window is shown again after minimizing
        function onVisibilityChanged() {
            if (!root.minimizing)
                return

            const visibility = root.window.visibility

            if (visibility === Window.Minimized || visibility === Window.Hidden)
                return

            root.minimizing = false
            root.window.opacity = 0
            root.window.contentItem.scale = 0.985
            restoreAnimation.restart()
        }
    }
}
