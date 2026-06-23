
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

    property                int               chunkContextLines:        0

    property                int               chunkExpandLines:         10

    /* Functions
     * ****************************************************************************************/
    function serialize() {
        let data = {
            defaultPath: root.defaultPath,
            showAvatar: root.showAvatar,
            showStashNodes: root.showStashNodes,
            chunkContextLines: root.chunkContextLines,
            chunkExpandLines: root.chunkExpandLines
        }

        return data;
    }

    function deserialize(data : var) {
        root.defaultPath = data.defaultPath ?? ""
        root.showAvatar = data.showAvatar ?? true
        root.showStashNodes = data.showStashNodes ?? false
        root.chunkContextLines = data.chunkContextLines ?? 0
        root.chunkExpandLines = data.chunkExpandLines ?? 10
    }
}

