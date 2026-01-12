pragma Singleton

import QtQuick

QtObject {
    id: style

    enum Theme {
        Light,
        Dark
    }


    /* Property Declarations
     * ****************************************************************************************/
    property          int           theme:                      Style.Theme.Light

    readonly property int           appWidth:                   1080

    readonly property int           appHeight:                  720

    property          Colors        colors:                     Colors{}

    readonly property Icons         icons:                      Icons{}

    //! Font types
    readonly property FontTypes     fontTypes:                  FontTypes{}

    //! Font sizes
    readonly property AppFontSize   appFont:                    AppFontSize {}

    readonly property FontIconSize  fontIconSize:               FontIconSize {}


    property          Colors        modernLightColors:          Colors {}

    property          Colors        modernDarkColors:           Colors {
        accent:              "#01468c"
        primaryBackground:   "#282828"
        secondaryBackground: "#383838"
        foreground:          "#fdfdfd"
        surfaceLight:        "#6b6b6b"
        surfaceMuted:        "#1f1f1f"
        navButton:           "#6b6b6b"
        hoverTitle:          "#6b6b6b"
        secondaryText:       "#efefef"

        addedFile:           "#3bdb6a"
        deletededFile:       "#FF3b3b"
        modifiediedFile:     "#FFc33b"
        renamedFile:         "#aafff8"
        untrackedFile:       "#990000ff"

        diffRemovedBg:       "#ed4c4c"
        diffAddedBg:         "#1b7b3a"
        diffRemovedBorder:   "#F5C2C7"
        diffAddedBorder:     "#A6E9C6"
    }

    property           string       currentTheme:               "Modern Light"

    onCurrentThemeChanged: changeTheme()

    /* Functions
     * ****************************************************************************************/
    function dp(size)
    {
        return size;
    }

    function changeTheme() {
        switch(style.currentTheme) {
        case "Modern Light":
            style.colors = modernLightColors
            break;
        case "Modern Dark":
            style.colors = modernDarkColors
            break;

        default:
            style.colors = modernLightColors
            break;
        }
    }
}
