#include "GitCherryPick.h"

GitCherryPick::GitCherryPick(QObject* parent)
    : IGitController(parent)
{
}

GitResult GitCherryPick::cherryPickCommit(const QString& commitHash)
{
    if (commitHash.trimmed().isEmpty())
        return GitResult(false, QVariant(), "Commit hash cannot be empty.");

    QStringList commits;
    commits << commitHash;
    return cherryPickCommits(commits);
}

GitResult GitCherryPick::cherryPickCommits(const QStringList& commitHashes)
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "Repository is not open.");

    if (commitHashes.isEmpty())
        return GitResult(false, QVariant(), "No commits selected for cherry-pick.");

    if (m_inProgress)
        return GitResult(false, QVariant(),
                         "A cherry-pick is already in progress. Continue or abort it first.");

    // Ensure the repository index is clean before starting a sequence
    if (repositoryHasConflicts()) {
        return GitResult(false, QVariant(), "You have existing conflicts in your repository. Resolve them first.");
    }

    int state = git_repository_state(m_currentRepo->repo);
    if (state != GIT_REPOSITORY_STATE_NONE) {
        return GitResult(false, QVariant(),
                         "Repository is busy (merge/rebase/cherry-pick in progress).");
    }

    m_startHeadHash = headHash();
    if (m_startHeadHash.isEmpty())
        return GitResult(false, QVariant(), "Failed to resolve HEAD.");

    m_pendingCommits = commitHashes;
    m_currentIndex = 0;
    m_inProgress = true;
    m_hasConflicts = false;
    emit cherryPickStateChanged();

    return processCommits();
}

GitResult GitCherryPick::continueCherryPick()
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "Repository is not open.");

    if (!m_inProgress)
        return GitResult(false, QVariant(), "No cherry-pick is in progress.");

    if (repositoryHasConflicts())
        return GitResult(false, QVariant(), "Resolve all cherry-pick conflicts before continuing.");

    if (m_currentIndex < 0 || m_currentIndex >= m_pendingCommits.size())
        return GitResult(false, QVariant(), "Cherry-pick state is invalid.");

    // Finalize the commit that previously conflicted
    QString currentHash = m_pendingCommits[m_currentIndex];
    QString error;
    git_commit* commit = lookupCommit(currentHash, &error);
    if (!commit)
        return GitResult(false, QVariant(), error.isEmpty() ? "Failed to locate commit." : error);

    GitResult commitRes = createCommitFromPick(commit);
    git_commit_free(commit);

    if (!commitRes.success())
        return commitRes;

    // Clean up sequencer state
    int cleanupError = git_repository_state_cleanup(m_currentRepo->repo);
    if (cleanupError != GIT_OK) {
        return GitResult(false, QVariant(), QString("Failed to cleanup repository state: %1")
                             .arg(git_error_last() ? git_error_last()->message : "Unknown error"));
    }

    // Hard reset HEAD to update index and working directory
    git_object* newHead = nullptr;
    int revparseError = git_revparse_single(&newHead, m_currentRepo->repo, "HEAD");
    if (revparseError != GIT_OK) {
        return GitResult(false, QVariant(), QString("Failed to get HEAD object: %1")
                             .arg(git_error_last() ? git_error_last()->message : "Unknown error"));
    }

    int resetError = git_reset(m_currentRepo->repo, newHead, GIT_RESET_HARD, nullptr);
    git_object_free(newHead);
    if (resetError != GIT_OK) {
        return GitResult(false, QVariant(), QString("Failed to reset repository to HEAD: %1")
                             .arg(git_error_last() ? git_error_last()->message : "Unknown error"));
    }

    m_hasConflicts = false;
    emit cherryPickStateChanged();

    m_currentIndex++;

    emitGitCommand("git cherry-pick --continue");

    return processCommits();
}


GitResult GitCherryPick::processCommits()
{
    while (m_currentIndex < m_pendingCommits.size()) {
        const QString commitHash = m_pendingCommits[m_currentIndex];

        GitResult res = applyCommit(commitHash);
        if (!res.success()) {
            if (res.data().toMap().value("status").toString() == "conflict")
                return res; // Stop processing, wait for user to resolve

            clearState();
            return res; // Hard error
        }

        // SUCCESS
        emitGitCommand("git cherry-pick " + quoteCommandArg(commitHash));

        m_currentIndex++;
    }

    // If we reach here, all commits are done
    QVariantMap data;
    data["status"] = "completed";
    data["appliedCount"] = m_currentIndex;
    data["totalCount"] = m_pendingCommits.size();

    clearState();
    return GitResult(true, data, "Cherry-pick completed.");
}

GitResult GitCherryPick::abortCherryPick()
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "Repository not found.");

    if (!m_inProgress)
        return GitResult(false, QVariant(), "No cherry-pick in progress.");

    GitResult resetResult = resetToOriginalHead();
    if (!resetResult.success())
        return resetResult;

    clearState();
    emitGitCommand("git cherry-pick --abort");

    return GitResult(true, QVariant(), "Cherry-pick aborted.");
}

