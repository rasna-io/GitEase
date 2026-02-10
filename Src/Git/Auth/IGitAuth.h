#pragma once

#include <git2.h>

/*!
 * \brief Authentication interface for Git operations
 */
class IGitAuth
{
public:
    virtual ~IGitAuth() = default;

    /**
     * @brief Apply authentication settings to libgit2 fetch options.
     *
     * @param fetchOpts libgit2 fetch options to modify
     */
    virtual void apply(git_fetch_options& fetchOpts) = 0;



    /**
     * @brief apply authentication settings to libgit2 fetch options.
     *
     * @param fetchOpts libgit2 fetch options to modify
     */
    virtual void applyFetch(git_fetch_options& fetchOpts) = 0;

    /**
     * @brief Apply HTTPS authentication callbacks to push options.
     *
     * Configures libgit2 push options to use HTTPS credentials.
     *
     * @param opts libgit2 push options to modify
     */
    virtual void applyPush(git_push_options& pushOpts) = 0;
};
