#pragma once

#include <QString>
#include <QVariantMap>

/*!
 * Turns the status the host reports into what the page shows, and reads the root .gitignore.
 * The git work itself is done by the host's GitIgnore controller.
 */
namespace RepositoryScanner {

/*!
 * Builds the page model from  hostScan, the data of GitIgnore::scan() ({ root, branch, entries }).
 * Meant to run on a worker thread: it sorts and counts every file and reads the .gitignore.
 *
 * Result keys: success, errorMessage, root, branch, files, counts, truncated, hasGitignore,
 * gitignoreContent, eol, appliedTemplates.
 *
 * A file is { path, name, dir, status, staged, isDir, ignored, trackedIgnored, hidden } where
 * status is committed, modified, staged, added, deleted, renamed, conflicted, untracked or
 * ignored. Ignored folders are reported as one entry with a trailing slash.
 */
QVariantMap analyze(const QVariantMap &hostScan);

} // namespace RepositoryScanner
