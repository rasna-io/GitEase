#include "GitRebase.h"

#include "GitUtils.h"

#include <git2/annotated_commit.h>
#include <git2/commit.h>
#include <git2/checkout.h>
#include <git2/index.h>
#include <git2/rebase.h>
#include <git2/repository.h>
#include <git2/revparse.h>
#include <git2/revwalk.h>
#include <git2/signature.h>

#include <QVariantList>
#include <git2/branch.h>

#include <QDateTime>
#include <QStringList>
#include <QVariantMap>
#include <QTimer>
#include <git2/cherrypick.h>

GitRebase::GitRebase(QObject* parent)
    : IGitController{parent}
{
}

GitResult GitRebase::rebase(const QString& upstream, const QString& branch)
{
    return rebaseOnto(QString(), upstream, branch);
}

GitResult GitRebase::rebaseOnto(const QString& onto,
                                const QString& upstream,
                                QString branch)
{
    return startRebase(onto, upstream, branch, {});
}

GitResult GitRebase::previewRebasePlan(const QString& onto,
                                       const QString& upstream,
                                       const QString& branch)
{
    Q_UNUSED(onto)

    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    if (upstream.trimmed().isEmpty()) {
        return GitResult(false, QVariant(), "Upstream reference is required.");
    }

    git_object* upstreamObject = nullptr;
    int result = git_revparse_single(&upstreamObject,
                                     m_currentRepo->repo,
                                     upstream.trimmed().toUtf8().constData());
    if (result != GIT_OK || !upstreamObject) {
        return GitResult(false, QVariant(),
                         QString("Invalid upstream '%1'.").arg(upstream));
    }

    QString branchSpec = branch.trimmed();
    if (branchSpec.isEmpty()) {
        branchSpec = "HEAD";
    }

    git_object* branchObject = nullptr;
    result = git_revparse_single(&branchObject,
                                 m_currentRepo->repo,
                                 branchSpec.toUtf8().constData());
    if (result != GIT_OK || !branchObject) {
        git_object_free(upstreamObject);
        return GitResult(false, QVariant(),
                         QString("Invalid branch '%1'.").arg(branchSpec));
    }

    git_revwalk* walk = nullptr;
    result = git_revwalk_new(&walk, m_currentRepo->repo);
    if (result != GIT_OK || !walk) {
        git_object_free(branchObject);
        git_object_free(upstreamObject);
        return GitResult(false, QVariant(),
                         QString("Failed to prepare rebase plan: %1").arg(GitUtils::getLastError()));
    }

    git_revwalk_sorting(walk, GIT_SORT_TOPOLOGICAL | GIT_SORT_TIME);
    git_revwalk_push(walk, git_object_id(branchObject));
    git_revwalk_hide(walk, git_object_id(upstreamObject));

    QVariantList commits;
    git_oid oid;
    while (git_revwalk_next(&oid, walk) == GIT_OK) {
        git_commit* commit = nullptr;
        if (git_commit_lookup(&commit, m_currentRepo->repo, &oid) != GIT_OK || !commit) {
            continue;
        }

        char hash[GIT_OID_HEXSZ + 1] = {0};
        git_oid_tostr(hash, sizeof(hash), git_commit_id(commit));

        QStringList parentHashes;
        const unsigned int parentCount = git_commit_parentcount(commit);
        for (unsigned int i = 0; i < parentCount; ++i) {
            const git_oid* parentOid = git_commit_parent_id(commit, i);
            if (!parentOid) {
                continue;
            }

            char parentHash[GIT_OID_HEXSZ + 1] = {0};
            git_oid_tostr(parentHash, sizeof(parentHash), parentOid);
            parentHashes.append(QString::fromUtf8(parentHash));
        }

        const git_signature* author = git_commit_author(commit);
        const QString message       = QString::fromUtf8(git_commit_message(commit));

        QVariantMap item;
        item["action"]          = "pick";
        item["hash"]            = QString::fromUtf8(hash);
        item["shortHash"]       = QString::fromUtf8(hash).left(7);
        item["summary"]         = message.split('\n').first();
        item["message"]         = message;
        item["author"]          = author && author->name ? QString::fromUtf8(author->name) : QString();
        item["authorEmail"]     = author && author->email ? QString::fromUtf8(author->email) : QString();
        item["authorDate"]      = author ? QDateTime::fromSecsSinceEpoch(author->when.time).toString(Qt::ISODate) : QString();
        item["parentHashes"]    = parentHashes;
        item["parentHash"]      = parentHashes.isEmpty() ? QString() : parentHashes.first();
        item["isMerge"]         = parentCount > 1;

        commits.append(item);
        git_commit_free(commit);
    }

    git_revwalk_free(walk);
    git_object_free(branchObject);
    git_object_free(upstreamObject);

    QVariantMap data;
    data["commits"]             = commits;
    data["upstream"]            = upstream.trimmed();
    data["onto"]                = onto.trimmed();
    data["branch"]              = branch.trimmed();
    data["supportedActions"]    = QStringList{"pick", "skip"};

    return GitResult(true, data);
}

