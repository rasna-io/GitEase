#include "GitRemote.h"
#include "GitResult.h"
#include "Remote.h"

#include <git2.h>
#include <QVariant>
#include <qdatetime.h>

GitRemote::GitRemote(QObject *parent)
    : IGitController{parent}
{}

GitResult GitRemote::push(const QString &remoteName, const QString &branchName,
                          const QString &username, const QString &password, bool force)
{
    if (remoteName.isEmpty()) {
        return GitResult(false, QVariant(), "Remote name cannot be empty");
    }

    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "No repository available");
    }

    if (branchName.isEmpty()) {
        return GitResult(false, QVariant(),
                         "No branch specified and repository is in detached HEAD state");
    }

    git_remote* remote = nullptr;
    int result = git_remote_lookup(&remote, m_currentRepo->repo, remoteName.toUtf8().constData());

    if (result != GIT_OK) {
        if (result == GIT_ENOTFOUND) {
            return GitResult(false, QVariant(),
                             QString("Remote '%1' not found. Use addRemote() to add it first.").arg(remoteName));
        }

        return GitResult(false, QVariant(), "Failed to lookup remote");
    }

    // Get remote URL and detect type
    const char* urlCStr = git_remote_url(remote);
    if (!urlCStr) {
        git_remote_free(remote);
        return GitResult(false, QVariant(), "Remote URL is empty");
    }

    QString remoteUrl = QString::fromUtf8(urlCStr);
    bool isHttps = remoteUrl.startsWith("https://");
    bool isSsh   = remoteUrl.startsWith("git@") || remoteUrl.startsWith("ssh://");

    if (isSsh) {
        git_remote_free(remote);
        return GitResult(false, QVariant(), "SSH remote detected; username/password cannot be used for push");
    }

    // Prepare push options
    git_push_options push_opts;
    result = git_push_options_init(&push_opts, GIT_PUSH_OPTIONS_VERSION);
    if (result != GIT_OK) {
        git_remote_free(remote);
        return GitResult(false, QVariant(), "Failed to initialize push options");
    }

    // Define a struct to hold credentials
    struct CredentialsPayload {
        QString username;
        QString token;
    };

    // Create payload on heap (will be freed later)
    CredentialsPayload* credentialsPayload = new CredentialsPayload{username, password};

    // Set the callback as a static function
    push_opts.callbacks.credentials = [](git_credential **out,
                                         const char *url,
                                         const char *username_from_url,
                                         unsigned int allowed_types,
                                         void *payload) -> int {

        CredentialsPayload* creds = static_cast<CredentialsPayload*>(payload);

        // Check if credentials are provided
        if (creds->username.isEmpty() || creds->token.isEmpty()) {
            qDebug() << "GitWrapperCPP: No credentials provided in payload";
            return GIT_EUSER;
        }

        // HTTPS authentication
        if (allowed_types & GIT_CREDENTIAL_USERPASS_PLAINTEXT) {
            return git_credential_userpass_plaintext_new(out,
                                                         creds->username.toUtf8().constData(),
                                                         creds->token.toUtf8().constData());
        }
        return GIT_EUSER;
    };

    push_opts.callbacks.payload = credentialsPayload;

    QString refspec = force ?
                          QString("+refs/heads/%1:refs/heads/%1").arg(branchName) :
                          QString("refs/heads/%1:refs/heads/%1").arg(branchName);

    char* refspec_cstr = new char[refspec.length() + 1];
    strcpy(refspec_cstr, refspec.toUtf8().constData());

    git_strarray refspecs;
    refspecs.strings = &refspec_cstr;
    refspecs.count = 1;

    // Perform the push
    result = git_remote_push(remote, &refspecs, &push_opts);

    // Cleanup
    delete credentialsPayload;
    delete[] refspec_cstr;
    git_remote_free(remote);

    // Handle result
    if (result != GIT_OK) {
        if (result == GIT_EUSER) {
            return GitResult(false, QVariant(),
                             "Authentication failed. Check your personal access token.");
        } else if (result == GIT_EEXISTS) {
            return GitResult(false, QVariant(),
                             QString("Push rejected: remote already has changes you don't have.\n"
                                     "Try pulling first with:\n"
                                     "git pull %1 %2").arg(remoteName).arg(branchName));
        } else if (result == GIT_ENONFASTFORWARD && !force) {
            return GitResult(false, QVariant(),
                             QString("Push rejected: non-fast-forward update.\n\n"
                                     "To force push, set force=true (not recommended on shared branches)"));
        }

        // Get libgit2 error message if available
        const git_error* error = giterr_last();
        QString errorMsg = "Push failed";
        if (error && error->message) {
            errorMsg += QString(": %1").arg(error->message);
        }

        return GitResult(false, QVariant(), errorMsg);
    }

    QVariantMap pushResult;
    pushResult["remote"] = remoteName;
    pushResult["branch"] = branchName;
    pushResult["force"] = force;
    pushResult["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);

    return GitResult(true, pushResult);
}

