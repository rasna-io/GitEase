import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase


/*! ***********************************************************************************************
 * StashManagerDock
 * show stash manager form
 * ************************************************************************************************/
Item {
    id : root

    property StashController stashController: null

    /* Property Declarations
     * ****************************************************************************************/

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/
    Stash {
        anchors.fill: parent

        stashController: root.stashController
    }

    /* Functions
     * ****************************************************************************************/
}

