#include "GitRemote.h"
#include "Auth/GitHttpsAuth.h"
#include "Auth/GitSshAuth.h"
#include "GitResult.h"
#include "Remote.h"

#include <git2.h>
#include <QVariant>
#include <qdatetime.h>

GitRemote::GitRemote(QObject *parent)
    : IGitController{parent}
{}

GitResult GitRemote::push(const QString& remote,
                          const QString& branch,
                          bool force)
{
    return pushInternal(remote, branch,
                        std::make_unique<GitSshAuth>(), force);
}

GitResult GitRemote::push(const QString& remote,
                          const QString& branch,
                          const QString& token,
                          bool force)
{
    return pushInternal(remote, branch,
                        std::make_unique<GitHttpsAuth>(token), force);
}

GitResult GitRemote::pushInternal(const QString& remoteName,
                                  const QString& branchName,
                                  std::unique_ptr<IGitAuth> auth,
                                  bool force)
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
    int result = git_remote_lookup(&remote,
                                   m_currentRepo->repo,
                                   remoteName.toUtf8().constData());

    if (result != GIT_OK) {
        if (result == GIT_ENOTFOUND)
            return GitResult(false, {}, "Remote not found");
        return GitResult(false, {}, "Failed to lookup remote");
    }

    git_push_options opts;
    git_push_options_init(&opts, GIT_PUSH_OPTIONS_VERSION);

    GitRepository::GitPayload payload {
        this,
        auth.get()
    };

    opts.callbacks.payload = &payload;
    auth->applyPush(opts);

    QByteArray refspec = force
                             ? QByteArray("+refs/heads/" + branchName.toUtf8() +
                                          ":refs/heads/" + branchName.toUtf8())
                             : QByteArray("refs/heads/" + branchName.toUtf8() +
                                          ":refs/heads/" + branchName.toUtf8());

    char* refspecs[] = { refspec.data() };
    git_strarray array { refspecs, 1 };

    result = git_remote_push(remote, &array, &opts);

    git_remote_free(remote);

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

GitResult GitRemote::getRemoteUrl(const QString& remoteName)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "No repository available");
    }

    if (remoteName.isEmpty()) {
        return GitResult(false, QVariant(), "Remote name cannot be empty");
    }

    git_remote* remote = nullptr;
    int result = git_remote_lookup(&remote,
                                   m_currentRepo->repo,
                                   remoteName.toUtf8().constData());

    if (result != GIT_OK || !remote) {
        return GitResult(false, QVariant(),
                         QString("Remote '%1' not found").arg(remoteName));
    }

    const char* fetchUrl = git_remote_url(remote);
    const char* pushUrl  = git_remote_pushurl(remote);

    // If push URL is empty, fall back to fetch URL
    QString finalUrl;
    if (pushUrl && strlen(pushUrl) > 0) {
        finalUrl = QString::fromUtf8(pushUrl);
    } else if (fetchUrl && strlen(fetchUrl) > 0) {
        finalUrl = QString::fromUtf8(fetchUrl);
    } else {
        finalUrl = ""; // remote exists but has no URL
    }

    QVariantMap data;
    data["remote"] = remoteName;
    data["fetchUrl"] = fetchUrl ? QString::fromUtf8(fetchUrl) : "";
    data["pushUrl"]  = pushUrl  ? QString::fromUtf8(pushUrl)  : "";
    data["url"]      = finalUrl;

    git_remote_free(remote);
    qDebug() << data;

    return GitResult(true, data);
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

GitResult GitRemote::editRemote(const QString &oldName, const QString &newName, const QString &newUrl)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository context is invalid or not initialized.");
    }

    if (oldName.isEmpty()) {
        return GitResult(false, QVariant(), "Current remote name must be provided for the update operation.");
    }

    int result = GIT_OK;
    QString activeRemoteName = oldName;

    // Handle Remote Renaming
    if (!newName.isEmpty() && newName != oldName) {
        git_strarray problems = {0};
        result = git_remote_rename(&problems, m_currentRepo->repo,
                                   oldName.toUtf8().constData(),
                                   newName.toUtf8().constData());

        git_strarray_free(&problems);

        if (result != GIT_OK) {
            const git_error* err = giterr_last();
            return GitResult(false, QVariant(),
                             QString("Failed to rename remote: %1").arg(err ? err->message : "Internal Git error"));
        }

        // Update the active name for the subsequent URL update step
        activeRemoteName = newName;
    }

    // Handle URL Update
    if (!newUrl.isEmpty()) {
        result = git_remote_set_url(m_currentRepo->repo,
                                    activeRemoteName.toUtf8().constData(),
                                    newUrl.toUtf8().constData());

        if (result != GIT_OK) {
            const git_error* err = giterr_last();
            return GitResult(false, QVariant(),
                             QString("Failed to update remote URL: %1").arg(err ? err->message : "Internal Git error"));
        }
    }
    
    return GitResult(true, activeRemoteName, "Remote configuration updated successfully.");
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