GitResult GitRemote::getRemotes()
{
    QList<Remote> remotes;

    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "No repository available");
    }

    git_strarray remote_list = {0};
    int result = git_remote_list(&remote_list, m_currentRepo->repo);

    if (result == GIT_OK) {
        for (size_t i = 0; i < remote_list.count; i++) {
            git_remote* remote = nullptr;
            result = git_remote_lookup(&remote, m_currentRepo->repo, remote_list.strings[i]);

            if (result == 0 && remote) {
                Remote remoteInfo;
                remoteInfo.setName(QString::fromUtf8(remote_list.strings[i]));
                remoteInfo.setUrl(QString::fromUtf8(git_remote_url(remote)));

                const char* fetch_url = git_remote_url(remote);
                const char* push_url = git_remote_pushurl(remote);
                if (fetch_url)
                    remoteInfo.setFetchURL(QString::fromUtf8(fetch_url));
                if (push_url)
                    remoteInfo.setPushURL(QString::fromUtf8(push_url));

                remotes.append(remoteInfo);
                git_remote_free(remote);
            }
        }
        git_strarray_free(&remote_list);
    }

    qDebug() << "GitWrapperCPP: Retrieved" << remotes.size() << "remotes";
    return GitResult(true, QVariant::fromValue(remotes));
}

GitResult GitRemote::addRemote(const QString &name, const QString &url)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "No repository available");
    }

    if (name.isEmpty() || url.isEmpty()) {
        return GitResult(false, QVariant(), "Remote name and URL cannot be empty");
    }

    // Check if remote already exists
    git_remote* existing = nullptr;
    if (git_remote_lookup(&existing, m_currentRepo->repo, name.toUtf8().constData()) == 0) {
        git_remote_free(existing);
        return GitResult(false, QVariant(),
                         QString("Remote '%1' already exists").arg(name));
    }

    git_remote* remote = nullptr;
    int result = git_remote_create(&remote, m_currentRepo->repo, name.toUtf8().constData(), url.toUtf8().constData());

    if (result != GIT_OK) {
        return GitResult(false, QVariant(),
                         QString("Failed to add remote '%1'").arg(name));
    }

    Remote remoteInfo;
    remoteInfo.setName(name);
    remoteInfo.setUrl(url);

    git_remote_free(remote);

    qDebug() << "GitWrapperCPP: Added remote" << name << "with URL" << url;
    return GitResult(true, QVariant::fromValue(remoteInfo));
}

GitResult GitRemote::removeRemote(const QString &name)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "No repository available");
    }

    if (name.isEmpty()) {
        return GitResult(false, QVariant(), "Remote name cannot be empty");
    }

    int result = git_remote_delete(m_currentRepo->repo, name.toUtf8().constData());

    if (result != GIT_OK) {

        if (result == GIT_ENOTFOUND) {
            return GitResult(false, QVariant(),
                             QString("Remote '%1' not found").arg(name));
        }

        return GitResult(false, QVariant(),
                         QString("Failed to remove remote '%1'").arg(name));
    }

    qDebug() << "GitWrapperCPP: Removed remote" << name;
    return GitResult(true, name);
}

GitResult GitRemote::getUpstreamName(const QString &localBranchName)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "No repository available");
    }

    git_reference* localRef = nullptr;
    git_reference* upstreamRef = nullptr;
    QString result = "";

    int error = git_branch_lookup(&localRef, m_currentRepo->repo, localBranchName.toUtf8().constData(), GIT_BRANCH_LOCAL);

    if (error == 0) {
        if (git_branch_upstream(&upstreamRef, localRef) == 0) {
            const char* name = nullptr;
            if (git_branch_name(&name, upstreamRef) == 0 && name) {
                result = QString::fromUtf8(name);
            }
        }
    }

    if (upstreamRef)
        git_reference_free(upstreamRef);
    if (localRef)
        git_reference_free(localRef);

    return GitResult(true, result);
}
