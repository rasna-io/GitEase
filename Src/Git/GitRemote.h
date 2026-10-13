#pragma once

#include "Auth/IGitAuth.h"
#include "IGitController.h"
#include "Repository.h"
#include <QObject>
#include <QVariantMap>

class GitResult;
class GitRemote : public IGitController
{
    Q_OBJECT
    Q_PROPERTY(bool pushInProgress READ isPushInProgress NOTIFY pushInProgressChanged FINAL)
    Q_PROPERTY(bool forcePush READ isForcePush NOTIFY forcePushChanged FINAL)
    QML_ELEMENT
public:
    explicit GitRemote(QObject *parent = nullptr);

    /**
     * @brief Push commits to a remote using SSH authentication.
     *
     * Uses the system SSH agent or default SSH keys to authenticate
     * the push operation.
     *
     * @param remote Name of the remote
     * @param branch Name of the branch to push
     * @param force  Whether to force push (default: false)
     *
     * @return GitResult with operation result
     */
    Q_INVOKABLE GitResult push(const QString& remote,
                               const QString& branch,
                               bool force = false);

    /**
     * @brief Push commits to a remote using HTTPS authentication.
     *
     * Uses a personal access token to authenticate the push
     * operation over HTTPS.
     *
     * @param remote Name of the remote
     * @param branch Name of the branch to push
     * @param token  Personal access token
     * @param force  Whether to force push (default: false)
     *
     * @return GitResult with operation result
     */
    Q_INVOKABLE GitResult push(const QString& remote,
                               const QString& branch,
                               const QString& token,
                               bool force = false);

    /**
     * @brief Push a local branch to a branch on a remote, optionally making it the upstream.
     *
     * Picks the authentication from the remote's URL: the SSH agent for SSH remotes, \a token for
     * HTTP(S) remotes, and none for remotes that need no credentials, such as a local path.
     *
     * @param remote       Name of the remote
     * @param localBranch  Local branch to push
     * @param remoteBranch Branch to update on the remote; usually the same name as localBranch
     * @param token        Personal access token, only used for HTTP(S) remotes
     * @param force        Whether to force push
     * @param setUpstream  Make remote/remoteBranch the upstream of localBranch once the push
     *                     succeeds, like git push -u
     *
     * @return GitResult with operation result
     */
    Q_INVOKABLE GitResult push(const QString& remote,
                               const QString& localBranch,
                               const QString& remoteBranch,
                               const QString& token,
                               bool force,
                               bool setUpstream);

    /**
     * @brief Runs push rules for a pending push.
     *
     * push() runs on the Git worker thread where rules cannot veto it, so callers invoke this
     * on the GUI thread right before queueing the push.
     *
     * @return GitResult that fails with the rule's message when the push must not happen
     */
    Q_INVOKABLE GitResult checkPushRules(const QString& remote,
                                         const QString& branch,
                                         bool force = false);

    /**
     * @brief Runs push rules for a push that updates a differently named branch on the remote.
     */
    Q_INVOKABLE GitResult checkPushRules(const QString& remote,
                                         const QString& localBranch,
                                         const QString& remoteBranch,
                                         bool force);

    /**
     * @brief Checks if a push operation is currently in progress
     * @return true if a push operation is actively running, false otherwise
     */
    Q_INVOKABLE bool isPushInProgress() const;

    /**
     * @brief Checks if force push mode is enabled
     * @return true if future pushes will use --force flag, false otherwise
     */
    Q_INVOKABLE bool isForcePush() const;

    /**
     * @brief Fetch changes from a remote repository.
     *
     * Automatically detects the protocol (SSH or HTTPS) from the remote URL
     * and uses the appropriate authentication method. For SSH remotes, uses
     * the system SSH agent. For HTTPS remotes, uses an empty token (relies on
     * system credentials or SSH agent forwarding). Remotes that need no
     * credentials, such as a local path, are fetched without any.
     *
     * @param remote Name of the remote
     *
     * @return GitResult with operation result
     */
    Q_INVOKABLE GitResult fetch(const QString& remote);

    /**
     * @brief Fetch changes from a remote repository using HTTPS with a token.
     *
     * Explicitly uses HTTPS authentication with a provided personal access token.
     * This method is useful when you want to use a specific token for authentication.
     *
     * @param remote Name of the remote (default: "origin")
     * @param token  Personal access token or password for HTTPS authentication
     *
     * @return GitResult with operation result
     */
    Q_INVOKABLE GitResult fetchWithToken(const QString& remote, const QString& token);
    
