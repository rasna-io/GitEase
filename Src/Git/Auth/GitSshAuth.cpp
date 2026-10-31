#include "GitSshAuth.h"

#include "Utilities/SshKeyManager/SshKeyManager.h"

namespace {
    // libgit2 re-invokes the credentials callback after every rejected attempt.
    // Counting attempts per operation lets us walk through the candidates once
    // (selected key file, then agent) and then give up instead of looping forever.
    thread_local int s_attempt = 0;

    // libgit2 rejects the SSH handshake with GIT_ECERTIFICATE
    // ("invalid or unknown remote ssh hostkey") when the server is not in
    // ~/.ssh/known_hosts and no callback accepts the key. Return 0 to proceed.
    // A positive return is not "accept": libgit2 only treats 0 as acceptance
    // and GIT_PASSTHROUGH as "use the known_hosts result".
    int acceptSshHostKey(git_cert *, int, const char *, void *)
    {
        return 0;
    }
}

void GitSshAuth::installCallbacks(git_remote_callbacks &callbacks)
{
    s_attempt = 0;
    callbacks.credentials = &GitSshAuth::credentialsCallback;
    callbacks.certificate_check = &acceptSshHostKey;
}

GitSshAuth::GitSshAuth()
{
    s_attempt = 0;
}

QString GitSshAuth::getSetupError() const
{
    return m_setupError;
}

void GitSshAuth::apply(git_fetch_options& fetchOpts)
{
    installCallbacks(fetchOpts.callbacks);
}

void GitSshAuth::applyFetch(git_fetch_options& fetchOpts)
{
    installCallbacks(fetchOpts.callbacks);
}

void GitSshAuth::applyPush(git_push_options& pushopts)
{
    installCallbacks(pushopts.callbacks);
}

int GitSshAuth::credentialsCallback(git_cred** out,
                                    const char* url,
                                    const char* username_from_url,
                                    unsigned int allowed_types,
                                    void*)
{
    if (!(allowed_types & GIT_CREDTYPE_SSH_KEY))
        return GIT_PASSTHROUGH;

    const QByteArray user = username_from_url ? QByteArray(username_from_url) : QByteArray("git");
    int attempt = s_attempt++;

    // Attempt 0: the key assigned to this remote's host (GitHub / GitLab), or
    // the default key, read straight from disk by libssh2. No ssh-agent,
    // ssh-add or OpenSSH install needed.
    if (attempt == 0) {
        const QString privKey = SshKeyManager::privateKeyPathForUrl(
            url ? QString::fromUtf8(url) : QString());
        if (!privKey.isEmpty()) {
            const QString pubKey = privKey + ".pub";
            const QByteArray priv = privKey.toUtf8();
            const QByteArray pub = pubKey.toUtf8();
            return git_credential_ssh_key_new(out, user.constData(),
                                              QFile::exists(pubKey) ? pub.constData() : nullptr,
                                              priv.constData(), nullptr);
        }
        attempt = 1;     // no key file: go straight to the agent
        s_attempt = 2;
    }

    // Attempt 1: fall back to a running ssh-agent (passphrase-protected keys,
    // hardware keys, password-manager agents). libgit2 talks to it directly.
    if (attempt == 1)
        return git_cred_ssh_key_from_agent(out, user.constData());

    return GIT_EAUTH;
}
