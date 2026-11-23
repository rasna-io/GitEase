#include "GitStash.h"
#include "GitCommandText.h"
#include <git2/strarray.h>
#include <git2/blob.h>
#include <git2/index.h>
#include <git2/refs.h>
#include <git2/revparse.h>
#include <git2/checkout.h>
#include <git2/reset.h>
#include <git2/tree.h>
#include <git2/oid.h>
#include <git2/diff.h>
#include <git2/apply.h>
#include <git2/status.h>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSet>

GitStash::GitStash(QObject *parent)
    : IGitController{parent}
{}

GitResult GitStash::save(const QString &message, bool keepIndex, bool includeUntracked)
{
    if (!m_currentRepo || !activeRepo()) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    QString identityReason;
    git_signature *signature = defaultSignature(activeRepo(), &identityReason);
    if (!signature)
        return identityMissingResult(identityReason);

    int result = GIT_OK;
    unsigned int flags = GIT_STASH_DEFAULT;
    if (keepIndex)
        flags |= GIT_STASH_KEEP_INDEX;
    if (includeUntracked)
        flags |= GIT_STASH_INCLUDE_UNTRACKED;

    QByteArray msgArray = message.toUtf8();
    const char* msg = msgArray.isEmpty() ? nullptr : msgArray.constData();

    git_oid stashOid;
    result = git_stash_save(
        &stashOid,
        activeRepo(),
        signature,
        msg,
        flags
        );

    git_signature_free(signature);

    if (result != GIT_OK)
        return GitResult(false, {}, git_error_last()->message);

    emitGitCommand(GitCommandText::stashPush(message, keepIndex, includeUntracked));

    return GitResult(true, {}, "Stash saved successfully.");
}

//! Declared here, defined further down next to the other stash-commit helpers.
static GitResult getHeadContext(git_repository *repo, git_commit **headCommit,
                                git_signature **sig, git_tree **headTree);
static GitResult createStashCommits(git_repository *repo, git_commit *headCommit, git_signature *sig,
                                    const git_oid *wipTreeOid, const git_oid *indexTreeOid,
                                    const QString &message);

