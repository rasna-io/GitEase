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
    property GuideController guideController: null

    /* Object Properties
     * ****************************************************************************************/
    title: "Rebase"
    icon: Style.icons.copy

    RulesPage {
        id: rulePagePop
    }

    content: ColumnLayout {
        spacing: 10

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "rules_dock_tutorial"
            guideName: "Organization Rules"
            guideIcon: Style.icons.copy
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return root },
                        icon: Style.icons.copy,
                        title: "Organization Rules Dock",
                        description: "Configure and enforce commit message, branch naming, and push rules. Click the header to expand this dock if it's collapsed.",
                        isInPopup: false,
                        activationDelay: 300,
                        onActivate: function() { root.collapsed = false }
                    },
                    {
                        targetProvider: function() { return content.children[1] },
                        icon: Style.icons.settings,
                        title: "Open Rules Settings",
                        description: "Click to open the full rules configuration page where you can define commit message patterns, branch naming conventions, and push restrictions."
                    }
                ]
            }
        }

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
