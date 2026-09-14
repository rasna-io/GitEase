#include "GitMerge.h"
#include <git2.h>
#include <QDebug>

#include "GitUtils.h"

GitMerge::GitMerge(QObject* parent)
    : IGitController(parent)
{
}

GitResult GitMerge::mergeBranchIntoCurrent(const QString& sourceBranch, bool noFF)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), "Repository is not open.");

    if (sourceBranch.trimmed().isEmpty())
        return GitResult(false, QVariant(), "Source branch name cannot be empty.");

    // 1. Look up source branch reference (local only, as in original)
    git_reference* sourceRef = nullptr;
    if (git_branch_lookup(&sourceRef,
                          activeRepo(),
                          sourceBranch.toUtf8().constData(),
                          GIT_BRANCH_LOCAL) != 0) {
        return GitResult(false, QVariant(), QString("Source branch '%1' not found.").arg(sourceBranch));
    }

    git_commit* sourceCommit = nullptr;
    if (git_reference_peel((git_object**)&sourceCommit, sourceRef, GIT_OBJECT_COMMIT) != GIT_OK) {
        git_reference_free(sourceRef);
        return GitResult(false, QVariant(), "Failed to resolve source branch to commit.");
    }

    git_reference* headRef = nullptr;
    if (git_repository_head(&headRef, activeRepo()) != GIT_OK) {
        git_commit_free(sourceCommit);
        git_reference_free(sourceRef);
        return GitResult(false, QVariant(), "Failed to get HEAD reference.");
    }

    git_commit* targetCommit = nullptr;
    if (git_reference_peel((git_object**)&targetCommit, headRef, GIT_OBJECT_COMMIT) != GIT_OK) {
        git_reference_free(headRef);
        git_commit_free(sourceCommit);
        git_reference_free(sourceRef);
        return GitResult(false, QVariant(), "Failed to resolve HEAD to commit.");
    }

    GitResult result = analyzeAndPerformMerge(targetCommit, sourceCommit, sourceRef, noFF);

    git_commit_free(targetCommit);
    git_commit_free(sourceCommit);
    git_reference_free(headRef);
    git_reference_free(sourceRef);

    if (result.success()) {
        QString cmd = noFF
            ? QString("git merge --no-ff %1").arg(quoteCommandArg(sourceBranch))
            : QString("git merge %1").arg(quoteCommandArg(sourceBranch));
        emitGitCommand(cmd);
    }

    return result;
}

GitResult GitMerge::analyzeAndPerformMerge(git_commit* targetCommit,
                                           git_commit* sourceCommit,
                                           git_reference* sourceRef,
                                           bool noFF)
{
    git_annotated_commit* annotated = nullptr;
    if (git_annotated_commit_from_ref(&annotated, activeRepo(), sourceRef) != GIT_OK)
        return GitResult(false, QVariant(), "Failed to create annotated commit for analysis.");

    const git_annotated_commit* heads[] = { annotated };

    git_merge_analysis_t analysis = GIT_MERGE_ANALYSIS_NONE;
    git_merge_preference_t preference = GIT_MERGE_PREFERENCE_NONE;
    int error = git_merge_analysis(&analysis, &preference, activeRepo(), heads, 1);

    if (error != GIT_OK) {
        git_annotated_commit_free(annotated);
        return GitResult(false, QVariant(), "Merge analysis failed.");
    }

    GitResult result;

    if (analysis & GIT_MERGE_ANALYSIS_UP_TO_DATE) {
        result = GitResult(true, QVariant(), "Branch is already up to date.");
    }
    else if ((analysis & GIT_MERGE_ANALYSIS_FASTFORWARD) && !noFF) {
        result = performFastForward(sourceCommit);
    }
    else if ((analysis & GIT_MERGE_ANALYSIS_FASTFORWARD) ||
             (analysis & GIT_MERGE_ANALYSIS_NORMAL)) {
        result = performNormalMerge(sourceRef);
    }
    else {
        result = GitResult(false, QVariant(), "Unsupported merge scenario.");
    }

    git_annotated_commit_free(annotated);
    return result;
}