GitResult GitStash::saveStaged(const QString &message)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, {}, "Repository not found.");

    git_repository *repo = activeRepo();

    git_commit    *headCommit = nullptr;
    git_signature *sig        = nullptr;
    git_tree      *headTree   = nullptr;
    GitResult ctx = getHeadContext(repo, &headCommit, &sig, &headTree);
    if (!ctx.success())
        return ctx;

    git_index *index   = nullptr;
    git_diff  *reverse = nullptr;

    auto cleanup = [&]() {
        git_diff_free(reverse);
        git_index_free(index);
        git_tree_free(headTree);
        git_signature_free(sig);
        git_commit_free(headCommit);
    };

    auto fail = [&](const QString &fallback) {
        const git_error *error = git_error_last();
        QString text = (error && error->message) ? QString::fromUtf8(error->message) : fallback;
        cleanup();
        return GitResult(false, {}, text);
    };

    if (git_repository_index(&index, repo) != GIT_OK || git_index_read(index, 1) != GIT_OK)
        return fail("Failed to read the index.");

    if (git_index_has_conflicts(index)) {
        cleanup();
        return GitResult(false, {}, "Resolve the merge conflicts before stashing.");
    }

    git_oid indexTreeOid;
    if (git_index_write_tree(&indexTreeOid, index) != GIT_OK)
        return fail("Failed to write the index tree.");

    if (git_oid_equal(&indexTreeOid, git_tree_id(headTree))) {
        cleanup();
        return GitResult(false, {}, "There are no staged changes to stash.");
    }

    // The staged changes turned around (index -> HEAD). Applied to the working tree it takes the
    // staged edits out and leaves any unstaged edits made on top of them, like git does.
    git_diff_options diffOpts = GIT_DIFF_OPTIONS_INIT;
    diffOpts.flags = GIT_DIFF_REVERSE | GIT_DIFF_SHOW_BINARY;
    if (git_diff_tree_to_index(&reverse, repo, headTree, index, &diffOpts) != GIT_OK)
        return fail("Failed to diff the staged changes.");

    // Dry run first, so a stash is only created when the working tree can be cleaned up afterwards.
    git_apply_options applyOpts = GIT_APPLY_OPTIONS_INIT;
    applyOpts.flags = GIT_APPLY_CHECK;
    if (git_apply(repo, reverse, GIT_APPLY_LOCATION_WORKDIR, &applyOpts) != GIT_OK) {
        cleanup();
        return GitResult(false, {}, "Some staged files have unstaged edits in the same lines, so the staged "
                                    "changes cannot be taken out on their own. Stash all changes instead.");
    }

    // A --staged stash records the index as both its index and its working tree.
    GitResult created = createStashCommits(repo, headCommit, sig, &indexTreeOid, &indexTreeOid, message);
    if (!created.success()) {
        cleanup();
        return created;
    }

    applyOpts.flags = 0;
    if (git_apply(repo, reverse, GIT_APPLY_LOCATION_WORKDIR, &applyOpts) != GIT_OK)
        return fail("The stash was created, but the staged changes could not be removed from the working tree.");

    // Put the staged paths in the index back to HEAD.
    QList<QByteArray> pathBytes;
    const size_t deltaCount = git_diff_num_deltas(reverse);
    for (size_t i = 0; i < deltaCount; ++i) {
        const git_diff_delta *delta = git_diff_get_delta(reverse, i);
        pathBytes.append(QByteArray(delta->old_file.path));
        if (qstrcmp(delta->old_file.path, delta->new_file.path) != 0)
            pathBytes.append(QByteArray(delta->new_file.path));
    }

    QVector<char *> pathPointers;
    for (QByteArray &bytes : pathBytes)
        pathPointers.append(bytes.data());

    git_strarray paths = { pathPointers.data(), static_cast<size_t>(pathPointers.size()) };
    if (git_reset_default(repo, reinterpret_cast<git_object *>(headCommit), &paths) != GIT_OK)
        return fail("The stash was created, but the staged changes could not be unstaged.");

    cleanup();

    emitGitCommand(GitCommandText::stashPushStaged(message));
    return GitResult(true, {}, "Staged changes stashed successfully.");
}

