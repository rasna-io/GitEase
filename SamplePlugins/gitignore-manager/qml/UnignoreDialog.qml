import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * UnignoreDialog
 * Confirms removing the rules that ignore the selected items. Lists every rule with the line it
 * is on; rules that live outside the root .gitignore are shown but cannot be removed here.
 * ************************************************************************************************/
GitignoreDialog {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! Result of GitignoreEngine::planUnignore(): { rules, unresolved }.
    property var plan:      null
    property int itemCount: 0

    readonly property var rules:         plan ? plan.rules : []
    readonly property int editableCount: rules.filter(r => r.editable).length

    /* Signals
     * ****************************************************************************************/
    signal confirmed()

    /* Object Properties
     * ****************************************************************************************/
    contentSpacing: Style.dp(12)

    /* Children
     * ****************************************************************************************/
    Text {
        Layout.fillWidth: true
        text: "Stop ignoring " + root.itemCount + " item(s)"
        wrapMode: Text.WordWrap
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.largePt
        font.weight: Font.DemiBold
        color: Style.colors.pluginCardTitle
    }

    Text {
        Layout.fillWidth: true
        text: "These rules currently ignore your selection. Removing a rule also affects every other file it matches."
        wrapMode: Text.WordWrap
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.captionPt
        color: Style.colors.pluginCardDescription
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, Style.dp(260))
        clip: true
        spacing: Style.dp(6)
        boundsBehavior: Flickable.StopAtBounds
        model: root.rules

        ScrollBar.vertical: ScrollBar {}

        delegate: UnignoreRuleRow {
            required property var modelData

            width: ListView.view.width - Style.dp(10)
            rule: modelData
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.plan !== null && root.rules.length === 0
        text: "No rule in the repository matches the selection."
        wrapMode: Text.WordWrap
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.captionPt
        color: Style.colors.warning
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.dp(8)

        Item { Layout.fillWidth: true }

        GitignoreButton {
            text: "Cancel"
            onClicked: root.close()
        }

        GitignoreButton {
            variant: "primary"
            enabled: root.editableCount > 0
            text: "Remove " + root.editableCount + " rule(s)"
            onClicked: root.confirmed()
        }
    }
}
