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

    //! Space kept free on the right for the scrollbar plus breathing room.
    readonly property int scrollGutter: 20
    readonly property real contentAvailableWidth: width - scrollGutter

    /* Object Properties
     * ****************************************************************************************/
    contentWidth: width
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    bottomMargin: 16

    ScrollBar.vertical: RuleScrollBar {}

    /* Functions
     * ****************************************************************************************/
    function markDirty() {
        if (!suppressDirty) isDirty = true
    }
}