GitResult GitMerge::performFastForward(git_commit* sourceCommit)
{
    git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
    opts.checkout_strategy = GIT_CHECKOUT_SAFE | GIT_CHECKOUT_RECREATE_MISSING;
    int error = git_checkout_tree(activeRepo(), (git_object*)sourceCommit, &opts);
    if (error != GIT_OK)
        return GitResult(false, QVariant(), "Checkout failed during fast-forward.");

    git_reference* headRef = nullptr;
    if (git_repository_head(&headRef, activeRepo()) != GIT_OK)
        return GitResult(false, QVariant(), "Failed to get HEAD.");

    git_reference* newRef = nullptr;
    error = git_reference_set_target(&newRef, headRef, git_commit_id(sourceCommit), "Fast-forward");
    git_reference_free(headRef);
    git_reference_free(newRef);

    if (error != GIT_OK)
        return GitResult(false, QVariant(), "Failed to update branch reference.");

    return GitResult(true, QVariant(), "Fast-forward merge completed.");
}

GitResult GitMerge::performNormalMerge(git_reference* sourceRef)
{
    git_annotated_commit* annotated = nullptr;
    if (git_annotated_commit_from_ref(&annotated, activeRepo(), sourceRef) != GIT_OK)
        return GitResult(false, QVariant(), "Failed to create annotated commit for merge.");

    const git_annotated_commit* heads[] = { annotated };

    git_merge_options mergeOpts = GIT_MERGE_OPTIONS_INIT;
    git_checkout_options checkoutOpts = GIT_CHECKOUT_OPTIONS_INIT;
    checkoutOpts.checkout_strategy = GIT_CHECKOUT_SAFE | GIT_CHECKOUT_ALLOW_CONFLICTS;

    int mergeResult = git_merge(activeRepo(), heads, 1, &mergeOpts, &checkoutOpts);

    // Check if merge started (even with conflicts)
    if (mergeResult != GIT_OK && mergeResult != GIT_ECONFLICT) {
        // Real failure - merge didn't start at all
        git_annotated_commit_free(annotated);
        return GitResult(false, QVariant(), "Merge operation failed.");
    }

    git_index* index = nullptr;
    if (git_repository_index(&index, activeRepo()) != GIT_OK) {
        git_annotated_commit_free(annotated);
        return GitResult(false, QVariant(), "Failed to read index after merge.");
    }

    GitResult result;

    // Check if there are conflicts (either from git_merge return or index)
    bool hasConflicts = (mergeResult == GIT_ECONFLICT) || (git_index_has_conflicts(index) == 1);

    if (hasConflicts) {
        // Store metadata BEFORE calling handleMergeConflicts
        storeMergeMetadata(sourceRef);

        // Set merge in progress flag
        m_mergeInProgress = true;
        emit mergeStateChanged();

        result = GitResult(false, QVariant(),
                           "Merge conflicts detected. Resolve them then continue.");
    } else {
        // No conflicts - automatically create merge commit
        result = finalizeAutomaticMerge(sourceRef, annotated, index);
    }

    git_index_free(index);
    git_annotated_commit_free(annotated);

    return result;
}

void GitMerge::storeMergeMetadata(git_reference* sourceRef)
{
    // Store source commit SHA
    const git_oid* sourceOid = git_reference_target(sourceRef);
    char sourceHash[GIT_OID_HEXSZ + 1] = {0};
    git_oid_tostr(sourceHash, sizeof(sourceHash), sourceOid);
    m_pendingSourceHash = QString::fromUtf8(sourceHash);

    // Store target commit SHA (current HEAD before merge)
    git_reference* headRef = nullptr;
    if (git_repository_head(&headRef, activeRepo()) == GIT_OK) {
        const git_oid* targetOid = git_reference_target(headRef);
        char targetHash[GIT_OID_HEXSZ + 1] = {0};
        git_oid_tostr(targetHash, sizeof(targetHash), targetOid);
        m_pendingTargetHash = QString::fromUtf8(targetHash);
        git_reference_free(headRef);
    }

    // Store branch names
    const char* sourceName = nullptr;
    git_branch_name(&sourceName, sourceRef);
    m_pendingSourceName = sourceName ? QString::fromUtf8(sourceName) : QString();
    m_pendingTargetName = currentBranchName();

    // Default message
    m_pendingMergeMessage = QString("Merge branch '%1' into '%2'")
                                .arg(m_pendingSourceName, m_pendingTargetName);
}

