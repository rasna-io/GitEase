.pragma library

// ====================================================================
// CommitGraphNavigation – stateless navigation & selection helpers.
// ====================================================================

/**
 * @param {Array}  commits         – current commit array
 * @param {Object} selectedCommit  – the currently selected commit (or null)
 * @param {number} selectedIndex   – index of selectedCommit in commits (-1 if none)
 * @param {string} navigationRule  – "Author Email", "Author", "Parent 1", "Branch", "Message"
 * @param {string} newNavRule      – (optional) new navigation rule to apply
 * @returns {{ selected: Object, index: number, scroll: boolean }}
 */
function selectNext(commits, selectedCommit, selectedIndex, navigationRule, newNavRule) {
    if (newNavRule !== undefined)
        navigationRule = newNavRule;

    if (!commits.length)
        return null;

    var idx = selectedIndex;
    if (idx < 0)
        return { selected: commits[0], index: 0, scroll: true };

    if (!selectedCommit)
        return null;

    if (navigationRule === "Parent 1") {
        if (!selectedCommit.parentHashes || !selectedCommit.parentHashes.length) return null;
        var parentHash = selectedCommit.parentHashes[0];
        for (var i = idx + 1; i < commits.length; i++) {
            if (commits[i] && commits[i].hash === parentHash) {
                return { selected: commits[i], index: i, scroll: true };
            }
        }
        return null;
    }

    if (navigationRule === "Branch") {
        var laneKey = selectedCommit.colorKey;
        if (!laneKey) return null;
        for (var i = idx + 1; i < commits.length; i++) {
            if (commits[i] && commits[i].colorKey === laneKey) {
                return { selected: commits[i], index: i, scroll: true };
            }
        }
        return null;
    }

    var matchValue = getNavigationRuleValue(selectedCommit, navigationRule);
    for (var i = idx + 1; i < commits.length; i++) {
        if (commits[i] && getNavigationRuleValue(commits[i], navigationRule) === matchValue) {
            return { selected: commits[i], index: i, scroll: true };
        }
    }
    return null;
}

/**
 * Same signature, but moves upwards.
 */
function selectPrevious(commits, selectedCommit, selectedIndex, navigationRule, newNavRule) {
    if (newNavRule !== undefined)
        navigationRule = newNavRule;

    if (!commits.length)
        return null;

    var idx = selectedIndex;
    if (idx < 0) return { selected: commits[0], index: 0, scroll: true };

    if (!selectedCommit)
        return null;

    if (navigationRule === "Parent 1") {
        for (var i = idx - 1; i >= 0; i--) {
            var commit = commits[i];
            if (commit && commit.parentHashes && commit.parentHashes.length &&
                commit.parentHashes[0] === selectedCommit.hash) {
                return { selected: commit, index: i, scroll: true };
            }
        }
        return null;
    }

    if (navigationRule === "Branch") {
        var laneKey = selectedCommit.colorKey;
        if (!laneKey) return null;
        for (var i = idx - 1; i >= 0; i--) {
            if (commits[i] && commits[i].colorKey === laneKey) {
                return { selected: commits[i], index: i, scroll: true };
            }
        }
        return null;
    }

    var matchValue = getNavigationRuleValue(selectedCommit, navigationRule);
    for (var i = idx - 1; i >= 0; i--) {
        if (commits[i] && getNavigationRuleValue(commits[i], navigationRule) === matchValue) {
            return { selected: commits[i], index: i, scroll: true };
        }
    }
    return null;
}

/**
 * Returns new selection state after a mouse click.
 *
 * @param {Object} commitData     – clicked commit
 * @param {number} index          – its index
 * @param {number} modifiers      – Qt keyboard modifiers
 * @param {Array}  currentHashes  – currently selected hashes
 * @param {number} lastIndex      – last selected index (for shift‑click)
 * @param {Array}  commits        – full commit array
 * @returns {{ hashes: Array, lastIndex: number }} new selection
 */
function applySelection(commitData, index, modifiers, currentHashes, lastIndex, commits) {
    if (!commitData || !commitData.hash)
        return null;

    if ((modifiers & Qt.ControlModifier)) {
        var list    = currentHashes ? currentHashes.slice() : [];
        var idx     = list.indexOf(commitData.hash);

        if (idx >= 0)
            list.splice(idx, 1);

        else
            list.push(commitData.hash);

        return { hashes: list, lastIndex: index };
    }

    if ((modifiers & Qt.ShiftModifier) && lastIndex >= 0) {
        var start   = Math.min(lastIndex, index);
        var end     = Math.max(lastIndex, index);
        var hashes  = [];

        for (var i = start; i <= end; i++) {
            var c = commits[i];
            if (c && c.hash) hashes.push(c.hash);
        }
        return { hashes: hashes, lastIndex: index };
    }

    return { hashes: [commitData.hash], lastIndex: index };
}

/**
 * @returns {number} index of selectedCommit in commits, or -1
 */
function selectedIndex(commits, selectedCommit) {
    if (!selectedCommit)
        return -1;

    for (var i = 0; i < commits.length; i++) {
        if (commits[i] && commits[i].hash === selectedCommit.hash)
            return i;
    }
    return -1;
}

function getNavigationRuleValue(commit, rule) {
    if (!commit)
        return null;

    switch (rule) {
        case "Author":
            return (commit.author || "").toString();

        case "Author Email":
            return (commit.authorEmail || "").toString();

        case "Parent 1":
            return (commit.parentHashes && commit.parentHashes.length) ? commit.parentHashes[0] : null;

        case "Branch":
            return commit.colorKey;

        case "Message":

        default:
            return (commit.summary || "").toString();
    }
}
