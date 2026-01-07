#pragma once

#include <QObject>

#include <git2/diff.h>

#include "GitFileStatus.h"
#include "GitResult.h"
#include "IGitController.h"

class GitStatus : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit GitStatus(QObject *parent = nullptr);

    /**
     * \brief Stage a file for commit
     * \param filePath Path to the file to stage
     * \return QVariantMap with operation result
     */
    Q_INVOKABLE GitResult stageFile(const QString &filePath);


    /**
     * \brief Unstage a file
     * \param filePath Path to the file to unstage
     * \return QVariantMap with operation result
     */
    Q_INVOKABLE GitResult unstageFile(const QString &filePath);

    /**
     * \brief Stage all unstaged changes
     * \return QVariantMap with count of staged files
     */
    Q_INVOKABLE GitResult stageAll(bool includeUntrackedFiles  = true);

    /**
     * \brief Unstage all staged changes
     * \return QVariantMap with count of unstaged files
     */
    Q_INVOKABLE GitResult unstageAll();

    /**
     * \brief Get list of currently staged files
     * \return QVariantMap with staged files list
     */
    Q_INVOKABLE GitResult getStagedFiles();

    /**
     * \brief Get repository status (staged/unstaged/untracked files)
     * \return QVariantMap with status information
     */
    Q_INVOKABLE GitResult status();

    /**
     * \brief Stage or unstage a file in the repository index
     *
     * This method stages or unstages a file depending on the `isRemove` parameter. If `isRemove` is `false`,
     * the file will be staged. If `isRemove` is `true`, the file will be removed (unstaged).
     *
     * \param filePath The path to the file to stage or unstage
     * \param isRemove Flag indicating whether the file should be staged (false) or unstaged (true)
     * \return GitResult containing success status, file path, and operation message
     */
    GitResult addToIndex(const QString& filePath, bool isRemove = false);

    /**
    * @brief Retrieves a processed diff for a specific file.
    *
    * This function uses the Patience diff algorithm to compare the index with the
    * working directory and pairs deleted/added lines into a single row structure
    * for side-by-side visualization in QML.
    *
    * @param filePath The relative path of the file within the repository to diff.
    * @return A QVariantList of maps containing line data (type, oldLine, newLine, content, contentNew).
    */
    Q_INVOKABLE GitResult getDiff(const QString &filePath);

    /**
    * @brief Retrieves a side-by-side diff between two specific commits for a file.
    * @param oldCommitHash The hash of the base commit.
    * @param newCommitHash The hash of the target commit to compare against.
    * @param filePath The relative path of the file.
    */
    Q_INVOKABLE GitResult getDiff(const QString &oldCommitHash, const QString &newCommitHash,
                      const QString &filePath);

    /**
    * @brief Retrieves the list of files changed in a specific commit with their stats.
    *
    * This function compares the given commit with its parent (if any) and extracts
    * the list of modified, added, or deleted files along with line-level statistics
    * (additions and deletions counts).
    *
    * @param commitHash The SHA-1 hash of the commit to inspect.
    * @return A QVariantList of maps, where each map contains:
    * - "filePath" (QString): Relative path of the file.
    * - "status" (QString): "A" for Added, "D" for Deleted, "M" for Modified, "R" for Renamed.
    * - "additions" (int): Number of lines added in this file.
    * - "deletions" (int): Number of lines deleted in this file.
    */
    Q_INVOKABLE GitResult getCommitFileChanges(const QString &commitHash);

private:
    /**
     * \brief Helper method to create a diff between two trees (commit snapshots).
     *
     * This method creates a diff between two trees (commit snapshots) for a given file.
     *
     * \param oldTree The old tree object (snapshot of the old commit)
     * \param newTree The new tree object (snapshot of the new commit)
     * \param diff The diff object that will contain the differences
     * \return GitResult containing success/failure status
     */
    GitResult getDiffBetweenTrees(git_tree *oldTree, git_tree *newTree, git_diff *&diff);
    /**
     * \brief Process a diff object and return a list of file changes.
     *
     * This method processes the diff and returns a list of file changes.
     *
     * \param diff The diff object to process
     * \return A list of file changes represented as GitDiff objects
     */
    QList<GitFileStatus> processDiff(git_diff *diff);

};