    /**
     * @brief Pull a remote branch into the checked out branch.
     *
     * Performs fetch + merge analysis. If a fast-forward is possible, it updates
     * the current branch. If already up to date, returns success with that status.
     * Non-fast-forward pulls are rejected to avoid implicit merge commits.
     *
     * @param remote Name of the remote
     * @param branch Branch on the remote to pull. If empty, the upstream branch when the checked
     *               out branch tracks this remote, otherwise the checked out branch's own name.
     *
     * @return GitResult with operation result
     */
    Q_INVOKABLE GitResult pull(const QString& remote,
                               const QString& branch = QString());

    /**
     * @brief Start pull asynchronously using HTTPS token authentication.
     *
     * @param remote Name of the remote
     * @param branch Branch to pull from. If empty, uses current local branch name.
     * @param token  Personal access token
     *
     * @return GitResult immediate start status (final result is emitted via pullFinished)
     */
    Q_INVOKABLE GitResult pull(const QString& remote,
                               const QString& branch,
                               const QString& token);

    /**
     * @brief Pull, picking the authentication from the remote's URL, and optionally remember
     *        the remote branch as the upstream.
     *
     * @param remote      Name of the remote
     * @param branch      Branch on the remote to pull, see pull(remote, branch).
     * @param token       Personal access token, only used for HTTP(S) remotes
     * @param setUpstream Make remote/branch the upstream of the checked out branch once it is
     *                    found on the remote
     *
     * @return GitResult with operation result
     */
    Q_INVOKABLE GitResult pull(const QString& remote,
                               const QString& branch,
                               const QString& token,
                               bool setUpstream);

    /**
     * @brief Works out where Pull and Push go for the checked out branch.
     *
     * The branch's upstream decides, the same as for git pull and git push. Push also honours
     * branch.<name>.pushRemote and remote.pushDefault, which is how a fork workflow pulls from one
     * remote and pushes to another. Without an upstream, a repository with a single remote uses
     * it; with several, the target stays empty and the caller asks the user. Push also stays
     * undecided when the upstream has a different name than the branch, which git's default
     * push.default=simple refuses to push to.
     *
     * @return GitResult whose data is a map with:
     *  - "branch":          the checked out branch, empty when HEAD is detached
     *  - "detached":        HEAD points at a commit rather than a branch
     *  - "unborn":          the branch has no commits yet
     *  - "remotes":         list of { name, url, hasBranch }; hasBranch is true when the remote
     *                       is known, from the last fetch, to have a branch named "branch"
     *  - "upstreamRemote", "upstreamBranch": the branch's upstream, empty when it has none
     *  - "pullRemote", "pullBranch": where Pull goes, empty when the user has to choose
     *  - "pushRemote":      the remote Push uses, empty when the user has to choose
     *  - "pushBranch":      the branch Push updates there, empty when the user has to choose
     *  - "publish":         the branch has no upstream yet, so Push makes its target the upstream
     *  - "defaultRemote":   the repository's default remote, see setDefaultRemote(); empty when none
     *  - "suggestedRemote": the remote to preselect when the user has to choose
     */
    Q_INVOKABLE GitResult remoteTarget();
    /**
     * @brief The authentication a transfer with a remote needs, chosen from the remote's URL.
     *
     * SSH URLs use the SSH agent, HTTP(S) URLs use \a token, and anything else - a local path,
     * file:// or git:// - offers no credentials, which those transports do not ask for.
     *
     * @param repo       Repository the remote belongs to
     * @param remoteName Name of the remote
     * @param token      Personal access token for HTTP(S) remotes
     * @param forPush    Use the remote's push URL, when it has one, instead of its fetch URL
     * @param error      Receives why the remote cannot be used; set whenever nullptr is returned
     */
    static std::unique_ptr<IGitAuth> authForRemote(git_repository *repo,
                                                   const QString &remoteName,
                                                   const QString &token,
                                                   bool forPush,
                                                   QString *error);


    /**
     * \brief Get list of remotes for the repository
     * \return QVariantList with remote information
     */
    Q_INVOKABLE GitResult getRemotes();

    /**
     * \brief Add a new remote
     * \param name Remote name
     * \param url Remote URL
     * \return QVariantMap with operation result
     */
    Q_INVOKABLE GitResult addRemote(const QString &name,
                                    const QString &url);

    /**
     * \brief Remove a remote
     * \param name Remote name
     * \return QVariantMap with operation result
     */
    Q_INVOKABLE GitResult removeRemote(const QString &name);


