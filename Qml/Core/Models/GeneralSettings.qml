
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

    property                bool              showStashNodes:           false

    /* Functions
     * ****************************************************************************************/
    function serialize() {
        let data = {
            defaultPath: root.defaultPath,
            showAvatar: root.showAvatar,
            showStashNodes: root.showStashNodes
        }

        return data;
    }

    function deserialize(data : var) {
        root.defaultPath = data.defaultPath ?? ""
        root.showAvatar = data.showAvatar ?? true
        root.showStashNodes = data.showStashNodes ?? false
    }
}

