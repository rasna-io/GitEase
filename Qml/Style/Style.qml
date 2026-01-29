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
        secondaryForeground: "#010101"
        surfaceLight:        "#6b6b6b"
        surfaceMuted:        "#1f1f1f"
        navButton:           "#6b6b6b"
        hoverTitle:          "#6b6b6b"
        secondaryText:       "#efefef"

        disabledButton:      "#9f9f9f"

        addedFile:           "#3bdb6a"
        deletededFile:       "#FF3b3b"
        modifiediedFile:     "#FFc33b"
        renamedFile:         "#aafff8"
        untrackedFile:       "#00ffff"

        voidStripe:          "#565656"
        editorBackgroound:   "#282828"
        editorForeground:    "#f1f1f1"
        linePanelBackgroound:"#383838"
        linePanelForeground: "#9f9f9f"

        cardBackground:      "#585858"

        primaryBorder:       "#686868"
        secondaryBorder:     "#383838"

        diffRemovedBg:       "#ed4c4c"
        diffAddedBg:         "#1b7b3a"
        diffRemovedBorder:   "#F5C2C7"
        diffAddedBorder:     "#A6E9C6"

        resizeHandle:        "#6b6b6b"
        resizeHandlePressed: "#9b9b9b"

        selectedText:            "#FFFFFF"
        onAccentText:            "#FFFFFF"
        onWarningText:           "#000000"
        onSuccessText:           "#000000"
        onErrorText:             "#FFFFFF"
        onInfoText:              "#000000"
        onBadgeText:             "#FFFFFF"
        
        defaultBackground:       "#4A4020"
        defaultHoverBackground:  "#5A5030"
        
        iconOnSurface:           "#B0B0B0"
        iconOnDefault:           "#FFD966"
        
        levelSystemBadge:        "#4DB85D"
        levelGlobalBadge:        "#4DB8B8"
        levelLocalBadge:         "#D4BC4D"
        levelWorktreeBadge:      "#D44D4D"
        levelAppBadge:           "#4D4DD4"
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
            style.theme = Style.Theme.Light
            style.colors = modernLightColors
            break;
        case "Modern Dark":
            style.theme = Style.Theme.Dark
            style.colors = modernDarkColors
            break;

        default:
            style.theme = Style.Theme.Light
            style.colors = modernLightColors
            break;
        }
    }
}
