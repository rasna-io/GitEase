import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * IPopup
 * ************************************************************************************************/
Popup {
    id: root

    /* Object Properties
     * ****************************************************************************************/
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside


    width: 523
    height: 475

    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0

    padding: 0

    background: Rectangle {
        color: "transparent"
    }

    Overlay.modal: Rectangle {
        color: "#000000"
        opacity: 0.35
    }
}
