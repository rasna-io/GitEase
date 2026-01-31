#pragma once

#include <QObject>
#include "GitResult.h"
#include "IGitController.h"

#include "Auth/IGitAuth.h"
#include "Auth/GitSshAuth.h"
#include "Auth/GitHttpsAuth.h"



class GitRepository : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

private:
    QString m_currentRepoPath;

    /**
     * @brief Internal clone implementation.
     *
     * Performs a git clone operation using the provided authentication strategy.
     * This method runs the clone asynchronously and emits progress and completion
     * signals back to the UI.
     *
     * @param url        Remote repository URL
     * @param localPath  Local directory where the repository will be cloned
     * @param auth       Authentication strategy (ownership is transferred)
     *
     * @return GitResult Immediate result indicating whether the clone was started
     */
    GitResult cloneInternal(const QString& url,
                            const QString& localPath,
                            IGitAuth* auth);

public:

    explicit GitRepository(QObject *parent = nullptr);

    /**
     * @brief Context object shared with libgit2 callbacks during clone.
     *
     * This structure is passed as the libgit2 callback payload and provides
     * access to both the owning GitRepository (for UI updates) and the
     * authentication strategy (for credentials).
     */
    struct GitClonePayload {
        GitRepository* parentThread;    ///< Owner repository (UI + signals)
        IGitAuth* auth;                 ///< Authentication strategy
    };

    /**
     * \brief Initialize a new Git repository
     * \param path Path where to create the repository
     * \return GitResult
     *
     * Creates a new Git repository at the specified path.
     */
    Q_INVOKABLE GitResult init(const QString &path);

    /**
     * \brief Open an existing Git repository
     * \param path Path to the repository
     * \return GitResult
     */
    Q_INVOKABLE GitResult open(const QString &path);

    /**
     * \brief Close the currently open repository
     * \return QVariantMap with {"success": bool, "error": message}
     */
    Q_INVOKABLE GitResult close();

    /**
     * @brief Clone a repository using SSH authentication.
     *
     * Uses the system SSH agent or default SSH keys to authenticate the clone
     * operation.
     *
     * @param url        Remote repository URL (SSH)
     * @param localPath  Local directory where the repository will be cloned
     *
     * @return GitResult Immediate result indicating whether the clone was started
     */
    Q_INVOKABLE GitResult clone(const QString& url,
                                const QString& localPath);              // SSH

    /**
     * @brief Clone a repository using HTTPS authentication.
     *
     * Uses a personal access token or password to authenticate the clone
     * operation over HTTPS.
     *
     * @param url        Remote repository URL (HTTPS)
     * @param localPath  Local directory where the repository will be cloned
     * @param token      Personal access token or password
     *
     * @return GitResult Immediate result indicating whether the clone was started
     */
    Q_INVOKABLE GitResult clone(const QString& url,
                                const QString& localPath,
                                const QString& token);                  // HTTPS


signals:
    void cloneFinished(QVariantMap result);
    void cloneProgress(int progress);
};
