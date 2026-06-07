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

    /// Build an interactive rebase plan without changing the repository.
    Q_INVOKABLE GitResult previewRebasePlan(const QString& onto,
                                            const QString& upstream,
                                            const QString& branch = QString());


    /// Continue an in-progress rebase (`git rebase --continue`).
    Q_INVOKABLE GitResult continueOp();

    /// Skip current rebase operation and continue (`git rebase --skip`).
    Q_INVOKABLE GitResult skipOp();

    /// Abort an in-progress rebase (`git rebase --abort`).
    Q_INVOKABLE GitResult abortOp();

    /// Quit rebase mode and cleanup state without resetting branch (`git rebase --quit`).
    Q_INVOKABLE GitResult quitOp();

    /// Return details about current rebase progress/conflicts.
    Q_INVOKABLE GitResult rebaseStatus();

    /**
     * @brief Start an interactive rebase driven by a user‑provided plan.
     *
     * The plan (operations) is an array of QVariantMap objects, each
     * containing at minimum "action" (string: "pick"/"skip") and "hash".
     * The commits are applied **in the order they appear in the array**,
     * giving the UI full control over the sequence.
     *
     * @param onto        New base commit. If empty, upstream is used as the base.
     * @param upstream    Upstream boundary (only used if onto is empty).
     * @param branch      Optional branch to rebase (empty = current HEAD).
     * @param operations  The interactive plan in user‑specified order.
     */
    Q_INVOKABLE void startInteractiveRebase(const QString& onto,
                                            const QString& upstream,
                                            const QString& branch,
                                            const QVariantList& operations);

    /**
     * @brief Continue the interactive rebase after the user has resolved conflicts.
     *
     * This must only be called when the rebase is in a conflict state
     * (after rebaseConflict() was emitted).
     */
    Q_INVOKABLE void interactiveContinue();

    /**
     * @brief Skip the current operation and move to the next one.
     *
     * Any conflicting changes are discarded.
     */
    Q_INVOKABLE void interactiveSkip();

    /**
     * @brief Abort the entire interactive rebase and return to the
     *        original state before the rebase started.
     */
    Q_INVOKABLE void interactiveAbort();

private:
    GitResult startRebase(const QString& onto,
                          const QString& upstream,
                          QString branch,
                          const QSet<QString>& skippedCommits);

    GitResult runRebase(git_rebase* rebase,
                        bool continueCurrentOperation,
                        const QSet<QString>& skippedCommits = {});

    GitResult conflictResult(git_rebase* rebase, const QString& message);
    GitResult openRebase(git_rebase** rebase) const;
    QVariantMap rebaseProgressData(git_rebase* rebase) const;
    GitResult resetWorktreeToHead() const;
    bool repositoryHasConflicts() const;
    bool isRebaseInProgress() const;

    // Helper to check out a branch
    GitResult checkoutBranch(const QString& branchName);
    QString getCurrentBranchName();


    /**
     * @brief Process the next entry in the plan.
     *
     * This function implements the main step‑by‑step loop of the
     * interactive rebase.  For each entry it either skips the commit
     * or cherry‑picks it.  It reschedules itself via QTimer::singleShot
     * to keep the event loop responsive.
     */
    void processNextOperation();

    /**
     * @brief Release all resources held by the interactive rebase session.
     */
    void cleanupInteractiveState();

    /**
     * @brief Look up a commit by its full SHA-1 hash.
     * @param hash 40-character hex string.
     * @return The commit object (caller must free with git_commit_free), or nullptr.
     */
    git_commit* lookupCommit(const QString& hash) const;

    /**
     * @brief Perform a cherry‑pick of a commit onto the current HEAD.
     *
     * The cherry‑pick only stages the changes; a separate commit step
     * is required to finalise it.
     *
     * @param commit  Commit to cherry‑pick.
     * @return GIT_OK on success, GIT_EMERGECONFLICT if conflicts occur,
     *         or another error code.
     */
    int cherryPickCommit(git_commit* commit);

    /**
     * @brief Create a commit from the current index, preserving the
     *        original author and message of the cherry‑picked commit.
     *
     * @param originalCommit  The commit that was cherry‑picked.
     * @return true on success.
     */
    bool commitCherryPick(git_commit* originalCommit);

    /**
     * @brief Abort an in‑progress cherry‑pick by resetting the index
     *        and worktree to HEAD.
     */
    void abortCherryPick();

    /**
     * @brief Reset HEAD and worktree to the given commit, discarding
     *        all local changes (used during abort).
     */
    bool resetToCommit(git_commit* target);

    QVariantList    m_interactivePlan;                  ///< Full plan as received from the UI.
    bool            m_interactiveInProgress = false;    ///< True while an interactive rebase is active.
    QString         m_interactiveOnto;                  ///< --onto reference (empty if not used).
    QString         m_interactiveUpstream;              ///< Upstream reference.
    QString         m_interactiveBranch;                ///< Branch being rebased (empty = HEAD).

    git_commit*     m_newBaseCommit         = nullptr;  ///< The commit onto which we rebase.
    git_reference*  m_originalHeadRef       = nullptr;  ///< Original HEAD before the rebase started.
    int             m_currentPlanIndex      = 0;        ///< Current position in m_interactivePlan.
    QString         m_currentOpHash;                    ///< Hash of the commit currently being processed.
    bool            m_isCherryPickActive    = false;    ///< True while a cherry‑pick is in progress (possibly conflicted).

    git_oid         m_originalHeadOid;                  ///< Original HEAD commit OID (if detached).
    bool            m_originalHeadDetached;             ///< True if we started from a detached HEAD.

    git_signature*  m_defaultSignature      = nullptr;

signals:
    /**
     * @brief Emitted when a rebase operation begins for a commit.
     *
     * @param commitHash Full SHA‑1 hash of the commit being processed.
     */
    void rebaseOperationStarted(const QString& commitHash);

    /**
     * @brief Emitted after a commit has been successfully applied.
     *
     * @param commitHash Full SHA‑1 hash of the rebased commit.
     */
    void rebaseOperationCompleted(const QString& commitHash);

    /**
     * @brief Emitted when a commit is skipped during the rebase.
     *
     * @param commitHash Full SHA‑1 hash of the skipped commit.
     */
    void rebaseOperationSkipped(const QString& commitHash);

    /**
     * @brief Emitted when a rebase operation stops due to conflicts.
     *
     * The UI should prompt the user to resolve conflicts and then call
     * `interactiveContinue()` or `interactiveSkip()`.
     *
     * @param commitHash Full SHA‑1 hash of the commit that caused the conflict.
     */
    void rebaseConflict(const QString& commitHash);

    /**
     * @brief Emitted when the interactive rebase finishes.
     *
     * @param success True if the rebase completed successfully,
     *                false if it failed.
     */
    void rebaseFinished(bool success);

    /**
     * @brief Emitted when the user aborts the interactive rebase.
     */
    void rebaseAborted();

};
