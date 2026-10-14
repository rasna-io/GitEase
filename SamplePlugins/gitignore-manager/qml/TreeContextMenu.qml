import QtQuick
import QtQuick.Controls

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * TreeContextMenu
 * The app's context menu for the trees: whatever the clicked item offers, then "Expand all" and
 * "Collapse all". Those two are only enabled when they would change something: nothing to expand
 * when every group is open, nothing to collapse when every group is closed.
 *
 *   treeMenu.openFor(eventPoint.scenePosition, [{ text, icon, enabled, action }], canExpand, canCollapse)
 * ************************************************************************************************/
ContextMenu {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string expandText:   "Expand all"
    property string collapseText: "Collapse all"

    /* Signals
     * ****************************************************************************************/
    signal expandAllRequested()
    signal collapseAllRequested()

    /* Functions
     * ****************************************************************************************/
    /*!
     * Shows the menu at the window position \a scenePosition. \a entries are the actions of the
     * clicked item (may be empty); the expand / collapse entries are appended.
     */
    function openFor(scenePosition, entries, canExpand, canCollapse) {
        const model = entries.slice()
        if (model.length > 0)
            model.push({ separator: true })

        model.push({ text: expandText, icon: Style.icons.caretDown, enabled: canExpand,
                     action: function() { root.expandAllRequested() } })
        model.push({ text: collapseText, icon: Style.icons.caretUp, enabled: canCollapse,
                     action: function() { root.collapseAllRequested() } })
        menuModel = model

        const pos = Overlay.overlay.mapFromItem(null, scenePosition.x, scenePosition.y)
        root.x = pos.x
        root.y = pos.y
        open()
    }

    /* Object Properties
     * ****************************************************************************************/
    parent: Overlay.overlay
    width: Style.dp(250)
}
