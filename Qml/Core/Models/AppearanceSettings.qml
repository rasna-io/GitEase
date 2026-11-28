
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

    property                bool                reducedMotion:            false

    /* Functions
     * ****************************************************************************************/
    function serialize() {
        let data = {
            currentTheme: root.currentTheme,
            fontSizePt: root.fontSizePt,
            reducedMotion: root.reducedMotion,
        }

        return data;
    }

    function deserialize(data : var) {
        root.currentTheme = data.currentTheme ?? "Modern Light"
        root.fontSizePt = data.fontSizePt ?? 11
        root.reducedMotion = data.reducedMotion ?? false
    }
}

