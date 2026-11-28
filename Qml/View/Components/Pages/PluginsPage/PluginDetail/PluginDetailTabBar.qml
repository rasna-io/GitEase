import QtQuick
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailTabBar
 * Row of tabs. Each tab is described by { id, label, count } (count < 0 hides the pill).
 * ************************************************************************************************/
RowLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    tabs: []
    property string currentTab: ""
    property color  tint: Style.colors.accent

    /* Signals
     * ****************************************************************************************/
    signal tabSelected(string tabId)

    /* Object Properties
     * ****************************************************************************************/
    spacing: Style.dp(24)

    /* Children
     * ****************************************************************************************/
    Repeater {
        model: root.tabs

        delegate: PluginDetailTab {
            label: modelData.label
            count: modelData.count
            active: root.currentTab === modelData.id
            tint: root.tint

            onClicked: root.tabSelected(modelData.id)
        }
    }

    Item {
        Layout.fillWidth: true
    }
}
