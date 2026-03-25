#pragma once

#include <QObject>
#include <QQmlEngine>

#include "IGitController.h"
#include "GitResult.h"

struct git_rebase;

/**
 * @brief Libgit2-powered rebase controller.
 *
 * Supports non-interactive rebase flows:
 * - start (optionally with branch and/or --onto semantics)
 * - continue
 * - skip
 * - abort
 * - quit (cleanup rebase state only)
 * - status query
 */
class GitRebase : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit GitRebase(QObject* parent = nullptr);

    /**
     * @brief Rebase a branch (or the current branch) onto an upstream.
     *
     * This is a convenience wrapper for `rebaseOnto` with an empty `onto`.
     *
     * @param upstream The target reference (branch, tag, or commit) to rebase onto.
     * @param branch   Optional branch to rebase. If empty, the current HEAD branch is used.
     *                 If provided, the branch will be checked out before the rebase.
     * @return GitResult containing success status and data.
     */
    Q_INVOKABLE GitResult rebase(const QString& upstream, const QString& branch = QString());

    /**
     * @brief Rebase a branch with an explicit `--onto` target.
     *
     * Equivalent to `git rebase --onto <onto> <upstream> <branch>`.
     *
     * @param onto     New base for the commits (the commits after `upstream` will be replayed onto this).
     *                 If empty, `upstream` serves as both the base and the boundary.
     * @param upstream Upstream boundary (commits after this point are replayed).
     * @param branch   Optional branch to rebase. If empty, the current HEAD branch is used.
     *                 If provided, the branch will be checked out before the rebase.
     * @return GitResult containing success status and data.
     */
    Q_INVOKABLE GitResult rebaseOnto(const QString& onto,
                                     const QString& upstream,
                                     QString branch = QString());

    /// Continue an in-progress rebase (`git rebase --continue`).
    Q_INVOKABLE GitResult continueRebase();

    /// Skip current rebase operation and continue (`git rebase --skip`).
    Q_INVOKABLE GitResult skipRebase();

    /// Abort an in-progress rebase (`git rebase --abort`).
    Q_INVOKABLE GitResult abortRebase();

    /// Quit rebase mode and cleanup state without resetting branch (`git rebase --quit`).
    Q_INVOKABLE GitResult quitRebase();

    /// Return details about current rebase progress/conflicts.
    Q_INVOKABLE GitResult rebaseStatus();

private:
    GitResult runRebase(git_rebase* rebase, bool continueCurrentOperation);
    GitResult conflictResult(git_rebase* rebase, const QString& message);
    GitResult openRebase(git_rebase** rebase) const;
    QVariantMap rebaseProgressData(git_rebase* rebase) const;
    GitResult resetWorktreeToHead() const;
    bool repositoryHasConflicts() const;
    bool isRebaseInProgress() const;

    // Helper to check out a branch
    GitResult checkoutBranch(const QString& branchName);
    QString getCurrentBranchName();
};
