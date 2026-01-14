#pragma once

#include <QObject>
#include <memory>
#include <vector>
#include <QString>

#include <git2/blob.h>
#include <git2/diff.h>
#include <git2/patch.h>
#include <git2/index.h>

#include "GitFileStatus.h"
#include "GitResult.h"
#include "IGitController.h"

// Smart pointer deleters for libgit2 types
struct IndexDeleter { void operator()(git_index* p) const { git_index_free(p); } };
struct BlobDeleter  { void operator()(git_blob* p)  const { git_blob_free(p);  } };
struct DiffDeleter  { void operator()(git_diff* p)  const { git_diff_free(p);  } };
struct PatchDeleter { void operator()(git_patch* p) const { git_patch_free(p); } };

using UniqueIndex = std::unique_ptr<git_index, IndexDeleter>;
using UniqueBlob  = std::unique_ptr<git_blob,  BlobDeleter>;
using UniqueDiff  = std::unique_ptr<git_diff,  DiffDeleter>;
using UniquePatch = std::unique_ptr<git_patch, PatchDeleter>;

class GitStatus : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit GitStatus(QObject *parent = nullptr);

    /**
     * \brief Stage a file for commit
     * \param filePath Path to the file to stage
     * \return GitResult with operation result
     */
    Q_INVOKABLE GitResult stageFile(const QString &filePath);

    /**
     * \brief Unstage a file
     * \param filePath Path to the file to unstage
     * \return GitResult with operation result
     */
    Q_INVOKABLE GitResult unstageFile(const QString &filePath);

    /**
     * \brief Stage all unstaged changes
     * \param includeUntrackedFiles Include new files not yet tracked by git
     * \return GitResult with count of staged files
     */
    Q_INVOKABLE GitResult stageAll(bool includeUntrackedFiles = true);

    /**
     * \brief Unstage all staged changes
     * \return GitResult with count of unstaged files
     */
    Q_INVOKABLE GitResult unstageAll();

    /**
     * \brief Get list of currently staged files
     * \return GitResult with staged files list
     */
    Q_INVOKABLE GitResult getStagedFiles();

    /**
     * \brief Get repository status (staged/unstaged/untracked files)
     * \return GitResult with status information
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

    /**
     * @brief Prepares a side-by-side diff view compatible with the QML DiffDelegate.
     * @param filePath Path to the file to inspect.
     */
    Q_INVOKABLE GitResult getDiffView(const QString& filePath);

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

    /**
     * @brief Retrieves the blob from the current index for a specific file.
     * @param repo Pointer to the active repository.
     * @param filePath Path of the file.
     * @param outMode Pointer to store the file mode (permissions).
     * @return Unique pointer to the git_blob.
     */
    UniqueBlob getIndexBlob(git_repository *repo, const QString &filePath, uint32_t *outMode);

    /**
     * @brief Converts a git_blob into a list of strings (one per line).
     * @param blob The git blob to read.
     * @return A vector of line contents.
     */
    std::vector<QString> readBlobLines(git_blob *blob);

    /**
     * @brief Splits a raw string into a vector of lines, preserving empty lines.
     * @param raw The raw content string.
     * @return A vector of strings split by newline characters.
     */
    std::vector<QString> splitLines(const QString &raw);

    /**
     * @brief Joins a vector of lines back into a single newline-delimited string.
     * @param lines The lines to join.
     * @return A single formatted string.
     */
    QString joinLines(const std::vector<QString> &lines);

    /**
     * @brief Reads the actual file content currently on disk (Working Directory).
     * @param repo Pointer to the active repository.
     * @param filePath Path of the file.
     * @return A vector of lines from the physical file.
     */
    std::vector<QString> readWorkdirLines(git_repository *repo, const QString &filePath);

    /**
     * @brief Internal logic to merge a specific patch range into a set of base lines.
     * @param indexLines The current lines stored in the Git Index.
     * @param patch The diff patch containing the new changes.
     * @param startLine The selection start.
     * @param endLine The selection end.
     * @return The resulting lines after the selective application.
     */
    std::vector<QString> applySelectedFromPatch(const std::vector<QString>& indexLines,
                                                git_patch* patch,
                                                int startLine,
                                                int endLine);
};
