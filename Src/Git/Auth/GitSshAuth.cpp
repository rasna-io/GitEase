#include "GitSshAuth.h"

void GitSshAuth::apply(git_fetch_options& fetchOpts)
{
    fetchOpts.callbacks.credentials = &GitSshAuth::credentialsCallback;
}

int GitSshAuth::credentialsCallback(git_cred** out,
                                    const char*,
                                    const char* username_from_url,
                                    unsigned int allowed_types,
                                    void*)
{
    if (allowed_types & GIT_CREDTYPE_SSH_KEY)
    {
        const char* user =
            username_from_url ? username_from_url : "git";

        return git_cred_ssh_key_from_agent(out, user);
    }

    return GIT_PASSTHROUGH;
}



