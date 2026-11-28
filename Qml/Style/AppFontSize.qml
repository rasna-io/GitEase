import QtQuick

/*! ***********************************************************************************************
 * AppFontSize holds application specific font sizes, like default, secondary, teriary, h1 font, etc
 * Note: Font sizes are in PT (pointsize)
 * ************************************************************************************************/
QtObject {
    /* Property Declarations
     * ****************************************************************************************/
    readonly property real minAppFontPt: 10
    readonly property real maxAppFontPt: 15

    //! Default Font pointsize
    property real   defaultPt:          11

    //! Secondary Font pt -> For less important texts
    property real   secondaryPt:        defaultPt * 0.7

    //! Tertiary Font pt -> For least important texts
    property real   tertiaryPt:         defaultPt * 0.55

    //! Extra small Font pt -> For very minor texts
    property real   extraSmallPt:       defaultPt * 0.59

    //! Micro Font pt -> smallest UI text (e.g. badges, dots)
    property real   microPt:            defaultPt * 0.73

    //! Caption Font pt -> For captions/hints below default
    property real   captionPt:          defaultPt * 0.82

    //! Small Font pt -> Slightly below default body text
    property real   smallPt:            defaultPt * 0.91

    //! Medium Font pt -> Slightly above default body text
    property real   mediumPt:           defaultPt * 1.09

    //! H4 Font pt
    property real   h4Pt:               defaultPt

    //! H3 Font pt
    property real   h3Pt:               defaultPt * 1.17

    //! Large Font pt
    property real   largePt:            defaultPt * 1.27

    //! Larger Font pt
    property real   largerPt:           defaultPt * 1.36

    //! H2 Font pt
    property real   h2Pt:               defaultPt * 1.5

    //! Extra large Font pt
    property real   xlPt:               defaultPt * 1.64

    //! H1 Font pt
    property real   h1Pt:               defaultPt * 2.0

    //! Extra extra large Font pt
    property real   xxlPt:              defaultPt * 1.82

    //! Small display Font pt -> large standalone icons/numbers
    property real   displaySmPt:        defaultPt * 2.55

    //! Medium display Font pt
    property real   displayMdPt:        defaultPt * 2.91

    //! Large display Font pt
    property real   displayLgPt:        defaultPt * 3.27

    //! Extra large display Font pt
    property real   displayXlPt:        defaultPt * 3.82

    //! Extra extra large display Font pt -> largest banner/empty-state icons
    property real   display2xlPt:       defaultPt * 4.55
}

