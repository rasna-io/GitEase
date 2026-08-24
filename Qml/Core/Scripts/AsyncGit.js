.pragma library
// ====================================================================
// AsyncGit – Callback wrapper around IGitController::callAsync().
// ====================================================================
/*!
 * Every Git controller inherits the async
 * entry point, so anything that can be called synchronously can be called through here instead:
 *
 *     AsyncGit.call(statusController, "status", [], function (result) {
 *         if (result.success)
 *             ...
 *     })
 *
 *     AsyncGit.call(commitController, "getCommits", [200, 0], onDone, onFail)
 *
 * The work runs on the Git worker thread and the callback fires back on the GUI thread. A call
 * whose repository was swapped while it was queued never reaches onDone - it is reported to
 * onFail with the reason "stale", so a slow load for the previous repository cannot repaint the
 * UI after the user has already moved on.
 */


var _pending    = ({})
var _wired      = []

/*!
 * Queue \a method on \a controller.
 * \param args   Array of arguments, or null.
 * \param onDone function(result, method) - called on success.
 * \param onFail function(error, method)  - called when the call could not be queued, could not be resolved, or went stale. Optional.
 */
function call(controller, method, args, onDone, onFail) {
    if (!controller) {
        if (onFail)
            onFail("no controller", method)
        return 0
    }

    _wire(controller)

    var id = controller.callAsync(method, args || [])

    if (!id) {
        if (onFail)
            onFail("could not queue " + method, method)
        return 0
    }

    _pending[id] = { done: onDone, fail: onFail }

    return id
}

/* Internals
 * ******************************************************************************************* */

function _wire(controller) {
    if (_wired.indexOf(controller) !== -1)
        return

    controller.asyncFinished.connect(_onFinished)
    controller.asyncFailed.connect(_onFailed)

    _wired.push(controller)
}

function _onFinished(id, method, result) {
    var entry = _pending[id]
    if (!entry)
        return

    delete _pending[id]

    if (entry.done)
        entry.done(result, method)
}

function _onFailed(id, method, error) {
    var entry = _pending[id]
    if (!entry)
        return

    delete _pending[id]

    if (entry.fail)
        entry.fail(error, method)
}
