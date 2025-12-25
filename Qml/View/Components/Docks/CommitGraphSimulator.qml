import QtQuick
import GitEase_Style
import GitEase_Style_Impl
import GitEase

Item {
    id: root

    property bool enabled: true
    property int intervalMs: 10000
    property int maxCommits: 250
    property int branchCounter: 0
    property var mergedBranches: []  // Track branches that have been merged

    property var commitDataArray: []
    property var branches: []
    property var commitDataList: []

    signal newCommitsReady(var newCommitList)

    Timer {
        id: simulationTimer
        interval: root.intervalMs
        repeat: true
        running: root.enabled
        triggeredOnStart: true
        onTriggered: {
            root.simulateRandomAction()
        }
    }

    Timer {
        id: previousBranchTimer
        interval: 300  // 300ms delay
        onTriggered: {
            root.addCommitsToPreviousBranches(branch)
        }
        property string branch: ""
    }

    function randomInt(maxExclusive) {
        return Math.floor(Math.random() * maxExclusive)
    }

    function randomChoice(arr) {
        if (!arr || arr.length === 0) return null
        return arr[randomInt(arr.length)]
    }

    function getBranchNamesFromModel() {
        var seen = {}
        var result = []
        
        // First, get branches from the branches model
        for (var i = 0; i < branches.length; i++) {
            var name = branches[i].name
            if (name && !seen[name] && mergedBranches.indexOf(name) === -1) {
                seen[name] = true
                result.push(name)
            }
        }
        
        // Also extract branches from commit data (for checkouts)
        for (var j = 0; j < commitDataArray.length; j++) {
            var commit = commitDataArray[j]
            if (commit && commit.branchNames) {
                for (var k = 0; k < commit.branchNames.length; k++) {
                    var branchName = commit.branchNames[k]
                    if (branchName && !seen[branchName] && mergedBranches.indexOf(branchName) === -1) {
                        seen[branchName] = true
                        result.push(branchName)
                    }
                }
            }
        }
        
        // Also check commitDataList for newer commits
        for (var l = 0; l < commitDataList.length; l++) {
            var commit2 = commitDataList[l]
            if (commit2 && commit2.branchNames) {
                for (var m = 0; m < commit2.branchNames.length; m++) {
                    var branchName2 = commit2.branchNames[m]
                    if (branchName2 && !seen[branchName2] && mergedBranches.indexOf(branchName2) === -1) {
                        seen[branchName2] = true
                        result.push(branchName2)
                    }
                }
            }
        }
        
        if (result.length === 0) result.push("main")
        return result
    }

    function getBranchHeads() {
        var heads = {}
        for (var i = 0; i < commitDataArray.length; i++) {
            var c = commitDataArray[i]
            var b = (c && c.branchNames && c.branchNames.length > 0) ? c.branchNames[0] : "main"
            if (!heads[b]) heads[b] = c.hash
        }
        return heads
    }

    function ensureSimulationSeed() {
        if (commitDataList && commitDataList.length > 0) return
        var now = new Date().toISOString()
        var seed = {
            id: "sim_seed_" + Date.now(),
            hash: "sim_seed_" + Date.now(),
            shortHash: "seed",
            message: "Seed commit",
            author: "Simulator",
            email: "sim@example.com",
            date: now,
            timestamp: now,
            branchNames: ["main"],
            tagNames: [],
            parentHashes: [],
            commitType: "normal"
        }
        commitDataList = [seed]
        newCommitsReady(commitDataList)
    }

    function pushToCommitDataList(newCommit) {
        var list = (commitDataList && Array.isArray(commitDataList)) ? commitDataList.slice() : []
        list.push(newCommit)
        newCommitsReady(list)
    }

    function simulateCommitOnBranch(branchName) {
        var heads = getBranchHeads()
        var parent = heads[branchName] || null
        var now = new Date().toISOString()
        var hash = "sim_c_" + Date.now() + "_" + randomInt(100000)
        var c = {
            id: hash,
            hash: hash,
            shortHash: hash.substring(0, 7),
            message: "Commit on " + branchName,
            author: "Simulator",
            email: "sim@example.com",
            date: now,
            timestamp: now,
            branchNames: [branchName],
            tagNames: [],
            parentHashes: parent ? [parent] : [],
            commitType: "normal"
        }
        pushToCommitDataList(c)
    }

    function simulateCheckoutFromBranch(parentBranch) {
        var heads = getBranchHeads()
        var parent = heads[parentBranch] || null
        if (!parent) return
        branchCounter++
        var newBranch = "sim/branch_" + branchCounter
        var now = new Date().toISOString()
        var hash = "sim_co_" + Date.now() + "_" + randomInt(100000)
        var c = {
            id: hash,
            hash: hash,
            shortHash: hash.substring(0, 7),
            message: "Checkout " + newBranch,
            author: "Simulator",
            email: "sim@example.com",
            date: now,
            timestamp: now,
            branchNames: [newBranch, parentBranch],
            tagNames: [],
            parentHashes: [parent],
            commitType: "checkout"
        }
        pushToCommitDataList(c)
    }

    function simulateMerge(destBranch, sourceBranch) {
        if (!destBranch || !sourceBranch || destBranch === sourceBranch) return
        var heads = getBranchHeads()
        var destHead = heads[destBranch] || null
        var srcHead = heads[sourceBranch] || null
        if (!destHead || !srcHead) return
        var now = new Date().toISOString()
        var hash = "sim_m_" + Date.now() + "_" + randomInt(100000)
        var c = {
            id: hash,
            hash: hash,
            shortHash: hash.substring(0, 7),
            message: "Merge " + sourceBranch + " into " + destBranch,
            author: "Simulator",
            email: "sim@example.com",
            date: now,
            timestamp: now,
            branchNames: [destBranch, sourceBranch],
            tagNames: [],
            parentHashes: [destHead, srcHead],
            commitType: "merge"
        }
        
        // Mark the source branch as merged
        if (mergedBranches.indexOf(sourceBranch) === -1) {
            mergedBranches.push(sourceBranch)
        }
        
        pushToCommitDataList(c)
    }

    function simulateRandomAction() {
        if (!root.enabled) return
        ensureSimulationSeed()

        if (commitDataList && commitDataList.length > root.maxCommits) {
            root.enabled = false
            return
        }

        var branchNames = getBranchNamesFromModel()
        var actionRoll = Math.random()

        // Adjusted probabilities: 40% commit, 50% checkout, 10% merge
        if (actionRoll < 0.40) {
            var b = randomChoice(branchNames)
            simulateCommitOnBranch(b)
            
            // After each commit, add commits to previous branches
            if (branchNames.length > 1) {
                // Use Qt Timer instead of setTimeout
                previousBranchTimer.branch = b
                previousBranchTimer.restart()
            }
            return
        }

        if (actionRoll < 0.90) {
            var parentB = randomChoice(branchNames)
            simulateCheckoutFromBranch(parentB)
            return
        }

        // Only try merge if we have at least 2 branches
        if (branchNames.length < 2) {
            var parentB = randomChoice(branchNames)
            simulateCheckoutFromBranch(parentB)
            return
        }
        
        var dst = randomChoice(branchNames)
        var src = randomChoice(branchNames)
        if (dst === src) {
            var parentB = randomChoice(branchNames)
            simulateCheckoutFromBranch(parentB)
            return
        }

        simulateMerge(dst, src)
    }
    
    function addCommitsToPreviousBranches(currentBranch) {
        var branchNames = getBranchNamesFromModel()
        
        var previousBranches = []
        
        // Filter branches manually (QML compatible)
        for (var i = 0; i < branchNames.length; i++) {
            if (branchNames[i] !== currentBranch) {
                previousBranches.push(branchNames[i])
            }
        }

        if (previousBranches.length === 0) {
            return
        }
        
        // Add commits to 1-2 random previous branches
        var numBranchesToUpdate = Math.min(2, previousBranches.length)
        var selectedBranches = []
        
        for (var i = 0; i < numBranchesToUpdate; i++) {
            var randomBranch = randomChoice(previousBranches)
            if (randomBranch && selectedBranches.indexOf(randomBranch) === -1) {
                selectedBranches.push(randomBranch)
            }
        }

        // Add commits to selected branches
        for (var j = 0; j < selectedBranches.length; j++) {
            var branch = selectedBranches[j]
            var actionType = Math.random()
            
            if (actionType < 0.7) {
                // 70% chance: add a simple commit
                simulateCommitOnBranch(branch)
            } else {
                // 30% chance: try to merge current branch into this branch
                if (currentBranch !== branch) {
                    simulateMerge(branch, currentBranch)
                }
            }
        }
    }
}
