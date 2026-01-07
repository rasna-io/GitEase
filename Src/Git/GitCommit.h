#pragma once


#include <QObject>
#include <git2/types.h>
#include "GitResult.h"
#include "IGitController.h"
#include "Repository.h"


/**
 * \brief Structure to hold parent commit information
 *
 * In Git, every commit has 0+ parent commits:
 * - Initial commit: 0 parents
 * - Normal commit: 1 parent (previous commit)
 * - Merge commit: 2+ parents
 */
struct ParentCommits
{
    git_commit** commits = nullptr;         ///< Array of parent commit pointers
    size_t count = 0;                       ///< Number of parents
    git_commit* amendedCommit = nullptr;    ///< Original commit being amended (for cleanup)
};

class GitCommit : public IGitController
{

    Q_OBJECT
    QML_ELEMENT

public:
    explicit GitCommit(QObject *parent = nullptr);


    /**
     * \brief Get commit history (paged)
     * \param limit Maximum number of commits to return (default: 50)
     * \param offset Number of commits to skip from the start of the walk (default: 0)
     * \return GitResult
     */
    Q_INVOKABLE GitResult getCommits(int limit = 50, int offset = 0);

    /**
     * \brief Get detailed information about a specific commit
     * \param commitHash Full or short commit hash
     * \return QVariantMap with commit details
     */
    Q_INVOKABLE GitResult getCommit(const QString &commitHash);

    /**
    * \brief Get a parent commit hash by index
    *
    * Returns the hash of the parent commit at the specified index.
    *
    * - index = 0 → first parent (default Git diff behavior)
    * - index > 0 → additional parents (merge commits)
    * - Initial commits have no parents → returns empty string
    *
    * \param commitHash Full or short commit hash
    * \param index Parent index (default: 0)
    * \return Parent commit hash, or empty string if index is invalid
    */
    Q_INVOKABLE QString getParentHash(const QString &commitHash, int index = 0);

    /**
     * \brief Create a new commit with staged changes
     * \param message Commit message (required)
     * \param amend Whether to amend the previous commit (default: false)
     * \param allowEmpty Allow empty commit (no changes) (default: false)
     * \return QVariantMap with commit result
     */
    Q_INVOKABLE GitResult commit(const QString &message, bool amend = false, bool allowEmpty = false);

    /**
     * \brief Validate commit message
     * \param message Commit message to validate
     * \return bool
     */
    bool validateCommitMessage(const QString &message);


    /**
     * \brief Get author signature for commit
     * \param repo Repository to get default signature from
     * \return git_signature* (caller must free) or nullptr on error
     */
    git_signature* getAuthorSignature(git_repository* repo);

    /**
     * \brief Creates tree object from staged changes in index
     * \return  git_tree* (caller must free) or nullptr on error
     */
    git_tree* createTreeFromStagedChanges();


    /**
     * \brief Resolves parent commits for new commit
     * \param amend Whether we're amending previous commit
     * \return ParentCommits structure (must call freeParentCommits)
     */
    ParentCommits resolveParentCommits(bool amend);


    /**
     * \brief Centralized cleanup of all commit-related resources
     * \param signature Author/committer signature to free
     * \param tree Tree object to free
     * \param parents Parent commits structure to free
     */
    void cleanupCommitResources(git_signature* signature, git_tree* tree,
                                ParentCommits& parents);


    /**
     * \brief Amend the last commit with a new message
     * \param newMessage New commit message
     * \return GitResult with operation result
     */
    Q_INVOKABLE GitResult amendLastCommit(const QString &newMessage);

    /**
     * \brief Revert a specific commit
     * \param commitHash Hash of commit to revert
     * \return GitResult with operation result
     */
    Q_INVOKABLE GitResult revertCommit(const QString &commitHash);

    /**
     * \brief Frees resources allocated in ParentCommits structure
     * \param parents Structure to clean up
     */
    void freeParentCommits(ParentCommits& parents);


    Repository *currentRepo() const;

    void setCurrentRepo(Repository *newCurrentRepo);

private:
    QStringList getAllParents(git_commit* gitCommit);

};

