import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl
import "qrc:/GitEase/Qml/View/Popups"

/*! ***********************************************************************************************
 * RulesDock
 * ************************************************************************************************/


UtilitiesCard {
    id: root

    /* Property Declarations
     * ****************************************************************************************/


    /* Object Properties
     * ****************************************************************************************/
    title: "Rules"
    icon: Style.icons.copy

    RulesPage {
        id: rulePagePop
    }

    content: ColumnLayout {
        spacing: 10

        Button {
            text: "Rules"

            onClicked: {
                rulePagePop.open()
            }
        }

    }

    /* Functions
     * ****************************************************************************************/


}
