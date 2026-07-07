import QtQuick

/*! ***********************************************************************************************
 * GuideController
 * Manages multi-step UI guide tours.
 *
 * Guide config format:
 *   {
 *     id:   "my_tour",
 *     name: "",  // optional, display name for tutorial-list UI (e.g. Settings → Help); falls
 *                // back to id when omitted
 *     icon: "",  // optional, display icon for the same UI
 *     page: "",  // optional, PageController page id that must be active for this guide's
 *                // targets to exist — used by tutorial-list UI to switch pages before replaying
 *     steps: [
 *       {
 *         targetProvider: function() { return someItem },  // optional, null = no spotlight
 *         icon:           "",
 *         title:          "Step Title",
 *         description:    "What to do here.",
 *         commands:       [],     // optional [{ label, command }, ...], rendered as one
 *                                 // copyable chip per entry (label is optional, e.g. a single
 *                                 // command needs no label: [{ command: "git push" }])
 *         media:          "",     // optional url/path to a gif or image (e.g. "qrc:/...")
 *                                 // illustrating this step, shown in GuideTooltip
 *         showNext:       true,   // defaults true
 *         showBack:       true,   // defaults true for step > 0
 *         showSkip:       true,   // defaults true
 *         isInPopup:      false,  // true = target is inside a Qt Popup (overlay layer)
 *         activationDelay: 0,     // ms to wait before resolving target (for popups that animate open)
 *         onActivate:     function() {},  // fires when step becomes active
 *         onNext:         function() {},  // fires when user clicks Next
 *       }
 *     ]
 *   }
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var appModel:       null
    property var activeGuide:    null
    property int currentStep:    0
    property var activeStepData: null

    /* Private Properties
     * ****************************************************************************************/
    property var _guides:         ({})
    property var _shownIds:       ([])
    property int _registryVersion: 0

    /** Every registered guide, as {id, name, icon, page}, for UI that lists/replays tutorials
     *  (e.g. Settings → Help). `name`/`icon`/`page` come from registerGuide()'s config and are
     *  optional — callers that only care about auto-triggering on hover can omit them. */
    readonly property var catalog: {
        _registryVersion // establish a dependency so this re-evaluates on every registration
        var list = []
        for (var id in _guides) {
            var g = _guides[id]
            list.push({ id: id, name: g.name || id, icon: g.icon || "", page: g.page || "" })
        }
        return list
    }

    /* Signals
     * ****************************************************************************************/
    signal guideStepChanged(var stepData)
    signal guideDismissed()

    property Timer activationTimer: Timer {
        property int pendingIndex: 0
        repeat: false
        onTriggered: root._resolveAndEmit(pendingIndex)
    }

    /* Functions
     * ****************************************************************************************/
    function registerGuide(config) {
        if (!config || !config.id) {
            console.warn("[GuideController] registerGuide: config.id is required")
            return
        }
        _guides[config.id] = config
        root._registryVersion++
    }

    /**
     * Start the guide with the given id if it has not been shown before.
     * Returns true when the guide was triggered.
     */
    function tryShow(id) {
        if (isShown(id))
            return false

        return _start(id)
    }

    /**
     * Start the guide with the given id regardless of whether it has already been shown.
     * Used by the Settings "Help" tab to let users replay any tutorial on demand.
     * Returns true when the guide was triggered.
     */
    function forceShow(id) {
        return _start(id)
    }

    /** Advance to the next step, or dismiss if already on the last step. */
    function next() {
        if (!root.activeGuide) return

        var step = root.activeGuide.steps[root.currentStep]
        if (step && step.onNext) step.onNext()

        if (root.currentStep < root.activeGuide.steps.length - 1) {
            root.currentStep++
            _activateStep(root.currentStep)
        } else {
            dismiss()
        }
    }

    /** Go back to the previous step. */
    function back() {
        if (!root.activeGuide || root.currentStep <= 0) return
        root.currentStep--
        _activateStep(root.currentStep)
    }

    /** Dismiss the guide immediately and mark it as shown. */
    function dismiss() {
        if (!root.activeGuide) return
        activationTimer.stop()

        _markShown(root.activeGuide.id)

        root.activeGuide    = null
        root.currentStep    = 0
        root.activeStepData = null
        root.guideDismissed()
    }

    /** Dismiss whichever tutorial is active and turn guides off entirely, so no further
     *  tutorial (this one or any other) auto-shows again until re-enabled in Settings. */
    function disableGuides() {
        dismiss()

        if (root.appModel && root.appModel.appSettings) {
            root.appModel.appSettings.guidesEnabled = false
            root.appModel.save()
        }
    }

    /** Clear all shown guide records so every guide can appear again. */
    function resetShownGuides() {
        _shownIds = []
        if (root.appModel && root.appModel.appSettings) {
            root.appModel.appSettings.shownGuides = []
            root.appModel.save()
        }
    }

    /** Returns true when the guide with the given id should not be shown.
     *  When guides are globally disabled, all ids are treated as shown so callers
     *  fall through to their normal (non-guide) code path automatically. */
    function isShown(id) {
        if (root.appModel && root.appModel.appSettings && !root.appModel.appSettings.guidesEnabled)
            return true

        if (_shownIds.indexOf(id) !== -1)
            return true

        if (root.appModel && root.appModel.appSettings)
            return root.appModel.appSettings.shownGuides.indexOf(id) !== -1

        return false
    }

    /* Private helpers
     * ****************************************************************************************/
    function _start(id) {
        if (root.activeGuide !== null)
            return false

        var guide = _guides[id]
        if (!guide || !guide.steps || guide.steps.length === 0) {
            console.warn("[GuideController] _start: no guide (or empty steps) for id:", id)
            return false
        }

        root.activeGuide = guide
        root.currentStep = 0
        _activateStep(0)
        return true
    }

    /** Record id as shown, both in-memory and persisted — merging into whatever was already
     *  persisted (e.g. from earlier sessions) rather than overwriting it. */
    function _markShown(id) {
        if (_shownIds.indexOf(id) === -1) {
            _shownIds.push(id)
            _shownIds = _shownIds.slice()
        }

        if (root.appModel && root.appModel.appSettings) {
            var persisted = (root.appModel.appSettings.shownGuides || []).slice()
            if (persisted.indexOf(id) === -1) {
                persisted.push(id)
                root.appModel.appSettings.shownGuides = persisted
                root.appModel.save()
            }
        }
    }

    function _activateStep(index) {
        var step = root.activeGuide.steps[index]
        if (!step)
            return

        if (step.onActivate)
            step.onActivate()

        var delay = step.activationDelay || 0
        if (delay > 0) {
            activationTimer.pendingIndex = index
            activationTimer.interval     = delay
            activationTimer.restart()
        } else {
            _resolveAndEmit(index)
        }
    }

    function _resolveAndEmit(index) {
        if (!root.activeGuide)
            return

        var guide = root.activeGuide
        var step  = guide.steps[index]
        if (!step)
            return

        var target = step.targetProvider ? step.targetProvider() : null

        root.activeStepData = {
            target:      target,
            icon:        step.icon        || "",
            title:       step.title       || "",
            description: step.description || "",
            commands:    step.commands    || [],
            media:       step.media       || "",
            showNext:    step.showNext    !== false,
            showBack:    index > 0 && (step.showBack !== false),
            showSkip:    step.showSkip    !== false,
            stepIndex:   index,
            totalSteps:  guide.steps.length,
            isInPopup:   step.isInPopup   || false
        }

        root.guideStepChanged(root.activeStepData)
    }
}
