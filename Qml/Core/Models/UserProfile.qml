import QtQuick
import QtQuick.Controls

import GitEase

/*! ***********************************************************************************************
 * UserProfile
 * Data model representing a Git User Profile with username, password and etc.
 * ************************************************************************************************/

QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string username:  ""
    property string password:  ""

    property string email:     ""
    property var    levels:    []
}
