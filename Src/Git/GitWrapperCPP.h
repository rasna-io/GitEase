/*! ***********************************************************************************************
 * GitWrapperCPP : C++ wrapper for libgit2 operations, exposed to QML.
 *                 Follows the UML design as QML_Service layer.
 * ************************************************************************************************/
#ifndef GITWRAPPERCPP_H
#define GITWRAPPERCPP_H

#include <QObject>
#include <QString>
#include <QVariant>
#include <QVariantList>
#include <QVariantMap>
#include <QQmlEngine>
#include <QDir>

extern "C" {
#include <git2.h>
}

/**
 * This class implements all Git operations required by the multi-page dockable Git client.
 * It follows the UML design exactly, exposing all methods as Q_INVOKABLE for QML access.
 *
 * \endcode
 */
class GitWrapperCPP : public QObject
{
    Q_OBJECT
    QML_ELEMENT

private:
    git_repository* m_currentRepo = nullptr;    ///< Currently opened repository handle
    QString m_currentRepoPath;                  ///< Path of currently open repository
    QString m_lastError;                        ///< Last error message for debugging

    /* Private Helper Functions */

    /**
     * \brief Handle libgit2 error and store in m_lastError
     * \param errorCode libgit2 error code
     *
     * Extracts error message from libgit2 and stores it for later retrieval.
     */
    void handleGitError(int errorCode);

    /**
     * \brief Create standardized operation result
     * \param success Whether operation succeeded
     * \param data Additional data to include (optional)
     * \param errorMessage Error message if failed (optional)
     * \return QVariantMap with standard result format
     *
     * Format: {"success": bool, "data": variant, "error": string}
     */
    QVariantMap createResult(bool success, const QVariant &data = QVariant(),
                             const QString &errorMessage = "");

    /**
     * \brief Convert git_commit to QVariantMap
     * \param commit Git commit object to convert
     * \return QVariantMap with commit details
     */
    QVariantMap commitToMap(git_commit *commit);


    /**
     * \brief Get current branch name
     * \param repo Git repository to check
     * \return Current branch name or empty string if detached HEAD
     */
    QString getCurrentBranchName(git_repository* repo);

    /**
     * \brief Convert status entry to QVariantMap
     * \param entry Git status entry to convert
     * \return QVariantMap with file status information
     */
    QVariantMap statusEntryToMap(const git_status_entry *entry);

    /**
     * \brief Check if path is absolute and exists
     * \param path Path to validate
     * \return true if path is absolute and exists
     */
    bool isValidPath(const QString &path);

    /* Commit Operations */

    /**
     * \brief Check if there are any staged changes
     * \return true if there are staged changes
     */
    bool hasStagedChanges();

    /**
     * \brief Validate commit message
     * \param message Commit message to validate
     * \return Empty string if valid, error message if invalid
     */
    QString validateCommitMessage(const QString &message);

    /**
     * \brief Convert git_signature to QVariantMap
     * \param sig Git signature to convert
     * \return QVariantMap with signature details
     */
    QVariantMap createSignatureMap(const git_signature *sig);

    /* Internal Test Function */
    void unitTest();

    /**
     * \brief Run comprehensive tests for commit operations
     * Tests complete workflow: clone -> create files -> stage -> commit -> push
     */
    void unitTestForGitWorkflow();

public:
    /**
     * \brief Constructor - initializes libgit2 library
     * \param parent Parent QObject (optional)
     */
    explicit GitWrapperCPP(QObject *parent = nullptr);

    /**
     * \brief Destructor - shuts down libgit2 and cleans up
     */
    ~GitWrapperCPP();

signals:
    void cloneFinished(QVariantMap result);
    void cloneProgress(int progress);

public slots:
    /* Repository Operations - from UML GitService */

    /* these three functions set m_currentRepo */
    /**
     * \brief Initialize a new Git repository
     * \param path Path where to create the repository
     * \return QVariantMap with {"success": bool, "data": path, "error": message}
     *
     * Creates a new Git repository at the specified path.
     */
    Q_INVOKABLE QVariantMap init(const QString &path);

    /**
     * \brief Open an existing Git repository
     * \param path Path to the repository
     * \return QVariantMap with {"success": bool, "data": path, "error": message}
     */
    Q_INVOKABLE QVariantMap open(const QString &path);

    /**
     * \brief Clone a remote repository
     * \param url Remote repository URL
     * \param localPath Local path where to clone
     * \return QVariantMap with {"success": bool, "data": localPath, "error": message}
     */
    Q_INVOKABLE QVariantMap clone(const QString &url, const QString &localPath);

    /**
     * \brief Close the currently open repository
     * \return QVariantMap with {"success": bool, "error": message}
     */
    Q_INVOKABLE QVariantMap close();

    /* Git Operations - from UML GitService */

    /**
     * \brief Get repository status (staged/unstaged/untracked files)
     * \return QVariantMap with status information
     */
    Q_INVOKABLE QVariantMap status();

    /**
     * \brief Get commit history
     * \param limit Maximum number of commits to return (default: 50)
     * \return QVariantList of commit objects
     */
    Q_INVOKABLE QVariantList getCommits(int limit = 50);

