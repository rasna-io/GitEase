/*! ***********************************************************************************************
 * GraphLayout Script - Advanced DAG visualization for Git history
 * Implements proper topological sorting, lane assignment, and merge handling
 * ************************************************************************************************/

.pragma library

/**
 * Main function to calculate DAG positions for commits
 * Implements:
 * 1. Topological sorting (parents before children in display)
 * 2. Intelligent lane assignment (minimize crossings)
 * 3. Proper merge commit handling
 * 4. Branch color differentiation
 * 5. Chronological timeline ordering
 */
function calculateDAGPositions(commits, columnSpacing, commitItemHeight, commitItemSpacing) {
    if (commits.length === 0) return {}
    
    
    var commitPositions = {}
    var commitToLane = {}
    
    // Build lookup maps for O(1) access
    var hashToCommit = {}
    var hashToIndex = {}
    for (var i = 0; i < commits.length; i++) {
        hashToCommit[commits[i].hash] = commits[i]
        hashToIndex[commits[i].hash] = i
    }
    
    // Build parent-child relationships for topological analysis
    var childrenMap = buildChildrenMap(commits)
    
    // Track active lanes - lanes[column] = next expected commit hash
    var lanes = []
    var processedCommits = {}
    
    
    // Process commits from top to bottom (newest to oldest in display)
    for (var i = 0; i < commits.length; i++) {
        var commit = commits[i]
        var commitHash = commit.hash
        var parents = commit.parentHashes || []
        var branchName = getBranchName(commit)
        
        // Mark this commit as processed
        processedCommits[commitHash] = true
        
        // Find optimal lane for this commit
        var lane = findOptimalLane(commitHash, branchName, lanes, null, hashToCommit)
        
        // Assign commit to lane
        commitToLane[commitHash] = lane
        
        
        // Update lanes based on commit type and parents
        updateLanesForCommit(lane, commit, parents, lanes, hashToCommit, processedCommits, hashToIndex)
        
        // IMPORTANT: Free all lanes that were expecting this commit
        // (This allows lane reuse after merges)
        for (var l = 0; l < lanes.length; l++) {
            if (l !== lane && lanes[l] === commitHash) {
                lanes[l] = null
            }
        }
        
        // ALSO: Free any lane expecting a commit that was already processed
        // (This handles cases where commit was processed in different lane)
        for (var l = 0; l < lanes.length; l++) {
            if (lanes[l] && processedCommits.hasOwnProperty(lanes[l])) {
                lanes[l] = null
            }
        }
    }
    
    // Create final position objects
    for (var j = 0; j < commits.length; j++) {
        var commit = commits[j]
        var lane = commitToLane[commit.hash] || 0
        
        commitPositions[commit.hash] = {
            x: lane * columnSpacing,
            y: j * (commitItemHeight + (commitItemSpacing * 2)),
            column: lane,
            branchName: getBranchName(commit),
            lane: lane,
            commitType: commit.commitType || "normal"
        }
    }
    
    return commitPositions
}

/**
 * Helper: Build parent-child relationships map
 * Used for topological analysis and better lane assignment
 */
function buildChildrenMap(commits) {
    var childrenMap = {}
    
    for (var i = 0; i < commits.length; i++) {
        var commit = commits[i]
        var parents = commit.parentHashes || []
        
        for (var p = 0; p < parents.length; p++) {
            var parentHash = parents[p]
            if (!childrenMap[parentHash]) {
                childrenMap[parentHash] = []
            }
            childrenMap[parentHash].push(commit.hash)
        }
    }
    
    return childrenMap
}

/**
 * Helper: Get primary branch name from commit
 * Returns the first branch name or "main" as fallback
 */
function getBranchName(commit) {
    return (commit.branchNames && commit.branchNames.length > 0) 
           ? commit.branchNames[0] 
           : "main"
}

/**
 * Helper: Find optimal lane for a commit
 * Strategy:
 * 1. If commit is expected in existing lane -> reuse that lane (PRIORITY)
 * 2. Find first FREE lane (minimize columns)
 * 3. Only create new lane if absolutely necessary
 */
function findOptimalLane(commitHash, branchName, lanes, branchToLane, hashToCommit) {
    // Strategy 1: Check if commit is EXPECTED in any existing lane (highest priority)
    for (var i = 0; i < lanes.length; i++) {
        if (lanes[i] === commitHash) {
            return i
        }
    }
    
    // Strategy 2: Find first FREE lane (reuse existing columns)
    for (var i = 0; i < lanes.length; i++) {
        if (!lanes[i]) {
            return i
        }
    }
    
    // Strategy 3: Only create new lane if no free lanes available
    return lanes.length
}

/**
 * Helper: Update lanes after processing a commit
 * Simplified algorithm - just track next expected commits
 */
function updateLanesForCommit(lane, commit, parents, lanes, hashToCommit, processedCommits, hashToIndex) {
    var commitHash = commit.hash
    
    // Ensure lane exists
    while (lanes.length <= lane) {
        lanes.push(null)
    }
    
    if (parents.length === 0) {
        // Initial commit - no parents, free the lane
        lanes[lane] = null
        
    } else if (parents.length === 1) {
        // Normal commit - single parent continues in same lane
        var parentHash = parents[0]
        
        if (!hashToCommit.hasOwnProperty(parentHash)) {
            // Parent not in our list, free the lane
            lanes[lane] = null
        } else {
            // Continue parent in same lane
            lanes[lane] = parentHash
        }
        
    } else {
        // Merge commit - multiple parents
        // First parent continues in current lane
        var firstParent = parents[0]
        if (hashToCommit.hasOwnProperty(firstParent)) {
            lanes[lane] = firstParent
        } else {
            lanes[lane] = null
        }
        
        // Process additional parents (merged branches)
        for (var p = 1; p < parents.length; p++) {
            var parentHash = parents[p]
            
            // Skip if parent doesn't exist in our commit list
            if (!hashToCommit.hasOwnProperty(parentHash)) {
                continue
            }
            
            // Check if parent already processed (appeared earlier in timeline)
            var parentAlreadyProcessed = processedCommits.hasOwnProperty(parentHash)
            
            if (parentAlreadyProcessed) {
                // Parent already shown - free any lane expecting it
                for (var i = 0; i < lanes.length; i++) {
                    if (lanes[i] === parentHash) {
                        lanes[i] = null
                        break
                    }
                }
            } else {
                // Parent will appear later - check if already in a lane
                var foundInLane = false
                for (var i = 0; i < lanes.length; i++) {
                    if (lanes[i] === parentHash) {
                        foundInLane = true
                        break
                    }
                }
                
                if (!foundInLane) {
                    // Not in any lane yet - assign it to first free lane
                    var assignedLane = -1
                    
                    // Try to reuse free lane
                    for (var i = 0; i < lanes.length; i++) {
                        if (!lanes[i]) {
                            assignedLane = i
                            break
                        }
                    }
                    
                    // Create new lane if no free lane available
                    if (assignedLane === -1) {
                        assignedLane = lanes.length
                        lanes.push(null)
                    }
                    
                    lanes[assignedLane] = parentHash
                }
            }
        }
    }
    
    // DON'T compact! Keep free lanes for reuse
    // Compaction removes free lanes that should be reused by future branches
}

