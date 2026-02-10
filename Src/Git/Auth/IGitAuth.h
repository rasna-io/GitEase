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
};
