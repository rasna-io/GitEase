.pragma library

// ====================================================================
// CommitGraphMenuBuilder – builds the context‑menu data model
// for a commit.
// ====================================================================

// pluginItems: optional array of {pluginId, id, label, icon, separator, order} from IContextMenuPlugin
function buildMenu(state, pluginItems) {
    if (state.numSelected > 1)
        return buildSelectionMenu(state);

    var model = state.isStash ? buildStashMenu(state) : buildCommitMenu(state);
    appendPluginItems(model, state, pluginItems);

    return model;
}

function buildSelectionMenu(state) {
    return [{
        text: "Cherry-Pick Selected (" + state.numSelected + ")",
        icon: "copy",
        enabled: state.cherryPickEnabled,
        action: "cherryPickSelected"
    }];
}

function buildStashMenu(state) {
    return [browseFilesItem(state)];
}

function buildCommitMenu(state) {
    var model = [];

    // Checkout section
    var checkoutDetached = {
        text: "Checkout " + state.shortHash + " (Detached)",
        icon: "hash",
        enabled: !state.isHead,
        action: "checkoutCommit",
        payload: { hash: state.fullHash }
    };

    if (state.localBranches.length > 0) {
        var checkoutSubMenu = state.localBranches.map(function(bName) {
            return {
                text: bName,
                icon: "gitBranch",
                enabled: bName !== state.currentBranch,
                action: "checkoutBranch",
                payload: { branch: bName }
            };
        });

        checkoutSubMenu.push(checkoutDetached);

        model.push({
            text: "Checkout",
            icon: "gitBranch",
            enabled: checkoutSubMenu.some(function(item) { return item.enabled; }),
            subItems: checkoutSubMenu
        });
    }

    else {
        model.push(checkoutDetached);
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

    // Create Branch / Tag
    model.push({
        text: "Create Branch Here...",
        icon: "branchPlus",
        action: "newBranch",
        payload: { hash: state.fullHash }
    });

    model.push({
        text: "Create Tag Here...",
        icon: "tag",
        action: "newTag",
        payload: { hash: state.fullHash }
    });

    model.push({
        separator: true
    });

    // Browse files
    model.push(browseFilesItem(state));

    // Merge
    if (state.hasMergeableBranches) {
        state.mergeableBranches.forEach(function(bName) {
            model.push({
                text: "Merge '" + bName + "' into '" + state.currentBranch + "'...",
                icon: "arowLeftRight",
                action: "mergeBranch",
                payload: { source: bName, target: state.currentBranch }
            });
        });
    }

    // Rebase
    if (state.canRebase) {
        model.push({
            text: "Rebase onto " + state.shortHash + "...",
            icon: "clockRotateLeft",
            action: "rebase",
            shortcut: "Ctrl+R",
            payload: { hash: state.fullHash }
        });
    }

    // Cherry‑Pick
    model.push({
        text: "Cherry-Pick " + state.shortHash,
        icon: "copy",
        enabled: state.canCherryPick,
        action: "cherryPickSingle",
        payload: { hash: state.fullHash }
    });

    model.push({
        separator: true
    });

    // Reset
    var resetTarget = state.currentBranch ? "'" + state.currentBranch + "'" : "HEAD";
    model.push({
        text: "Reset " + resetTarget + " to This Commit",
        icon: "reset",
        action: "reset",
        subItems: [
           {text: "Soft (keep changes staged)",   icon: "resetSoft",  action: "resetSoft",  payload: { hash: state.fullHash }},
           {text: "Mixed (keep changes unstaged)", icon: "resetMixed", action: "resetMixed", payload: { hash: state.fullHash }},
           {text: "Hard (discard all changes)",   icon: "resetHard",  action: "resetHard",  payload: { hash: state.fullHash }},
        ]
    });

    return model;
}

function browseFilesItem(state) {
    return {
        text: "Browse Files at This Commit...",
        icon: "folder",
        action: "browseFiles",
        payload: { hash: state.fullHash, message: state.commitMessage, date: state.commitDate }
    };
}

function appendPluginItems(model, state, pluginItems) {
    if (!pluginItems || pluginItems.length === 0)
        return;

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