GitResult GitStash::saveUnstaged(const QString &message)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, {}, "Repository not found.");

    git_repository *repo = activeRepo();

    git_commit    *headCommit = nullptr;
    git_signature *sig        = nullptr;
    git_tree      *headTree   = nullptr;
    GitResult ctx = getHeadContext(repo, &headCommit, &sig, &headTree);
    if (!ctx.success())
        return ctx;

    git_status_list *statuses = nullptr;
    git_index       *wipIndex = nullptr;
    git_diff        *recorded = nullptr;
    git_tree        *wipTree  = nullptr;

    auto cleanup = [&]() {
        git_tree_free(wipTree);
        git_diff_free(recorded);
        git_index_free(wipIndex);
        git_status_list_free(statuses);
        git_tree_free(headTree);
        git_signature_free(sig);
        git_commit_free(headCommit);
    };

    auto fail = [&](const QString &fallback) {
        const git_error *error = git_error_last();
        QString text = (error && error->message) ? QString::fromUtf8(error->message) : fallback;
        cleanup();
        return GitResult(false, {}, text);
    };

    // The files of the Unstaged section: working tree changes against the index, plus untracked files.
    git_status_options statusOpts = GIT_STATUS_OPTIONS_INIT;
    statusOpts.show  = GIT_STATUS_SHOW_INDEX_AND_WORKDIR;
    statusOpts.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED | GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS;
    if (git_status_list_new(&statuses, repo, &statusOpts) != GIT_OK)
        return fail("Failed to read the repository status.");

    // The stash's working tree: HEAD with only the unstaged and untracked files laid over it.
    // Staged-only files are left out, so they are neither recorded nor touched.
    if (git_index_new(&wipIndex) != GIT_OK || git_index_read_tree(wipIndex, headTree) != GIT_OK)
        return fail("Failed to prepare the stash tree.");

    const unsigned int unstagedFlags = GIT_STATUS_WT_NEW | GIT_STATUS_WT_MODIFIED
                                       | GIT_STATUS_WT_DELETED | GIT_STATUS_WT_TYPECHANGE;

    QSet<QString> untracked;
    const size_t count = git_status_list_entrycount(statuses);
    for (size_t i = 0; i < count; ++i) {
        const git_status_entry *entry = git_status_byindex(statuses, i);

        if (entry->status & GIT_STATUS_CONFLICTED) {
            cleanup();
            return GitResult(false, {}, "Resolve the merge conflicts before stashing.");
        }

        if (!(entry->status & unstagedFlags) || !entry->index_to_workdir)
            continue;

        const git_diff_file &file = entry->index_to_workdir->new_file;
        const char *path = file.path;

        if (entry->status & GIT_STATUS_WT_NEW)
            untracked.insert(QString::fromUtf8(path));

        if (entry->status & GIT_STATUS_WT_DELETED) {
            git_index_remove_bypath(wipIndex, path);
            continue;
        }

        git_oid blobOid;
        if (git_blob_create_from_workdir(&blobOid, repo, path) != GIT_OK)
            return fail(QString("Failed to read %1.").arg(QString::fromUtf8(path)));

        git_index_entry indexEntry = {};
        indexEntry.mode = file.mode ? file.mode : GIT_FILEMODE_BLOB;
        indexEntry.path = path;
        git_oid_cpy(&indexEntry.id, &blobOid);
        if (git_index_add(wipIndex, &indexEntry) != GIT_OK)
            return fail(QString("Failed to add %1 to the stash.").arg(QString::fromUtf8(path)));
    }

    git_oid wipTreeOid;
    if (git_index_write_tree_to(&wipTreeOid, wipIndex, repo) != GIT_OK
        || git_tree_lookup(&wipTree, repo, &wipTreeOid) != GIT_OK)
        return fail("Failed to write the stash tree.");

    // What the stash ends up holding; only these paths are cleaned out of the working tree, so
    // nothing is removed that the stash couldn't give back.
    if (git_diff_tree_to_tree(&recorded, repo, headTree, wipTree, nullptr) != GIT_OK)
        return fail("Failed to diff the stash tree.");

    const size_t recordedCount = git_diff_num_deltas(recorded);
    if (recordedCount == 0) {
        cleanup();
        return GitResult(false, {}, "There are no unstaged changes to stash.");
    }

    // No staged changes are recorded: the index commit is HEAD's tree.
    GitResult created = createStashCommits(repo, headCommit, sig, &wipTreeOid, git_tree_id(headTree), message);
    if (!created.success()) {
        cleanup();
        return created;
    }

    // Put the tracked files back to their index version and delete the untracked ones.
    QStringList paths;
    QList<QByteArray> trackedBytes;
    for (size_t i = 0; i < recordedCount; ++i) {
        const git_diff_delta *delta = git_diff_get_delta(recorded, i);
        const QString path = QString::fromUtf8(delta->new_file.path ? delta->new_file.path
                                                                    : delta->old_file.path);
        paths.append(path);

        if (untracked.contains(path)) {
            const QString workdir = workdirOf(repo);
            if (!workdir.isEmpty()) {
                QFile::remove(QDir(workdir).filePath(path));

                // Untracked folders left empty go too, as with git; rmpath stops at the first
                // folder that still holds something.
                const QString folder = QFileInfo(path).path();
                if (folder != ".")
                    QDir(workdir).rmpath(folder);
            }
        } else {
            trackedBytes.append(path.toUtf8());
        }
    }

    if (!trackedBytes.isEmpty()) {
        QVector<char *> pointers;
        for (QByteArray &bytes : trackedBytes)
            pointers.append(bytes.data());

        git_checkout_options checkoutOpts = GIT_CHECKOUT_OPTIONS_INIT;
        checkoutOpts.checkout_strategy = GIT_CHECKOUT_FORCE | GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH;
        checkoutOpts.paths = { pointers.data(), static_cast<size_t>(pointers.size()) };
        if (git_checkout_index(repo, nullptr, &checkoutOpts) != GIT_OK)
            return fail("The stash was created, but the unstaged changes could not be removed from the working tree.");
    }

    cleanup();

    emitGitCommand(GitCommandText::stashPushUnstaged(message, paths, !untracked.isEmpty()));
    return GitResult(true, {}, "Unstaged changes stashed successfully.");
}


