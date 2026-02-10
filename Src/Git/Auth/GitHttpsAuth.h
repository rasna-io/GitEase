#pragma once

#include "IGitAuth.h"
#include <QString>
#include "GitRepository.h"

/**
 * @brief HTTPS authentication using token/password.
 *
 * This class configures libgit2 to authenticate using HTTPS credentials,
 * typically a personal access token.
 */
class GitHttpsAuth : public IGitAuth
{

private:

    QString m_token;    ///< HTTPS token or password

    /**
     * @brief libgit2 credentials callback for HTTPS authentication.
     *
     * This callback is invoked by libgit2 when credentials are required.
     * The payload is expected to point to a GitCloneContext structure.
     *
     * @param out          Output credentials object
     * @param url          Remote URL (unused)
     * @param username_from_url Username parsed from URL (may be null)
     * @param allowed_types Bitmask of allowed credential types
     * @param payload      Pointer to GitCloneContext
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
     * @brief Construct HTTPS authentication using a token.
     *
     * @param token Personal access token or password
     */
    explicit GitHttpsAuth(const QString& token);

    /**
     * @brief Apply HTTPS authentication callbacks to fetch options.
     *
     * @param fetchOpts libgit2 fetch options to modify
     */
    void apply(git_fetch_options& fetchOpts) override;

    /**
     * @brief applyFetch HTTPS authentication callbacks to fetch options.
     *
     * @param fetchOpts libgit2 fetch options to modify
     */
    void applyFetch(git_fetch_options& fetchOpts) override;

    /**
     * @brief Apply HTTPS authentication settings to libgit2 push options.
     *
     * Implementations should register the appropriate credentials
     * callback for push operations.
     *
     * @param pushOpts libgit2 push options to modify
     */
    void applyPush(git_push_options& opts) override;
};
