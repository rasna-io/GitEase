import QtQuick
import QtQuick.Controls

/*! ***********************************************************************************************
 * RuleSettingsBase
 * Shared base for all per-category rule settings pages (CommitMessageSettings, PushRulesSettings, etc.)
 * Provides the common contract: ruleData in, targetModel/ruleIndex for saving, dirty tracking.
 * ************************************************************************************************/
Flickable {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string ruleColor: ""
    property var ruleData
    property var targetModel
    property int ruleIndex: -1
    property bool isDirty: false
    property bool suppressDirty: false

    /* Object Properties
     * ****************************************************************************************/
    contentWidth: width
    clip: true

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    /* Functions
     * ****************************************************************************************/
    function markDirty() {
        if (!suppressDirty) isDirty = true
    }
}