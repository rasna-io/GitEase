
import QtQuick

/*! ***********************************************************************************************
 * GeneralSettings
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property                string            defaultPath:              ""

    property                bool              showAvatar:               true

    /* Functions
     * ****************************************************************************************/
    function serialize() {
        let data = {
            defaultPath: root.defaultPath,
            showAvatar: root.showAvatar
        }

        return data;
    }

    function deserialize(data : var) {
        root.defaultPath = data.defaultPath ?? ""
        root.showAvatar = data.showAvatar ?? true
    }
}