    /**
     * \brief Get list of branches
     * \return QVariantList of branch objects with name, isRemote, isCurrent properties
     */
    Q_INVOKABLE QVariantList getBranches();

    /**
    * \brief Creates a new branch pointing to the current HEAD.
    * \param branchName Name of the new branch.
    * \param repoPath Path to the repository (optional).
    * \return True if creation was successful, false otherwise.
    */
    Q_INVOKABLE bool createBranch(const QString &branchName, const QString &repoPath = "");

    /**
    * \brief Deletes an existing local branch from the repository.
    * \param branchName The name of the local branch to be removed.
    * \param repoPath Path to the repository. If empty, uses the current repository.
    * \return True if the branch was successfully deleted, false otherwise.
    */
    Q_INVOKABLE bool deleteBranch(const QString &branchName, const QString &repoPath = "");

    /**
    * \brief Safely switches the current working directory to a target branch.
    * \param branchName The name of the local branch to checkout.
    * \param repoPath Path to the repository. If empty, uses the current repository.
    * \return True if the checkout was successful, false if there are conflicts or errors.
    */
    Q_INVOKABLE bool checkoutBranch(const QString &branchName, const QString &repoPath = "");

    /**
    * \brief Renames an existing local branch.
    * \param oldName The current name of the branch.
    * \param newName The new desired name for the branch.
    * \return True if the rename was successful.
    */
    Q_INVOKABLE bool renameBranch(const QString &oldName, const QString &newName);

    /**
    * \brief Retrieves the name of the tracked upstream branch.
    * \param localBranchName The name of the local branch to check.
    * \return The upstream branch name (e.g., "origin/main") or an empty QString if no upstream is set.
    */
    Q_INVOKABLE QString getUpstreamName(const QString &localBranchName);

    /**
     * \brief Get basic repository information
     * \return QVariantMap with repository info
     */
    Q_INVOKABLE QVariantMap getRepoInfo();

    /* Commit Operations */

    /**
     * \brief Create a new commit with staged changes
     * \param message Commit message (required)
     * \param amend Whether to amend the previous commit (default: false)
     * \param allowEmpty Allow empty commit (no changes) (default: false)
     * \return QVariantMap with commit result
     */
    Q_INVOKABLE QVariantMap commit(const QString &message, bool amend = false, bool allowEmpty = false);

    /**
     * \brief Stage a file for commit
     * \param filePath Path to the file to stage
     * \return QVariantMap with operation result
     */
    Q_INVOKABLE QVariantMap stageFile(const QString &filePath);

    /**
     * \brief Unstage a file
     * \param filePath Path to the file to unstage
     * \return QVariantMap with operation result
     */
    Q_INVOKABLE QVariantMap unstageFile(const QString &filePath);

    /**
     * \brief Stage all unstaged changes
     * \return QVariantMap with count of staged files
     */
    Q_INVOKABLE QVariantMap stageAll();

    /**
     * \brief Unstage all staged changes
     * \return QVariantMap with count of unstaged files
     */
    Q_INVOKABLE QVariantMap unstageAll();

    /**
     * \brief Get list of currently staged files
     * \return QVariantMap with staged files list
     */
    Q_INVOKABLE QVariantMap getStagedFiles();

    /**
     * \brief Get detailed information about a specific commit
     * \param commitHash Full or short commit hash
     * \return QVariantMap with commit details
     */
    Q_INVOKABLE QVariantMap getCommit(const QString &commitHash);

    /**
     * \brief Amend the last commit with a new message
     * \param newMessage New commit message
     * \return QVariantMap with operation result
     */
    Q_INVOKABLE QVariantMap amendLastCommit(const QString &newMessage);

    /**
     * \brief Revert a specific commit
     * \param commitHash Hash of commit to revert
     * \return QVariantMap with operation result
     */
    Q_INVOKABLE QVariantMap revertCommit(const QString &commitHash);

    /**
     * \brief Push commits to a remote repository
     * \param remoteName Name of the remote (default: "origin")
     * \param branchName Branch to push (default: current branch)
     * \param username GitHub username (required for HTTPS)
     * \param password GitHub Personal Access Token (required for HTTPS)
     * \param force Whether to force push (default: false)
     * \return QVariantMap with operation result
     */
    Q_INVOKABLE QVariantMap push(const QString &remoteName = "origin",
                                 const QString &branchName = "",
                                 const QString &username = "",
                                 const QString &password = "",
                                 bool force = false);

    /**
     * \brief Get list of remotes for the repository
     * \return QVariantList with remote information
     */
    Q_INVOKABLE QVariantList getRemotes();

    /**
     * \brief Add a new remote
     * \param name Remote name
     * \param url Remote URL
     * \return QVariantMap with operation result
     */
    Q_INVOKABLE QVariantMap addRemote(const QString &name,
                                      const QString &url);

    /**
     * \brief Remove a remote
     * \param name Remote name
     * \return QVariantMap with operation result
     */
    Q_INVOKABLE QVariantMap removeRemote(const QString &name);
};

#endif // GITWRAPPERCPP_H
