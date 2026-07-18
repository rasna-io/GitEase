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
        accent:              Qt.lighter(modernLightColors.accent, 1.4)
        primaryBackground:   midnightBlack
        secondaryBackground: graphiteDark
        foreground:          mutedLavenderSlate
        secondaryForeground: "#010101"
        surfaceLight:        "#6b6b6b"
        surfaceMuted:        "#1f1f1f"
        navButton:           "#6b6b6b"
        hoverTitle:          "#6b6b6b"
        secondaryText:       "#efefef"

        disabledButton:      "#9f9f9f"

        navigationRailBgColor: "#383838"

        addedFile:           "#3bdb6a"
        deletededFile:       "#FF3b3b"
        modifiediedFile:     "#FFc33b"
        renamedFile:         "#aafff8"
        untrackedFile:       "#00ffff"

        voidStripe:          deepObsidianOverlay
        editorBackgroound:   obsidianDark
        editorForeground:    mutedLavenderSlate
        linePanelBackgroound:obsidianDark
        linePanelForeground: deepCharcoalBlue

        cardBackground:      onyxShadow

        primaryBorder:       darkCharcoal
        secondaryBorder:     darkCharcoal

        diffRemovedBg:       paleCoralMist
        diffAddedBg:         softMintGlow
        diffRemovedBorder:   "#F5C2C7"
        diffAddedBorder:     "#A6E9C6"

        resizeHandle:        primaryBorder
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

        notificationInfo:            "#12324A"
        notificationInfoBorder:      "#2B6AA3"
        notificationInfoIcon:        "#7AB9FF"

        notificationSuccess:         "#123824"
        notificationSuccessBorder:   "#2E7D32"
        notificationSuccessIcon:     "#7EE082"

        notificationWarning:         "#3A2A12"
        notificationWarningBorder:   "#F57C00"
        notificationWarningIcon:     "#FFCC80"

        notificationError:           "#3A1216"
        notificationErrorBorder:     "#D32F2F"
        notificationErrorIcon:       "#FF8A80"

        notificationInfoText:        "#EAF4FF"
        notificationSuccessText:     "#E8FFF0"
        notificationWarningText:     "#FFF3E0"
        notificationErrorText:       "#FFEBEE"

        repoItemStatusPendingBg:     "#3F2F0B"
        repoItemStatusPendingText:   "#FCD34D"
        repoItemStatusFetchingBg:    "#0B2545"
        repoItemStatusFetchingText:  "#93C5FD"
        repoItemStatusPullingBg:     "#082F49"
        repoItemStatusPullingText:   "#7DD3FC"
        repoItemStatusDoneBg:        "#052E16"
        repoItemStatusDoneText:      "#86EFAC"
        repoItemStatusDirtyBg:       "#422006"
        repoItemStatusDirtyText:     "#FDE68A"
        repoItemStatusConflictBg:    "#450A0A"
        repoItemStatusConflictText:  "#FCA5A5"
        repoItemStatusCanceledBg:    "#450A0A"
        repoItemStatusCanceledText:  "#FCA5A5"
        repoItemStatusPATBg:         "#43525D"
        repoItemStatusPATText:       "#90CAF9"
        // Conflict marker backgrounds
        conflictMarkerStartBg:  "#2C5D4B"  // Solid Dark Green (Header)
        conflictOursBg:         "#1E3E31"  // Faded Dark Green (Content)

        conflictMarkerEndBg:    "#285E8E"  // Solid Dark Blue (Header)
        conflictTheirsBg:       "#1E3A5F"  // Faded Dark Blue (Content)

        conflictSeparatorBg:    "transparent"
        conflictMarkerText:     "#E0E0E0"  // Brighter text for headers
        hintText:               "#a0a0a0"
        lineNumberColor:        "#a0a0a0"

        conflictMarker:         "#FF6B6B"
        conflictStatusConflictColor : "#FF6B6B"
        conflictStatusModifiedColor : "#FFD966"
        conflictStatusAddedColor     : "#4DB85D"

        // Interactive rebase status colors
        property color rebaseStatusPending:    secondaryText
        property color rebaseStatusInProgress: "#FFA500"        // bright orange
        property color rebaseStatusRebased:    "#2ECC40"        // bright green
        property color rebaseStatusConflict:   "#FF4136"        // bright red
        property color rebaseStatusSkipped:    mutedText        // dimmed

        contextMenuBackground: "#22222A"
        contextMenuBorder:     "#2C2C33"
        contextMenuSeparator:  "#2C2C33"
        contextMenuHover:      "#A0A0A0"
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
