import QtQuick

import GitEase

/*! ***********************************************************************************************
 * plugin
 * Data model representing a plugin with id, name, and etc.
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string pluginId: ""
    property string name: ""
    property string description: ""
    property string author: ""
    property string latestVersion: ""
    property string minAppVersion: ""
    property string size: ""
    property string iconUrl: ""
    property string releaseDate: ""

    property bool   isInstalled: false
    property bool   isCompatible: false
    property bool   updateAvailable: true
    property bool   isEnabled: false
}
