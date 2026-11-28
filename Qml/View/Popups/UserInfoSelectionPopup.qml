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
    width: 450
    height: Math.min((parent ? parent.height - 60 : 720), selectorItem.implicitHeight)
    padding: 0

    /* Children
     * ****************************************************************************************/
    background: Rectangle {
        radius: 12
        color: Style.colors.primaryBackground
        border.width: 1
        border.color: Style.colors.primaryBorder
    }

    contentItem: UserInfoSelector {
        id: selectorItem
        userProfileController: root.userProfileController

        onCloseRequested: root.close()
    }

    onClosed: selectorItem.closeForm()
    onOpened: selectorItem.closeForm()
}