GitResult GitCherryPick::cherryPickStatus()
{
    QVariantMap data;
    data["inProgress"] = m_inProgress;
    data["hasConflicts"] = m_hasConflicts || repositoryHasConflicts();
    data["currentIndex"] = m_currentIndex;
    data["totalCount"] = m_pendingCommits.size();

    if (!m_inProgress) {
        data["status"] = "idle";
        return GitResult(true, data);
    }

    data["status"] = data["hasConflicts"].toBool() ? "conflict" : "in_progress";
    if (m_currentIndex >= 0 && m_currentIndex < m_pendingCommits.size())
        data["currentCommit"] = m_pendingCommits[m_currentIndex];
    return GitResult(true, data);
}

bool GitCherryPick::hasCherryPickConflicts() const
{
    return m_hasConflicts || repositoryHasConflicts();
}

bool GitCherryPick::isCherryPickInProgress() const
{
    return m_inProgress;
}

GitResult GitCherryPick::applyCommit(const QString& commitHash)
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "Repository is not open.");

    QString error;
    git_commit* commit = lookupCommit(commitHash, &error);
    if (!commit)
        return GitResult(false, QVariant(), error.isEmpty() ? "Failed to locate commit." : error);

    if (git_commit_parentcount(commit) > 1) {
        git_commit_free(commit);
        return GitResult(false, QVariant(),
                         "Cherry-picking merge commits is not supported yet.");
    }

    git_cherrypick_options opts = GIT_CHERRYPICK_OPTIONS_INIT;
    opts.checkout_opts.checkout_strategy =
        GIT_CHECKOUT_SAFE |
        GIT_CHECKOUT_ALLOW_CONFLICTS |
        GIT_CHECKOUT_RECREATE_MISSING;

    int result = git_cherrypick(m_currentRepo->repo, commit, &opts);
    if (result != GIT_OK && result != GIT_ECONFLICT) {
        git_commit_free(commit);
        return GitResult(false, QVariant(),
                         QString("Cherry-pick failed: %1").arg(GitUtils::getLastError()));
    }

    if (repositoryHasConflicts()) {
        m_hasConflicts = true;
        emit cherryPickStateChanged();
        GitResult conflict = conflictResult(commitHash,
                                            "Cherry-pick stopped due to conflicts. Resolve conflicts and continue.");
        git_commit_free(commit);
        return conflict;
    }

    GitResult commitResult = createCommitFromPick(commit);
    git_commit_free(commit);

    return commitResult;
}

GitResult GitCherryPick::createCommitFromPick(git_commit* pickedCommit)
{
    if (!pickedCommit)
        return GitResult(false, QVariant(), "Invalid commit.");

    git_index* index = nullptr;
    if (git_repository_index(&index, m_currentRepo->repo) != GIT_OK || !index) {
        return GitResult(false, QVariant(), "Failed to open repository index.");
    }

    if (git_index_has_conflicts(index)) {
        git_index_free(index);
        return GitResult(false, QVariant(), "Resolve conflicts before continuing.");
    }

    git_oid treeOid;
    if (git_index_write_tree(&treeOid, index) != GIT_OK) {
        git_index_free(index);
        return GitResult(false, QVariant(), "Failed to write cherry-pick tree.");
    }

    git_tree* tree = nullptr;
    if (git_tree_lookup(&tree, m_currentRepo->repo, &treeOid) != GIT_OK) {
        git_index_free(index);
        return GitResult(false, QVariant(), "Failed to lookup cherry-pick tree.");
    }

    git_object* headObj = nullptr;
    if (git_revparse_single(&headObj, m_currentRepo->repo, "HEAD") != GIT_OK) {
        git_tree_free(tree);
        git_index_free(index);
        return GitResult(false, QVariant(), "Failed to resolve HEAD.");
    }

    git_commit* headCommit = (git_commit*)headObj;

    const git_signature* author = git_commit_author(pickedCommit);
    git_signature* authorCopy = nullptr;
    if (author && git_signature_dup(&authorCopy, author) != GIT_OK) {
        authorCopy = nullptr;
    }

    git_signature* committer = nullptr;
    if (git_signature_default(&committer, m_currentRepo->repo) != GIT_OK) {
        git_signature_now(&committer, "CherryPick", "CherryPick@example.com");
    }

    const char* message = git_commit_message(pickedCommit);
    QByteArray messageUtf8 = message ? QByteArray(message) : QByteArray("Cherry-pick");

    const git_commit* parents[] = { headCommit };

    git_oid commitOid;
    int error = git_commit_create(
        &commitOid,
        m_currentRepo->repo,
        "HEAD",
        authorCopy ? authorCopy : committer,
        committer,
        nullptr,
        messageUtf8.constData(),
        tree,
        1,
        parents);

    git_signature_free(authorCopy);
    git_signature_free(committer);
    git_tree_free(tree);
    git_index_free(index);
    git_commit_free(headCommit);

    if (error != GIT_OK) {
        return GitResult(false, QVariant(), "Failed to create cherry-pick commit.");
    }

    git_repository_state_cleanup(m_currentRepo->repo);

    return GitResult(true, QVariant(), "Cherry-pick commit created.");
}

