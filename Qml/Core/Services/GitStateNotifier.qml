import QtQuick

/*! ***********************************************************************************************
 * GitStateNotifier
 *
 * The single "the repository changed" broadcast of the application.
 *
 * Every controller reports the git command it just ran here.
 * the commands that write to the repository raise repositoryChanged() one time, after a short
 * debounce. Operations that finish without a command of their own - an async fetch/pull/push
 * result, git typed into the embedded terminal - call notifyChanged() directly.
 *
 * Views listen to repositoryChanged() and re-read whatever they display, so no view ever has to
 * know about - or notify - another view.
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! A burst of commands (staging a whole list, dropping every stash, ...) collapses into one
    //! refresh, raised this many milliseconds after the last command of the burst.
    property int debounceInterval: 150

    //! True while the listeners are re-reading the repository. Those reads are reported back here
    //! like any other command, so reporting is ignored for the duration.
    property bool notifying: false

    //! Git verbs that write to the repository. Only these raise repositoryChanged()
    readonly property var mutatingVerbs: [
        "add", "am", "apply", "branch", "bundle", "checkout", "cherry-pick", "clean", "clone",
        "commit", "fetch", "init", "merge", "mv", "pull", "push", "rebase", "remote", "reset",
        "restore", "revert", "rm", "stash", "submodule", "switch", "tag", "worktree"
    ]

    //! Arguments that turn one of the verbs above into a plain read, e.g. "git branch -a".
    readonly property var readOnlyArguments: ({
        "branch": ["-a", "-r", "-l", "-v", "-vv", "--list", "--merged", "--no-merged",
                   "--contains", "--show-current"],
        "bundle": ["list-heads", "verify"],
        "remote": ["-v", "--verbose", "get-url", "show"],
        "stash":  ["list", "show"],
        "tag":    ["-l", "-n", "--list"]
    })

    /* Signals
     * ****************************************************************************************/
    signal repositoryChanged()

    /* Children
     * ****************************************************************************************/
    property Timer debounceTimer: Timer {
        interval: root.debounceInterval
        repeat: false

        onTriggered: root.emitRepositoryChanged()
    }

    /* Functions
     * ****************************************************************************************/
    //! Entry point for every git command a controller runs.
    function reportCommand(command) {
        if (root.isMutating(command))
            root.notifyChanged()
    }

    //! A compiled command can chain steps ("git reset --hard HEAD && git clean -fd");
    //! one writing step makes the whole line a change.
    function isMutating(command) {
        if (root.notifying || !command)
            return false

        let steps = String(command).split("&&")
        for (let i = 0; i < steps.length; ++i) {
            if (root.stepMutates(steps[i]))
                return true
        }

        return false
    }

    //! Determine whether a single Git command modifies the repository
    function stepMutates(step) {
        let tokens = step.trim().split(/\s+/).filter(token => token.length > 0)
        if (tokens.length === 0 || tokens[0] !== "git")
            return false

        // Step over git's own options to reach the verb, e.g. "git -C <path> rev-parse".
        let index = 1
        while (index < tokens.length && tokens[index].startsWith("-")) {
            if (tokens[index] === "-C" || tokens[index] === "-c")
                ++index
            ++index
        }

        if (index >= tokens.length)
            return false

        let verb = tokens[index]
        if (root.mutatingVerbs.indexOf(verb) === -1)
            return false

        let readOnly = root.readOnlyArguments[verb]
        if (readOnly) {
            let subcommand = tokens[index + 1]
            if (subcommand !== undefined && !subcommand.startsWith("-") && readOnly.indexOf(subcommand) !== -1)
                return false

            for (let i = index + 1; i < tokens.length; ++i) {
                if (tokens[i].startsWith("-") && readOnly.indexOf(tokens[i]) !== -1)
                    return false
            }
        }

        return true
    }

    //! Entry point for changes that carry no command of their own.
    function notifyChanged() {
        if (root.notifying)
            return

        root.debounceTimer.restart()
    }

    function emitRepositoryChanged() {
        root.notifying = true
        try {
            root.repositoryChanged()
        } finally {
            root.notifying = false
        }
    }
}