GitResult GitRebase::startRebase(const QString& onto,
                                 const QString& upstream,
                                 QString branch,
                                 const QSet<QString>& skippedCommits)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    if (upstream.trimmed().isEmpty()) {
        return GitResult(false, QVariant(), "Upstream reference is required.");
    }

    if (isRebaseInProgress()) {
        return GitResult(false, QVariant(),
                         "A rebase is already in progress. Continue or abort it first.");
    }

    QString originalBranch  = branch;
    bool hasBranch          = !branch.trimmed().isEmpty();

    // If a branch is provided, ensure it is checked out
    if (hasBranch) {
        QString currentBranch = getCurrentBranchName();
        if (currentBranch != originalBranch) {
            GitResult checkoutResult = checkoutBranch(branch);
            if (!checkoutResult.success()) {
                return checkoutResult;
            }
        }
        // After checkout, we want to use the current HEAD, so we clear 'branch'
        // to prevent creating a separate annotated commit for it.
        branch = QString();
    }

    git_rebase* rebase                  = nullptr;
    git_annotated_commit* branchCommit  = nullptr;
    git_annotated_commit* ontoCommit    = nullptr;
    git_annotated_commit* upstreamCommit= nullptr;

    int result = git_annotated_commit_from_revspec(
        &upstreamCommit, m_currentRepo->repo, upstream.trimmed().toUtf8().constData());
    if (result != GIT_OK) {
        return GitResult(false, QVariant(),
                         QString("Invalid upstream '%1'.").arg(upstream));
    }

    if (!branch.trimmed().isEmpty()) {
        result = git_annotated_commit_from_revspec(
            &branchCommit, m_currentRepo->repo, branch.trimmed().toUtf8().constData());
        if (result != GIT_OK) {
            git_annotated_commit_free(upstreamCommit);
            return GitResult(false, QVariant(),
                             QString("Invalid branch '%1'.").arg(branch));
        }
    }

    if (!onto.trimmed().isEmpty()) {
        result = git_annotated_commit_from_revspec(
            &ontoCommit, m_currentRepo->repo, onto.trimmed().toUtf8().constData());
        if (result != GIT_OK) {
            git_annotated_commit_free(branchCommit);
            git_annotated_commit_free(upstreamCommit);
            return GitResult(false, QVariant(),
                             QString("Invalid onto '%1'.").arg(onto));
        }
    }

    git_rebase_options rebaseOpts = GIT_REBASE_OPTIONS_INIT;
    rebaseOpts.checkout_options.checkout_strategy = GIT_CHECKOUT_SAFE | GIT_CHECKOUT_RECREATE_MISSING;

    result = git_rebase_init(&rebase,
                             m_currentRepo->repo,
                             branchCommit,
                             upstreamCommit,
                             ontoCommit,
                             &rebaseOpts);

    git_annotated_commit_free(branchCommit);
    git_annotated_commit_free(upstreamCommit);
    git_annotated_commit_free(ontoCommit);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(),
                         QString("Failed to start rebase: %1").arg(GitUtils::getLastError()));
    }

    GitResult rebaseResult = runRebase(rebase, false, skippedCommits);
    git_rebase_free(rebase);

    if (rebaseResult.success()) {
        QString command = skippedCommits.isEmpty() ? "git rebase" : "git rebase -i";
        if (!onto.trimmed().isEmpty()) {
            command += " --onto " + quoteCommandArg(onto);
        }
        command += " " + quoteCommandArg(upstream);
        if (hasBranch) {
            command += " " + quoteCommandArg(originalBranch);
        }
        if (!skippedCommits.isEmpty()) {
            command += QString("  # skipped %1 commit(s)").arg(skippedCommits.count());
        }
        emitGitCommand(command);
    }

    return rebaseResult;
}

GitResult GitRebase::continueOp()
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    if (!isRebaseInProgress()) {
        return GitResult(false, QVariant(), "No rebase is in progress.");
    }

    git_rebase* rebase = nullptr;
    GitResult openResult = openRebase(&rebase);
    if (!openResult.success()) {
        return openResult;
    }

    GitResult continueResult = runRebase(rebase, true);
    git_rebase_free(rebase);

    if (continueResult.success()) {
        emitGitCommand("git rebase --continue");
    }

    return continueResult;
}