GitResult GitCherryPick::conflictResult(const QString& commitHash, const QString& message)
{
    QVariantMap data;
    data["status"] = "conflict";
    data["inProgress"] = true;
    data["hasConflicts"] = true;
    data["currentCommit"] = commitHash;
    data["currentIndex"] = m_currentIndex;
    data["totalCount"] = m_pendingCommits.size();
    return GitResult(false, data, message);
}

GitResult GitCherryPick::resetToOriginalHead()
{
    if (m_startHeadHash.isEmpty())
        return GitResult(false, QVariant(), "Original HEAD not recorded.");

    git_object* target = nullptr;
    if (git_revparse_single(&target, m_currentRepo->repo, m_startHeadHash.toUtf8().constData()) != GIT_OK) {
        return GitResult(false, QVariant(), "Failed to resolve original HEAD.");
    }

    int result = git_reset(m_currentRepo->repo, target, GIT_RESET_HARD, nullptr);
    git_object_free(target);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(),
                         QString("Failed to reset branch: %1").arg(GitUtils::getLastError()));
    }

    git_index* index = nullptr;
    if (git_repository_index(&index, m_currentRepo->repo) == GIT_OK && index) {
        git_index_conflict_cleanup(index);
        git_index_write(index);
        git_index_free(index);
    }

    git_repository_state_cleanup(m_currentRepo->repo);

    return GitResult(true);
}

void GitCherryPick::clearState()
{
    m_pendingCommits.clear();
    m_currentIndex = -1;
    m_startHeadHash.clear();
    m_inProgress = false;
    m_hasConflicts = false;
    emit cherryPickStateChanged();
}

git_commit* GitCherryPick::lookupCommit(const QString& commitHash, QString* errorMessage) const
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return nullptr;

    git_oid oid;
    int result = git_oid_fromstr(&oid, commitHash.toUtf8().constData());
    if (result != GIT_OK) {
        git_object* obj = nullptr;
        result = git_revparse_single(&obj, m_currentRepo->repo, commitHash.toUtf8().constData());
        if (result == GIT_OK && obj) {
            git_oid_cpy(&oid, git_object_id(obj));
            git_object_free(obj);
        } else {
            if (errorMessage)
                *errorMessage = QString("Invalid commit hash: %1").arg(commitHash);
            return nullptr;
        }
    }

    git_commit* commit = nullptr;
    if (git_commit_lookup(&commit, m_currentRepo->repo, &oid) != GIT_OK) {
        if (errorMessage)
            *errorMessage = QString("Commit not found: %1").arg(commitHash);
        return nullptr;
    }

    return commit;
}

bool GitCherryPick::repositoryHasConflicts() const
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return false;

    git_index* index = nullptr;
    if (git_repository_index(&index, m_currentRepo->repo) != GIT_OK || !index)
        return false;

    const bool hasConflicts = git_index_has_conflicts(index) != 0;
    git_index_free(index);
    return hasConflicts;
}

QString GitCherryPick::headHash() const
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return QString();

    git_reference* headRef = nullptr;
    if (git_repository_head(&headRef, m_currentRepo->repo) != GIT_OK)
        return QString();

    const git_oid* oid = git_reference_target(headRef);
    if (!oid) {
        git_reference_free(headRef);
        return QString();
    }

    char hash[GIT_OID_HEXSZ + 1] = {0};
    git_oid_tostr(hash, sizeof(hash), oid);
    git_reference_free(headRef);
    return QString::fromUtf8(hash);
}

GitResult GitCherryPick::skipCherryPick()
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "Repository is not open.");

    if (!m_inProgress)
        return GitResult(false, QVariant(), "No cherry-pick is in progress.");

    if (m_currentIndex < 0 || m_currentIndex >= m_pendingCommits.size())
        return GitResult(false, QVariant(), "Cherry-pick state is invalid.");

    git_object* headObj = nullptr;
    if (git_revparse_single(&headObj, m_currentRepo->repo, "HEAD") == GIT_OK) {
        git_reset(m_currentRepo->repo, headObj, GIT_RESET_HARD, nullptr);
        git_object_free(headObj);
    } else {
        return GitResult(false, QVariant(), "Failed to resolve HEAD during skip.");
    }

    git_index* index = nullptr;
    if (git_repository_index(&index, m_currentRepo->repo) == GIT_OK && index) {
        git_index_conflict_cleanup(index);
        git_index_write(index);
        git_index_free(index);
    }

    git_repository_state_cleanup(m_currentRepo->repo);

    m_hasConflicts = false;
    emit cherryPickStateChanged();

    emitGitCommand("git cherry-pick --skip");

    m_currentIndex++;

    return processCommits();
}
