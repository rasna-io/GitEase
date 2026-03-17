import QtQuick

QtObject{
    // Primary colors
    property color primaryBackground:   "#FDFDFD"
    property color secondaryBackground: "#F9F9F9"
    property color foreground:          "#363636"
    property color secondaryForeground: "#FDFDFD"
    property color accent:              "#074E96"
    property color accentHover:         "#0C64BE"
    property color error:               "#DC3545"
    property color warning:             "#FFA500"
    property color disabledButton:      "#9D9D9D"

    property color navButton:           "#F3F3F3"
    property color hoverTitle:          "#E8E8E8"
    property color textButton:          "#FDFDFD"

    
    // Files Status
    property color addedFile:           "#B9FAB9"
    property color deletededFile:       "#FF9898"
    property color modifiediedFile:     "#FFF398"
    property color renamedFile:         "#aafff8"
    property color untrackedFile:       "#990000ff"

    // Text colors
    property color secondaryText:       "#5F6A7A"
    property color mutedText:           "#9D9D9D"
    property color titleText:           "#000000"
    property color descriptionText:     "#777272"
    property color hintText:            "#484848"
    property color placeholderText:     "#C9C9C9"

    property color voidStripe:          "#f4f4f4"
    property color editorBackgroound:   "#fcfcfc"
    property color editorForeground:    "#565656"
    property color linePanelBackgroound:"#f6f6f6"
    property color linePanelForeground: "#666666"
    
    // Surface & Background colors
    property color cardBackground:      "#E8E8E8"
    property color surfaceLight:        "#F3F3F3"
    property color surfaceMuted:        "#D9D9D9"
    property color hintBackground:      "#DEE5EB"
    
    // Border colors
    property color primaryBorder:       "#D7DCE5"
    property color secondaryBorder:     "#E7ECF5"

    property color diffRemovedBg:       "#FDECEC"
    property color diffAddedBg:         "#ECFDF3"
    property color diffRemovedBorder:   "#F5C2C7"
    property color diffAddedBorder:     "#A6E9C6"

    // Windows Header Buttons
    property color windowsMinimize:     "#4A9EFF"
    property color windowsMaximize:     "#FFB84D"
    property color windowsClose:        "#FF5555"

    // Header indicator
    property color resizeHandle:        "#E8E8E8"
    property color resizeHandlePressed: "#A0a0a0"

    property color selectedText:            "#FFFFFF"
    property color onAccentText:            "#FFFFFF"
    property color onWarningText:           "#363636"
    property color onSuccessText:           "#363636"
    property color onErrorText:             "#363636"
    property color onInfoText:              "#363636"
    property color onBadgeText:             "#363636"
    
    property color defaultBackground:       "#FFF4D9"
    property color defaultHoverBackground:  "#FFE8B3"
    
    property color iconOnSurface:           "#9D9D9D"
    property color iconOnDefault:           "#8B6914"

    property color userInfoSelectectedItem: "#44074E96"

    property color repoSelectectedItem:     "#44074E96"
    
    // User Profile Level Badge Colors (darker shades for white text readability in light mode)
    property color levelSystemBadge:        "#2D8B3D"
    property color levelGlobalBadge:        "#2D8B8B"
    property color levelLocalBadge:         "#B89A2D"
    property color levelWorktreeBadge:      "#B83D3D"
    property color levelAppBadge:           "#3D3DB8"
    
    // Notification colors (light theme)
    property color notificationInfo:            "#E3F2FD"
    property color notificationInfoBorder:      "#90CAF9"
    property color notificationInfoIcon:        "#1976D2"

    property color notificationSuccess:         "#E8F5E9"
    property color notificationSuccessBorder:   "#81C784"
    property color notificationSuccessIcon:     "#388E3C"

    property color notificationWarning:         "#FFF3E0"
    property color notificationWarningBorder:   "#FFB74D"
    property color notificationWarningIcon:     "#F57C00"

    property color notificationError:           "#FFEBEE"
    property color notificationErrorBorder:     "#E57373"
    property color notificationErrorIcon:       "#D32F2F"

    property color notificationInfoText:        "#0D2A4D"
    property color notificationSuccessText:     "#0F2E17"
    property color notificationWarningText:     "#3A2300"
    property color notificationErrorText:       "#4D0D12"

    property color notificationBadge:           "#ef4444"
    property color notificationBadgeText:       "#FFFFFF"

    property color repoItemStatusPendingBg:     "#FEF3C7"
    property color repoItemStatusPendingText:   "#92400E"
    property color repoItemStatusFetchingBg:    "#DBEAFE"
    property color repoItemStatusFetchingText:  "#1E40AF"
    property color repoItemStatusPullingBg:     "#E0F2FE"
    property color repoItemStatusPullingText:   "#0369A1"
    property color repoItemStatusDoneBg:        "#DCFCE7"
    property color repoItemStatusDoneText:      "#166534"
    property color repoItemStatusDirtyBg:       "#FEF9C3"
    property color repoItemStatusDirtyText:     "#78350F"
    property color repoItemStatusConflictBg:    "#FEE2E2"
    property color repoItemStatusConflictText:  "#991B1B"
    property color repoItemStatusCanceledBg:    "#FEE2E2"
    property color repoItemStatusCanceledText:  "#991B1B"
    property color repoItemStatusPATBg:         "#90CAF9"
    property color repoItemStatusPATText:       "#43525D"

    // Conflict marker backgrounds
    property color conflictMarkerStartBg:   "#d4b89c"
    property color conflictMarkerEndBg:     "#d4b89c"
    property color conflictOursBg:          "#e6f4d9"
    property color conflictTheirsBg:        "#d9e8f5"
    property color conflictSeparatorBg:     "transparent"
    property color conflictMarkerText:      "#666666"
    property color lineNumberColor:         "#6e7681"
}
