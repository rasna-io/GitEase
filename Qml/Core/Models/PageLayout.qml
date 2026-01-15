import QtQuick
import QtQuick.Controls

import GitEase
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * Page Layout
 * Data model representing a application page Layout with id, docks, and etc.
 * ************************************************************************************************/

QtObject {
    id: root

    property string pageTitle: ""

    // Array of dock layout items.
    // Each item is expected to look like:
    // {
    //   key: "Commit Graph Dock",
    //   position: Enums.DockPosition.Left|Top|Right|Bottom|-1,
    //   isFloating: true|false
    // }
    property var docks: []
}
