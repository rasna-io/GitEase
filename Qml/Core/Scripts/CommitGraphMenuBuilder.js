.pragma library

// ====================================================================
// CommitGraphMenuBuilder – builds the context‑menu data model
// for a commit.
// ====================================================================

// pluginItems: optional array of {pluginId, id, label, icon, separator, order} from IContextMenuPlugin
function buildMenu(state, pluginItems) {
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
        separator: true
    });

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

    model.push({
        separator: true
    });

    // Browse files
    model.push({
        text: "Browse files at this commit",
        icon: "folder",
        action: "browseFiles",
        payload: { hash: state.fullHash, message: state.commitMessage, date: state.commitDate }
    });

    // Merge
    if (state.hasMergeableBranches) {
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
            shortcut: "Ctrl+R",
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

    model.push({
        separator: true
    });

    // Reset
    model.push({
        text: "Reset " + state.currentBranch + " into this commit",
        icon: "reset",
        action: "reset",
        subItems: [
           {text: "--Soft (Keep all changes)",  icon: "resetSoft",  action: "resetSoft",  payload: { hash: state.fullHash }},
           {text: "--Mixed (Reset index to commit)", icon: "resetMixed", action: "resetMixed", payload: { hash: state.fullHash }},
           {text: "--Hard (Discard all changes)", icon: "resetHard",  action: "resetHard",  payload: { hash: state.fullHash }},
        ]
    });

    // Plugin context menu items (appended after a separator when non-empty)
    if (pluginItems && pluginItems.length > 0) {
        model.push({ separator: true });
        pluginItems.forEach(function(pi) {
            if (pi.separator) {
                model.push({ separator: true });
                return;
            }
            model.push({
                text:    pi.label,
                icon:    pi.icon || "",
                action:  "pluginAction",
                payload: { pluginId: pi.pluginId, itemId: pi.id, hash: state.fullHash }
            });
        });
    }

    return model;
}
