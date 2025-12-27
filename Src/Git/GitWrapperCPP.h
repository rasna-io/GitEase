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
     * \brief Open repository at given path
     * \param path Repository path to open
     * \return git_repository pointer or nullptr on error
     *
     * If m_currentRepo is already open and path is empty, returns current repo.
     * Otherwise opens a new repository. Caller must free if different from m_currentRepo.
     */
    git_repository* openRepository(const QString &path);

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

    /* Internal Test Function */
    void unitTest();

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
     * \param repoPath Path to repository (optional, uses current if empty)
     * \return QVariantMap with status information
     */
    Q_INVOKABLE QVariantMap status(const QString &repoPath = "");

    /**
     * \brief Get commit history
     * \param repoPath Path to repository (optional, uses current if empty)
     * \param limit Maximum number of commits to return (default: 50)
     * \return QVariantList of commit objects
     */
    Q_INVOKABLE QVariantList getCommits(const QString &repoPath = "", int limit = 50);

    /**
     * \brief Get list of branches
     * \param repoPath Path to repository (optional, uses current if empty)
     * \return QVariantList of branch objects with name, isRemote, isCurrent properties
     */
    Q_INVOKABLE QVariantList getBranches(const QString &repoPath = "");

    /**
    * \brief Creates a new branch pointing to the current HEAD.
    * \param branchName Name of the new branch.
    * \param repoPath Path to the repository (optional).
    * \return True if creation was successful, false otherwise.
    */
    Q_INVOKABLE bool createBranch(const QString &branchName, const QString &repoPath = "");

    /**
     * \brief Get basic repository information
     * \param repoPath Path to repository (optional, uses current if empty)
     * \return QVariantMap with repository info
     */
    Q_INVOKABLE QVariantMap getRepoInfo(const QString &repoPath = "");
};

#endif // GITWRAPPERCPP_H