GitResult GitRebase::skipOp()
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    if (!isRebaseInProgress()) {
        return GitResult(false, QVariant(), "No rebase is in progress.");
    }

    if (repositoryHasConflicts()) {
        GitResult resetResult = resetWorktreeToHead();
        if (!resetResult.success()) {
            return resetResult;
        }
    }

    git_rebase* rebase = nullptr;
    GitResult openResult = openRebase(&rebase);
    if (!openResult.success()) {
        return openResult;
    }

    GitResult skipResult = runRebase(rebase, false);
    git_rebase_free(rebase);

    if (skipResult.success()) {
        emitGitCommand("git rebase --skip");
    }

    return skipResult;
}

GitResult GitRebase::abortOp()
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    if (!isRebaseInProgress()) {
        return GitResult(false, QVariant(), "No rebase is in progress.");
    }

    git_rebase* rebase = nullptr;
    GitResult openResult = openRebase(&rebase);
    if (!openResult.success()) {
        return openResult;
    }

    int result = git_rebase_abort(rebase);
    git_rebase_free(rebase);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(),
                         QString("Failed to abort rebase: %1").arg(GitUtils::getLastError()));
    }

    emitGitCommand("git rebase --abort");
    return GitResult(true, QVariant(), "Rebase aborted.");
}

GitResult GitRebase::quitOp()
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    if (!isRebaseInProgress()) {
        return GitResult(false, QVariant(), "No rebase is in progress.");
    }

    const int result = git_repository_state_cleanup(m_currentRepo->repo);
    if (result != GIT_OK) {
        return GitResult(false, QVariant(),
                         QString("Failed to quit rebase: %1").arg(GitUtils::getLastError()));
    }

    emitGitCommand("git rebase --quit");
    return GitResult(true, QVariant(), "Rebase state cleaned up.");
}

GitResult GitRebase::rebaseStatus()
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    QVariantMap data;
    data["inProgress"] = isRebaseInProgress();
    data["hasConflicts"] = repositoryHasConflicts();

    if (!data["inProgress"].toBool()) {
        data["status"] = "idle";
        return GitResult(true, data);
    }

    git_rebase* rebase = nullptr;
    GitResult openResult = openRebase(&rebase);
    if (!openResult.success()) {
        return openResult;
    }

    QVariantMap progressData = rebaseProgressData(rebase);
    git_rebase_free(rebase);

    for (auto it = progressData.constBegin(); it != progressData.constEnd(); ++it) {
        data[it.key()] = it.value();
    }
    data["status"] = data["hasConflicts"].toBool() ? "conflict" : "in_progress";

    return GitResult(true, data);
}

GitResult GitRebase::runRebase(git_rebase* rebase,
                               bool continueCurrentOperation,
                               const QSet<QString>& skippedCommits)
{
    if (!rebase) {
        return GitResult(false, QVariant(), "Invalid rebase state.");
    }

    git_signature* signature = nullptr;
    int result = git_signature_default(&signature, m_currentRepo->repo);
    if (result != GIT_OK || !signature) {
        return GitResult(false, QVariant(),
                         "Failed to load Git user identity (user.name / user.email).");
    }

    QVariantList rebasedCommits;
    QVariantList skippedCommitList;
    QVariantMap rebaseData;
    rebaseData["totalOperations"] = static_cast<int>(git_rebase_operation_entrycount(rebase));

    auto recordCommit = [&](const git_oid* oid) {
        if (!oid) {
            return;
        }
        char oidStr[GIT_OID_HEXSZ + 1] = {0};
        git_oid_tostr(oidStr, sizeof(oidStr), oid);
        rebasedCommits.push_back(QString::fromUtf8(oidStr));
    };

    auto commitCurrent = [&]() -> GitResult {
        git_oid commitOid;
        int commitResult = git_rebase_commit(&commitOid, rebase, nullptr, signature, nullptr, nullptr);

        if (commitResult == GIT_OK) {
            recordCommit(&commitOid);
            return GitResult(true);
        }

        if (commitResult == GIT_EAPPLIED) {
            return GitResult(true);
        }

        if (commitResult == GIT_EUNMERGED) {
            return conflictResult(rebase, "Rebase stopped due to conflicts. Resolve conflicts and continue.");
        }

        return GitResult(false, QVariant(),
                         QString("Failed to create rebased commit: %1").arg(GitUtils::getLastError()));
    };

    auto operationHashByIndex = [&](size_t index) -> QString {
        if (index == GIT_REBASE_NO_OPERATION) {
            return QString();
        }

        git_rebase_operation* operation = git_rebase_operation_byindex(rebase, index);
        if (!operation) {
            return QString();
        }

        char oidStr[GIT_OID_HEXSZ + 1] = {0};
        git_oid_tostr(oidStr, sizeof(oidStr), &operation->id);
        return QString::fromUtf8(oidStr);
    };

    if (continueCurrentOperation && git_rebase_operation_current(rebase) != GIT_REBASE_NO_OPERATION) {
        GitResult commitResult = commitCurrent();
        if (!commitResult.success()) {
            git_signature_free(signature);
            return commitResult;
        }
    }

    while (true) {
        git_rebase_operation* operation = nullptr;
        result = git_rebase_next(&operation, rebase);

        if (result == GIT_ITEROVER) {
            break;
        }

        if (result != GIT_OK) {
            if (repositoryHasConflicts()) {
                const QString currentHash = operationHashByIndex(git_rebase_operation_current(rebase));
                if (!currentHash.isEmpty() && skippedCommits.contains(currentHash)) {
                    GitResult resetResult = resetWorktreeToHead();
                    if (!resetResult.success()) {
                        git_signature_free(signature);
                        return resetResult;
                    }
                    skippedCommitList.push_back(currentHash);
                    continue;
                }

                git_signature_free(signature);
                return conflictResult(rebase,
                                      "Rebase stopped due to conflicts. Resolve conflicts and continue.");
            }

            git_signature_free(signature);
            return GitResult(false, QVariant(),
                             QString("Failed to apply rebase operation: %1").arg(GitUtils::getLastError()));
        }

        char operationId[GIT_OID_HEXSZ + 1] = {0};
        git_oid_tostr(operationId, sizeof(operationId), &operation->id);
        const QString operationHash = QString::fromUtf8(operationId);

        if (skippedCommits.contains(operationHash)) {
            GitResult resetResult = resetWorktreeToHead();
            if (!resetResult.success()) {
                git_signature_free(signature);
                return resetResult;
            }
            skippedCommitList.push_back(operationHash);
            continue;
        }

        GitResult commitResult = commitCurrent();
        if (!commitResult.success()) {
            git_signature_free(signature);
            return commitResult;
        }
    }

    result = git_rebase_finish(rebase, signature);
    git_signature_free(signature);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(),
                         QString("Failed to finish rebase: %1").arg(GitUtils::getLastError()));
    }

    rebaseData["rebasedCommits"]= rebasedCommits;
    rebaseData["skippedCommits"]= skippedCommitList;
    rebaseData["appliedCount"]  = rebasedCommits.count();
    rebaseData["skippedCount"]  = skippedCommitList.count();
    rebaseData["status"]        = "completed";

    return GitResult(true, rebaseData, "Rebase completed.");
}

