.pragma library

// ====================================================================
// CommitGraphFilter – pure filter / data‑loading helpers.
// ====================================================================

/**
 * Filters the full commit list according to text, dates, and modes.
 * @param {Array}  allCommits        – full unfiltered list
 * @param {string} filterText        – search text
 * @param {string} filterStartDate   – YYYY‑MM‑DD
 * @param {string} filterEndDate     – YYYY‑MM‑DD
 * @param {Array}  filterMode        – active modes (e.g. ["Messages"])
 * @param {Array}  selectedHashes    – currently selected hashes
 * @param {string} branchName        – optional branch name to keep visible
 * @param {string} branchHeadHash    – branch tip hash used for ancestor reachability
 * @returns {Object} { filtered: Array, stillSelected: Array }
 */
function applyFilter(allCommits, filterText, filterStartDate, filterEndDate, filterMode, selectedHashes, branchName, branchHeadHash) {
    var base    = allCommits || [];
    var needle  = (filterText || "").trim().toLowerCase();
    var branch  = (branchName || "").trim();
    var visibleBranchHashes = branch ? reachableHashesFrom(base, branchHeadHash) : null;
    var startMs = parseDateYYYYMMDD(filterStartDate);
    var endMs   = parseDateYYYYMMDD(filterEndDate);

    if (!isNaN(endMs))
        endMs = endMs + (24 * 60 * 60 * 1000) - 1;

    var filtered = [];
    for (var i = 0; i < base.length; i++) {
        var c = base[i];
        if (!c) continue;

        if (branch && (!visibleBranchHashes || !visibleBranchHashes[c.hash]))
            continue;

        if (!isNaN(startMs) || !isNaN(endMs)) {
            var commitMs = new Date(c.authorDate).getTime();
            if (!isNaN(startMs) && !(commitMs >= startMs))
                continue;

            if (!isNaN(endMs) && !(commitMs <= endMs))
                continue;
        }

        if (needle && !applicationFilter(c, needle, filterMode))
            continue;

        filtered.push(c);
    }

    var stillSelected = [];
    if (selectedHashes && selectedHashes.length) {
        for (var si = 0; si < selectedHashes.length; si++) {
            var h = selectedHashes[si];
            if (filtered.some(function(x) { return x.hash === h; }))
                stillSelected.push(h);
        }
    }

    return { filtered: filtered, stillSelected: stillSelected };
}

/**
 * Simple date parser (identical to original).
 */
function parseDateYYYYMMDD(str) {
    if (!str)
        return NaN;

    str = ("" + str).trim();

    if (str.length < 8)
        return NaN;

    var parts = str.split(/[-\/]/);

    if (parts.length !== 3)
        return NaN;

    var y = parseInt(parts[0], 10)
    var m = parseInt(parts[1], 10)
    var d = parseInt(parts[2], 10)

    if (isNaN(y) || isNaN(m) || isNaN(d))
        return NaN;

    return new Date(y, m-1, d, 0,0,0,0).getTime();
}

function hasAnyFilter(filterText, filterStartDate, filterEndDate, branchName) {
    return (filterText      && filterText.trim().length > 0)        ||
           (filterStartDate && filterStartDate.trim().length > 0)   ||
           (filterEndDate   && filterEndDate.trim().length > 0)     ||
           (branchName      && branchName.trim().length > 0);
}

function reachableHashesFrom(commits, headHash) {
    if (!headHash)
        return {};

    var byHash = {};
    for (var i = 0; i < commits.length; i++) {
        var commit = commits[i];
        if (commit && commit.hash)
            byHash[commit.hash] = commit;
    }

    var reachable = {};
    var stack = [headHash];
    while (stack.length > 0) {
        var hash = stack.pop();
        if (!hash || reachable[hash])
            continue;

        reachable[hash] = true;

        var current = byHash[hash];
        if (!current || !current.parentHashes)
            continue;

        for (var p = 0; p < current.parentHashes.length; p++)
            stack.push(current.parentHashes[p]);
    }

    return reachable;
}

function applicationFilter(commit, needle, modes) {
    if (!needle)
        return true;

    var activeMode = (modes && modes.length > 0) ? modes : ["Messages"];
    for (var i = 0; i < activeMode.length; i++) {
        var mode = activeMode[i];
        var haystack = "";
        switch (mode) {
            case "Messages":
                haystack = (commit.summary||"") + " " + (commit.message||"")
                break;

            case "Subjects":
                haystack = commit.summary || ""
                break;

            case "Authors":
                haystack = commit.author || ""
                break;
            case "Emails":
                haystack = commit.authorEmail || ""
                break;

            case "SHA-1":
                haystack = commit.hash || ""
                break;
        }

        if (haystack.toLowerCase().indexOf(needle) !== -1)
            return true;
    }

    return false;
}
