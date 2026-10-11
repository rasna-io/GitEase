.pragma library

/* Pure helpers for the Files view: filtering, building the tree rows and reading the selection.
 * Nothing here touches the UI, so every function takes what it needs and returns plain data.
 * ****************************************************************************************/

var CHANGE_STATUSES = { modified: true, staged: true, added: true, deleted: true,
                        renamed: true, conflicted: true }

function isChange(status) {
    return CHANGE_STATUSES[status] === true
}

function isTracked(file) {
    return file.status !== "untracked" && file.status !== "ignored"
}

function matchesFilter(file, filter) {
    switch (filter) {
    case "changes":
        return isChange(file.status)
    case "untracked":
        return file.status === "untracked"
    case "ignored":
        return file.status === "ignored"
    case "committed":
        return file.status === "committed"
    case "trackedIgnored":
        return file.trackedIgnored
    default:
        return true
    }
}

//! Files that pass the hidden-files switch, the search text and the status filter, plus counts.
function filterFiles(files, showHidden, search, filter) {
    const needle = search.trim().toLowerCase()
    const list = []
    const stats = { all: 0, changes: 0, untracked: 0, ignored: 0, committed: 0, trackedIgnored: 0 }

    for (let i = 0; i < files.length; i++) {
        const f = files[i]
        if (!showHidden && f.hidden)
            continue
        if (needle.length > 0 && f.path.toLowerCase().indexOf(needle) === -1)
            continue

        stats.all++
        if (isChange(f.status)) {
            stats.changes++
        }
        if (f.status === "untracked") {
            stats.untracked++
        }
        if (f.status === "ignored") {
            stats.ignored++
        }
        if (f.status === "committed") {
            stats.committed++
        }
        if (f.trackedIgnored) {
            stats.trackedIgnored++
        }

        if (matchesFilter(f, filter))
            list.push(f)
    }
    return { list: list, stats: stats }
}

//! One status for a folder: all ignored, all untracked, conflicted, changed or clean.
function folderStatusOf(st) {
    if (!st || st.total === 0)
        return "committed"
    if (st.ignored === st.total)
        return "ignored"
    if (st.untracked === st.total)
        return "untracked"
    if (st.conflicted > 0)
        return "conflicted"
    if (st.changes > 0 || st.untracked > 0)
        return "changed"
    return "committed"
}

/*!
 * Flat rows of the tree: folders first, then files, both A-Z. A folder's children are only
 * emitted when isExpanded(path) says so. Also returns the number of files under each folder
 * and which folders hold changed or untracked files.
 */
function buildRows(files, isExpanded) {
    const top = { folders: {}, files: [] }
    const totals = {}
    const changed = {}
    const agg = {}

    for (let i = 0; i < files.length; i++) {
        const f = files[i]
        const parts = f.path.split("/").filter(part => part.length > 0)
        const changedFile = isChange(f.status) || f.status === "untracked"

        let node = top
        let path = ""
        for (let d = 0; d < parts.length - 1; d++) {
            path = path.length > 0 ? path + "/" + parts[d] : parts[d]
            if (!node.folders[parts[d]])
                node.folders[parts[d]] = { name: parts[d], path: path, folders: {}, files: [] }
            node = node.folders[parts[d]]

            totals[path] = (totals[path] || 0) + 1
            const st = agg[path] || (agg[path] = { total: 0, changes: 0, untracked: 0, ignored: 0, conflicted: 0 })
            st.total++
            if (f.status === "ignored") {
                st.ignored++
            } else if (f.status === "untracked") {
                st.untracked++
            } else if (f.status === "conflicted") {
                st.conflicted++
            } else if (isChange(f.status)) {
                st.changes++
            }
            if (changedFile)
                changed[path] = true
        }
        node.files.push(f)
    }

    const rows = []
    const byName = (a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase())

    function emit(node, depth) {
        const folders = Object.keys(node.folders).map(k => node.folders[k]).sort(byName)
        for (const folder of folders) {
            rows.push({ kind: "folder", depth: depth, name: folder.name, path: folder.path,
                        status: folderStatusOf(agg[folder.path]) })
            if (isExpanded(folder.path, totals[folder.path] || 0))
                emit(folder, depth + 1)
        }
        // An ignored folder is one entry from git; it sits with the folders.
        const entries = node.files.slice().sort(byName)
        for (const f of entries.filter(x => x.isDir))
            rows.push({ kind: "file", depth: depth, name: f.name, path: f.path, file: f })
        for (const f of entries.filter(x => !x.isDir))
            rows.push({ kind: "file", depth: depth, name: f.name, path: f.path, file: f })
    }
    emit(top, 0)

    return { rows: rows, totals: totals, changed: changed }
}

/*!
 * Splits the selection by what can be done with it. A selected key ending in "/" that git did
 * not report is a whole folder: it becomes one entry (one rule) and its committed files are
 * listed in `tracked` so they can leave the index.
 */
function analyseSelection(selected, files) {
    const byPath = {}
    for (let i = 0; i < files.length; i++)
        byPath[files[i].path] = files[i]

    const result = { toIgnore: [], toUnignore: [], tracked: [], trackedIgnored: [] }

    for (const path in selected) {
        const f = byPath[path]

        if (!f && path.endsWith("/")) {
            const trimmed = path.substring(0, path.length - 1)
            const slash = trimmed.lastIndexOf("/")
            result.toIgnore.push({ path: path, name: trimmed.substring(slash + 1),
                                   dir: slash < 0 ? "" : trimmed.substring(0, slash),
                                   status: "folder", staged: false, isDir: true, ignored: false,
                                   trackedIgnored: false, hidden: false })
            for (let i = 0; i < files.length; i++) {
                if (files[i].path.indexOf(path) === 0 && isTracked(files[i]))
                    result.tracked.push(files[i])
            }
            continue
        }
        if (!f)
            continue

        if (f.status === "ignored") {
            result.toUnignore.push(f)
        } else if (f.trackedIgnored) {
            result.toUnignore.push(f)
            result.trackedIgnored.push(f)
        } else {
            result.toIgnore.push(f)
            if (isTracked(f))
                result.tracked.push(f)
        }
    }
    return result
}

//! The selection without entries that are no longer in the repository.
function pruneSelection(selected, files) {
    const present = {}
    for (let i = 0; i < files.length; i++) {
        const path = files[i].path
        present[path] = true
        let slash = path.indexOf("/")
        while (slash > 0) {
            present[path.substring(0, slash + 1)] = true
            slash = path.indexOf("/", slash + 1)
        }
    }

    const kept = {}
    let count = 0
    for (const path in selected) {
        if (present[path]) {
            kept[path] = true
            count++
        }
    }
    return { selected: kept, count: count }
}

//! True when a folder above \a path is selected, which already covers it.
function isCovered(selected, path) {
    let slash = path.lastIndexOf("/", path.endsWith("/") ? path.length - 2 : path.length)
    while (slash > 0) {
        if (selected[path.substring(0, slash + 1)] === true)
            return true
        slash = path.lastIndexOf("/", slash - 1)
    }
    return false
}

//! Every folder that contains one of \a files, as a list of paths.
function folderPaths(files) {
    const seen = {}
    const list = []
    for (let i = 0; i < files.length; i++) {
        const path = files[i].path
        let slash = path.indexOf("/")
        while (slash > 0) {
            const folder = path.substring(0, slash)
            if (!seen[folder]) {
                seen[folder] = true
                list.push(folder)
            }
            slash = path.indexOf("/", slash + 1)
        }
    }
    return list
}
