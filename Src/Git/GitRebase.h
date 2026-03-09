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
     * @brief Start an interactive-less rebase of the current branch onto @p upstream.
     * @param upstream Target ref/branch/commit to rebase onto (required).
     * @param branch Optional branch to rebase; if empty, uses current branch.
     */
    Q_INVOKABLE GitResult rebase(const QString& upstream, const QString& branch = QString());
    /**
     * @brief Rebase with explicit onto target (equivalent to git rebase --onto).
     * @param onto New base where commits should be replayed.
     * @param upstream Upstream boundary (commits after this are replayed).
     * @param branch Optional branch to rebase; if empty, uses current branch.
     */
    Q_INVOKABLE GitResult rebaseOnto(const QString& onto,
                                     const QString& upstream,
                                     const QString& branch = QString());

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
};
