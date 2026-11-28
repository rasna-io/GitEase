import QtQuick

import GitEase

/*! ***********************************************************************************************
 * IdentityGuard
 * Makes sure git knows who is committing before an action that records a name: commit, amend,
 * merge, cherry-pick, rebase, stash and annotated tags. When git has no name and email, it opens
 * the "Who is making this commit?" dialog, and the action runs again once a user is saved.
 *
 * One instance per UiSession, handed to the pages and popups that need it, like GitStateNotifier.
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property UserProfileController userProfileController: null

    property IdentityPromptPopup   prompt:                null

    /* Functions
     * ****************************************************************************************/

    /**
     * Use before an action that always needs a name and email.
     * Returns true when git has one. Otherwise it opens the dialog and returns false; the dialog
     * calls retry() once the user has saved a name and email.
     * \param action What the button should say after "Save and", e.g. "commit" or "stash".
     */
    function check(action, retry) : bool {
        if (root.userProfileController.refreshIdentity().found)
            return true

        root.prompt.ask(action, retry)
        return false
    }

    /**
     * Use with an action's result. Returns true when the action was refused because git has no
     * name and email; the dialog is open then and calls retry() once the user has saved one.
     * The action changed nothing in that case, so retrying it is safe.
     */
    function handle(result, action, retry) : bool {
        if (result.errorCode !== "identityMissing")
            return false

        root.prompt.ask(action, retry)
        return true
    }
}
