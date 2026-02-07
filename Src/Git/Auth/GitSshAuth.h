#pragma once

#include "IGitAuth.h"


/**
 * @brief SSH authentication using SSH agent.
 *
 * Configures libgit2 to authenticate using SSH. The implementation relies on
 * the system SSH agent and default SSH key locations.
 */
class GitSshAuth : public IGitAuth
{

private:
    /**
     * @brief libgit2 credentials callback for SSH authentication.
     *
     * This callback is invoked by libgit2 when SSH credentials are required.
     * It attempts to authenticate using the SSH agent.
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


    static bool ensureAgentRunning();

    static bool isSshAgentRunning();
    static bool enableSshAgentAutoStart();
    static bool startSshAgent();

public:

    /**
     * @brief Construct SSH authentication handler.
     */
    GitSshAuth();


    /**
     * @brief Apply SSH authentication callbacks to fetch options.
     *
     * Registers the SSH credentials callback with libgit2 fetch options.
     *
     * @param fetchOpts libgit2 fetch options to modify
     */
    void apply(git_fetch_options& fetchOpts) override;

    /**
     * @brief applyFetch SSH authentication callbacks to fetch options.
     *
     * Registers the SSH credentials callback with libgit2 fetch options.
     *
     * @param fetchOpts libgit2 fetch options to modify
     */
    void applyFetch(git_fetch_options& fetchOpts) override;

    /**
     * @brief Apply SSH authentication callbacks to push options.
     *
     * Registers the SSH credentials callback used during push
     * operations. Authentication is performed via the system
     * SSH agent.
     *
     * @param opts libgit2 push options to modify
     */
    void applyPush(git_push_options& opts) override;

};


