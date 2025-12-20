import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SetupProfileContent
 * Second step of welcome flow - Profile Setup
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var controller: null

    SetupProfileForm {
        anchors.fill: parent
        showHint: true
    }
}