GitResult GitMerge::finalizeAutomaticMerge(git_reference* sourceRef,
                                           git_annotated_commit* annotated,
                                           git_index* index)
{
    git_commit* targetCommit = nullptr;
    git_commit* sourceCommit = nullptr;

    git_reference* headRef = nullptr;
    if (git_repository_head(&headRef, activeRepo()) != GIT_OK) {
        return GitResult(false, QVariant(), "Failed to get HEAD.");
    }
    if (git_reference_peel((git_object**)&targetCommit, headRef, GIT_OBJECT_COMMIT) != GIT_OK) {
        git_reference_free(headRef);
        return GitResult(false, QVariant(), "Failed to peel HEAD to commit.");
    }
    git_reference_free(headRef);

    // Get source commit from annotated commit
    if (git_commit_lookup(&sourceCommit, activeRepo(),
                          git_annotated_commit_id(annotated)) != GIT_OK) {
        git_commit_free(targetCommit);
        return GitResult(false, QVariant(), "Failed to lookup source commit.");
    }

    // Build merge message
    const char* sourceName = nullptr;
    git_branch_name(&sourceName, sourceRef);
    QString message = QString("Merge branch '%1' into '%2'")
                          .arg(QString::fromUtf8(sourceName),
                               currentBranchName());

    GitResult result = createMergeCommit(message, targetCommit, sourceCommit, index);

    git_commit_free(targetCommit);
    git_commit_free(sourceCommit);

    if (result.success()) {
        resetMergeState();
    }
    return result;
}

GitResult GitMerge::continueOp(const QString& commitMessage)
{
    if (!m_mergeInProgress)
        return GitResult(false, QVariant(), "No merge is currently in progress.");

    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), "Repository is not open.");

    if (hasMergeConflicts())
        return GitResult(false, QVariant(), "Resolve all merge conflicts before continuing.");

    if (m_pendingSourceHash.isEmpty() || m_pendingTargetHash.isEmpty())
        return GitResult(false, QVariant(), "Merge metadata is missing.");

    git_oid sourceOid, targetOid;
    if (git_oid_fromstr(&sourceOid, m_pendingSourceHash.toUtf8().constData()) != GIT_OK ||
        git_oid_fromstr(&targetOid, m_pendingTargetHash.toUtf8().constData()) != GIT_OK) {
        return GitResult(false, QVariant(), "Stored commit hashes are invalid.");
    }

    git_commit* sourceCommit = nullptr;
    git_commit* targetCommit = nullptr;
    if (git_commit_lookup(&sourceCommit, activeRepo(), &sourceOid) != GIT_OK ||
        git_commit_lookup(&targetCommit, activeRepo(), &targetOid) != GIT_OK) {
        git_commit_free(sourceCommit);
        git_commit_free(targetCommit);
        return GitResult(false, QVariant(), "Could not look up one of the parent commits.");
    }

    // Get the current index (which now contains the resolved merge)
    git_index* index = nullptr;
    if (git_repository_index(&index, activeRepo()) != GIT_OK) {
        git_commit_free(sourceCommit);
        git_commit_free(targetCommit);
        return GitResult(false, QVariant(), "Failed to open repository index.");
    }

    QString finalMessage = commitMessage.trimmed().isEmpty()
                               ? m_pendingMergeMessage
                               : commitMessage.trimmed();

    GitResult result = createMergeCommit(finalMessage, targetCommit, sourceCommit, index);

    git_index_free(index);
    git_commit_free(sourceCommit);
    git_commit_free(targetCommit);

    if (result.success()) {
        resetMergeState();
        emitGitCommand("git merge --continue");
    }

    return result;
}

