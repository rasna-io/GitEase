.pragma library

function isGuided(message) {
    return !!message && message.indexOf("\n1. ") !== -1
}

//! Guided failures stay on screen until dismissed. Other failures use a timed toast.
function notifyFailure(notificationController, title, remoteName, errorMessage) {
    if (!notificationController)
        return

    const detail = errorMessage || "Unknown error"
    if (isGuided(detail)) {
        notificationController.error(detail, title, 0, false)
        return
    }

    const prefix = remoteName ? ("Failed for " + remoteName + ": ") : ""
    notificationController.error(prefix + detail, title, 8000)
}
