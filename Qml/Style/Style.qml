pragma Singleton

import QtQuick

QtObject {
    id: style

    enum Theme {
        Light,
        Dark
    }


    /* Signals
     * ****************************************************************************************/
    //! A plugin removed the custom theme in use; the settings should go back to the default one.
    signal themeFallbackRequested()

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

    property          Colors        modernDarkColors:           ModernDarkColors {}

    property          Colors        modernSoftColors:           ModernSoftColors {}

    property          string        currentTheme:               "Modern Light"

    //! Themes registered by plugins : name -> { name, colors: Colors, dark: bool }.
    property          var           customThemes:               ({})

    //! Names of the registered custom themes, in registration order.
    property          var           customThemeNames:           []

    property          bool          reducedMotion:               false

    readonly property bool          motionEnabled:               !style.reducedMotion

    readonly property int           motionFast:                  style.motionEnabled ? 140 : 0

    readonly property int           motionMedium:                style.motionEnabled ? 240 : 0

    readonly property int           motionPage:                  style.motionEnabled ? 300 : 0

    onCurrentThemeChanged: changeTheme()

    /* Functions
     * ****************************************************************************************/
    function dp(size)
    {
        return size;
    }

    /*!
     * Replaces the custom themes. themes is a list of { name, colors, dark }.
     * With reapply the current theme is selected again, so a custom theme that was just
     * changed, added or removed takes effect (a removed one falls back to Modern Soft).
     */
    function setCustomThemes(themes, reapply) {
        const wasCustom = style.customThemes[style.currentTheme] !== undefined
        const map = {}
        const names = []
        for(const t of themes) {
            map[t.name] = t
            names.push(t.name)
        }
        style.customThemes = map
        style.customThemeNames = names

        if(reapply && (wasCustom || map[style.currentTheme] !== undefined)) {
            style.changeTheme()
        }
    }

    //! Asks the application to select its default theme in the settings.
    function fallbackToDefaultTheme() {
        style.themeFallbackRequested()
    }

    function changeTheme() {
        switch(style.currentTheme) {
        case "Modern Light":
            style.theme = Style.Theme.Light
            style.colors = modernLightColors
            break;
        case "Modern Soft":
            // Light-family theme: keeps Style.Theme.Light so brightness-dependent code treats it as light
            style.theme = Style.Theme.Light
            style.colors = modernSoftColors
            break;
        case "Modern Dark":
            style.theme = Style.Theme.Dark
            style.colors = modernDarkColors
            break;

        default: {
            const custom = style.customThemes[style.currentTheme]
            if(custom && custom.colors) {
                style.theme = custom.dark ? Style.Theme.Dark : Style.Theme.Light
                style.colors = custom.colors
            } else {
                style.theme = Style.Theme.Light
                style.colors = modernLightColors
            }
            break;
        }
        }
    }
}
