import QtQuick

import GitEase

/*! ***********************************************************************************************
 * DockAblePage
 * Dock functions
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property bool showDropZone: false

    /* Children
     * ****************************************************************************************/
    PageDropZone{
        id: pageDropZone
        anchors.fill: parent
        visible: showDropZone
        opacity: 0.7
        z: 9
    }
}