// Build a tree that is identical to baseTree except for one file replaced by fileOid.
// Handles nested paths by using an in-memory index.
static bool buildModifiedTree(git_oid *out, git_repository *repo,
                              git_tree *baseTree, const char *path,
                              const git_oid *fileOid)
{
    git_index *idx = nullptr;
    if (git_index_new(&idx) != GIT_OK) return false;

    if (git_index_read_tree(idx, baseTree) != GIT_OK) {
        git_index_free(idx);
        return false;
    }

    git_blob *blob = nullptr;
    if (git_blob_lookup(&blob, repo, fileOid) != GIT_OK) {
        git_index_free(idx);
        return false;
    }
    git_off_t blobSize = git_blob_rawsize(blob);
    git_blob_free(blob);

    git_index_entry entry = {};
    entry.path      = path;
    entry.mode      = GIT_FILEMODE_BLOB;
    entry.file_size = (uint32_t)blobSize;
    git_oid_cpy(&entry.id, fileOid);

    if (git_index_add(idx, &entry) != GIT_OK) {
        git_index_free(idx);
        return false;
    }

    int rc = git_index_write_tree_to(out, idx, repo);
    git_index_free(idx);
    return rc == GIT_OK;
}

// Resolves HEAD to a commit and retrieves the three resources needed by stash
static GitResult getHeadContext(git_repository *repo, git_commit **headCommit,
                                git_signature **sig, git_tree **headTree)
{
    git_object *headObj = nullptr;
    if (git_revparse_single(&headObj, repo, "HEAD") != GIT_OK)
        return GitResult(false, {}, "No HEAD commit found.");

    git_object *peeled = nullptr;
    if (git_object_peel(&peeled, headObj, GIT_OBJECT_COMMIT) != GIT_OK) {
        git_object_free(headObj);
        return GitResult(false, {}, "HEAD does not resolve to a commit.");
    }
    git_object_free(headObj);
    *headCommit = (git_commit *)peeled;

    QString identityReason;
    *sig = IGitController::defaultSignature(repo, &identityReason);
    if (!*sig) {
        git_commit_free(*headCommit);
        return IGitController::identityMissingResult(identityReason);
    }

    if (git_commit_tree(headTree, *headCommit) != GIT_OK) {
        git_signature_free(*sig);
        git_commit_free(*headCommit);
        return GitResult(false, {}, "Failed to get HEAD tree.");
    }

    return GitResult(true, {}, "");
}

// Builds the two commits that make up a git stash entry and points refs/stash at the result.
static GitResult createStashCommits(
    git_repository *repo,
    git_commit *headCommit,
    git_signature *sig,
    const git_oid *wipTreeOid,
    const git_oid *indexTreeOid,
    const QString &message)
{
    git_reference *headRef = nullptr;
    QString branch = "HEAD";
    if (git_repository_head(&headRef, repo) == GIT_OK) {
        if (git_reference_is_branch(headRef))
            branch = QString::fromUtf8(git_reference_shorthand(headRef));
        git_reference_free(headRef);
    }

    char shortHash[9] = {};
    git_oid_tostr(shortHash, 8, git_commit_id(headCommit));
    QString summary  = QString::fromUtf8(git_commit_summary(headCommit));
    QString stashMsg = message.isEmpty()
                           ? QString("WIP on %1: %2 %3").arg(branch, shortHash, summary)
                           : message;
    QString indexMsg = QString("index on %1: %2 %3").arg(branch, shortHash, summary);

    // Index commit
    git_tree *indexTree = nullptr;
    if (git_tree_lookup(&indexTree, repo, indexTreeOid) != GIT_OK)
        return GitResult(false, {}, "Failed to lookup index tree.");

    git_oid indexCommitOid;
    const git_commit *indexParents[] = { headCommit };
    int rc = git_commit_create(&indexCommitOid, repo, nullptr, sig, sig,
                               "UTF-8", indexMsg.toUtf8().constData(),
                               indexTree, 1, indexParents);
    git_tree_free(indexTree);
    if (rc != GIT_OK)
        return GitResult(false, {}, "Failed to create index commit.");

    // WIP commit
    git_commit *indexCommit = nullptr;
    if (git_commit_lookup(&indexCommit, repo, &indexCommitOid) != GIT_OK)
        return GitResult(false, {}, "Failed to lookup index commit.");

    git_tree *wipTree = nullptr;
    if (git_tree_lookup(&wipTree, repo, wipTreeOid) != GIT_OK) {
        git_commit_free(indexCommit);
        return GitResult(false, {}, "Failed to lookup WIP tree.");
    }

    git_oid wipOid;
    const git_commit *wipParents[] = { headCommit, indexCommit };
    rc = git_commit_create(&wipOid, repo, nullptr, sig, sig,
                           "UTF-8", stashMsg.toUtf8().constData(),
                           wipTree, 2, wipParents);
    git_tree_free(wipTree);
    git_commit_free(indexCommit);
    if (rc != GIT_OK)
        return GitResult(false, {}, "Failed to create stash commit.");

    // Update refs/stash. The stash list is read from its reflog, which libgit2 only writes for
    // refs/stash when one already exists - so make sure it does, or the first stash is invisible.
    if (git_reference_ensure_log(repo, "refs/stash") != GIT_OK)
        return GitResult(false, {}, "Failed to create the stash reflog.");

    git_reference *stashRef = nullptr;
    int refRc = git_reference_create(&stashRef, repo, "refs/stash", &wipOid, 1,
                                     stashMsg.toUtf8().constData());
    if (stashRef) git_reference_free(stashRef);
    if (refRc != GIT_OK)
        return GitResult(false, {}, "Failed to update refs/stash.");

    return GitResult(true, {}, "");
}

