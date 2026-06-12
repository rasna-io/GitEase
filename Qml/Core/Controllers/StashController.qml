import QtQuick

import GitEase

/*! ***********************************************************************************************
 * StashController
 * ************************************************************************************************/
GitStash {
    property StatusController statusController

    function stashLines(filePath, startLine, endLine, mode) {
        let content = statusController.buildSelectedLinesContent(filePath, startLine, endLine, mode)
        if (!content || content.length === 0) {
            return
        }

        let message = (startLine === endLine) ? `Stash line ${startLine} of ${filePath}` : `Stash lines ${startLine}-${endLine} of ${filePath}`
        let result = stashSelectedLines(filePath, message, content)
        if(result.success)
        {
            statusController.revertSelectedLines(filePath, startLine, endLine, mode)
        }

        return result
    }
}

