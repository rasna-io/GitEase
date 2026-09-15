import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * IPopup
 * ************************************************************************************************/
Popup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property Item hostItem: null

    readonly property Item declaredHost: root._declaredHost

    readonly property Item hostOverlay: {
        let host = root.hostItem ?? root._declaredHost
        return host ? host.Overlay.overlay : null
    }

    property Item _declaredHost: null

    /* Object Properties
     * ****************************************************************************************/
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    width: 523
    height: 475

    x: root.parent ? Math.round((root.parent.width  - width)  / 2) : 0
    y: root.parent ? Math.round((root.parent.height - height) / 2) : 0

    padding: 0

    background: Rectangle {
        color: "transparent"
    }

    Overlay.modal: Rectangle {
        color: "#000000"
        opacity: 0.35
    }

    /* Event Handlers
     * ****************************************************************************************/
    Component.onCompleted: {
        root._declaredHost = root.parent
        root.parent = Qt.binding(() => root.hostOverlay ?? root._declaredHost)
    }
}