GitResult GitStash::stashFile(const QString &filePath, const QString &message)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, {}, "Repository not found.");

    git_repository *repo = activeRepo();
    QByteArray pathBytes = filePath.toUtf8();
    const char *path = pathBytes.constData();

    git_commit *headCommit = nullptr;
    git_signature *sig = nullptr;
    git_tree *headTree = nullptr;
    GitResult ctx = getHeadContext(repo, &headCommit, &sig, &headTree);
    if (!ctx.success())
        return ctx;

    auto cleanup = [&]() {
        git_tree_free(headTree);
        git_signature_free(sig);
        git_commit_free(headCommit);
    };

    // Blob from workdir
    git_oid blobOid;
    if (git_blob_create_from_workdir(&blobOid, repo, path) != GIT_OK) {
        cleanup();
        return GitResult(false, {}, git_error_last() ? git_error_last()->message : "Failed to read file.");
    }

    // WIP tree
    git_oid wipTreeOid;
    if (!buildModifiedTree(&wipTreeOid, repo, headTree, path, &blobOid)) {
        cleanup();
        return GitResult(false, {}, "Failed to build WIP tree.");
    }

    // Index tree: compare staged blob against HEAD blob for this path
    git_index *repoIdx = nullptr;
    git_repository_index(&repoIdx, repo);
    git_index_read(repoIdx, 1);
    const git_index_entry *staged = git_index_get_bypath(repoIdx, path, 0);

    git_oid indexTreeOid;
    bool hasDistinctStagedVersion = false;

    git_tree_entry *headFileEntry = nullptr;
    const bool fileInHead = git_tree_entry_bypath(&headFileEntry, headTree, path) == GIT_OK;

    if (staged) {
        // Compare against the blob OID for this path in the HEAD tree
        if (fileInHead) {
            hasDistinctStagedVersion =
                git_oid_cmp(&staged->id, git_tree_entry_id(headFileEntry)) != 0;
        } else {
            // File didn't exist in HEAD, so staging it is definitely a change
            hasDistinctStagedVersion = true;
        }
    }
    git_tree_entry_free(headFileEntry);

    if (hasDistinctStagedVersion) {
        if (!buildModifiedTree(&indexTreeOid, repo, headTree, path, &staged->id)) {
            git_index_free(repoIdx);
            cleanup();
            return GitResult(false, {}, "Failed to build index tree.");
        }
    } else {
        git_oid_cpy(&indexTreeOid, git_tree_id(headTree));
    }
    git_index_free(repoIdx);

    GitResult result = createStashCommits(repo, headCommit, sig, &wipTreeOid, &indexTreeOid, message);
    cleanup();

    if (!result.success())
        return result;

    // Reset index entry to HEAD
    const char *pathspecs[] = { path };
    git_strarray pathArr = { const_cast<char **>(pathspecs), 1 };
    git_object *headForReset = nullptr;
    if (git_revparse_single(&headForReset, repo, "HEAD") == GIT_OK) {
        git_reset_default(repo, headForReset, &pathArr);
        git_object_free(headForReset);
    }

    // Checkout workdir from index
    git_checkout_options coOpts = GIT_CHECKOUT_OPTIONS_INIT;
    coOpts.checkout_strategy = GIT_CHECKOUT_FORCE | GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH;
    coOpts.paths = pathArr;
    git_checkout_index(repo, nullptr, &coOpts);

    // A file HEAD doesn't have (untracked, or newly added) is not in the index any more, so the
    // checkout above leaves it alone - remove it, the stash now holds its content.
    if (!fileInHead) {
        const QString workdir = workdirOf(repo);
        if (!workdir.isEmpty())
            QFile::remove(QDir(workdir).filePath(filePath));
    }

    emitGitCommand(QString("git stash push -- %1").arg(filePath));
    return GitResult(true, {}, QString("File stashed: %1").arg(filePath));
}

