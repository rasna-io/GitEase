
import QtQuick
import GitEase_Style

/*! ***********************************************************************************************
 * AppearanceSettings
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/

    property                string              currentTheme:             "Modern Light"

    /* Functions
     * ****************************************************************************************/
    function serialize() {
        let data = {
            currentTheme: root.currentTheme,
        }

        return data;
    }

    function deserialize(data : var) {
        root.currentTheme = data.currentTheme ?? "Modern Light"
    }
}

