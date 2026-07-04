import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * UserInfoSelectionPopup
 * ************************************************************************************************/
IPopup {
    id: root

    property UserProfileController              userProfileController

    /* Guide target aliases — resolved after popup content is instantiated */
    readonly property alias guideAddButton:    selectorItem.guideAddButton
    readonly property alias guideProfilesList: selectorItem.guideProfilesList

    /* Property Declarations
     * ****************************************************************************************/

    /* Signals
     * ****************************************************************************************/

    /* Object Properties
     * ****************************************************************************************/
    width: 400
    height: parent.height / 2
    padding: 20

    /* Children
     * ****************************************************************************************/
    background: Rectangle {
        radius: 4
        color: Style.colors.primaryBackground
        border.width: 1
        border.color: Style.colors.primaryBorder
    }

    contentItem: UserInfoSelector {
        id: selectorItem
        userProfileController: root.userProfileController
    }
}
