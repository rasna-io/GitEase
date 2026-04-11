#pragma once

#include "GitResult.h"
#include "IGitController.h"
#include <QObject>

struct git_commit;
struct git_reference;
struct git_index;
struct git_signature;

/**
 * @brief Handles branch merging and merge lifecycle.
 *
 * Responsibilities:
 *  - Performing merge analysis (fast‑forward, normal, up‑to‑date)
 *  - Executing fast‑forward and normal merges
 *  - Creating merge commits
 *  - Managing merge state (in‑progress, pending commits)
 *
 * Conflict inspection and resolution are delegated to GitConflict.
 */
class GitMerge : public IGitController
{
    Q_OBJECT
    Q_PROPERTY(bool mergeConflicts READ hasMergeConflicts NOTIFY mergeStateChanged FINAL)
    Q_PROPERTY(bool mergeInProgress READ isMergeInProgress NOTIFY mergeStateChanged FINAL)
    QML_ELEMENT


private:
    bool m_mergeInProgress = false;
    QString m_pendingSourceHash;   // SHA of the source commit (the branch being merged)
    QString m_pendingTargetHash;   // SHA of the target commit (the branch we were on)
    QString m_pendingSourceName;   // Name of the source branch
    QString m_pendingTargetName;   // Name of the target branch
    QString m_pendingMergeMessage; // Default merge message

private:
    // Merge analysis and execution helpers
    GitResult analyzeAndPerformMerge(git_commit* targetCommit,
                                     git_commit* sourceCommit,
                                     git_reference* sourceRef);
    GitResult performFastForward(git_commit* sourceCommit);
    GitResult performNormalMerge(git_reference* sourceRef);

    // Commit creation helper
    GitResult createMergeCommit(const QString& message,
                                git_commit* targetCommit,
                                git_commit* sourceCommit,
                                git_index* index);

    GitResult handleMergeConflicts(git_reference* sourceRef);

    GitResult finalizeAutomaticMerge(git_reference* sourceRef,
                                     git_annotated_commit* annotated,
                                     git_index* index);


    git_signature* createSignature() const;

    QString currentBranchName() const;

    void resetMergeState();

    void storeMergeMetadata(git_reference* sourceRef);

public:
    explicit GitMerge(QObject* parent = nullptr);

    /**
     * @brief Merges the given source branch into the currently checked out branch.
     * @param sourceBranch Name of the branch to merge (local branch).
     * @return GitResult indicating success or failure, with an optional message.
     */
    Q_INVOKABLE GitResult mergeBranchIntoCurrent(const QString& sourceBranch);

    /**
     * @brief Continues a merge after all conflicts have been resolved.
     * @param commitMessage Optional custom commit message. If empty, a default is used.
     * @return GitResult indicating success or failure.
     */
    Q_INVOKABLE GitResult continueMerge(const QString& commitMessage = QString());

    /**
     * @brief Checks whether the repository currently has merge conflicts.
     * @return true if conflicts exist in the index.
     */
    Q_INVOKABLE bool hasMergeConflicts() const;

    /**
     * @brief Checks whether a merge operation is in progress (i.e., conflicts are pending).
     * @return true if a merge was started but not yet committed.
     */
    Q_INVOKABLE bool isMergeInProgress() const;

    /// Abort an in-progress merge (`git merge --abort`).
    Q_INVOKABLE GitResult abortMerge();

signals:
    /**
     * @brief Emitted whenever the merge state changes (start, conflict, resolution, completion).
     */
    void mergeStateChanged();

};
