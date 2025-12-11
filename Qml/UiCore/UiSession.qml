import QtQuick

import GitEase


/*! ***********************************************************************************************
 * The UiSession contains all information required by graphical components to display the right
 * state.
 * ************************************************************************************************/
Item {
    id: root


    /* Property Declarations
     * ****************************************************************************************/

    property        AppModel                  appModel:               AppModel {}


    property        DeviceController         deviceController:        DeviceController {}


    property        UiSessionPopups          popups


}
