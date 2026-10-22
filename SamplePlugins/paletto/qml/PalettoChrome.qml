import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * PalettoChrome
 * Colors and fonts of the Paletto editor. One instance lives in PalettoPage and is passed down
 * to the components as their `chrome` property. They deliberately do not read Style.colors: while the
 * scheme is being edited every token can change, and the editor must stay readable and usable
 * however far the experiment goes. Only the mode (light, soft or dark) is switched, from the base theme.
 * ************************************************************************************************/
QtObject {
    /* Mode
     * ****************************************************************************************/
    //! "light", "soft" or "dark". Follows the base theme of the palette being edited, not the
    //! edited tokens, so the editor does not change while colors are dragged. Set by PalettoPage.
    property string mode: "light"

    //! Picks the value of the current mode.
    function pick(light, soft, dark) {
        return mode === "dark" ? dark : mode === "soft" ? soft : light
    }

    /* Colors                      light      soft       dark
     * ****************************************************************************************/
    readonly property color page:          pick("#EDEFF4", "#D5D9E2", "#121318")
    readonly property color panel:         pick("#FFFFFF", "#E7E9EF", "#191B22")
    readonly property color panelRaised:   pick("#F2F4F8", "#DDE1E8", "#20232C")
    readonly property color field:         pick("#F6F7FA", "#EEF0F4", "#14161C")
    readonly property color border:        pick("#D8DCE5", "#BCC3D1", "#2C303B")
    readonly property color borderStrong:  pick("#BFC6D4", "#A6AEBF", "#3A3F4D")

    readonly property color rowHover:      pick("#EEF1F7", "#D8DCE5", "#1E2129")
    readonly property color rowSelected:   pick("#DDE7FF", "#C9D6F2", "#243049")

    readonly property color text:          pick("#1A2030", "#1E2433", "#E7E9EF")
    readonly property color textDim:       pick("#4F5C73", "#434D61", "#9CA3B4")
    readonly property color textFaint:     pick("#7A8499", "#667085", "#6C7385")

    readonly property color accent:        pick("#2F5BEA", "#1E4FD0", "#6D8DFF")
    readonly property color accentHover:   pick("#4670F0", "#173FB0", "#839EFF")
    readonly property color accentText:    pick("#FFFFFF", "#FFFFFF", "#0B1020")
    readonly property color success:       pick("#16A34A", "#15803D", "#4ADE80")
    readonly property color warning:       pick("#B45309", "#B45309", "#FBBF24")
    readonly property color danger:        pick("#D42B2B", "#B91C1C", "#FF6B6B")

    readonly property color checkerLight:  pick("#FFFFFF", "#F2F4F7", "#4A4E5B")
    readonly property color checkerDark:   pick("#CDD2DD", "#BCC3D1", "#363945")

    /* Fonts
     * ****************************************************************************************/
    readonly property string fontText:  Style.fontTypes.inter
    readonly property string fontMono:  Style.fontTypes.jetBrainsMono
    readonly property string fontIcons: Style.fontTypes.font6Pro

    readonly property real sizeMicro:   Style.appFont.captionPt
    readonly property real sizeCaption: Style.appFont.smallPt
    readonly property real sizeBody:    Style.appFont.h4Pt
    readonly property real sizeTitle:   Style.appFont.largePt
}
