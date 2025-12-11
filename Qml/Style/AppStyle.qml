pragma Singleton

import QtQml 2.11
import QtQuick

QtObject {
    id: root

    property real width: 1920

    property real height: 1080

    property real   scaleFactor: Math.min((width / 1920), (height / 1080))

    readonly property Colors  colors : Colors{}

    readonly property Icons  icons : Icons{}


    //! Font sizes
    readonly property AppFontSize   appFont:        AppFontSize {
        defaultPt: 16 * root.scaleFactor
    }
    readonly property FontIconSize  fontIconSize:   FontIconSize {
        scaleFactor: root.scaleFactor
    }

    function dp( value ){
        return value
    }
}