GitResult GitRebase::conflictResult(git_rebase* rebase, const QString& message)
{
    QVariantMap data = rebaseProgressData(rebase);
    data["status"] = "conflict";
    data["inProgress"] = true;
    data["hasConflicts"] = true;
    return GitResult(false, data, message);
}

GitResult GitRebase::openRebase(git_rebase** rebase) const
{
    if (!rebase) {
        return GitResult(false, QVariant(), "Invalid rebase handle.");
    }

    *rebase = nullptr;
    git_rebase_options rebaseOpts = GIT_REBASE_OPTIONS_INIT;
    const int result = git_rebase_open(rebase, m_currentRepo->repo, &rebaseOpts);
    if (result != GIT_OK) {
        return GitResult(false, QVariant(),
                         QString("Failed to open rebase state: %1").arg(GitUtils::getLastError()));
    }

    return GitResult(true);
}

QVariantMap GitRebase::rebaseProgressData(git_rebase* rebase) const
{
    QVariantMap data;
    data["inProgress"] = isRebaseInProgress();
    data["hasConflicts"] = repositoryHasConflicts();
    data["currentOperation"] = static_cast<qlonglong>(GIT_REBASE_NO_OPERATION);
    data["totalOperations"] = 0;

    if (!rebase) {
        return data;
    }

    data["currentOperation"] = static_cast<qlonglong>(git_rebase_operation_current(rebase));
    data["totalOperations"] = static_cast<qlonglong>(git_rebase_operation_entrycount(rebase));

    const size_t current = git_rebase_operation_current(rebase);
    if (current == GIT_REBASE_NO_OPERATION) {
        return data;
    }

    git_rebase_operation* op = git_rebase_operation_byindex(rebase, current);
    if (!op) {
        return data;
    }

    char oidStr[GIT_OID_HEXSZ + 1] = {0};
    git_oid_tostr(oidStr, sizeof(oidStr), &op->id);
    data["currentCommit"] = QString::fromUtf8(oidStr);
    data["operationType"] = static_cast<int>(op->type);

    return data;
}

GitResult GitRebase::resetWorktreeToHead() const
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    git_checkout_options checkoutOpts = GIT_CHECKOUT_OPTIONS_INIT;
    checkoutOpts.checkout_strategy = GIT_CHECKOUT_FORCE | GIT_CHECKOUT_RECREATE_MISSING;
    int result = git_checkout_head(m_currentRepo->repo, &checkoutOpts);
    if (result != GIT_OK) {
        return GitResult(false, QVariant(),
                         QString("Failed to reset worktree before skipping: %1")
                             .arg(GitUtils::getLastError()));
    }

    git_index* index = nullptr;
    result = git_repository_index(&index, m_currentRepo->repo);
    if (result != GIT_OK || !index) {
        return GitResult(false, QVariant(),
                         QString("Failed to open index: %1").arg(GitUtils::getLastError()));
    }

    git_index_conflict_cleanup(index);
    result = git_index_write(index);
    git_index_free(index);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(),
                         QString("Failed to cleanup index conflicts: %1")
                             .arg(GitUtils::getLastError()));
    }

    return GitResult(true);
}

