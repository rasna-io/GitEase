import QtQuick

QtObject{
    property color midnightBlack:       "#101013"
    property color warmChalk:           "#EFEFEC"
    property color darkCharcoal:        "#1D1D22"
    property color graphiteDark:        "#17171C"
    property color obsidianDark:        "#0D0D0F"
    property color mintyFresh:          "#86EFAC"
    property color softMintGlow:        "#144ADE80"
    property color paleCoralMist:       "#14F87171"
    property color deepObsidianOverlay: "#9914141E"
    property color deepCharcoalBlue:    "#28283A"
    property color graphiteMidnight:    "#17171C"
    property color mutedLavenderSlate:  "#9898B4"
    property color vibrantMint:         "#4ADE80"
    property color softCoralMist:       "#F87171"
    property color cornflowerBlue:      "#60a5fa"
    property color amber:               "#d97706"
    property color purple:              "#a855f7"
    property color marigold:            "#fbbf24"


    property color vibrantMintBg:       Qt.darker(vibrantMint, 7.5)
    property color softCoralMistBg:     Qt.darker(softCoralMist, 7.5)
    property color cornflowerBlueBg:    Qt.darker(cornflowerBlue, 7.5)
    property color amberBg:             Qt.darker(amber, 7.5)
    property color purpleBg:            Qt.darker(purple, 7.5)
    property color marigoldBg:          Qt.darker(marigold, 7.5)
    property color subtleAzureGlow:     "#243B82F6"
    property color obsidianDeep:        "#111118"
    property color softCloudWhite:      "#F4F4F8"
    property color slateLavender:       "#9898B4"
    property color deepMidnight:        "#323248"
    property color darkObsidian:        "#222230"
    property color abyssBlack:          "#131316"
    property color offWhite:            "#E8E8E3"
    property color softParchment:       "#ECECE9"
    property color darkGraphite:        "#0D0D0F"
    property color charcoalGray:        "#222228"
    property color lightPlatinum:       "#DDDDDF"
    property color azureTint:           "#1F2563EB"
    property color accentWash:          "#142563EB"
    property color graphiteSurface:     "#1A1A20"
    property color graphiteHover:       "#202028"
    property color graphiteSelected:    "#26262F"
    property color slateMuted:          "#6A6A78"
    property color frostWash:           "#14F4F4F8"

    // Primary colors
    property color primaryBackground:   "#FBFCFE"
    property color secondaryBackground: "#EEF1F6"
    property color foreground:          "#232A3A"
    property color secondaryForeground: "#FFFFFF"
    property color accent:              "#2563EB"
    property color accentHover:         "#1D4FD8"
    property color error:               "#DC2626"
    property color warning:             "#D97706"
    property color disabledButton:      "#A9B2C3"

    property color navigationRailBgColor: "#EEF1F6"

    property color navButton:           "#F3F5F9"
    property color hoverTitle:          "#E8ECF3"
    property color textButton:          "#FFFFFF"
    
    // Files Status
    property color addedFile:           "#A7E8BD"
    property color deletededFile:       "#F7A8A8"
    property color modifiediedFile:     "#F8DF8E"
    property color renamedFile:         "#A5E3F0"
    property color untrackedFile:       "#992563EB"

    // Text colors
    property color secondaryText:       "#566074"
    property color mutedText:           "#8B94A7"
    property color titleText:           "#101626"
    property color descriptionText:     "#657089"
    property color hintText:            "#465066"
    property color placeholderText:     "#8B94A7"

    property color voidStripe:          "#F3F5F9"
    property color editorBackgroound:   "#FFFFFF"
    property color editorForeground:    "#3B4458"
    property color linePanelBackgroound:"#F5F7FA"
    property color linePanelForeground: "#8B94A7"
    
    // Surface & Background colors
    property color cardBackground:      "#E6EAF1"
    property color surfaceLight:        "#F3F5F9"
    property color surfaceMuted:        "#DEE3EB"
    property color hintBackground:      "#E6EEF9"
    
    // Border colors
    property color primaryBorder:       "#DCE1EA"
    property color secondaryBorder:     "#E8ECF3"

    // Control / Input surfaces (settings & form controls)
    property color controlBackground:      "#F3F5F9"
    property color controlBackgroundHover: "#E9EDF4"
    property color controlBorder:          "#D5DBE6"
    property color controlBorderHover:     "#93B0EA"
    property color switchTrackOff:         "#CBD2DE"
    property color switchHandle:           "#FFFFFF"

    property color diffRemovedBg:       "#FEF2F2"
    property color diffAddedBg:         "#F0FDF4"
    property color diffRemovedBorder:   "#FECACA"
    property color diffAddedBorder:     "#BBF7D0"

    // Windows Header Buttons
    property color windowsMinimize:     "#4A9EFF"
    property color windowsMaximize:     "#FFB84D"
    property color windowsClose:        "#FF5555"

    // Header indicator
    property color resizeHandle:        primaryBorder
    property color resizeHandlePressed: "#A9B2C3"

    property color selectedText:            "#FFFFFF"
    property color onAccentText:            "#FFFFFF"
    property color onWarningText:           "#363636"
    property color onSuccessText:           "#363636"
    property color onErrorText:             "#FFFFFF"
    property color onInfoText:              "#363636"
    property color onBadgeText:             "#363636"
    
    property color defaultBackground:       "#FEF6E0"
    property color defaultHoverBackground:  "#FDEBB8"
    
    property color iconOnSurface:           "#8B94A7"
    property color iconOnDefault:           "#92610E"

    property color userInfoSelectedBackground: Qt.rgba(59 / 255, 130 / 255, 246 / 255, 0.1)

    property color pluginBadgeBackground:   "#1A2563EB"
    property color pluginBadgeBorder:       "#402563EB"
    property color pluginBadgeText:         "#1D4FD8"

    property color repoSelectectedItem:     "#262563EB"
    
    // User Profile Level Badge Colors (darker shades for white text readability in light mode)
    property color levelSystemBadge:        "#16A34A"
    property color levelGlobalBadge:        "#0891B2"
    property color levelLocalBadge:         "#D97706"
    property color levelWorktreeBadge:      "#DC2626"
    property color levelAppBadge:           "#4F46E5"
    
    // Notification colors (light theme)
    property color notificationInfo:            "#EFF6FF"
    property color notificationInfoBorder:      "#BFDBFE"
    property color notificationInfoIcon:        "#2563EB"

    property color notificationSuccess:         "#F0FDF4"
    property color notificationSuccessBorder:   "#BBF7D0"
    property color notificationSuccessIcon:     "#16A34A"

    property color notificationWarning:         "#FFFBEB"
    property color notificationWarningBorder:   "#FDE68A"
    property color notificationWarningIcon:     "#D97706"

    property color notificationError:           "#FEF2F2"
    property color notificationErrorBorder:     "#FECACA"
    property color notificationErrorIcon:       "#DC2626"

    property color notificationInfoText:        "#1E3A8A"
    property color notificationSuccessText:     "#14532D"
    property color notificationWarningText:     "#78350F"
    property color notificationErrorText:       "#7F1D1D"

    property color notificationBadge:           "#DC2626"
    property color notificationBadgeText:       "#FFFFFF"

    property color repoItemStatusPendingBg:     "#FEF3C7"
    property color repoItemStatusPendingText:   "#92400E"
    property color repoItemStatusFetchingBg:    "#DBEAFE"
    property color repoItemStatusFetchingText:  "#1E40AF"
    property color repoItemStatusPullingBg:     "#E0F2FE"
    property color repoItemStatusPullingText:   "#0369A1"
    property color repoItemStatusDoneBg:        "#DCFCE7"
    property color repoItemStatusDoneText:      "#166534"
    property color repoItemStatusDirtyBg:       "#FFEDD5"
    property color repoItemStatusDirtyText:     "#9A3412"
    property color repoItemStatusConflictBg:    "#FEE2E2"
    property color repoItemStatusConflictText:  "#991B1B"
    property color repoItemStatusCanceledBg:    "#FEE2E2"
    property color repoItemStatusCanceledText:  "#991B1B"
    property color repoItemStatusPATBg:         "#E0E7FF"
    property color repoItemStatusPATText:       "#3730A3"

    // Conflict marker backgrounds
    property color conflictOursBg:          "#EFF6FF"
    property color conflictOursLabel:       "#1D4ED8"
    property color conflictTheirsBg:        "#F5F3FF"
    property color conflictTheirsLabel:     "#6D28D9"

    property color conflictCardOpenBorder:  "#D97706"
    property color conflictCardOpenStrip:   "#FFFBEB"
    property color conflictCardOpenLabel:   "#92400E"
    property color conflictCardDoneBorder:  "#16A34A"
    property color conflictCardDoneStrip:   "#F0FDF4"
    property color conflictCardDoneLabel:   "#15803D"

    property color lineNumberColor:         "#8B94A7"
    property color conflictMarker:          "#DC2626"

    property color conflictStatusConflictColor  :  "#DC2626"
    property color conflictStatusModifiedColor  :  "#D97706"
    property color conflictStatusAddedColor     :     "#16A34A"

    // Scrollbars — translucent so whatever sits in the strip behind them stays readable
    property color scrollBarHandle:         "#40475569"
    property color scrollBarHandleHover:    "#66475569"
    property color scrollBarHandlePressed:  "#8C475569"
    property color scrollBarTrack:          "transparent"
    property color scrollBarTrackHover:     "#0F475569"

    // Scrollbar minimap of where a diff's changes sit
    property color diffMarkerAdded:         "#16A34A"
    property color diffMarkerRemoved:       "#DC2626"
    property color diffMarkerModified:      "#D97706"

    property color conflictFileSelectedBg:  "#1A2563EB"
    property color conflictSectionLabel:    "#6B7488"
    property color conflictProgressTrack:   "#E3E8F0"
    property color conflictProgressFiles:   "#2563EB"
    property color conflictProgressChunks:  "#16A34A"
    property color conflictDestructive:     "#DC2626"
    property color conflictAssistAccent:    "#B45309"

    property color rebaseActionPick:       "#64748B"
    property color rebaseActionPickOnMenu: "#475569"
    property color rebaseActionReword:     "#2563EB"
    property color rebaseActionSquash:     "#7C3AED"
    property color rebaseActionFixup:      "#DB2777"
    property color rebaseActionEdit:       "#B45309"
    property color rebaseActionDrop:       "#DC2626"

    // Interactive rebase status colors
    property color rebaseStatusPending:    mutedText
    property color rebaseStatusInProgress: "#D97706"       // warm orange
    property color rebaseStatusRebased:    "#16A34A"       // dark green
    property color rebaseStatusConflict:   "#DC2626"       // deep red
    property color rebaseStatusSkipped:    mutedText       // dimmed

    // Plugins page colors
    property color updateButton: "#16A34A"
    property color compatible:   "#16A34A"   // Green
    property color incompatible: "#DC2626"   // Red

    property color pluginPageBackground:       "#F4F6FA"
    property color pluginPanelBackground:      "#FFFFFF"
    property color pluginPanelBorder:          "#E1E6EE"
    property color pluginCardBackground:       "#FFFFFF"
    property color pluginCardBorder:           "#E1E6EE"
    property color pluginCardFooterBorder:     "#EDF0F5"
    property color pluginDivider:              "#E6EAF1"
    property color pluginSectionLabel:         "#646E82"
    property color pluginSectionMetaText:      "#8B94A7"
    property color pluginSidebarLabel:         "#8B94A7"
    property color pluginSidebarRowText:       "#465066"
    property color pluginSidebarRowActiveText: "#2563EB"
    property color pluginSidebarRowActiveBg:   "#1A2563EB"
    property color pluginSidebarRowHoverBg:    "#0D2563EB"
    property color pluginCountPillBackground:  "#EDF0F5"
    property color pluginCountPillText:        "#7B8599"
    property color pluginCardTitle:            "#1B2231"
    property color pluginCardMetaText:         "#8B94A7"
    property color pluginCardDescription:      "#566074"
    property color pluginBtnSecondaryBorder:   "#D5DBE6"
    property color pluginBtnSecondaryText:     "#566074"
    property color pluginToggleTrackOff:       "#D5DBE6"
    property color pluginToggleTrackOffBorder: "#B9C2D2"
    property color pluginToggleThumbOff:       "#FFFFFF"

    // Terminal colors
    property color terminalBackground:  "#F7F9FC"
    property color terminalUserAndHost: "#15803D"
    property color terminalWorkDir:     "#1D4ED8"
    property color terminalCommand:     "#232A3A"

    property color contextMenuBackground: "#FFFFFF"
    property color contextMenuBorder:     "#D5DBE6"
    property color contextMenuSeparator:  "#E6EAF1"
    property color contextMenuHover:      "#EEF2F9"
    property color contextMenuDanger:     "#DC2626"

    property color branchSelectedAccent:  "#2563EB"

    // Committing page header
    property color branchAccent:    branchSelectedAccent   // #2563EB
    property color chipBorder:      primaryBorder          // #D7DCE5
    property color chipText:        secondaryText          // #5F6A7A
    property color forcePushText:   "#DC2626"              // distinct warning red
    property color forcePushBorder: "#4DEF4444"            // semi‑transparent red

    // File list sections
    property color countBadgeText:      secondaryText          // #5F6A7A
    property color countBadgeBg:        cardBackground         // #E8E8E8
    property color sectionHeaderBg:     surfaceLight           // #F3F3F3
    property color sectionLabel:        "#7B8599"
    property color emptyCircleBg:       surfaceLight           // #F3F3F3
    property color emptyCircleBorder:   "#DCE1EA"
    property color emptyStateText:      "#8B94A7"
    property color emptyStateSubText:   "#B3BBCB"

    // Section actions and badge
    property color actionIconIdle:        "#8B94A7"
    property color stashAmber:            "#D97706"
    property color stageGreen:            "#16A34A"
    property color discardRed:            "#DC2626"
    property color countText:             "#B45309"
    property color countBg:               "#12FBBF24"

    // Action pill (row-level)
    property color actionPillBg:          surfaceLight         // #F3F3F3
    property color actionPillBorder:      primaryBorder        // #D7DCE5
    property color openBlue:              branchAccent         // #2563EB

    // Row-level
    property color filePathText:         "#5F6A82"
    property color rowHoverBg:           "#F0F3F8"

    // Diff view header line counts
    property color diffAddedCount:       "#16A34A"
    property color diffRemovedCount:     "#DC2626"

    // Commit Panel
    property color commitButton:         branchAccent         // #2563EB
    property color fileBrowserRowHoverBg: Qt.rgba(0,0,0,0.04)
    property color fileBrowserSearchBg:  Qt.rgba(0,0,0,0.05)
    property color headerBackground:            "#F1F4F9"
    property color headerButtonBackground:      "#E7EBF2"
    property color headerButtonBackgroundHover: "#DCE2EC"
    property color headerButtonBorder:          "#D5DBE6"

    property color segmentedSelected:           "#FFFFFF"

    property color utilitiesPanelBackground:            controlBackground
    property color utilitiesPanelBorder:                primaryBorder
    property color utilitiesPanelScrollBar:             controlBorder
    property color utilitiesPanelScrollBarHover:        mutedText

    property color utilitiesFilterBackground:           primaryBackground
    property color utilitiesFilterBorder:               controlBorder
    property color utilitiesFilterBorderFocus:          accent
    property color utilitiesFilterText:                 foreground
    property color utilitiesFilterPlaceholder:          placeholderText

    property color utilitiesCardBackground:             primaryBackground
    property color utilitiesCardSeparator:              primaryBorder

    property color utilitiesCardHeaderBackground:       controlBackground
    property color utilitiesCardHeaderHoverBackground:  controlBackgroundHover
    property color utilitiesCardHeaderIcon:             accent
    property color utilitiesCardTitle:                  foreground
    property color utilitiesCardChevron:                mutedText

    property color utilitiesCardBadgeBackground:        primaryBackground
    property color utilitiesCardBadgeBorder:            controlBorder
    property color utilitiesCardBadgeText:              secondaryText

    property color utilitiesSegmentTrackBackground:     secondaryBorder
    property color utilitiesSegmentTrackBorder:         controlBorder
    property color utilitiesSegmentHoverBackground:     controlBackground
    property color utilitiesSegmentSelectedBackground:  segmentedSelected
    property color utilitiesSegmentText:                secondaryText
    property color utilitiesSegmentSelectedText:        foreground

    property color utilitiesSurfaceBackground:          controlBackground
    property color utilitiesSurfaceBorder:              secondaryBorder
    property color utilitiesHintText:                   secondaryText

    property color utilitiesRowBackground:              primaryBackground
    property color utilitiesRowHoverBackground:         controlBackground
    property color utilitiesRowSelectedBackground:      azureTint
    property color utilitiesRowBorder:                  controlBorder
    property color utilitiesRowSelectedIndicator:       accent
    property color utilitiesRowText:                    foreground
    property color utilitiesRowSelectedText:            accent
    property color utilitiesRowIcon:                    secondaryText
    property color utilitiesRowIconAccent:              accent
    property color utilitiesRowMetaText:                secondaryText
    property color utilitiesRowSubText:                 mutedText
    property color utilitiesRowMissingText:             error
    property color utilitiesEmptyStateText:             mutedText

    property color utilitiesFieldLabel:                 secondaryText
    property color utilitiesInputBackground:            controlBackground
    property color utilitiesInputHoverBackground:       controlBackgroundHover
    property color utilitiesInputBorder:                controlBorder
    property color utilitiesInputBorderFocus:           accent
    property color utilitiesInputText:                  foreground
    property color utilitiesInputPlaceholder:           placeholderText
    property color utilitiesInputPopupBackground:       primaryBackground

    property color utilitiesCheckBoxAccent:             accent
    property color utilitiesCheckBoxText:               foreground

    property color utilitiesPickerButtonBackground:      "transparent"
    property color utilitiesPickerButtonHoverBackground: accentHover
    property color utilitiesPickerButtonBorder:          controlBorder
    property color utilitiesPickerButtonIcon:            secondaryText
    property color utilitiesPickerButtonIconHover:       onAccentText

    property color dashedButtonText:                    secondaryText
    property color dashedButtonBorder:                  controlBorder
    property color dashedButtonTextHover:               accent
    property color dashedButtonBorderHover:             accent
    property color dashedButtonBackgroundHover:         accentWash
    property color dashedButtonTextDanger:              error
    property color dashedButtonBorderDanger:            error

    property color utilitiesActionIcon:                 secondaryText
    property color utilitiesActionIconActive:           accent
    property color utilitiesActionIconWarning:          "#B45309"
    property color utilitiesActionIconDanger:           error

    // stash card
    property color stashCardBackground:                  utilitiesRowBackground
    property color stashCardBorder:                      utilitiesRowBorder
    property color stashCardBorderHover:                 controlBorderHover
    property color stashCardBorderSelected:              accent
    property color stashCardRef:                         utilitiesRowSubText
    property color stashCardMessage:                     utilitiesRowText
    property color stashCardTime:                        utilitiesRowSubText
    property color stashCardMeta:                        utilitiesRowMetaText
    property color stashCardMetaSeparator:               utilitiesRowSubText

    // stash card actions
    property color stashActionText:                      accent
    property color stashActionBorder:                    accent
    property color stashActionHoverBackground:           accentWash
    property color stashActionFilledText:                onAccentText
    property color stashActionFilledBackground:          accent
    property color stashActionFilledHoverBackground:     accentHover
    property color stashActionDangerText:                error
    property color stashActionDangerBorder:              error
    property color stashActionDangerHoverBackground:     paleCoralMist

    property color stashDiffLink:                        utilitiesRowMetaText
    property color stashDiffLinkHover:                   accent

    // Popup
    property color popupBackground:                  "#FFFFFF"           
    property color popupBorder:                      primaryBorder       
    property color popupHeaderSeparator:             primaryBorder
    property color popupTitleText:                   foreground       
    property color popupCloseButton:                 mutedText
    property color popupCloseButtonHover:            foreground
    property color popupSectionLabel:                secondaryText 
    property color popupInputBackground:             controlBackground
    property color popupInputBorder:                 controlBorder
    property color popupInputBorderFocus:            accent
    property color popupInputText:                   foreground
    property color popupChipBackground:              controlBackground
    property color popupChipBorder:                  controlBorder
    property color popupChipText:                    secondaryText
    property color popupBaseBranchBackground:        controlBackground
    property color popupBaseBranchBorder:            controlBorder
    property color popupBaseBranchText:              secondaryText
    property color popupRadioBorder:                 secondaryText
    property color popupRadioBorderChecked:          accent
    property color popupRadioDot:                    "#FFFFFF"
    property color popupCheckboxBackgroundChecked:   accent
    property color popupCheckboxBorder:              mutedText
    property color popupCheckboxCheckmark:           "#FFFFFF"
    property color popupCheckboxLabelText:           secondaryText
    property color popupCommandPreviewBackground:    controlBackground
    property color popupCommandPreviewBorder:        controlBorder
    property color popupCommandPreviewText:          secondaryText
    property color popupFooterBackground:            controlBackground
    property color popupCreateButtonBackground:      accent
    property color popupCreateButtonText:            "#FFFFFF"
    property color popupCancelButtonBorder:          controlBorder
    property color popupCancelButtonText:            secondaryText

    property color onColorText:                 "#FFFFFF"
    property color scrimColor:                  "#000000"
    property color progressOverlay:             "#CBD2DE"

    // Ghost button hover wash on popups
    property color ghostButtonHoverBackground:  "#142563EB"

    // Navigation rail item that is not selected (non-accent variant)
    property color navItemInactive:             "#8B94A7"

    // Commit graph
    property color graphSelectedRowBg:          "#402563EB"
    property color graphHeadRowBg:              "#33D97706"
    property color graphTagLabel:               "#CA8A04"
    property color graphAvatarBackground:       "#DCE1EA"
    property color graphUncommittedColor:       "#8B94A7"

    // Plugin detail screenshots
    property color pluginPreviewBackground:     "#E9EDF4"
    property color pluginThumbBackground:       "#E9EDF4"

    // Fallback identity color for repositories without one
    property color repositoryAvatarDefault:     "#B9FAB9"

    // Embedded terminal chrome (terminal is dark in both themes)
    property color terminalScrollBar:           "#C3CAD7"
    property color terminalScrollBarHover:      "#A9B2C3"
    property color terminalScrollBarPressed:    "#8B94A7"
    property color terminalHeaderBorder:        "#DCE1EA"

    // Terminal ANSI palette (SGR 31-37)
    property color terminalAnsiRed:             "#B91C1C"
    property color terminalAnsiGreen:           "#15803D"
    property color terminalAnsiYellow:          "#A16207"
    property color terminalAnsiBlue:            "#1D4ED8"
    property color terminalAnsiMagenta:         "#7E22CE"
    property color terminalAnsiCyan:            "#0E7490"
    property color terminalAnsiWhite:           "#475569"

    // Diff view text
    property color diffText:                    "#161B26"
    property color diffTextStacked:             "#161B26"
    property color diffRemovedText:             "#991B1B"
    property color diffAddedText:               "#166534"
    property color diffLineNumberText:          "#566074"
    property color popupBodyText:                    secondaryText
    property color popupShadow:                      "#2E0F172A"
}
