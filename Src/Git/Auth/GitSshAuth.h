#pragma once

#include "IGitAuth.h"
#include "QString"
#include "QProcess"
#include "QStandardPaths"
#include "QDir"
#include "QFile"
#include "QThread"


/**
 * @brief SSH authentication using a key file from ~/.ssh.
 *
 * Configures libgit2 to authenticate over SSH with the key selected in
 * Settings → SSH Keys: the key assigned to the remote's provider (GitHub or
 * GitLab) if any, otherwise the default key (see
 * SshKeyManager::privateKeyPathForUrl()). The key is
 * read directly from disk by libssh2, so no OpenSSH client, ssh-add or
 * ssh-agent service is required. If the key is rejected (for example because
 * it is passphrase-protected), a running ssh-agent is tried as a fallback.
 *
 * Works the same for GitHub, GitLab and any other host: the user is "git" and
 * the host identifies the account by the public key that was uploaded to it.
 *
 * @note Passphrase-protected key files are only usable through an agent.
 */
class GitSshAuth : public IGitAuth
{

private:
    QString m_setupError;  // Empty unless setup failed

    /**
     * @brief libgit2 credentials callback for SSH authentication.
     *
     * Tries, in order: the active key file, then the ssh-agent, then fails
     * with GIT_EAUTH so libgit2 does not retry forever.
     *
     * @param out                Output credentials object
     * @param url                Remote URL (unused)
     * @param username_from_url  Username parsed from URL (may be null)
     * @param allowed_types      Bitmask of allowed credential types
     * @param payload            Callback payload (unused)
     *
     * @return 0 on success, libgit2 error code otherwise
     */
    static int credentialsCallback(git_cred** out,
                                   const char* url,
                                   const char* username_from_url,
                                   unsigned int allowed_types,
                                   void* payload);

public:

    /**
     * @brief Construct SSH authentication handler.
     */
    GitSshAuth();

    /**
     * @brief Get the setup error message, if any.
     *
     * @return Empty string if setup was successful, error message otherwise.
     */
    QString getSetupError() const;


    /**
     * @brief Apply SSH authentication callbacks to fetch options.
     *
     * @param fetchOpts libgit2 fetch options to modify
     */
    void apply(git_fetch_options& fetchOpts) override;

    /**
     * @brief Apply SSH authentication callbacks to fetch options.
     *
     * @param fetchOpts libgit2 fetch options to modify
     */
    void applyFetch(git_fetch_options& fetchOpts) override;

    /**
     * @brief Apply SSH authentication callbacks to push options.
     *
     * @param opts libgit2 push options to modify
     */
    void applyPush(git_push_options& opts) override;
};