bool GitRebase::repositoryHasConflicts() const
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return false;
    }

    git_index* index = nullptr;
    if (git_repository_index(&index, m_currentRepo->repo) != GIT_OK || !index) {
        return false;
    }

    const bool hasConflicts = git_index_has_conflicts(index) != 0;
    git_index_free(index);
    return hasConflicts;
}

bool GitRebase::isRebaseInProgress() const
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return false;
    }

    const int state = git_repository_state(m_currentRepo->repo);
    return state == GIT_REPOSITORY_STATE_REBASE ||
           state == GIT_REPOSITORY_STATE_REBASE_INTERACTIVE ||
           state == GIT_REPOSITORY_STATE_REBASE_MERGE;
}

GitResult GitRebase::checkoutBranch(const QString& branchName)
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "Repository not open.");

    git_reference* targetRef = nullptr;
    git_object* targetCommit = nullptr;

    int error = git_branch_lookup(&targetRef, m_currentRepo->repo,
                                  branchName.toUtf8().constData(),
                                  GIT_BRANCH_LOCAL);
    if (error != GIT_OK) {
        return GitResult(false, QVariant(),
                         QString("Branch '%1' not found.").arg(branchName));
    }

    error = git_reference_peel(&targetCommit, targetRef, GIT_OBJ_COMMIT);
    if (error != GIT_OK) {
        git_reference_free(targetRef);
        return GitResult(false, QVariant(),
                         QString("Failed to peel reference for branch '%1'.").arg(branchName));
    }

    git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
    opts.checkout_strategy = GIT_CHECKOUT_SAFE | GIT_CHECKOUT_RECREATE_MISSING;

    error = git_checkout_tree(m_currentRepo->repo, targetCommit, &opts);
    if (error != GIT_OK) {
        git_object_free(targetCommit);
        git_reference_free(targetRef);
        return GitResult(false, QVariant(),
                         QString("Failed to checkout branch '%1'.").arg(branchName));
    }

    error = git_repository_set_head(m_currentRepo->repo,
                                    git_reference_name(targetRef));
    if (error != GIT_OK) {
        git_object_free(targetCommit);
        git_reference_free(targetRef);
        return GitResult(false, QVariant(),
                         QString("Failed to set HEAD to branch '%1'.").arg(branchName));
    }

    git_object_free(targetCommit);
    git_reference_free(targetRef);

    emitGitCommand(QString("git checkout %1").arg(quoteCommandArg(branchName)));

    return GitResult(true, QVariant(),
                     QString("Checked out branch '%1'.").arg(branchName));
}

QString GitRebase::getCurrentBranchName()
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return "";

    QString branchName;  // Empty string to start
    git_reference* head = nullptr;  // libgit2 HEAD reference

    int error = git_repository_head(&head, m_currentRepo->repo);

    // Get HEAD reference (points to current branch)
    if (error == GIT_OK)
    {
        const char* name = nullptr;  // Will store branch name

        // Extract branch name from reference
        if (git_branch_name(&name, head) == GIT_OK && name)
        {
            branchName = QString::fromUtf8(name);  // Convert C string to QString
        }
        git_reference_free(head);  // Clean up libgit2 object
    }
    else if (error == GIT_ENOTFOUND)
    {
        branchName = "initial/no-commits";
    }
    else
    {
        branchName = "Detached HEAD";
    }

    emitGitCommand("git rev-parse --abbrev-ref HEAD");

    return branchName;  // "main", "master", or Detached HEAD if detached
}

