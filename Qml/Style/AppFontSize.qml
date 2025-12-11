import QtQuick

/*!
 * AppFontSize holds application specific font sizes, like default, secondary, teriary, h1 font, etc
 * Note: Font sizes are in PT (pointsize)
 */
QtObject {
    //* Property Declarations
    //* ************************************/

    //! Default Font pointsize
    property real   defaultPt:          11

    //! Secondary Font pt -> For less important texts
    property real   secondaryPt:        defaultPt * 0.7

    //! Tertiary Font pt -> For least important texts
    property real   tertiaryPt:         defaultPt * 0.55

    //! Extra small Font pt -> For very minor texts
    property real extraSmallPt:         6.5

    //! H4 Font pt
    property real   h4Pt:               defaultPt

    //! H3 Font pt
    property real   h3Pt:               defaultPt * 1.17

    //! H2 Font pt
    property real   h2Pt:               defaultPt * 1.5

    //! H1 Font pt
    property real   h1Pt:               defaultPt * 2.0
}

