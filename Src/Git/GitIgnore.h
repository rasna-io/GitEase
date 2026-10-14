#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QStringList>

#include "GitResult.h"
#include "IGitController.h"

class GitStatus;

/**
 * @class GitIgnore
 * @brief Ignore-aware repository status for the Gitignore Manager plugin (and anything else that
 * needs to know which files are ignored, and why).
 *
 * Changed and untracked files come from GitStatus and the branch from GitBranch. What this
 * controller adds is what they leave out: ignored files (folders collapsed to one entry), the
 * tracked-but-ignored marker, and the rule behind an ignored path, which libgit2 does not expose.
 * Taking files out of the index is GitStatus::removeFromIndex().
 */
class GitIgnore : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit GitIgnore(QObject *parent = nullptr);

    /**
     * @brief Working directory and current branch of the repository.
     * @return GitResult with data as a map { root, branch }. branch is "Detached HEAD" when detached.
     */
    Q_INVOKABLE GitResult repositoryInfo();

    /**
     * @brief Status of every file: tracked, untracked and ignored.
     *
     * Ignored folders that are ignored as a whole are one entry with a trailing slash.
     *
     * @return GitResult with data as a map { root, branch, entries }. An entry is
     * { path, status, staged, isDir, ignored, trackedIgnored } where status is committed,
     * modified, staged, added, deleted, renamed, conflicted, untracked or ignored, and
     * trackedIgnored marks tracked files that a rule matches (the rule has no effect on them).
     */
    Q_INVOKABLE GitResult scan();

    /**
     * @brief The rules that ignore \a paths.
     *
     * Equivalent of git check-ignore -v --no-index: a path that is tracked is still checked.
     * Paths that are not ignored, or that a negated rule re-includes, are left out.
     *
     * @param paths Paths relative to the repository root; a trailing slash marks a folder.
     * @return GitResult with data as a list of { path, source, line, pattern }. source is
     * relative to the root (".gitignore", "sub/.gitignore", ".git/info/exclude") or the absolute
     * path of the global excludes file.
     */
    Q_INVOKABLE GitResult checkIgnore(const QStringList &paths);

private:
    //! Source of the changed and untracked files; bound to the same repository as this controller.
    GitStatus *m_status = nullptr;
};
