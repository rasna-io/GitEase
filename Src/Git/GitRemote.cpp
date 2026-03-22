#include "GitRemote.h"
#include "Auth/GitHttpsAuth.h"
#include "Auth/GitSshAuth.h"
#include "GitResult.h"
#include "Remote.h"
#include "Utilities/GitProtocolDetector.h"

#include <git2.h>
#include <QDebug>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QVariant>
#include <QVariantList>
#include <qdatetime.h>
#include <QFutureWatcher>
#include <QtConcurrent>

namespace {
QString lastGitErrorMessage()
{
    const git_error* err = git_error_last();
    if (err && err->message) {
        return QString::fromUtf8(err->message);
    }
    return QString();
}

QString currentHeadRefName(git_repository* repo)
{
    git_reference* head = nullptr;
    int rc = git_repository_head(&head, repo);
    if (rc != GIT_OK || !head) {
        return QString("<no-head>");
    }

    const char* refName = git_reference_name(head);
    QString out = refName ? QString::fromUtf8(refName) : QString("<unnamed-head>");
    git_reference_free(head);
    return out;
}

QString currentHeadOid(git_repository* repo)
{
    git_oid oid;
    int rc = git_reference_name_to_id(&oid, repo, "HEAD");
    if (rc != GIT_OK) {
        return QString("<no-oid>");
    }

    char hash[GIT_OID_HEXSZ + 1];
    git_oid_tostr(hash, sizeof(hash), &oid);
    return QString::fromUtf8(hash);
}

QString workingTreeSummary(git_repository* repo)
{
    git_status_options opts = GIT_STATUS_OPTIONS_INIT;
    opts.show = GIT_STATUS_SHOW_INDEX_AND_WORKDIR;
    opts.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED |
                 GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX |
                 GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS;

    git_status_list* statusList = nullptr;
    int rc = git_status_list_new(&statusList, repo, &opts);
    if (rc != GIT_OK || !statusList) {
        return QString("status_error=%1 lastError=%2")
            .arg(rc)
            .arg(lastGitErrorMessage());
    }

    size_t count = git_status_list_entrycount(statusList);
    int staged = 0;
    int unstaged = 0;
    int conflicted = 0;
    int untracked = 0;

    for (size_t i = 0; i < count; ++i) {
        const git_status_entry* e = git_status_byindex(statusList, i);
        if (!e) {
            continue;
        }
        unsigned int s = e->status;
        if (s & (GIT_STATUS_INDEX_NEW |
                 GIT_STATUS_INDEX_MODIFIED |
                 GIT_STATUS_INDEX_DELETED |
                 GIT_STATUS_INDEX_RENAMED |
                 GIT_STATUS_INDEX_TYPECHANGE)) {
            staged++;
        }
        if (s & (GIT_STATUS_WT_MODIFIED |
                 GIT_STATUS_WT_DELETED |
                 GIT_STATUS_WT_TYPECHANGE |
                 GIT_STATUS_WT_RENAMED)) {
            unstaged++;
        }
        if (s & GIT_STATUS_WT_NEW) {
            untracked++;
        }
        if (s & GIT_STATUS_CONFLICTED) {
            conflicted++;
        }
    }

    git_status_list_free(statusList);
    return QString("entries=%1 staged=%2 unstaged=%3 untracked=%4 conflicted=%5")
        .arg(count)
        .arg(staged)
        .arg(unstaged)
        .arg(untracked)
        .arg(conflicted);
}
}

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

    return startAsyncFetch(remote, std::move(auth));
}

GitResult GitRemote::fetchWithToken(const QString& remote, const QString& token)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "No repository available");
    }

    if (remote.isEmpty()) {
        return GitResult(false, QVariant(), "Remote name cannot be empty");
    }

    return startAsyncFetch(remote, std::make_unique<GitHttpsAuth>(token));
}

