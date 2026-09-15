
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

    property                real                fontSizePt:               11

    /* Functions
     * ****************************************************************************************/
    function serialize() {
        let data = {
            currentTheme: root.currentTheme,
            fontSizePt: root.fontSizePt,
        }

        return data;
    }

    function deserialize(data : var) {
        root.currentTheme = data.currentTheme ?? "Modern Light"
        root.fontSizePt = data.fontSizePt ?? 11
    }
}

