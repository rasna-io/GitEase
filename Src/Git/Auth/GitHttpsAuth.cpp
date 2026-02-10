#include "GitHttpsAuth.h"


GitHttpsAuth::GitHttpsAuth(const QString& token)
    : m_token(token)
{
}

void GitHttpsAuth::apply(git_fetch_options& fetchOpts)
{
    fetchOpts.callbacks.credentials = &GitHttpsAuth::credentialsCallback;
}

int GitHttpsAuth::credentialsCallback(git_cred** out,
                                        const char*,
                                        const char* username_from_url,
                                        unsigned int allowed_types,
                                        void* payload)
{
    GitRepository::GitClonePayload* paylaod = static_cast<GitRepository::GitClonePayload*>(payload);

    GitHttpsAuth* httpsAuth  = static_cast<GitHttpsAuth*>(paylaod->auth);

    if (allowed_types & GIT_CREDTYPE_USERPASS_PLAINTEXT)
    {
        const char* user =
            username_from_url ? username_from_url : "git";

        return git_cred_userpass_plaintext_new(
            out,
            user,
            httpsAuth->m_token.toUtf8().constData()
            );
    }

    return GIT_PASSTHROUGH;
}