GitResult GitRemote::startAsyncFetch(const QString& remoteName,
                                     std::unique_ptr<IGitAuth> auth)
{
    const QString safeRemote = remoteName;

    auto future = QtConcurrent::run(
        [this,
         safeRemote,
         auth = std::move(auth)]() mutable -> GitResult {
            return fetchInternal(safeRemote, std::move(auth));
        });

    auto* watcher = new QFutureWatcher<GitResult>(this);

    connect(watcher, &QFutureWatcher<GitResult>::finished,
            this, [=]() {
                const GitResult result = watcher->result();

                QVariantMap payload;
                payload["remote"] = safeRemote;
                payload["success"] = result.success();
                payload["errorMessage"] = result.errorMessage();
                payload["data"] = result.data();

                emit fetchFinished(payload);
                watcher->deleteLater();
            });

    watcher->setFuture(future);

    emitGitCommand(QString("git fetch %1").arg(quoteCommandArg(remoteName)));

    return GitResult(true, QVariant(), "Fetch started");
}

GitResult GitRemote::pull(const QString& remote, const QString& branch)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "No repository available");
    }

    if (remote.isEmpty()) {
        return GitResult(false, QVariant(), "Remote name cannot be empty");
    }

    auto urlResult = getRemoteUrl(remote);
    if (!urlResult.success()) {
        return urlResult;
    }

    QString remoteUrl = urlResult.data().toMap()["url"].toString();
    if (remoteUrl.isEmpty()) {
        return GitResult(false, QVariant(), "Remote has no URL configured");
    }

    GitProtocolDetector::GitProtocol protocol = GitProtocolDetector::detectProtocol(remoteUrl);

    std::unique_ptr<IGitAuth> auth;
    switch (protocol) {
    case GitProtocolDetector::GitProtocol::SSH:
        auth = std::make_unique<GitSshAuth>();
        break;
    case GitProtocolDetector::GitProtocol::HTTPS:
    case GitProtocolDetector::GitProtocol::HTTP:
        auth = std::make_unique<GitHttpsAuth>("");
        break;
    case GitProtocolDetector::GitProtocol::Unknown:
    default:
        return GitResult(false, QVariant(),
                         QString("Unsupported protocol for remote URL: %1").arg(remoteUrl));
    }

    if (auto sshAuth = dynamic_cast<GitSshAuth*>(auth.get())) {
        QString setupError = sshAuth->getSetupError();
        if (!setupError.isEmpty()) {
            return GitResult(false, QVariant(), setupError);
        }
    }

    return pullStartAsyncInternal(remote, branch, std::move(auth));
}

GitResult GitRemote::pull(const QString& remote,
                          const QString& branch,
                          const QString& token)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "No repository available");
    }

    if (remote.isEmpty()) {
        return GitResult(false, QVariant(), "Remote name cannot be empty");
    }

    return pullStartAsyncInternal(remote, branch, std::make_unique<GitHttpsAuth>(token));
}

GitResult GitRemote::pullStartAsyncInternal(const QString& remoteName,
                                            const QString& branchName,
                                            std::unique_ptr<IGitAuth> auth)
{
    if (m_pullInProgress) {
        return GitResult(false, QVariant(), "Pull already in progress");
    }

    m_pullInProgress = true;

    const QString safeRemote = remoteName;
    const QString safeBranch = branchName;

    auto future = QtConcurrent::run(
        [this,
         safeRemote,
         safeBranch,
         auth = std::move(auth)]() mutable -> QVariantMap {
            GitResult res = pullInternal(safeRemote, safeBranch, std::move(auth));
            QVariantMap out;
            out["success"] = res.success();
            out["errorMessage"] = res.errorMessage();
            out["data"] = res.data();
            out["remote"] = safeRemote;
            out["branch"] = safeBranch;
            return out;
        });

    auto* watcher = new QFutureWatcher<QVariantMap>(this);
    connect(watcher, &QFutureWatcher<QVariantMap>::finished, this, [this, watcher]() {
        m_pullInProgress = false;
        emit pullFinished(watcher->result());
        watcher->deleteLater();
    });
    watcher->setFuture(future);

    return GitResult(true, QVariant(), "Pull started");
}

