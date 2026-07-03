.pragma library

// ====================================================================
// CommitGraphMenuBuilder – builds the context‑menu data model
// for a commit.
// ====================================================================

function buildMenu(state) {
    var model = [];

    // Checkout section
    if (state.branchNames.length > 0) {
        var checkoutSubMenu = state.branchNames.map(function(bName) {
            return {
                text: bName,
                icon: "gitBranch",
                action: "checkoutBranch",
                payload: { branch: bName }
            };
        });

        checkoutSubMenu.push({
            text: "Checkout " + state.shortHash + " (Detached)",
            icon: "hash",
            action: "checkoutCommit",
            payload: { hash: state.fullHash }
        });

        model.push({
            text: "Checkout",
            icon: "gitBranch",
            enabled: !state.isHead,
            subItems: checkoutSubMenu
        });
    }

    else {
        model.push({
            text: "Checkout Commit " + state.shortHash,
            icon: "hash",
            enabled: !state.isHead,
            action: "checkoutCommit",
            payload: { hash: state.fullHash }
        });
    }

    model.push({
        text: "Push",
        icon: "arrowUp",
        action: "push",
        enabled: state.pushEnabled,
        hasCheckBox: true,
        checkBoxText: "Force",
        payload: { branch: state.currentBranch }
    });

    // New Branch / Tag
    model.push({
        text: "New Branch from here",
        icon: "branchPlus",
        action: "newBranch",
        payload: { hash: state.fullHash }
    });

    model.push({
        text: "Create Tag here",
        icon: "tag",
        action: "newTag",
        payload: { hash: state.fullHash }
    });

    // Merge
    if (state.hasMergeableBranches) {
        model.push({
                separator: true
        });

        state.mergeableBranches.forEach(function(bName) {
            model.push({
                text: "Merge '" + bName + "' into '" + state.currentBranch + "'",
                icon: "arowLeftRight",
                action: "mergeBranch",
                payload: { source: bName, target: state.currentBranch }
            });
        });
    }

    // Rebase
    if (state.canRebase) {
        model.push({
            text: "Rebase onto " + state.shortHash,
            icon: "clockRotateLeft",
            action: "rebase",
            payload: { hash: state.fullHash }
        });
    }

    // Cherry‑Pick
    if (state.numSelected > 1) {
        model.push({
            text: "Cherry-Pick Selected (" + state.numSelected + ")",
            icon: "copy",
            enabled: state.cherryPickEnabled,
            action: "cherryPickSelected"
        });
    }
    else {
        model.push({
            text: "Cherry-Pick " + state.shortHash,
            icon: "copy",
            enabled: state.canCherryPick,
            action: "cherryPickSingle",
            payload: { hash: state.fullHash }
        });
    }

    // Reset
    model.push({
        text: "Reset onto" + state.shortHash,
        icon: "reset",
        action: "reset",
        subItems: [
            {text: "--Soft (Keep all changes)",  icon: "resetSoft",  action: "resetSoft",  payload: { hash: state.fullHash }},
            {text: "--Mixed (reset only index)", icon: "resetMixed", action: "resetMixed", payload: { hash: state.fullHash }},
            {text: "--Hard (discard and reset)", icon: "resetHard",  action: "resetHard",  payload: { hash: state.fullHash }},
        ]
    });

    return model;
}
