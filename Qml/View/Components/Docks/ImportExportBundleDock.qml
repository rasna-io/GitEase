import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * ImportExportBundleDock
 * show import export bundle form
 * ************************************************************************************************/
Item {
    id : root

    property BranchController branchController: null
    property BundleController bundleController: null

    /* Property Declarations
     * ****************************************************************************************/

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/
    ImportExportBundle {
        anchors.fill: parent

        branchController: root.branchController
        bundleController: root.bundleController
    }

    /* Functions
     * ****************************************************************************************/
}
