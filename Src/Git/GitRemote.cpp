#include "GitRemote.h"
#include "Auth/GitHttpsAuth.h"
#include "Auth/GitSshAuth.h"
#include "GitResult.h"
#include "Remote.h"
#include "Utilities/GitProtocolDetector.h"

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

    emitGitCommand(QString("git push %1%2 %3")
                       .arg(force ? "--force " : "",
                            quoteCommandArg(remoteName),
                            quoteCommandArg(branchName)));

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

    emitGitCommand(QString("git remote get-url %1").arg(quoteCommandArg(remoteName)));

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

    emitGitCommand("git remote -v");

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

    emitGitCommand(QString("git remote add %1 %2")
                       .arg(quoteCommandArg(name), quoteCommandArg(url)));

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

    emitGitCommand(QString("git remote remove %1").arg(quoteCommandArg(name)));

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

    if (!newName.isEmpty() && newName != oldName) {
        emitGitCommand(QString("git remote rename %1 %2")
                           .arg(quoteCommandArg(oldName), quoteCommandArg(newName)));
    }

    const QString effectiveName = (!newName.isEmpty() && newName != oldName) ? newName : oldName;
    if (!newUrl.isEmpty()) {
        emitGitCommand(QString("git remote set-url %1 %2")
                           .arg(quoteCommandArg(effectiveName), quoteCommandArg(newUrl)));
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

    emitGitCommand(QString("git rev-parse --abbrev-ref %1@{upstream}")
                       .arg(localBranchName));

    return GitResult(true, result);
}

GitResult GitRemote::fetch(const QString& remote)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "No repository available");
    }

    if (remote.isEmpty()) {
        return GitResult(false, QVariant(), "Remote name cannot be empty");
    }

    // Get the remote URL to detect protocol
    auto urlResult = getRemoteUrl(remote);
    if (!urlResult.success()) {
        return urlResult;
    }

    QString remoteUrl = urlResult.data().toMap()["url"].toString();
    if (remoteUrl.isEmpty()) {
        return GitResult(false, QVariant(), "Remote has no URL configured");
    }

    // Detect protocol and use appropriate authentication
    GitProtocolDetector::GitProtocol protocol = GitProtocolDetector::detectProtocol(remoteUrl);

    std::unique_ptr<IGitAuth> auth;
    switch (protocol) {
        case GitProtocolDetector::GitProtocol::SSH:
            auth = std::make_unique<GitSshAuth>();
            break;
        case GitProtocolDetector::GitProtocol::HTTPS:
        case GitProtocolDetector::GitProtocol::HTTP:
            // For HTTPS/HTTP, use empty token (relies on system credentials)
            auth = std::make_unique<GitHttpsAuth>("");
            break;
        case GitProtocolDetector::GitProtocol::Unknown:
        default:
            return GitResult(false, QVariant(),
                           QString("Unsupported protocol for remote URL: %1").arg(remoteUrl));
    }

    // Check SSH auth setup if needed
    if (auto sshAuth = dynamic_cast<GitSshAuth*>(auth.get())) {
        QString setupError = sshAuth->getSetupError();
        if (!setupError.isEmpty()) {
            return GitResult(false, QVariant(), setupError);
        }
    }

    return fetchInternal(remote, std::move(auth));
}

GitResult GitRemote::fetchWithToken(const QString& remote, const QString& token)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "No repository available");
    }

    if (remote.isEmpty()) {
        return GitResult(false, QVariant(), "Remote name cannot be empty");
    }

    return fetchInternal(remote, std::make_unique<GitHttpsAuth>(token));
}

GitResult GitRemote::fetchInternal(const QString& remoteName, std::unique_ptr<IGitAuth> auth)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "No repository available");
    }

    git_remote* remote = nullptr;
    int result = git_remote_lookup(&remote,
                                   m_currentRepo->repo,
                                   remoteName.toUtf8().constData());

    if (result != GIT_OK) {
        if (result == GIT_ENOTFOUND)
            return GitResult(false, QVariant(), "Remote not found");
        return GitResult(false, QVariant(), "Failed to lookup remote");
    }

    git_fetch_options opts = GIT_FETCH_OPTIONS_INIT;

    GitRepository::GitPayload payload {
        this,
        auth.get()
    };

    opts.callbacks.payload = &payload;
    auth->applyFetch(opts);

    result = git_remote_fetch(remote, nullptr, &opts, nullptr);

    git_remote_free(remote);

    if (result != GIT_OK) {
        if (result == GIT_EUSER) {
            return GitResult(false, QVariant(),
                           "Authentication failed. Check your credentials or SSH keys.");
        } else if (result == GIT_EEXISTS) {
            return GitResult(false, QVariant(),
                           "Fetch conflict: Unable to update refs");
        } else if (result == GIT_EUNBORNBRANCH) {
            return GitResult(false, QVariant(),
                           "Cannot fetch: repository has no commits");
        }

        // Get libgit2 error message if available
        const git_error* error = giterr_last();
        QString errorMsg = "Fetch failed";
        if (error && error->message) {
            errorMsg += QString(": %1").arg(error->message);
        }

        return GitResult(false, QVariant(), errorMsg);
    }

    QVariantMap fetchResult;
    fetchResult["remote"] = remoteName;
    fetchResult["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);
    fetchResult["status"] = "Successfully fetched from remote";

    return GitResult(true, fetchResult);
}
