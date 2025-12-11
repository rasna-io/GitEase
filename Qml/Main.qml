import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls

import GitEase
import GitEase_Style
import GitEase.Resources
import GitEase_Style_Impl


/*! ***********************************************************************************************
 * This is the highest level graphical object, i.e., the main application window. The state
 * of each instance is stored in the UiSession, which needs to be passed to its children.
 * Multiple instances can be created.
 * ************************************************************************************************/
ApplicationWindow {
    id: window

    /* Property Declarations
     * ****************************************************************************************/


    /* Object Properties
     * ****************************************************************************************/
    width: Style.appWidth
    height: Style.appHeight
    visible: true
    title: qsTr("GitEase")


    /* Fonts
     * ****************************************************************************************/



    /* Style
     * ****************************************************************************************/


    /* Children
     * ****************************************************************************************/

    UiSession {
        id: uiSessionId
        popups: uiSessionId.popups
    }

    UiSessionPopups {
        id: popups
        width: window.width
        height: window.height
    }
}