void GitRebase::startInteractiveRebase(const QString& onto,
                                       const QString& upstream,
                                       const QString& branch,
                                       const QVariantList& operations)
{
    if (m_interactiveInProgress) {
        emit rebaseFinished(false);
        return;
    }

    if (!m_currentRepo || !m_currentRepo->repo) {
        emit rebaseFinished(false);
        return;
    }

    if (isRebaseInProgress()) {
        emit rebaseFinished(false);
        return;
    }

    // Check for uncommitted changes
    git_status_list* statusList = nullptr;
    git_status_options statusOpts = GIT_STATUS_OPTIONS_INIT;
    statusOpts.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED;
    if (git_status_list_new(&statusList, m_currentRepo->repo, &statusOpts) == GIT_OK) {
        size_t count = git_status_list_entrycount(statusList);
        git_status_list_free(statusList);
        if (count > 0) {
            cleanupInteractiveState();
            emit rebaseFinished(false);
            return;
        }
    }

    // Store the plan
    m_interactivePlan = operations;

    m_interactiveOnto     = onto.trimmed();
    m_interactiveUpstream = upstream.trimmed();
    m_interactiveBranch   = branch.trimmed();

    // Save original HEAD reference
    git_reference* headRef = nullptr;
    if (git_repository_head(&headRef, m_currentRepo->repo) == GIT_OK) {
        m_originalHeadRef = headRef;
    } else {
        m_originalHeadRef = nullptr;
    }

    if (m_originalHeadRef == nullptr) {
        // Detached HEAD – save the commit OID
        git_oid headOid;
        if (git_reference_name_to_id(&headOid, m_currentRepo->repo, "HEAD") == GIT_OK) {
            m_originalHeadOid = headOid;
            m_originalHeadDetached = true;
        } else {
            // Should not happen, but if it does, abort
            cleanupInteractiveState();
            emit rebaseFinished(false);
            return;
        }
    } else {
        m_originalHeadDetached = false;
    }

    // Checkout target branch if necessary
    QString actualBranch = m_interactiveBranch;
    bool hasBranch = !actualBranch.isEmpty();
    if (hasBranch) {
        QString currentBranch = getCurrentBranchName();
        if (currentBranch != actualBranch) {
            GitResult checkoutRes = checkoutBranch(actualBranch);
            if (!checkoutRes.success()) {
                cleanupInteractiveState();
                emit rebaseFinished(false);
                return;
            }
        }
        actualBranch.clear(); // after checkout we use HEAD
    }

    // Resolve the new base commit
    QString baseRef = m_interactiveOnto.isEmpty() ? m_interactiveUpstream : m_interactiveOnto;
    if (baseRef.isEmpty()) {
        cleanupInteractiveState();
        emit rebaseFinished(false);
        return;
    }

    git_object* baseObj = nullptr;
    int result = git_revparse_single(&baseObj, m_currentRepo->repo, baseRef.toUtf8().constData());
    if (result != GIT_OK || !baseObj) {
        cleanupInteractiveState();
        emit rebaseFinished(false);
        return;
    }

    // It must be a commit
    if (git_object_type(baseObj) != GIT_OBJ_COMMIT) {
        git_object_free(baseObj);
        cleanupInteractiveState();
        emit rebaseFinished(false);
        return;
    }

    m_newBaseCommit = reinterpret_cast<git_commit*>(baseObj); // we own it now

    // Checkout the new base (detach HEAD)
    git_checkout_options checkoutOpts = GIT_CHECKOUT_OPTIONS_INIT;
    checkoutOpts.checkout_strategy = GIT_CHECKOUT_SAFE | GIT_CHECKOUT_RECREATE_MISSING;
    result = git_checkout_tree(m_currentRepo->repo, reinterpret_cast<git_object*>(m_newBaseCommit), &checkoutOpts);
    if (result != GIT_OK) {
        cleanupInteractiveState();
        emit rebaseFinished(false);
        return;
    }

    // Set HEAD to the new base commit (detached)
    result = git_repository_set_head_detached(m_currentRepo->repo, git_commit_id(m_newBaseCommit));
    if (result != GIT_OK) {
        cleanupInteractiveState();
        emit rebaseFinished(false);
        return;
    }

    // Create default committer signature
    git_signature* sig = nullptr;
    if (git_signature_default(&sig, m_currentRepo->repo) == GIT_OK) {
        m_defaultSignature = sig;
    }

    // Kick off processing
    m_interactiveInProgress = true;
    m_currentPlanIndex = 0;
    QTimer::singleShot(0, this, &GitRebase::processNextOperation);
}