GitResult GitMerge::createMergeCommit(const QString& message,
                                      git_commit* targetCommit,
                                      git_commit* sourceCommit,
                                      git_index* index)
{
    git_oid treeOid;
    if (git_index_write_tree(&treeOid, index) != GIT_OK) {
        return GitResult(false, QVariant(), "Failed to write merge tree.");
    }

    git_tree* tree = nullptr;
    if (git_tree_lookup(&tree, activeRepo(), &treeOid) != GIT_OK) {
        return GitResult(false, QVariant(), "Failed to lookup merge tree.");
    }

    git_signature* sig = createSignature();
    if (!sig) {
        git_tree_free(tree);
        return GitResult(false, QVariant(), "Failed to create commit signature.");
    }

    const git_commit* parents[] = { targetCommit, sourceCommit };

    git_oid commitOid;
    int error = git_commit_create(
        &commitOid,
        activeRepo(),
        "HEAD",
        sig,
        sig,
        nullptr,
        message.toUtf8().constData(),
        tree,
        2,          // number of parents
        parents);

    git_signature_free(sig);
    git_tree_free(tree);

    if (error != GIT_OK) {
        return GitResult(false, QVariant(), "Failed to create merge commit.");
    }

    git_repository_state_cleanup(activeRepo());

    return GitResult(true, QVariant(), "Merge commit created successfully.");
}

bool GitMerge::hasMergeConflicts() const
{
    if (!m_currentRepo || !activeRepo())
        return false;

    git_index* index = nullptr;
    if (git_repository_index(&index, activeRepo()) != GIT_OK)
        return false;

    bool conflicts = (git_index_has_conflicts(index) == 1);
    git_index_free(index);
    return conflicts;
}

bool GitMerge::isMergeInProgress() const
{
    // Check both our internal flag and Git's repository state
    if (m_mergeInProgress) {
        return true;
    }

    // Fallback: Check Git's repository state
    if (!m_currentRepo || !activeRepo()) {
        return false;
    }

    // Check if Git thinks we're in a merge
    int state = git_repository_state(activeRepo());
    return (state == GIT_REPOSITORY_STATE_MERGE);
}

git_signature* GitMerge::createSignature() const
{
    if (!m_currentRepo || !activeRepo())
        return nullptr;

    git_signature* sig = nullptr;

    if (git_signature_default(&sig, activeRepo()) != GIT_OK)
        git_signature_now(&sig, "Unknown", "unknown@example.com");
    return sig;
}

QString GitMerge::currentBranchName() const
{
    if (!m_currentRepo || !activeRepo())
        return QString();

    git_reference* head = nullptr;
    if (git_repository_head(&head, activeRepo()) != GIT_OK) {
        return QString();
    }

    const char* name = nullptr;
    QString branchName;
    if (git_branch_name(&name, head) == GIT_OK && name) {
        branchName = QString::fromUtf8(name);
    }
    git_reference_free(head);
    return branchName;
}

void GitMerge::resetMergeState()
{
    m_mergeInProgress = false;
    m_pendingSourceHash.clear();
    m_pendingTargetHash.clear();
    m_pendingSourceName.clear();
    m_pendingTargetName.clear();
    m_pendingMergeMessage.clear();
    emit mergeStateChanged();  // CRITICAL: Add this line
}

GitResult GitMerge::abortOp()
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), "Repository not found.");

    if (!isMergeInProgress())
        return GitResult(false, QVariant(), "No merge in progress.");

    int result = git_repository_state_cleanup(activeRepo());

    if (result != GIT_OK) {
        return GitResult(false, QVariant(),
                         QString("Failed to abort merge: %1").arg(GitUtils::getLastError()));
    }

    resetMergeState();
    emitGitCommand("git merge --abort");

    return GitResult(true, QVariant(), "Merge aborted.");
}
