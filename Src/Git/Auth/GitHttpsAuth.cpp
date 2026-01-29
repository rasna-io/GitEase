#include "GitHttpsAuth.h"

GitHttpsAuth::GitHttpsAuth(const QString& username,
                           const QString& password,
                           QObject *parent):
    m_username(username),
    m_password(password)
{
}

void GitHttpsAuth::apply(git_fetch_options& fetchOpts)
{
    fetchOpts.callbacks.credentials = &GitHttpsAuth::credentialsCallback;
    fetchOpts.callbacks.payload = this;
}

int GitHttpsAuth::credentialsCallback(git_cred** out,
                                      const char*,
                                      const char*,
                                      unsigned int allowed_types,
                                      void* payload)
{
    auto* self = static_cast<GitHttpsAuth*>(payload);
    if (allowed_types & GIT_CREDTYPE_USERPASS_PLAINTEXT)
    {
        return git_cred_userpass_plaintext_new(out,
                                               self->m_username.toUtf8().constData(),
                                               self->m_password.toUtf8().constData());
    }
    return -1;
}
