import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * OpenRepositoryContent
 * Repository Selection
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var controller: null

    RepositorySelector {
        anchors.fill: parent
        showDescription: true
        descriptionText: "Choose how you want to get started with your Git repository"

        onRepositorySelected: function(name, path) {
            // Handle repository selection
        }
    }
}

