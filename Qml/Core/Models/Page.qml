import QtQuick
import QtQuick.Controls

import GitEase
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * Page
 * Data model representing a application page with id, title, and etc.
 * ************************************************************************************************/

QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string id: ""
    property string title: "Page"

    // QML file to load for this page (qrc:/...)
    property url source: ""

    // Icon glyph (usually from Style.icons.*)
    property string icon: ""
}