GitResult GitRemote::pullInternal(const QString& remoteName,
                                  const QString& branchName,
                                  std::unique_ptr<IGitAuth> auth)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "No repository available");
    }

    if (remoteName.isEmpty()) {
        return GitResult(false, QVariant(), "Remote name cannot be empty");
    }
    
    qDebug().noquote() << QString("[GitRemote][PullTrace] START remote=%1 requestedBranch=%2 headRef=%3 headOid=%4 wt=%5")
                              .arg(remoteName,
                                   branchName,
                                   currentHeadRefName(m_currentRepo->repo),
                                   currentHeadOid(m_currentRepo->repo),
                                   workingTreeSummary(m_currentRepo->repo));

    git_reference* headRef = nullptr;
    int headResult = git_repository_head(&headRef, m_currentRepo->repo);
    if (headResult != GIT_OK) {
        qDebug().noquote() << QString("[GitRemote][PullTrace] FAIL git_repository_head rc=%1 err=%2")
                                  .arg(headResult)
                                  .arg(lastGitErrorMessage());
        if (headResult == GIT_EUNBORNBRANCH) {
            return GitResult(false, QVariant(), "Cannot pull: repository has no commits yet");
        }
        if (headResult == GIT_ENOTFOUND) {
            return GitResult(false, QVariant(), "Cannot pull: detached HEAD state");
        }
        return GitResult(false, QVariant(), "Failed to resolve current HEAD");
    }

    QString currentBranch;
    const char* currentBranchName = nullptr;
    if (git_branch_name(&currentBranchName, headRef) == GIT_OK && currentBranchName) {
        currentBranch = QString::fromUtf8(currentBranchName);
    }
    git_reference_free(headRef);

    if (currentBranch.isEmpty()) {
        qDebug().noquote() << "[GitRemote][PullTrace] FAIL empty current branch (detached)";
        return GitResult(false, QVariant(), "Cannot pull: detached HEAD state");
    }

    QString targetBranch = branchName.trimmed();
    if (targetBranch.isEmpty()) {
        targetBranch = currentBranch;
    }

    if (targetBranch != currentBranch) {
        qDebug().noquote() << QString("[GitRemote][PullTrace] FAIL target mismatch current=%1 target=%2")
                                  .arg(currentBranch, targetBranch);
        return GitResult(false, QVariant(),
                         QString("Pull can only be applied to the checked out branch ('%1').")
                             .arg(currentBranch));
    }

    auto fetchResult = fetchInternal(remoteName, std::move(auth));
    if (!fetchResult.success()) {
        qDebug().noquote() << QString("[GitRemote][PullTrace] FAIL fetch remote=%1 error=%2")
                                  .arg(remoteName, fetchResult.errorMessage());
        return fetchResult;
    }

    git_reference* localRef = nullptr;
    int result = git_branch_lookup(&localRef,
                                   m_currentRepo->repo,
                                   targetBranch.toUtf8().constData(),
                                   GIT_BRANCH_LOCAL);
    if (result != GIT_OK || !localRef) {
        qDebug().noquote() << QString("[GitRemote][PullTrace] FAIL local branch lookup branch=%1 rc=%2 err=%3")
                                  .arg(targetBranch)
                                  .arg(result)
                                  .arg(lastGitErrorMessage());
        return GitResult(false, QVariant(),
                         QString("Local branch '%1' not found").arg(targetBranch));
    }

    QString remoteTrackingBranch = remoteName + "/" + targetBranch;
    git_reference* remoteRef = nullptr;
    result = git_branch_lookup(&remoteRef,
                               m_currentRepo->repo,
                               remoteTrackingBranch.toUtf8().constData(),
                               GIT_BRANCH_REMOTE);
    if (result != GIT_OK || !remoteRef) {
        qDebug().noquote() << QString("[GitRemote][PullTrace] FAIL remote branch lookup branch=%1 rc=%2 err=%3")
                                  .arg(remoteTrackingBranch)
                                  .arg(result)
                                  .arg(lastGitErrorMessage());
        git_reference_free(localRef);
        return GitResult(false, QVariant(),
                         QString("Remote branch '%1' not found after fetch").arg(remoteTrackingBranch));
    }

    git_annotated_commit* remoteHead = nullptr;
    result = git_annotated_commit_from_ref(&remoteHead, m_currentRepo->repo, remoteRef);
    if (result != GIT_OK || !remoteHead) {
        qDebug().noquote() << QString("[GitRemote][PullTrace] FAIL annotated commit from remote ref rc=%1 err=%2")
                                  .arg(result)
                                  .arg(lastGitErrorMessage());
        git_reference_free(remoteRef);
        git_reference_free(localRef);
        return GitResult(false, QVariant(), "Failed to inspect remote branch state");
    }

    const git_annotated_commit* annotatedHeads[] = {remoteHead};
    git_merge_analysis_t analysis = GIT_MERGE_ANALYSIS_NONE;
    git_merge_preference_t preference = GIT_MERGE_PREFERENCE_NONE;
    result = git_merge_analysis(&analysis, &preference,
                                m_currentRepo->repo, annotatedHeads, 1);

    if (result != GIT_OK) {
        qDebug().noquote() << QString("[GitRemote][PullTrace] FAIL merge analysis rc=%1 err=%2")
                                  .arg(result)
                                  .arg(lastGitErrorMessage());
        git_annotated_commit_free(remoteHead);
        git_reference_free(remoteRef);
        git_reference_free(localRef);
        return GitResult(false, QVariant(), "Failed to analyze merge state");
    }
    
    qDebug().noquote() << QString("[GitRemote][PullTrace] analysis=%1 preference=%2 currentBranch=%3 targetBranch=%4")
                              .arg(static_cast<int>(analysis))
                              .arg(static_cast<int>(preference))
                              .arg(currentBranch, targetBranch);

    QVariantMap pullResult;
    pullResult["remote"] = remoteName;
    pullResult["branch"] = targetBranch;
    pullResult["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);

    if (analysis & GIT_MERGE_ANALYSIS_UP_TO_DATE) {
        pullResult["status"] = "Already up to date";
        qDebug().noquote() << QString("[GitRemote][PullTrace] UP_TO_DATE headRef=%1 headOid=%2 wt=%3")
                                  .arg(currentHeadRefName(m_currentRepo->repo),
                                       currentHeadOid(m_currentRepo->repo),
                                       workingTreeSummary(m_currentRepo->repo));
        emitGitCommand(QString("git pull %1 %2")
                           .arg(quoteCommandArg(remoteName), quoteCommandArg(targetBranch)));
        git_annotated_commit_free(remoteHead);
        git_reference_free(remoteRef);
        git_reference_free(localRef);
        return GitResult(true, pullResult);
    }

    if (analysis & GIT_MERGE_ANALYSIS_FASTFORWARD) {
        const git_oid* targetOid = git_annotated_commit_id(remoteHead);
        if (!targetOid) {
            qDebug().noquote() << "[GitRemote][PullTrace] FAIL null fast-forward target oid";
            git_annotated_commit_free(remoteHead);
            git_reference_free(remoteRef);
            git_reference_free(localRef);
            return GitResult(false, QVariant(), "Failed to resolve fast-forward target");
        }
        
        char ffHash[GIT_OID_HEXSZ + 1];
        git_oid_tostr(ffHash, sizeof(ffHash), targetOid);
        qDebug().noquote() << QString("[GitRemote][PullTrace] FAST_FORWARD targetOid=%1").arg(QString::fromUtf8(ffHash));

        git_reference* updatedLocalRef = nullptr;
        result = git_reference_set_target(&updatedLocalRef,
                                          localRef,
                                          targetOid,
                                          "pull: Fast-forward");
        if (result != GIT_OK || !updatedLocalRef) {
            qDebug().noquote() << QString("[GitRemote][PullTrace] FAIL set target rc=%1 err=%2")
                                      .arg(result)
                                      .arg(lastGitErrorMessage());
            git_annotated_commit_free(remoteHead);
            git_reference_free(remoteRef);
            git_reference_free(localRef);
            return GitResult(false, QVariant(), "Failed to update local branch reference");
        }

        result = git_repository_set_head(m_currentRepo->repo, git_reference_name(updatedLocalRef));
        if (result != GIT_OK) {
            qDebug().noquote() << QString("[GitRemote][PullTrace] FAIL set head rc=%1 err=%2")
                                      .arg(result)
                                      .arg(lastGitErrorMessage());
            git_reference_free(updatedLocalRef);
            git_annotated_commit_free(remoteHead);
            git_reference_free(remoteRef);
            git_reference_free(localRef);
            return GitResult(false, QVariant(), "Failed to set HEAD after fast-forward");
        }

        git_object* targetCommit = nullptr;
        result = git_object_lookup(&targetCommit, m_currentRepo->repo, targetOid, GIT_OBJECT_COMMIT);
        if (result != GIT_OK || !targetCommit) {
            qDebug().noquote() << QString("[GitRemote][PullTrace] FAIL lookup target commit rc=%1 err=%2")
                                      .arg(result)
                                      .arg(lastGitErrorMessage());
            git_reference_free(updatedLocalRef);
            git_annotated_commit_free(remoteHead);
            git_reference_free(remoteRef);
            git_reference_free(localRef);
            return GitResult(false, QVariant(), "Failed to resolve pulled commit");
        }

        git_checkout_options checkoutOpts = GIT_CHECKOUT_OPTIONS_INIT;
        checkoutOpts.checkout_strategy = GIT_CHECKOUT_SAFE | GIT_CHECKOUT_RECREATE_MISSING;
        // Ensure HEAD/index/worktree are all synchronized to the pulled commit.
        result = git_reset(m_currentRepo->repo, targetCommit, GIT_RESET_HARD, &checkoutOpts);
        git_object_free(targetCommit);
        git_reference_free(updatedLocalRef);
        git_annotated_commit_free(remoteHead);
        git_reference_free(remoteRef);
        git_reference_free(localRef);

        if (result != GIT_OK) {
            qDebug().noquote() << QString("[GitRemote][PullTrace] FAIL checkout head rc=%1 err=%2 headRef=%3 headOid=%4 wt=%5")
                                      .arg(result)
                                      .arg(lastGitErrorMessage())
                                      .arg(currentHeadRefName(m_currentRepo->repo))
                                      .arg(currentHeadOid(m_currentRepo->repo))
                                      .arg(workingTreeSummary(m_currentRepo->repo));
            return GitResult(false, QVariant(),
                             "Pull failed while updating working tree (local changes may conflict)");
        }

        pullResult["status"] = "Fast-forward";
        qDebug().noquote() << QString("[GitRemote][PullTrace] FAST_FORWARD_DONE headRef=%1 headOid=%2 wt=%3")
                                  .arg(currentHeadRefName(m_currentRepo->repo),
                                       currentHeadOid(m_currentRepo->repo),
                                       workingTreeSummary(m_currentRepo->repo));
        emitGitCommand(QString("git pull %1 %2")
                           .arg(quoteCommandArg(remoteName), quoteCommandArg(targetBranch)));
        return GitResult(true, pullResult);
    }

    git_annotated_commit_free(remoteHead);
    git_reference_free(remoteRef);
    git_reference_free(localRef);

    if (analysis & GIT_MERGE_ANALYSIS_NORMAL) {
        qDebug().noquote() << QString("[GitRemote][PullTrace] NORMAL_MERGE_REQUIRED headRef=%1 headOid=%2 wt=%3")
                                  .arg(currentHeadRefName(m_currentRepo->repo),
                                       currentHeadOid(m_currentRepo->repo),
                                       workingTreeSummary(m_currentRepo->repo));
        return GitResult(false, QVariant(),
                         "Non-fast-forward pull detected. Merge/rebase is required and is not automated here.");
    }

    qDebug().noquote() << QString("[GitRemote][PullTrace] FAIL unsupported analysis=%1 headRef=%2 headOid=%3 wt=%4")
                              .arg(static_cast<int>(analysis))
                              .arg(currentHeadRefName(m_currentRepo->repo))
                              .arg(currentHeadOid(m_currentRepo->repo))
                              .arg(workingTreeSummary(m_currentRepo->repo));
    return GitResult(false, QVariant(), "Pull failed: unsupported merge analysis result");
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
    
    qDebug().noquote() << QString("[GitRemote][FetchTrace] START remote=%1 headRef=%2 headOid=%3 wt=%4")
                              .arg(remoteName,
                                   currentHeadRefName(m_currentRepo->repo),
                                   currentHeadOid(m_currentRepo->repo),
                                   workingTreeSummary(m_currentRepo->repo));

    result = git_remote_fetch(remote, nullptr, &opts, nullptr);

    git_remote_free(remote);

    if (result != GIT_OK) {
        qDebug().noquote() << QString("[GitRemote][FetchTrace] FAIL remote=%1 rc=%2 err=%3")
                                  .arg(remoteName)
                                  .arg(result)
                                  .arg(lastGitErrorMessage());
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
    qDebug().noquote() << QString("[GitRemote][FetchTrace] DONE remote=%1 headRef=%2 headOid=%3 wt=%4")
                              .arg(remoteName,
                                   currentHeadRefName(m_currentRepo->repo),
                                   currentHeadOid(m_currentRepo->repo),
                                   workingTreeSummary(m_currentRepo->repo));

    // Collect fetched heads with before/after info 
    QVariantList fetchedHeads;
    QStringList logLines;
    struct FetchHeadPayload {
        git_repository* repo;
        QVariantList* heads;
        QString remoteName;
        QStringList* logs;
    } headPayload { m_currentRepo->repo, &fetchedHeads, remoteName, &logLines };

    auto fetchHeadCb = [](const char* ref_name,
                          const char* remote_url,
                          const git_oid* oid,
                          unsigned int is_merge,
                          void* payload) -> int {
        auto* data = static_cast<FetchHeadPayload*>(payload);
        auto* repo = data->repo;
        auto* heads = data->heads;
        auto* logs = data->logs;
        const QString remoteName = data->remoteName;

        QVariantMap entry;
        QString refStr = ref_name ? QString::fromUtf8(ref_name) : "";
        entry["ref"] = refStr;
        entry["remoteUrl"] = remote_url ? QString::fromUtf8(remote_url) : "";
        entry["commit"] = oid ? QString::fromLatin1(git_oid_tostr_s(oid)) : "";
        entry["isMerge"] = static_cast<bool>(is_merge);

        // Derive branch name (refs/heads/<branch>)
        QString branchName = refStr.startsWith("refs/heads/") ? refStr.mid(QString("refs/heads/").size()) : refStr;
        entry["branch"] = branchName;

        // Compute tracking ref and reflog delta to mimic git fetch output
        QString trackingRef = QString("refs/remotes/%1/%2").arg(remoteName, branchName);
        entry["trackingRef"] = trackingRef;

        git_reflog* log = nullptr;
        if (git_reflog_read(&log, repo, trackingRef.toUtf8().constData()) == 0 && log) {
            size_t count = git_reflog_entrycount(log);
            if (count > 0) {
                const git_reflog_entry* latest = git_reflog_entry_byindex(log, 0);
                const git_oid* oldOid = git_reflog_entry_id_old(latest);
                const git_oid* newOid = git_reflog_entry_id_new(latest);
                char bufOld[GIT_OID_HEXSZ + 1] = {0};
                char bufNew[GIT_OID_HEXSZ + 1] = {0};
                if (oldOid) git_oid_tostr(bufOld, sizeof(bufOld), oldOid);
                if (newOid) git_oid_tostr(bufNew, sizeof(bufNew), newOid);
                entry["oldCommit"] = QString::fromLatin1(bufOld);
                entry["newCommit"] = QString::fromLatin1(bufNew);
                QString shortOld = entry["oldCommit"].toString().left(7);
                QString shortNew = entry["newCommit"].toString().left(7);
                QString summary;
                if (shortOld.isEmpty() || shortOld == "0000000") {
                    summary = QString(" * [new branch]     %1 -> %2/%1 (%3)")
                                  .arg(branchName,
                                       remoteName,
                                       shortNew.isEmpty() ? "0000000" : shortNew);
                } else if (shortOld == shortNew) {
                    summary = QString(" = up to date       %1 (%2)")
                                  .arg(branchName,
                                       shortNew.isEmpty() ? "0000000" : shortNew);
                } else {
                    summary = QString("   %1..%2  %3 -> %4/%3")
                                  .arg(shortOld.isEmpty() ? "0000000" : shortOld,
                                       shortNew.isEmpty() ? "0000000" : shortNew,
                                       branchName,
                                       remoteName);
                }
                entry["summary"] = summary;
                if (logs) logs->append(summary);
            }
            git_reflog_free(log);
        }

        heads->append(entry);
        return 0;
    };

    git_repository_fetchhead_foreach(m_currentRepo->repo, fetchHeadCb, &headPayload);
    fetchResult["heads"] = fetchedHeads;
    if (!logLines.isEmpty())
        fetchResult["log"] = logLines;
    if (!fetchedHeads.isEmpty())
        fetchResult["branch"] = fetchedHeads.first().toMap().value("branch");

    return GitResult(true, fetchResult);
}
