import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RulesDock — compact utilities-card entry point for Organization Rules.
 * Full configuration lives on the Rules page registered by this plugin.
 * ************************************************************************************************/

UtilitiesCard {
    id: root

    property GuideController guideController: null

    title: "Rules"
    icon: Style.icons.rules

    content: ColumnLayout {
        spacing: 10

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "rules_dock_tutorial"
            guideName: "Organization Rules"
            guideIcon: Style.icons.rules
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return root },
                        icon: Style.icons.rules,
                        title: "Organization Rules Dock",
                        description: "Commit-message and workflow rules are configured on the Rules page in the navigation rail.",
                        isInPopup: false,
                        activationDelay: 300,
                        onActivate: function() { root.collapsed = false }
                    }
                ]
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Open the Rules page in the navigation rail to add, import, or export organization rules for this repository."
            font.pixelSize: Style.appFont.defaultPt
            font.family: Style.fontTypes.inter
            color: Style.colors.utilitiesHintText
        }
    }
}
