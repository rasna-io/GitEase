import QtQuick

/*! ***********************************************************************************************
 * GuideHoverTrigger
 * Drop-in replacement for a bare HoverHandler that registers and shows a guide shortly after its
 * parent item is hovered. Declare it exactly where a HoverHandler would normally go (its hover
 * area is its parent item's bounds, same as any HoverHandler).
 *
 * `stepsFactory` is called lazily (on hover, and once eagerly at creation — see below), so steps
 * that depend on runtime state (compact layout, read-only/chunk mode, per-instance target items)
 * are always built fresh. `guideController.tryShow()` is already a no-op once the guide has been
 * shown, so re-registering on every hover is cheap and safe.
 *
 * Registration also happens eagerly (Component.onCompleted / whenever guideController or guideId
 * changes), not just on hover. This means a guide is listed and playable from the Settings "Help"
 * tab (GuideController.forceShow) as soon as its owning component exists, without requiring the
 * user to have hovered it first.
 *
 * `guideName` / `guideIcon` / `guidePage` are optional display metadata forwarded to
 * GuideController.registerGuide() — they don't affect triggering, only how the guide shows up
 * in tutorial-list UI (Settings → Help). See GuideController's header comment for their meaning.
 *
 * Usage
 *   GuideHoverTrigger {
 *       guideController: root.guideController
 *       guideId:         "my_tour"
 *       guideName:       "My Tour"
 *       guideIcon:       Style.icons.star
 *       stepsFactory:    function() { return [ {...}, {...} ] }
 *   }
 * ************************************************************************************************/
HoverHandler {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    guideController: null
    property string guideId:         ""
    property string guideName:       ""
    property string guideIcon:       ""
    property string guidePage:       ""
    property var    stepsFactory:    null
    property int    delay:           400

    /* Object Properties
     * ****************************************************************************************/
    onHoveredChanged: hovered ? _delayTimer.restart() : _delayTimer.stop()

    // HoverHandler has no default property (it isn't a QQuickItem), so the Timer must be
    // attached via an explicit property assignment rather than declared as a plain child.
    property Timer _delayTimer: Timer {
        interval: root.delay
        repeat:   false
        onTriggered: {
            if (root.hovered)
                root._trigger()
        }
    }

    Component.onCompleted: root._register()
    onGuideControllerChanged: root._register()
    onGuideIdChanged: root._register()

    /* Functions
     * ****************************************************************************************/
    function _register() {
        if (!root.guideController || !root.stepsFactory || root.guideId.length === 0)
            return

        root.guideController.registerGuide({
            id:    root.guideId,
            name:  root.guideName,
            icon:  root.guideIcon,
            page:  root.guidePage,
            steps: root.stepsFactory()
        })
    }

    function _trigger() {
        if (!root.guideController)
            return

        if (root.guideController.isShown(root.guideId))
            return

        root._register()
        root.guideController.tryShow(root.guideId)
    }
}
