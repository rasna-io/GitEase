#pragma once

#include "IGitAuth.h"
#include "QString"
#include "QProcess"
#include "QStandardPaths"
#include "QDir"
#include "QFile"
#include "QThread"


/**
 * @brief SSH authentication using SSH agent.
 *
 * Configures libgit2 to authenticate using SSH. The implementation relies on
 * the system SSH agent and default SSH key locations.
 */
class GitSshAuth : public IGitAuth
{

private:
    QString m_setupError;  // Stores setup error message, empty if setup successful

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


    /**
     * @brief Ensure the OpenSSH agent service is running.
     *
     * Checks whether the ssh-agent service is running and, if not,
     * attempts to enable and start it.
     *
     * @note Enabling or starting the service may require
     * administrator privileges.
     *
     * @return true if the agent is running or was started successfully,
     *         false otherwise
     */
    static bool ensureAgentRunning();

    /**
     * @brief Check whether the ssh-agent service is currently running.
     *
     * @return true if the service is running, false otherwise
     */
    static bool isSshAgentRunning();

    /**
     * @brief Check whether the SSH agent is actually accessible and functional.
     *
     * Tests connectivity to the SSH agent by attempting to list keys.
     *
     * @return true if the agent is accessible, false otherwise
     */
    static bool isSshAgentAccessible();

    /**
     * @brief Manually setup SSH environment variables for agent communication.
     *
     * Attempts to locate and set the correct SSH_AUTH_SOCK environment variable
     * for connecting to the SSH agent on Windows.
     *
     * @return true if environment was successfully setup, false otherwise
     */
    static bool setupSshEnvironment();

    /**
     * @brief Check whether any SSH keys are currently loaded in the agent.
     *
     * @return true if keys are loaded, false otherwise
     */
    static bool hasSshKeysLoaded();

    /**
     * @brief Attempt to load default SSH keys into the agent.
     *
     * Tries to load common SSH key files (id_rsa, id_ed25519, id_ecdsa)
     * from the user's .ssh directory.
     *
     * @return true if at least one key was loaded successfully, false otherwise
     */
    static bool loadDefaultSshKeys();

    /**
     * @brief Start the ssh-agent service.
     *
     * @return true if the service was started successfully,
     *         false otherwise
     */
    static bool startSshAgent();

public:

    /**
     * @brief Construct SSH authentication handler.
     */
    GitSshAuth();

    /**
     * @brief Check if SSH agent setup was successful and get error message if not.
     *
     * @return Empty string if setup was successful, error message otherwise.
     */
    QString getSetupError() const;


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
    
    /**
     * @brief Check whether the SSH authentication agent is ready for use.
     *
     * Verifies that the system OpenSSH Authentication Agent (`ssh-agent`)
     * is available and running. This function does not attempt to start
     * or modify the agent service.
     *
     * @return true if the SSH agent is running and ready for authentication,
     *         false otherwise
     */
    static bool isAgentReady();
};