GitResult GitStash::stashSelectedLines(const QString &filePath, const QString &message, const QString &blob)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, {}, "Repository not found.");

    git_repository *repo = activeRepo();
    QByteArray pathBytes = filePath.toUtf8();
    const char *path = pathBytes.constData();

    git_commit *headCommit = nullptr;
    git_signature *sig = nullptr;
    git_tree *headTree = nullptr;
    GitResult ctx = getHeadContext(repo, &headCommit, &sig, &headTree);
    if (!ctx.success())
        return ctx;

    auto cleanup = [&]() {
        git_tree_free(headTree);
        git_signature_free(sig);
        git_commit_free(headCommit);
    };

    QByteArray blobBytes = blob.toUtf8();
    git_oid blobOid;
    if (git_blob_create_frombuffer(&blobOid, repo,
                                   blobBytes.constData(), blobBytes.size()) != GIT_OK) {
        cleanup();
        return GitResult(false, {}, "Failed to create blob from selected lines.");
    }

    // Build WIP tree
    git_oid wipTreeOid;
    if (!buildModifiedTree(&wipTreeOid, repo, headTree, path, &blobOid)) {
        cleanup();
        return GitResult(false, {}, "Failed to build WIP tree.");
    }

    // Build index tree — compare staged blob against HEAD blob for this path
    git_index *repoIdx = nullptr;
    git_repository_index(&repoIdx, repo);
    git_index_read(repoIdx, 1);
    const git_index_entry *staged = git_index_get_bypath(repoIdx, path, 0);

    git_oid indexTreeOid;
    bool hasDistinctStagedVersion = false;

    if (staged) {
        git_tree_entry *headEntry = nullptr;
        if (git_tree_entry_bypath(&headEntry, headTree, path) == GIT_OK) {
            hasDistinctStagedVersion =
                git_oid_cmp(&staged->id, git_tree_entry_id(headEntry)) != 0;
            git_tree_entry_free(headEntry);
        } else {
            hasDistinctStagedVersion = true;
        }
    }

    if (hasDistinctStagedVersion) {
        if (!buildModifiedTree(&indexTreeOid, repo, headTree, path, &staged->id)) {
            git_index_free(repoIdx);
            cleanup();
            return GitResult(false, {}, "Failed to build index tree.");
        }
    } else {
        git_oid_cpy(&indexTreeOid, git_tree_id(headTree));
    }
    git_index_free(repoIdx);

    GitResult result = createStashCommits(repo, headCommit, sig, &wipTreeOid, &indexTreeOid, message);
    cleanup();
    if (!result.success())
        return result;

    emitGitCommand(QString("git stash push -- %1").arg(filePath));
    return GitResult(true, {}, "Selected lines stashed successfully.");
}

