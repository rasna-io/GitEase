#include "GitRebase.h"

#include "GitUtils.h"

#include <git2/annotated_commit.h>
#include <git2/checkout.h>
#include <git2/index.h>
#include <git2/rebase.h>
#include <git2/repository.h>
#include <git2/signature.h>

#include <QVariantList>
#include <git2/branch.h>

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

    QString originalBranch = branch;
    bool hasBranch = !branch.trimmed().isEmpty();

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

    git_rebase* rebase = nullptr;
    git_annotated_commit* branchCommit = nullptr;
    git_annotated_commit* ontoCommit = nullptr;
    git_annotated_commit* upstreamCommit = nullptr;

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

    GitResult rebaseResult = runRebase(rebase, false);
    git_rebase_free(rebase);

    if (rebaseResult.success()) {
        QString command = "git rebase";
        if (!onto.trimmed().isEmpty()) {
            command += " --onto " + quoteCommandArg(onto);
        }
        command += " " + quoteCommandArg(upstream);
        if (hasBranch) {
            command += " " + quoteCommandArg(originalBranch);
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

GitResult GitRebase::runRebase(git_rebase* rebase, bool continueCurrentOperation)
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
                git_signature_free(signature);
                return conflictResult(rebase,
                                      "Rebase stopped due to conflicts. Resolve conflicts and continue.");
            }

            git_signature_free(signature);
            return GitResult(false, QVariant(),
                             QString("Failed to apply rebase operation: %1").arg(GitUtils::getLastError()));
        }

        Q_UNUSED(operation)

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

    rebaseData["rebasedCommits"] = rebasedCommits;
    rebaseData["appliedCount"] = rebasedCommits.count();
    rebaseData["status"] = "completed";

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
