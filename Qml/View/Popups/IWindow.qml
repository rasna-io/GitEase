import QtQuick
import QtQuick.Controls
import QtQuick.Window

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * IWindow
 * Base component for top-level windows that behave like the app's popups: a frameless window that
 * opens centered over its host (or the screen), carries its own WindowController so a header can
 * drag-move / minimize / maximize it. Resize borders come free from WindowController's native helper.
 * ************************************************************************************************/
Window {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property          Item              hostItem:               null
    readonly property var               hostWindow:             root.hostItem ? root.hostItem.Window.window : null
    readonly property WindowController  windowController:       windowController
    property          bool              _minimumSizeApplied:    false

    /* Object Properties
     * ****************************************************************************************/
    modality: Qt.ApplicationModal
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint

    onHostWindowChanged: {
        if (root.hostWindow && !root.visible)
            root.transientParent = root.hostWindow
    }

    onVisibleChanged: {
        if (!root.visible)
            return

        if (!root._minimumSizeApplied) {
            root._minimumSizeApplied = true
            root.windowController.setMinimumSize(root.minimumWidth, root.minimumHeight)
        }

        root.windowController.refreshBorderless()

        Qt.callLater(function() {
            let host = root.hostWindow
            if (host) {
                root.x = host.x + Math.round((host.width  - root.width)  / 2)
                root.y = host.y + Math.round((host.height - root.height) / 2)
            } else {
                root.x = Math.round((Screen.width  - root.width)  / 2)
                root.y = Math.round((Screen.height - root.height) / 2)
            }
        })
    }

    /* Children
     * ****************************************************************************************/
    WindowController {
        id: windowController
        window: root
    }
}