    /**
    * @brief Updates an existing remote's configuration.
    * * This method handles both renaming the remote and updating its URL.
    * If newName is identical to oldName or empty, the rename step is skipped.
    * * @param oldName The current identifier of the remote (e.g., "origin").
    * @param newName The desired new name.
    * @param newUrl  The new repository URL.
    * @return GitResult indicating success or a detailed error message on failure.
    */
    Q_INVOKABLE GitResult editRemote(const QString &oldName,
                                     const QString &newName,
                                     const QString &newUrl);

    /**
    * \brief Retrieves the name of the tracked upstream branch.
    * \param localBranchName The name of the local branch to check.
    * \return The upstream branch name (e.g., "origin/main") or an empty QString if no upstream is set.
    */
    Q_INVOKABLE GitResult getUpstreamName(const QString &localBranchName);

    /**
    * \brief Retrieves the URLs of a specified remote.
    *
    * This method looks up the given remote name in the current repository and
    * returns both the fetch and push URLs. If the remote does not exist, an
    * error message is returned.
    *
    * \param remoteName The name of the remote (e.g., "origin").
    * \return GitResult containing a QVariantMap with:
    *         - "remote": The remote name
    *         - "fetchUrl": The fetch URL of the remote
    *         - "pushUrl": The push URL of the remote (may be empty if not set)
    *         or an error message if the operation failed.
    */
    Q_INVOKABLE GitResult getRemoteUrl(const QString &remoteName);

signals:
    /**
     * @brief Emitted when an asynchronous fetch finishes.
     *
     * Payload keys:
     *  - "remote": QString remote name
     *  - "success": bool
     *  - "errorMessage": QString (only on failure)
     *  - "data": QVariant (result payload from Git)
     */
    void fetchFinished(QVariantMap result);
private:

    /**
     * @brief Internal implementation for pushing commits to a remote.
     *
     * Performs a git push operation using the provided authentication
     * strategy. This method is shared by both SSH and HTTPS push
     * entry points.
     *
     * @param remoteName Name of the remote (e.g. "origin")
     * @param branchName Name of the branch to push
     * @param auth       Authentication strategy (ownership transferred)
     * @param force      Whether to force push
     *
     * @return GitResult containing the push result
     */
    GitResult pushInternal(const QString& remoteName,
                           const QString& branchName,
                           std::unique_ptr<IGitAuth> auth,
                           bool force);

    GitResult pushStartAsyncInternal(const QString& remoteName,
                                     const QString& branchName,
                                     std::unique_ptr<IGitAuth> auth,
                                     bool force);
    /**
     * @brief Internal implementation for fetching from a remote.
     *
     * Performs a git fetch operation using the provided authentication
     * strategy. This method is shared by both SSH and HTTPS fetch
     * entry points.
     *
     * @param remoteName Name of the remote (e.g. "origin")
     * @param auth       Authentication strategy (ownership transferred)
     *
     * @return GitResult containing the fetch result
     */
    GitResult fetchInternal(const QString& remoteName,
                            std::unique_ptr<IGitAuth> auth);

    /**
     * @brief Captures the current commit IDs for all tracking branches of a specific remote.
     *
     * This helper iterates through all remote-tracking branches (e.g., refs/remotes/origin/*)
     * and stores their current OID. This snapshot is used to compare states before and
     * after a fetch to determine which branches were updated or newly created.
     *
     * @param remoteName The name of the remote to snapshot (e.g., "origin").
     * @return A QHash mapping branch names (without the remote prefix) to their commit OID strings.
     */
    QHash<QString, QString> getRemoteTrackingTipsSnapshot(const QString& remoteName);

    /**
     * @brief Launch asynchronous fetch and wire completion signal.
     */
    GitResult startAsyncFetch(const QString& remoteName,
                              std::unique_ptr<IGitAuth> auth);


    /**
     * @brief Internal implementation for pull.
     *
     * Pull is implemented as fetch + merge analysis + fast-forward update.
     * Non-fast-forward pulls are rejected.
     *
     * @param remoteName Name of remote
     * @param branchName Branch to pull (empty => current branch)
     * @param auth       Authentication strategy
     *
     * @return GitResult with operation result
     */
    GitResult pullInternal(const QString& remoteName,
                           const QString& branchName,
                           std::unique_ptr<IGitAuth> auth);

    GitResult pullStartAsyncInternal(const QString& remoteName,
                                     const QString& branchName,
                                     std::unique_ptr<IGitAuth> auth);

signals:
    void fetchProgress(int progress);
    void pullFinished(QVariantMap result);
    void pushFinished(QVariantMap result);
    void pushInProgressChanged();
    void forcePushChanged();

private:
    bool m_pullInProgress = false;
    bool m_pushInProgress = false;
    bool m_forcePush = false;
};