void GitRebase::processNextOperation()
{
    if (!m_interactiveInProgress)
        return;

    // If we've processed everything, finish the rebase
    if (m_currentPlanIndex >= m_interactivePlan.size()) {
        // If we started on a branch, move it to the new HEAD
        if (m_originalHeadRef) {
            git_oid headOid;
            if (git_reference_name_to_id(&headOid, m_currentRepo->repo, "HEAD") == GIT_OK) {
                git_reference* newRef = nullptr;
                int err = git_reference_set_target(&newRef, m_originalHeadRef, &headOid, "rebase completed");
                if (err == GIT_OK) {
                    git_reference_free(m_originalHeadRef);
                    m_originalHeadRef = newRef;
                }
            }
        }
        cleanupInteractiveState();
        emit rebaseFinished(true);
        return;
    }

    // Get the next plan entry
    QVariantMap op = m_interactivePlan[m_currentPlanIndex].toMap();
    QString action = op.value("action").toString().toLower();
    QString hash   = op.value("hash").toString();

    // Handle skip
    if (action == "skip") {
        emit rebaseOperationSkipped(hash);
        m_currentPlanIndex++;
        QTimer::singleShot(0, this, &GitRebase::processNextOperation);
        return;
    }

    if (action == "pick") {
        emit rebaseOperationStarted(hash);
        m_currentOpHash = hash;

        git_commit* commit = lookupCommit(hash);
        if (!commit) {
            cleanupInteractiveState();
            emit rebaseFinished(false);
            return;
        }

        int cpResult = cherryPickCommit(commit);
        if (cpResult == GIT_OK) {
            // Check whether the cherry-pick actually left conflicts in the index
            bool hasConflicts = false;

            git_index* index = nullptr;
            if (git_repository_index(&index, m_currentRepo->repo) == GIT_OK) {
                hasConflicts = git_index_has_conflicts(index);
                git_index_free(index);
            }

            if (hasConflicts) {
                // Treat as a conflict – do not try to commit
                git_commit_free(commit);
                m_isCherryPickActive = true;
                emit rebaseConflict(hash);
                return;
            }

            // Proceed with commit
            if (!commitCherryPick(commit)) {
                git_commit_free(commit);
                abortCherryPick();
                git_repository_state_cleanup(m_currentRepo->repo);
                cleanupInteractiveState();
                emit rebaseFinished(false);
                return;
            }

            git_repository_state_cleanup(m_currentRepo->repo);
            git_commit_free(commit);
            emit rebaseOperationCompleted(hash);
            m_currentPlanIndex++;
            m_isCherryPickActive = false;
            QTimer::singleShot(0, this, &GitRebase::processNextOperation);
        } else if (cpResult == GIT_EMERGECONFLICT) {
            git_commit_free(commit);
            m_isCherryPickActive = true;
            emit rebaseConflict(hash);
        } else {
            git_commit_free(commit);
            abortCherryPick();
            git_repository_state_cleanup(m_currentRepo->repo);
            cleanupInteractiveState();
            emit rebaseFinished(false);
        }
        return;
    }
    m_currentPlanIndex++;
    QTimer::singleShot(0, this, &GitRebase::processNextOperation);
}

void GitRebase::interactiveContinue()
{
    if (!m_interactiveInProgress || !m_isCherryPickActive)
        return;

    // Look up the original commit again to preserve its metadata
    git_commit* originalCommit = lookupCommit(m_currentOpHash);
    if (!originalCommit) {
        cleanupInteractiveState();
        emit rebaseFinished(false);
        return;
    }

    // The user resolved conflicts – commit the result
    if (!commitCherryPick(originalCommit)) {
        git_commit_free(originalCommit);
        cleanupInteractiveState();
        emit rebaseFinished(false);
        return;
    }

    git_commit_free(originalCommit);
    emit rebaseOperationCompleted(m_currentOpHash);
    m_currentPlanIndex++;
    m_isCherryPickActive = false;
    QTimer::singleShot(0, this, &GitRebase::processNextOperation);
}

void GitRebase::interactiveSkip()
{
    if (!m_interactiveInProgress || !m_isCherryPickActive)
        return;

    // Abort the cherry‑pick (reset index and worktree)
    abortCherryPick();
    emit rebaseOperationSkipped(m_currentOpHash);
    m_currentPlanIndex++;
    m_isCherryPickActive = false;
    QTimer::singleShot(0, this, &GitRebase::processNextOperation);
}

void GitRebase::interactiveAbort()
{
    if (!m_interactiveInProgress)
        return;

    // If we were mid‑cherry‑pick, abort it first
    if (m_isCherryPickActive) {
        abortCherryPick();
    }
    else if (m_currentRepo && m_currentRepo->repo) {
        git_repository_state_cleanup(m_currentRepo->repo);
    }

    // Reset to the original HEAD
    if (m_originalHeadRef) {
        git_object* target = nullptr;
        if (git_reference_peel(&target, m_originalHeadRef, GIT_OBJ_COMMIT) == GIT_OK) {
            git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
            opts.checkout_strategy = GIT_CHECKOUT_SAFE | GIT_CHECKOUT_RECREATE_MISSING;

            git_checkout_tree(m_currentRepo->repo, target, &opts);

            git_repository_set_head(m_currentRepo->repo, git_reference_name(m_originalHeadRef));

            git_object_free(target);
        }
    }
    else if (m_originalHeadDetached) {
        // Reset to the original detached commit
        git_commit* target = nullptr;
        if (git_commit_lookup(&target, m_currentRepo->repo, &m_originalHeadOid) == GIT_OK) {
            resetToCommit(target);
            git_commit_free(target);
        }
    }

    git_repository_state_cleanup(m_currentRepo->repo);

    cleanupInteractiveState();
    emit rebaseAborted();
}

