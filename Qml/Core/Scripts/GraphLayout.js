/*! ***********************************************************************************************
 * GraphLayout Script
 * calculateDAGPositions for nodes
 * ************************************************************************************************/

.pragma library

function calculateDAGPositions(commits, columnSpacing, commitItemHeight, commitItemSpacing) {
    var commitPositions = {}
    var hashToCommit = {}  // Map hash to commit data
    var branchToColumn = {}  // Map branch name to column number
    var columnToBranch = {}  // Map column number to branch name (inverse mapping)
    var nextColumn = 0

    // Step 1: Build hash map from commits
    for (var h = 0; h < commits.length; h++) {
        var commitH = commits[h]
        hashToCommit[commitH.hash] = commitH
    }

    // Step 2: Sort commits from oldest to newest
    var topologicalOrder = commits.slice().reverse();  // Reversed order (oldest->newest)

    // Step 3: Iterate over the commits to assign branches and columns
    for (var topoIdx = 0; topoIdx < topologicalOrder.length; topoIdx++) {
        var commitForBranch = topologicalOrder[topoIdx];
        if (!commitForBranch) continue;

        // Get the primary branch for this commit
        var commitBranch = commitForBranch.branchNames && commitForBranch.branchNames.length > 0
            ? commitForBranch.branchNames[0] : "main";

        // Handle checkout (branch creation) scenario
        if (commitForBranch.commitType === "checkout" && commitForBranch.branchNames.length > 1) {
            var parentBranch = null;
            if (commitForBranch.parentHashes && commitForBranch.parentHashes.length > 0) {
                var parentHash = commitForBranch.parentHashes[0];
                var parentCommit = hashToCommit[parentHash];
                if (parentCommit && parentCommit.branchNames) {
                    parentBranch = parentCommit.branchNames[0];
                }
            }

            // Check if parent branch exists and assign new column
            if (parentBranch && branchToColumn.hasOwnProperty(parentBranch)) {
                var parentColumn = branchToColumn[parentBranch];

                // Try to reuse an existing column if possible
                var reuseColumn = -1;
                for (var col = parentColumn + 1; col < nextColumn; col++) {
                    var occupyingBranch = columnToBranch[col];
                    if (occupyingBranch) {
                        var branchHasHead = false;
                        for (var checkIdx = 0; checkIdx < commits.length; checkIdx++) {
                            var checkCommit = commits[checkIdx];
                            if (checkCommit.branchNames && checkCommit.branchNames.indexOf(occupyingBranch) !== -1) {
                                if (checkCommit.commitType === "merge" && checkCommit.branchNames.indexOf(occupyingBranch) !== -1) {
                                    reuseColumn = col;
                                    break;
                                }
                            }
                        }
                        if (reuseColumn !== -1) break;
                    }
                }

                // If a reusable column is found, assign it
                if (reuseColumn !== -1) {
                    var newBranch = commitForBranch.branchNames[0];
                    branchToColumn[newBranch] = reuseColumn;
                    columnToBranch[reuseColumn] = newBranch;
                } else {
                    // Shift branches and add a new column after the parent column
                    var shiftedBranches = {};
                    var shiftedColumns = {};
                    for (var branchName in branchToColumn) {
                        var oldCol = branchToColumn[branchName];
                        if (oldCol > parentColumn) {
                            shiftedBranches[branchName] = oldCol + 1;
                            shiftedColumns[oldCol + 1] = branchName;
                        } else {
                            shiftedBranches[branchName] = oldCol;
                            shiftedColumns[oldCol] = branchName;
                        }
                    }

                    // Assign the new branch to the column right after parent
                    var newBranch = commitForBranch.branchNames[0];
                    shiftedBranches[newBranch] = parentColumn + 1;
                    shiftedColumns[parentColumn + 1] = newBranch;
                    branchToColumn = shiftedBranches;
                    columnToBranch = shiftedColumns;

                    // Update nextColumn if needed
                    var maxColumn = Math.max.apply(Math, Object.values(branchToColumn));
                    nextColumn = maxColumn + 1;
                }
            } else {
                // If no parent branch exists, assign a new column
                if (!branchToColumn.hasOwnProperty(commitBranch)) {
                    branchToColumn[commitBranch] = nextColumn;
                    columnToBranch[nextColumn] = commitBranch;
                    nextColumn++;
                }
            }
        } else {
            // Handle regular branches (non-checkout commits)
            if (!branchToColumn.hasOwnProperty(commitBranch)) {
                branchToColumn[commitBranch] = nextColumn;
                columnToBranch[nextColumn] = commitBranch;
                nextColumn++;
            }
        }
    }

    // Step 4: Assign positions for each commit based on its column and order
    for (var j = 0; j < commits.length; j++) {
        var commit = commits[j];

        if (!commit) continue;

        // Determine which branch this commit belongs to
        var commitBranchName = "main";
        var commitColumn = 0;

        if (commit.commitType === "merge") {
            if (commit.branchNames && Array.isArray(commit.branchNames) && commit.branchNames.length > 0) {
                commitBranchName = commit.branchNames[0];
            }
        } else if (commit.commitType === "checkout") {
            if (commit.branchNames && Array.isArray(commit.branchNames) && commit.branchNames.length > 0) {
                commitBranchName = commit.branchNames[0];
            }
        } else {
            if (commit.branchNames && Array.isArray(commit.branchNames) && commit.branchNames.length > 0) {
                commitBranchName = commit.branchNames[0];
            }
        }

        // Assign column based on branch
        if (branchToColumn.hasOwnProperty(commitBranchName)) {
            commitColumn = branchToColumn[commitBranchName];
        } else {
            branchToColumn[commitBranchName] = nextColumn++;
            commitColumn = branchToColumn[commitBranchName];
        }

        // Assign positions (x, y) based on column and order of appearance
        commitPositions[commit.hash] = {
            x: commitColumn * columnSpacing,
            y: j * (commitItemHeight + (commitItemSpacing * 2)),  // Adjust for vertical spacing
            column: commitColumn,
            branchName: commitBranchName
        };
    }

    return commitPositions;
}
