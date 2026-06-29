.pragma library

// ====================================================================
// CommitGraphDataLoader – pure data compilation helpers.
// ====================================================================

// Global map for commit hashes whose branch names will be resolved in later
// pages. Needed for pagination. Entries are removed once processed.
let branchAssignmentByHash = new Map();

/**
 * Compiles graph‑ready commits from raw controller data.
 * @param {Array} rawCommits  – page from commitController.getCommits()
 * @param {Array} rawBranches – branchController.getBranches()
 * @param {Array} rawStashes  – stashController.list().data
 * @param {Array} allTags     – tagController.list().data  (optional)
 * @param {Object} appSettings – appModel.appSettings.generalSettings (optional)
 * @returns {Array} compiled commit objects with colorKey, branchNames, etc.
 */
function compileGraphCommits(rawCommits, rawBranches, rawStashes, allTags, appSettings) {
    if (!rawCommits)
        return [];

    var hashToTags = {};
    if (allTags) {
        for (var i = 0; i < allTags.length; i++) {
            var tg = allTags[i];
            if (tg.commitId) {
                if (!hashToTags[tg.commitId])
                    hashToTags[tg.commitId] = [];

                hashToTags[tg.commitId].push(tg.name);
            }
        }
    }

    var tipHashToBranches = {};
    if (rawBranches) {
        for (var i = 0; i < rawBranches.length; i++) {
            var b = rawBranches[i];
            if (!b || !b.targetHash)
                continue;

            if (!tipHashToBranches[b.targetHash])
                tipHashToBranches[b.targetHash] = [];

            tipHashToBranches[b.targetHash].push(b.name);
        }
    }

    var showStashes = appSettings ? !!appSettings.showStashNodes : false;
    var stashNodeList = [];
    if (showStashes && rawStashes && rawStashes.length) {
        var seenStash = {};
        for (var s = 0; s < rawStashes.length; s++) {
            var stash = rawStashes[s];
            if (!stash || !stash.id || seenStash[stash.id])
                continue;

            seenStash[stash.id] = true;

            var label = "stash@{" + stash.index + "}";
            stashNodeList.push({
                hash            : stash.id,
                shortHash       : stash.id.substring(0, 7),
                message         : stash.message || label,
                summary         : stash.message || label,
                author          : stash.author || "",
                authorEmail     : "",
                authorDate      : stash.dateTime || "",
                parentHashes    : stash.parentId ? [stash.parentId] : [],
                commitType      : "stash",
                branchNames     : [label],
                tagNames        : [],
                colorKey        : "",
                isStash         : true,
                stashIndex      : stash.index,
                stashLabel      : label,
                stashParentId   : stash.parentId || "",
                files           : null,
                isUncommitted   : false
            });
        }
    }

    var compiled = [];
    var stashInserted = {};

    for (var c = 0; c < rawCommits.length; c++) {
        var commit = rawCommits[c];

        for (var sj = 0; sj < stashNodeList.length; sj++) {
            var sn = stashNodeList[sj];
            if (!stashInserted[sn.hash] && sn.stashParentId === commit.hash) {
                compiled.push(sn);
                stashInserted[sn.hash] = true;
            }
        }

        let haveBranchName = tipHashToBranches[commit.hash]?.length > 0 ?? false

        let branchNames = []
        if (haveBranchName) {
            branchNames = tipHashToBranches[commit.hash];
            for (let pr = 0; pr < commit.parentHashes.length; ++pr) {
                if (!branchAssignmentByHash.has(commit.parentHashes[pr]))
                    branchAssignmentByHash.set(commit.parentHashes[pr], branchNames)
            }
        }

        if (!haveBranchName) {
            if (branchAssignmentByHash.has(commit.hash)) {
                branchNames = branchAssignmentByHash.get(commit.hash)

                for (let pr1 = 0; pr1 < commit.parentHashes.length; ++pr1) {
                    if (!branchAssignmentByHash.has(commit.parentHashes[pr1]))
                        branchAssignmentByHash.set(commit.parentHashes[pr1], branchNames)
                }

                // delete used key
                branchAssignmentByHash.delete(commit.hash)
            }
        }

        if (branchNames.length === 0) {
            if (commit.hash === "__uncommitted__") {
                branchNames = ["__uncommitted__"]
            }
        }

        compiled.push({
            hash            : commit.hash,
            shortHash       : commit.shortHash,
            message         : commit.message,
            summary         : commit.summary,
            author          : commit.author,
            authorEmail     : commit.authorEmail,
            authorDate      : commit.authorDate,
            parentHashes    : commit.parentHashes || [],
            commitType      : (commit.parentHashes && commit.parentHashes.length > 1) ? "merge" : "normal",
            branchNames     : branchNames,
            tagNames        : hashToTags[commit.hash] || [],
            colorKey        : branchNames[0] || "main",
            isHead          : haveBranchName,
            isStash         : false,
            stashIndex      : -1,
            stashLabel      : "",
            stashParentId   : "",
            files           : commit.files || null,
            isUncommitted   : commit.isUncommitted || false
        });
    }

    for (var sk = 0; sk < stashNodeList.length; sk++) {
        if (!stashInserted[stashNodeList[sk].hash])
            compiled.push(stashNodeList[sk]);
    }

    return compiled;
}

/**
 * Creates an uncommitted pseudo‑commit from status data.
 * @param {Array} statusData – result of statusController.status().data
 * @param {string} headHash  – current HEAD hash
 * @returns {Object|null} uncommitted node
 */
function createUncommittedNode(statusData, headHash) {
    if (!statusData)
        return null;

    var staged      = [];
    var unstaged    = [];
    statusData.forEach(function(file) {
        if (file.isStaged)
            staged.push(file);

        else if (file.isUnstaged || file.isUntracked)
            unstaged.push(file);
    });

    var total = staged.length + unstaged.length;
    if (total === 0)
        return null;

    return {
        hash: "__uncommitted__",
        shortHash       : "",
        message         : "Working tree Changes",
        summary         : "Working tree Changes (" + total + " files)",
        author          : "",
        authorEmail     : "",
        authorDate      : "",
        parentHashes    : headHash ? [headHash] : [],
        commitType      : "uncommitted",
        branchNames     : [],
        tagNames        : [],
        colorKey        : "uncommitted",
        isUncommitted   : true,
        isStash         : false,
        files           : { staged: staged, unstaged: unstaged }
    };
}
