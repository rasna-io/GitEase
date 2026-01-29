#include "GitSshAuth.h"

GitSshAuth::GitSshAuth(const QString &privateKeyPath, QObject *parent):
    m_privateKeyPath(privateKeyPath)
{
}

void GitSshAuth::apply(git_fetch_options& fetchOpts)
{
    fetchOpts.callbacks.credentials = &GitSshAuth::credentialsCallback;
    fetchOpts.callbacks.payload = this;
}

int GitSshAuth::credentialsCallback(git_cred** out,
                                    const char*,
                                    const char* username,
                                    unsigned int allowed_types,
                                    void* payload)
{
    auto* self = static_cast<GitSshAuth*>(payload);
    const char* user = username ? username : "git";

    // Try SSH agent first
    if (allowed_types & GIT_CREDTYPE_SSH_KEY)
    {
        int rc = git_cred_ssh_key_from_agent(out, user);
        if (rc == 0)
            return 0;

        // fallback to key path
        if (!self->m_privateKeyPath.isEmpty())
        {
            rc = git_cred_ssh_key_new(out,
                                      user,
                                      nullptr,
                                      self->m_privateKeyPath.toUtf8().constData(),
                                      nullptr);
            if (rc == 0)
                return 0;
        }
    }
    return -1; // failed
}