git_commit* GitRebase::lookupCommit(const QString& hash) const
{
    git_oid oid;
    if (git_oid_fromstr(&oid, hash.toUtf8().constData()) != GIT_OK)
        return nullptr;

    git_commit* commit = nullptr;
    if (git_commit_lookup(&commit, m_currentRepo->repo, &oid) != GIT_OK)
        return nullptr;

    return commit;
}

int GitRebase::cherryPickCommit(git_commit* commit)
{
    git_cherrypick_options opts = GIT_CHERRYPICK_OPTIONS_INIT;
    opts.checkout_opts.checkout_strategy = GIT_CHECKOUT_SAFE | GIT_CHECKOUT_RECREATE_MISSING;
    return git_cherrypick(m_currentRepo->repo, commit, &opts);
}

bool GitRebase::commitCherryPick(git_commit* originalCommit)
{
    git_oid headOid;
    if (git_reference_name_to_id(&headOid, m_currentRepo->repo, "HEAD") != GIT_OK) {
        qWarning() << "commitCherryPick: failed to get HEAD OID";
        return false;
    }

    git_commit* parent = nullptr;
    if (git_commit_lookup(&parent, m_currentRepo->repo, &headOid) != GIT_OK) {
        qWarning() << "commitCherryPick: failed to lookup parent commit";
        return false;
    }

    const git_signature* author = git_commit_author(originalCommit);
    const char* message = git_commit_message(originalCommit);

    git_index* index = nullptr;
    if (git_repository_index(&index, m_currentRepo->repo) != GIT_OK) {
        qWarning() << "commitCherryPick: failed to get repository index";
        git_commit_free(parent);
        return false;
    }

    if (git_index_has_conflicts(index)) {
        git_index_free(index);
        git_commit_free(parent);
        return false;
    }

    git_oid treeOid;
    if (git_index_write_tree(&treeOid, index) != GIT_OK) {
        const git_error *err = git_error_last();
        qWarning() << "commitCherryPick: failed to write tree:" << (err ? err->message : "unknown");
        git_index_free(index);
        git_commit_free(parent);
        return false;
    }

    git_tree* tree = nullptr;
    if (git_tree_lookup(&tree, m_currentRepo->repo, &treeOid) != GIT_OK) {
        qWarning() << "commitCherryPick: failed to lookup tree";
        git_index_free(index);
        git_commit_free(parent);
        return false;
    }

    const git_commit* parents[1] = { parent };

    git_oid newCommitOid;
    int result = git_commit_create(
        &newCommitOid,
        m_currentRepo->repo,
        "HEAD",
        author,
        m_defaultSignature,
        "UTF-8",
        message,
        tree,
        1,
        parents
        );

    git_tree_free(tree);
    git_index_free(index);
    git_commit_free(parent);

    if (result != GIT_OK) {
        const git_error *err = git_error_last();
        qWarning() << "commitCherryPick: git_commit_create failed:" << (err ? err->message : "unknown");
        return false;
    }

    return true;
}

void GitRebase::abortCherryPick()
{
    // Reset index and worktree to HEAD
    git_object* headObj = nullptr;
    if (git_revparse_single(&headObj, m_currentRepo->repo, "HEAD") != GIT_OK)
        return;

    git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
    opts.checkout_strategy = GIT_CHECKOUT_FORCE | GIT_CHECKOUT_RECREATE_MISSING;
    git_checkout_tree(m_currentRepo->repo, headObj, &opts);
    git_object_free(headObj);

    // Also reset the index
    git_index* index = nullptr;
    if (git_repository_index(&index, m_currentRepo->repo) == GIT_OK) {
        git_index_read(index, true); // force reload from disk
        git_index_free(index);
    }
}

bool GitRebase::resetToCommit(git_commit* target)
{
    git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
    opts.checkout_strategy = GIT_CHECKOUT_FORCE | GIT_CHECKOUT_RECREATE_MISSING;
    int result = git_checkout_tree(m_currentRepo->repo, reinterpret_cast<git_object*>(target), &opts);
    if (result != GIT_OK)
        return false;
    return git_repository_set_head_detached(m_currentRepo->repo, git_commit_id(target)) == GIT_OK;
}

void GitRebase::cleanupInteractiveState()
{
    if (m_newBaseCommit) {
        git_commit_free(m_newBaseCommit);
        m_newBaseCommit = nullptr;
    }
    if (m_originalHeadRef) {
        git_reference_free(m_originalHeadRef);
        m_originalHeadRef = nullptr;
    }
    m_interactiveInProgress = false;
    m_isCherryPickActive = false;
    m_interactivePlan.clear();
    m_currentPlanIndex = 0;
    m_currentOpHash.clear();

    if (m_defaultSignature) {
        git_signature_free(m_defaultSignature);
        m_defaultSignature = nullptr;
    }
}
