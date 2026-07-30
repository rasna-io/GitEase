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
        accent:              "#3B82F6"
        accentHover:         "#2F6FE0"
        primaryBackground:   darkGraphite
        secondaryBackground: graphiteDark
        foreground:          softCloudWhite
        secondaryForeground: "#010101"
        surfaceLight:        "#6b6b6b"
        surfaceMuted:        "#1f1f1f"
        navButton:           "#6b6b6b"
        hoverTitle:          "#6b6b6b"
        secondaryText:       "#efefef"
        placeholderText:     "#6A6A6E"

        disabledButton:      "#9f9f9f"

        titleText:           "#ffffff"

        navigationRailBgColor: "#383838"

        addedFile:           "#4ADE80"
        deletededFile:       "#F87171"
        modifiediedFile:     "#FBBF24"
        renamedFile:         "#aafff8"
        untrackedFile:       "#00ffff"

        voidStripe:          deepObsidianOverlay
        editorBackgroound:   obsidianDark
        editorForeground:    mutedLavenderSlate
        linePanelBackgroound:obsidianDark
        linePanelForeground: deepCharcoalBlue

        cardBackground:      charcoalGray

        primaryBorder:       darkCharcoal
        secondaryBorder:     darkCharcoal

        controlBackground:      "#1B1B22"
        controlBackgroundHover: "#232330"
        controlBorder:          "#2E2E37"
        controlBorderHover:     "#3E5C88"
        switchTrackOff:         "#3A3A44"
        switchHandle:           "#EDEDF2"

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

        userInfoSelectedBackground: Qt.rgba(59 / 255, 130 / 255, 246 / 255, 0.1)

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

        contextMenuBackground: obsidianDeep
        contextMenuBorder:     "#2C2C33"
        contextMenuSeparator:  "#2C2C33"
        contextMenuHover:      "#34343D"
        contextMenuDanger:     "#FF6B6B"

        branchSelectedAccent:  "#93C5FD"

        // Committing page header
        branchAccent:          "#60A5FA"
        chipBorder:            "#222228"
        chipText:              "#9898B0"
        forcePushText:         softCoralMist    // #F87171
        forcePushBorder:       "#4DEF4444"

        // File list sections
        countBadgeText:      "#1E1E30"
        countBadgeBg:        "#141424"
        sectionHeaderBg:     midnightBlack         // #101013
        sectionLabel:        "#323248"
        emptyCircleBg:       "#141420"
        emptyCircleBorder:   "#1C1C28"
        emptyStateText:      "#1E1E30"
        emptyStateSubText:   "#181828"

        // Section actions and badge
        actionIconIdle:        "#3A3A52"
        stashAmber:            "#FBBF24"
        stageGreen:            "#4ADE80"
        discardRed:            softCoralMist       // #F87171 – reuse existing
        countText:             "#FBBF24"
        countBg:               "#12FBBF24"

        // Action pill (row-level)
        actionPillBg:         onyxShadow          // #17171C
        actionPillBorder:     "#1E1E2A"
        openBlue:             branchAccent        // #60A5FA

        // Row-level
        rowHoverBg:          "#17171C"

        // Diff view header line counts
        diffAddedCount:    "#4ADE80"
        diffRemovedCount:  "#F87171"

        // Commit Panel
        commitButton:      "#3B82F6"
        fileBrowserRowHoverBg: Qt.rgba(1,1,1,0.04)
        fileBrowserSearchBg:  Qt.rgba(1,1,1,0.05)
        headerBackground:            midnightBlack
        headerButtonBackground:      graphiteDark
        headerButtonBackgroundHover: "#26262E"
        headerButtonBorder:          charcoalGray

        segmentedSelected:           "#2A2A32"

        // panel chrome
        utilitiesPanelBackground:            abyssBlack
        utilitiesPanelBorder:                charcoalGray
        utilitiesPanelScrollBar:             deepCharcoalBlue
        utilitiesPanelScrollBarHover:        slateMuted

        // filter field
        utilitiesFilterBackground:           graphiteSurface
        utilitiesFilterBorder:               charcoalGray
        utilitiesFilterText:                 softCloudWhite
        utilitiesFilterPlaceholder:          slateMuted

        // card shell
        utilitiesCardBackground:             abyssBlack
        utilitiesCardSeparator:              charcoalGray

        // card header
        utilitiesCardHeaderBackground:       midnightBlack
        utilitiesCardHeaderHoverBackground:  graphiteHover
        utilitiesCardTitle:                  slateLavender
        utilitiesCardChevron:                slateMuted

        // card header badge
        utilitiesCardBadgeBackground:        graphiteHover
        utilitiesCardBadgeBorder:            deepCharcoalBlue
        utilitiesCardBadgeText:              slateLavender

        // segmented control
        utilitiesSegmentTrackBackground:     graphiteSurface
        utilitiesSegmentTrackBorder:         charcoalGray
        utilitiesSegmentHoverBackground:     graphiteHover
        utilitiesSegmentSelectedBackground:  "#2A2A32"
        utilitiesSegmentText:                slateLavender
        utilitiesSegmentSelectedText:        softCloudWhite

        // inset surface
        utilitiesSurfaceBackground:          graphiteSurface
        utilitiesSurfaceBorder:              charcoalGray
        utilitiesHintText:                   slateLavender

        // list rows
        utilitiesRowBackground:              graphiteSurface
        utilitiesRowHoverBackground:         graphiteHover
        utilitiesRowSelectedBackground:      graphiteSelected
        utilitiesRowBorder:                  charcoalGray
        utilitiesRowSelectedIndicator:       "#93C5FD"
        utilitiesRowText:                    softCloudWhite
        utilitiesRowSelectedText:            "#93C5FD"
        utilitiesRowIcon:                    slateLavender
        utilitiesRowIconAccent:              "#93C5FD"
        utilitiesRowMetaText:                slateLavender
        utilitiesRowSubText:                 slateMuted
        utilitiesRowMissingText:             softCoralMist
        utilitiesEmptyStateText:             slateMuted

        // inputs
        utilitiesFieldLabel:                 slateLavender
        utilitiesInputBackground:            graphiteSurface
        utilitiesInputHoverBackground:       graphiteHover
        utilitiesInputBorder:                charcoalGray
        utilitiesInputText:                  softCloudWhite
        utilitiesInputPlaceholder:           slateMuted
        utilitiesInputPopupBackground:       obsidianDeep

        // check box
        utilitiesCheckBoxText:               softCloudWhite

        // file / folder picker button
        utilitiesPickerButtonBorder:         charcoalGray
        utilitiesPickerButtonIcon:           slateLavender

        // dashed ghost button
        dashedButtonText:                    slateLavender
        dashedButtonBorder:                  deepCharcoalBlue
        dashedButtonTextHover:               softCloudWhite
        dashedButtonBorderHover:             slateLavender
        dashedButtonBackgroundHover:         frostWash
        dashedButtonTextDanger:              softCoralMist
        dashedButtonBorderDanger:            softCoralMist

        // per-row action icons
        utilitiesActionIcon:                 slateMuted
        utilitiesActionIconActive:           "#7AB9FF"
        utilitiesActionIconWarning:          "#FFD966"
        utilitiesActionIconDanger:           softCoralMist
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
