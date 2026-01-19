import QtQuick

import GitEase

/*! ***********************************************************************************************
 * BranchController
 * ************************************************************************************************/
GitBranch {
    id : root

    function getBranchLineage(branchName) : var {
        if (!branchName) {
            console.warn("getBranchLineage: branchName is empty")
            return []
        }

        var result = GitService.getBranchLineage(branchName)

        if (result.success) {
            // result.data contains the QVariantList we filled in C++
            return result.data
        } else {
            console.error("Failed to get lineage:", result.message)
            return []
        }
    }

}
