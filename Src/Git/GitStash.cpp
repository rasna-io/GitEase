#include "GitStash.h"
#include <git2/strarray.h>
#include <git2/blob.h>
#include <git2/index.h>
#include <git2/refs.h>
#include <git2/revparse.h>
#include <git2/checkout.h>
#include <git2/reset.h>
#include <git2/tree.h>
#include <git2/oid.h>

GitStash::GitStash(QObject *parent)
    : IGitController{parent}
{}

GitResult GitStash::save(const QString &message, bool keepIndex)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    git_signature *signature = nullptr;
    int result = git_signature_default(&signature, m_currentRepo->repo);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(), "Failed to create signature.");
    }

    git_stash_flags flags = keepIndex ? GIT_STASH_KEEP_INDEX : GIT_STASH_DEFAULT;

    QByteArray msgArray = message.toUtf8();
    const char* msg = msgArray.isEmpty() ? nullptr : msgArray.constData();

    git_oid stashOid;
    result = git_stash_save(
        &stashOid,
        m_currentRepo->repo,
        signature,
        msg,
        flags
        );

    git_signature_free(signature);

    if (result != GIT_OK)
        return GitResult(false, {}, git_error_last()->message);

    QString command = "git stash push";
    if (keepIndex) {
        command += " --keep-index";
    }
    if (!message.trimmed().isEmpty()) {
        command += " -m " + quoteCommandArg(message.trimmed());
    }
    emitGitCommand(command);

    return GitResult(true, {}, "Stash saved successfully.");
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

    if (git_signature_default(sig, repo) != GIT_OK) {
        git_commit_free(*headCommit);
        return GitResult(false, {}, "Failed to create signature.");
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

    // Update refs/stash
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
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, {}, "Repository not found.");

    git_repository *repo = m_currentRepo->repo;
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

    if (staged) {
        // Look up the blob OID for this path in the HEAD tree
        git_tree_entry *headEntry = nullptr;
        if (git_tree_entry_bypath(&headEntry, headTree, path) == GIT_OK) {
            hasDistinctStagedVersion =
                git_oid_cmp(&staged->id, git_tree_entry_id(headEntry)) != 0;
            git_tree_entry_free(headEntry);
        } else {
            // File didn't exist in HEAD, so staging it is definitely a change
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

    emitGitCommand(QString("git stash push -- %1").arg(filePath));
    return GitResult(true, {}, QString("File stashed: %1").arg(filePath));
}

GitResult GitStash::stashSelectedLines(const QString &filePath, const QString &message, const QString &blob)
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, {}, "Repository not found.");

    git_repository *repo = m_currentRepo->repo;
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
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, {}, "Repository not found.");
    }

    QVariantList resultList;

    ListPayload payload { m_currentRepo->repo, &resultList };

    int result = git_stash_foreach(
        m_currentRepo->repo,
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
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    git_stash_apply_options options = GIT_STASH_APPLY_OPTIONS_INIT;
    options.checkout_options.checkout_strategy = GIT_CHECKOUT_SAFE;

    if (reinstateIndex) {
        options.flags |= GIT_STASH_APPLY_REINSTATE_INDEX;
    }

    int result = git_stash_apply(m_currentRepo->repo, index, &options);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(), QString("Failed to apply stash: %1").arg(git_error_last()->message));
    }

    QString command = QString("git stash apply stash@{%1}").arg(index);
    if (reinstateIndex) {
        command += " --index";
    }
    emitGitCommand(command);

    return GitResult(true, QVariant(), "Stash applied successfully.");
}

GitResult GitStash::remove(int index)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    int result = git_stash_drop(m_currentRepo->repo, index);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(), QString("Failed to remove stash: %1").arg(git_error_last()->message));
    }

    emitGitCommand(QString("git stash drop stash@{%1}").arg(index));

    return GitResult(true, QVariant(), "Stash removed successfully.");
}

GitResult GitStash::pop(int index, bool reinstateIndex)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    git_stash_apply_options options = GIT_STASH_APPLY_OPTIONS_INIT;
    options.checkout_options.checkout_strategy = GIT_CHECKOUT_SAFE;

    if (reinstateIndex) {
        options.flags |= GIT_STASH_APPLY_REINSTATE_INDEX;
    }

    int result = git_stash_pop(m_currentRepo->repo, index, &options);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(), QString("Failed to pop stash: %1").arg(git_error_last()->message));
    }

    QString command = QString("git stash pop stash@{%1}").arg(index);
    if (reinstateIndex) {
        command += " --index";
    }
    emitGitCommand(command);

    return GitResult(true, QVariant(), "Stash popped successfully.");
}