GitResult GitStash::list()
{
    if (!m_currentRepo || !activeRepo()) {
        return GitResult(false, {}, "Repository not found.");
    }

    QVariantList resultList;

    ListPayload payload { activeRepo(), &resultList };

    int result = git_stash_foreach(
        activeRepo(),
        [](size_t index,
           const char* message,
           const git_oid* stash_id,
           void* data) -> int
        {
            auto* payload = static_cast<ListPayload*>(data);

            QVariantMap stash;

            stash["index"] = static_cast<int>(index);
            stash["id"] = QString::fromLatin1(git_oid_tostr_s(stash_id));

            stash["message"] = message
                                   ? QString::fromUtf8(message).trimmed()
                                   : QStringLiteral("WIP");


            git_commit* commit = nullptr;
            if (git_commit_lookup(&commit, payload->repo, stash_id) == GIT_OK) {
                const git_signature* author = git_commit_author(commit);
                if (author) {
                    stash["author"] = QString::fromUtf8(author->name ? author->name : "");
                    stash["dateTime"] = QDateTime::fromSecsSinceEpoch(author->when.time);
                }

                const git_oid* parentOid = git_commit_parent_id(commit, 0);
                if (parentOid) {
                    stash["parentId"] = QString::fromLatin1(git_oid_tostr_s(parentOid));
                }

                // Number of files the stash carries, i.e. the diff against the commit it was
                // taken on top of (same view as "git stash show --name-only").
                git_tree* stashTree = nullptr;
                if (git_commit_tree(&stashTree, commit) == GIT_OK) {
                    git_tree* parentTree = nullptr;
                    git_commit* parent = nullptr;
                    if (git_commit_parent(&parent, commit, 0) == GIT_OK) {
                        git_commit_tree(&parentTree, parent);
                        git_commit_free(parent);
                    }

                    git_diff* diff = nullptr;
                    if (git_diff_tree_to_tree(&diff, payload->repo, parentTree, stashTree, nullptr) == GIT_OK) {
                        stash["fileCount"] = static_cast<int>(git_diff_num_deltas(diff));
                        git_diff_free(diff);
                    }

                    git_tree_free(parentTree);
                    git_tree_free(stashTree);
                }

                git_commit_free(commit);
            }

            payload->list->append(stash);
            return 0;
        },
        &payload
        );

    if (result != GIT_OK) {
        return GitResult(false, {}, git_error_last()->message);
    }

    emitGitCommand("git stash list");

    return GitResult(
        true,
        resultList,
        QString("Found %1 stashes.").arg(resultList.size())
        );
}

GitResult GitStash::apply(int index, bool reinstateIndex)
{
    if (!m_currentRepo || !activeRepo()) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    git_stash_apply_options options = GIT_STASH_APPLY_OPTIONS_INIT;
    options.checkout_options.checkout_strategy = GIT_CHECKOUT_SAFE;

    if (reinstateIndex) {
        options.flags |= GIT_STASH_APPLY_REINSTATE_INDEX;
    }

    int result = git_stash_apply(activeRepo(), index, &options);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(), QString("Failed to apply stash: %1").arg(git_error_last()->message));
    }

    emitGitCommand(GitCommandText::stashApply(index, reinstateIndex));

    return GitResult(true, QVariant(), "Stash applied successfully.");
}

GitResult GitStash::remove(int index)
{
    if (!m_currentRepo || !activeRepo()) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    int result = git_stash_drop(activeRepo(), index);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(), QString("Failed to remove stash: %1").arg(git_error_last()->message));
    }

    emitGitCommand(GitCommandText::stashDrop(index));

    return GitResult(true, QVariant(), "Stash removed successfully.");
}

GitResult GitStash::pop(int index, bool reinstateIndex)
{
    if (!m_currentRepo || !activeRepo()) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    git_stash_apply_options options = GIT_STASH_APPLY_OPTIONS_INIT;
    options.checkout_options.checkout_strategy = GIT_CHECKOUT_SAFE;

    if (reinstateIndex) {
        options.flags |= GIT_STASH_APPLY_REINSTATE_INDEX;
    }

    int result = git_stash_pop(activeRepo(), index, &options);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(), QString("Failed to pop stash: %1").arg(git_error_last()->message));
    }

    emitGitCommand(GitCommandText::stashPop(index, reinstateIndex));

    return GitResult(true, QVariant(), "Stash popped successfully.");
}
