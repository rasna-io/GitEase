import QtQuick

import GitEase

/*! ***********************************************************************************************
 * Repository
 * Data model representing a Git repository with path, name, and etc.
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string id: ""
    property string path: ""
    property string name: ""
}
