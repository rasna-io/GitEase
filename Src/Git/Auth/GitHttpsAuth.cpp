#include "GitHttpsAuth.h"

#include <git2/sys/errors.h>
#include <QUrl>

GitHttpsAuth::GitHttpsAuth(const QString& token)
    : m_token(token)
{
}

void GitHttpsAuth::apply(git_fetch_options& fetchOpts)
{
    fetchOpts.callbacks.credentials = &GitHttpsAuth::credentialsCallback;
}

void GitHttpsAuth::applyFetch(git_fetch_options& fetchOpts)
{
    fetchOpts.callbacks.credentials = &GitHttpsAuth::credentialsCallback;
}

void GitHttpsAuth::applyPush(git_push_options &pushopts)
{
    pushopts.callbacks.credentials = &GitHttpsAuth::credentialsCallback;
}

int GitHttpsAuth::credentialsCallback(git_cred** out,
                                        const char* url,
                                        const char* username_from_url,
                                        unsigned int allowed_types,
                                        void* payload)
{
    GitRepository::GitPayload* paylaod = static_cast<GitRepository::GitPayload*>(payload);

    GitHttpsAuth* httpsAuth  = static_cast<GitHttpsAuth*>(paylaod->auth);

    // Without a token, offering empty credentials only makes libgit2 replay the request until
    // it gives up; declining fails straight away with an authentication error instead.
    if (httpsAuth->m_token.isEmpty())
        return GIT_PASSTHROUGH;

    // Asked again for the same URL: the server refused the token, and it will refuse it again.
    const QString requestUrl = QString::fromUtf8(url ? url : "");
    if (!httpsAuth->m_answeredUrl.isEmpty() && httpsAuth->m_answeredUrl == requestUrl)
    {
        httpsAuth->m_tokenRejected = true;
        git_error_set_str(GIT_ERROR_HTTP, "the server did not accept the token");
        return GIT_EAUTH;
    }

    if (allowed_types & GIT_CREDTYPE_USERPASS_PLAINTEXT)
    {
        const char* user =
            username_from_url ? username_from_url : "git";

        httpsAuth->m_answeredUrl = requestUrl;

        return git_cred_userpass_plaintext_new(
            out,
            user,
            httpsAuth->m_token.toUtf8().constData()
            );
    }

    return GIT_PASSTHROUGH;
}

bool GitHttpsAuth::tokenRejected() const
{
    return m_tokenRejected;
}

QString GitHttpsAuth::rejectedTokenMessage(const QString& remoteName, const QString& url, bool forPush)
{
    const QUrl parsed(url);
    const QString host = parsed.host().isEmpty() ? QStringLiteral("The server") : parsed.host();

    QString repository = parsed.path();
    if (repository.startsWith('/'))
        repository.remove(0, 1);
    if (repository.endsWith(QStringLiteral(".git")))
        repository.chop(4);
    if (repository.isEmpty())
        repository = QStringLiteral("this repository");

    QString message = QString("%1 did not accept the token for '%2'. Use a personal access token, not your "
                              "account password, that has not expired and is allowed to %3 %4.")
                          .arg(host, remoteName, forPush ? QStringLiteral("push to") : QStringLiteral("read"), repository);

    if (host.compare(QStringLiteral("github.com"), Qt::CaseInsensitive) == 0)
        message += QStringLiteral(" On GitHub, a classic token needs the \"repo\" scope; a fine-grained token needs "
                                  "this repository with the \"Contents\" permission%1.")
                       .arg(forPush ? QStringLiteral(" set to \"Read and write\"") : QString());

    return message;
}
