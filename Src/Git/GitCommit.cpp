#include "GitCommit.h"

#include <git2/branch.h>
#include <git2/commit.h>
#include <git2/errors.h>
#include <git2/object.h>
#include <git2/refs.h>
#include <git2/revwalk.h>
#include <git2/types.h>
#include <git2/signature.h>
#include <git2/index.h>
#include <git2.h>

#include <Models/Commit.h>

#include <QRegularExpression>

GitCommit::GitCommit(QObject *parent)
    : IGitController{parent}
{}


GitResult GitCommit::getCommits(int limit, int offset)
{
    QList<Commit> commits;

    // Check if the repository is open
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    git_revwalk *walker = nullptr;
    int result = git_revwalk_new(&walker, m_currentRepo->repo);

    // Check if the walker was successfully created
    if (result != GIT_OK) {
        git_revwalk_free(walker); // Cleanup in case of failure
        return GitResult(false, QVariant(), "Failed to create revwalk.");
    }

    // Sort by time (newest first)
    git_revwalk_sorting(walker, GIT_SORT_TOPOLOGICAL | GIT_SORT_TIME);

    // Push all branch tips to include commits reachable from any branch
    {
        git_branch_iterator* iter = nullptr;
        if (git_branch_iterator_new(&iter, m_currentRepo->repo, GIT_BRANCH_ALL) == 0) {
            git_reference* ref = nullptr;
            git_branch_t type;

            while (git_branch_next(&ref, &type, iter) == 0) {
                const git_oid* oid = git_reference_target(ref);
                if (oid) {
                    git_revwalk_push(walker, oid);
                } else {
                    // If symbolic ref, peel to commit
                    git_object* target = nullptr;
                    if (git_reference_peel(&target, ref, GIT_OBJECT_COMMIT) == 0 && target) {
                        const git_oid* peeledOid = git_object_id(target);
                        if (peeledOid)
                            git_revwalk_push(walker, peeledOid);
                        git_object_free(target);
                    }
                }

                git_reference_free(ref);
            }

            git_branch_iterator_free(iter);
        }
    }

    // Push HEAD as fallback (detached HEAD or repos without branches)
    git_revwalk_push_head(walker);

    git_oid oid;
    int count = 0;

    // Skip `offset` commits (paging)
    int skipped = 0;
    while (skipped < offset && git_revwalk_next(&oid, walker) == 0) {
        skipped++;
    }

    // Walk through commits up to limit
    while (count < limit && git_revwalk_next(&oid, walker) == 0) {
        git_commit *gitCommit = nullptr;
        result = git_commit_lookup(&gitCommit, m_currentRepo->repo, &oid);

        if (result == 0 && gitCommit) {
            // Wrap the git_commit into a Commit object and append to the list
            Commit commit = Commit(gitCommit);
            QStringList parentHashes = getAllParents(gitCommit);

            commit.setparentHashes(parentHashes);

            commits.append(commit); // Assuming Commit class wraps git_commit
            git_commit_free(gitCommit);  // Clean up the git_commit object
            count++;
        }
    }

    // Clean up the walker
    git_revwalk_free(walker);

    // If no commits are found, return a failure result
    if (commits.isEmpty()) {
        return GitResult(false, QVariant(), "No commits found.");
    }

    return GitResult(true, QVariant::fromValue(commits), QString("Retrieved %1 commits").arg(commits.size()));
}

GitResult GitCommit::getCommit(const QString &commitHash)
{
    if (commitHash.isEmpty()) {
        return GitResult(false, QVariant(), "Commit hash cannot be empty");
    }

    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    git_oid oid;
    int result = git_oid_fromstr(&oid, commitHash.toUtf8().constData());

    if (result != GIT_OK) {
        // Try with short hash
        git_object *obj = nullptr;
        result = git_revparse_single(&obj, m_currentRepo->repo, commitHash.toUtf8().constData());

        if (result == GIT_OK) {
            git_oid_cpy(&oid, git_object_id(obj));
            git_object_free(obj);
        } else {
            return GitResult(false, QVariant(),
                             QString("Invalid commit hash: %1").arg(commitHash));
        }
    }

    git_commit *gitCommit = nullptr;
    result = git_commit_lookup(&gitCommit, m_currentRepo->repo, &oid);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(),
                         QString("Commit not found: %1").arg(commitHash));
    }

    Commit commit = Commit(gitCommit);



    // Get parent hashes
    QStringList parentHashes = getAllParents(gitCommit);

    commit.setparentHashes(parentHashes);


    // Get tree hash
    const git_oid *tree_oid = git_commit_tree_id(gitCommit);
    if (tree_oid) {
        char tree_hash[GIT_OID_HEXSZ + 1];
        git_oid_tostr(tree_hash, sizeof(tree_hash), tree_oid);
        commit.setTreeHash(QString::fromUtf8(tree_hash));
    }

    git_commit_free(gitCommit);

    return GitResult(true, QVariant::fromValue(commit));
}

QString GitCommit::getParentHash(const QString &commitHash, int index)
{
    if (!m_currentRepo || !m_currentRepo->repo || commitHash.isEmpty() || index < 0)
        return "";

    git_oid oid;
    if (git_oid_fromstr(&oid, commitHash.toUtf8().constData()) != 0)
        return "";

    git_commit* commit = nullptr;
    if (git_commit_lookup(&commit, m_currentRepo->repo, &oid) != 0)
        return "";

    QString parentHash;

    unsigned int parentCount = git_commit_parentcount(commit);

    if (index < static_cast<int>(parentCount)) {
        const git_oid* parentOid = git_commit_parent_id(commit, index);
        if (parentOid) {
            char hash[GIT_OID_HEXSZ + 1];
            git_oid_tostr(hash, sizeof(hash), parentOid);
            parentHash = QString::fromUtf8(hash);
        }
    }

    git_commit_free(commit);
    return parentHash;
}

GitResult GitCommit::commit(const QString& message,
                                bool amend,
                                bool allowEmpty)
{
    if (!validateCommitMessage(message))
        return GitResult(false, QVariant(),
                         "Commit failed: The commit message is invalid. Ensure it is properly formatted.");


    git_signature* author = getAuthorSignature(m_currentRepo->repo);
    if (!author) {
        return GitResult(false, QVariant(),
                         "Failed to create author signature. Check Git config.");
    }

    git_tree* tree = createTreeFromStagedChanges();

    if (!tree) {
        return GitResult(false, QVariant(),
                         "Failed to create tree from staged changes.");
    }

    ParentCommits parents = resolveParentCommits(amend);

    git_oid newCommitOid;

    QByteArray messageUtf8 = message.trimmed().toUtf8();

    int result = git_commit_create(
        &newCommitOid,                      // Output: new commit's SHA-1
        m_currentRepo->repo,                // Repository to create in
        "HEAD",                             // Update HEAD reference
        author,                             // Who wrote the changes
        author,                             // Who committed them
        nullptr,                            // Default encoding (UTF-8)
        messageUtf8.constData(),            // Commit message
        tree,                               // Tree snapshot
        parents.count,                      // Number of parents
        (const git_commit**)parents.commits // Parent commits
        );

    if (result != GIT_OK) {
        // Cleanup on failure
        cleanupCommitResources(author, tree, parents);

        // Provide helpful error messages
        if (result == GIT_EAMBIGUOUS)
            return GitResult(false, QVariant(),
                             "Ambiguous commit state. Repository may be mid-merge/rebase.");
        else if (result == GIT_EUNBORNBRANCH)
            return GitResult(false, QVariant(),
                             "Cannot amend: no commits yet (unborn branch).");


        return GitResult(false, QVariant(), "Failed to create commit object.");
    }

    git_commit* newCommit = nullptr;
    result = git_commit_lookup(&newCommit, m_currentRepo->repo, &newCommitOid);

    if (result != GIT_OK)
        return GitResult(false, QVariant(), "Failed to lookup new Commit.");

    Commit data = Commit(newCommit);

    git_commit_free(newCommit);

    cleanupCommitResources(author, tree, parents);


    return GitResult(true, QVariant::fromValue(data));
}

bool GitCommit::validateCommitMessage(const QString &message)
{
    if (message.trimmed().isEmpty())
        return false;

    // Check for common commit message issues
    QRegularExpression trailingWhitespace("\\s+$");
    if (trailingWhitespace.match(message).hasMatch())
        return false;

    return true;
}

git_signature* GitCommit::getAuthorSignature(git_repository* repo)
{
    git_signature* signature = nullptr;

    // Try to get default signature from Git config
    int result = git_signature_default(&signature, repo);

    if (result != GIT_OK) {
        return nullptr;
    }

    return signature;
}

git_tree* GitCommit::createTreeFromStagedChanges()
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return nullptr;
    }

    git_index* index = nullptr;

    // Get the index for the repository
    int result = git_repository_index(&index, m_currentRepo->repo);
    if (result != GIT_OK) {
        return nullptr;
    }

    // Create a tree object from the staged changes in the index
    git_oid treeOid;
    result = git_index_write_tree(&treeOid, index);
    git_index_free(index);  // Free the index after writing the tree

    if (result != GIT_OK) {
        return nullptr;
    }

    // Lookup the tree object in the repository
    git_tree* tree = nullptr;
    result = git_tree_lookup(&tree, m_currentRepo->repo, &treeOid);
    if (result != GIT_OK) {
        return nullptr;
    }

    return tree;
}

ParentCommits GitCommit::resolveParentCommits(bool amend)
{
    ParentCommits parents {};

    if (amend) {
        // Get current HEAD reference
        git_reference* headRef = nullptr;
        int result = git_repository_head(&headRef, m_currentRepo->repo);

        if (result == 0 && headRef) {
            // Get the commit being amended
            result = git_reference_peel((git_object**)&parents.amendedCommit,
                                        headRef, GIT_OBJECT_COMMIT);
            git_reference_free(headRef);

            if (result == 0 && parents.amendedCommit) {
                // Copy parent commits from the commit being amended
                parents.count = git_commit_parentcount(parents.amendedCommit);

                if (parents.count > 0) {
                    parents.commits = new git_commit*[parents.count];

                    for (size_t i = 0; i < parents.count; ++i) {
                        // Note: git_commit_parent INCREMENTS refcount
                        if (git_commit_parent(&parents.commits[i],
                                              parents.amendedCommit, i) != 0) {
                            // Error handling: free what we got so far
                            for (size_t j = 0; j < i; ++j) {
                                git_commit_free(parents.commits[j]);
                            }
                            delete[] parents.commits;
                            parents.commits = nullptr;
                            parents.count = 0;
                            break;
                        }
                    }
                }
            }
        }
    } else {
        // REGULAR COMMIT CASE: Use HEAD as parent

        git_commit* headCommit = nullptr;
        int result = git_revparse_single((git_object**)&headCommit, m_currentRepo->repo, "HEAD");

        if (result == 0 && headCommit) {
            // Normal commit: HEAD is the parent
            parents.count = 1;
            parents.commits = new git_commit*[1];
            parents.commits[0] = headCommit;
        } else {
            // No HEAD = initial commit (0 parents)
            parents.count = 0;
        }
    }

    return parents;
}

void GitCommit::cleanupCommitResources(git_signature* signature, git_tree* tree,
                                           ParentCommits& parents)
{
    if (signature)
        git_signature_free(signature);

    if (tree)
        git_tree_free(tree);

    freeParentCommits(parents);
}

GitResult GitCommit::amendLastCommit(const QString &newMessage)
{
    if (newMessage.isEmpty()) {
        return GitResult(false, QVariant(),
                         "Cannot amend commit with empty message.\n\n"
                         "Tip: Use commit() with amend flag to keep the same message.");
    }

    return commit(newMessage, true);
}

GitResult GitCommit::revertCommit(const QString &commitHash)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    if (commitHash.isEmpty()) {
        return GitResult(false, QVariant(), "Commit hash cannot be empty");
    }

    // Convert commit hash to OID
    git_oid oid;
    int result = git_oid_fromstr(&oid, commitHash.toUtf8().constData());
    if (result != 0) {
        return GitResult(false, QVariant(),
                         QString("Invalid commit hash: %1").arg(commitHash));
    }

    // Look up the commit to revert
    git_commit *commit_to_revert = nullptr;  // DECLARED HERE - FIXED!
    result = git_commit_lookup(&commit_to_revert, m_currentRepo->repo, &oid);
    if (result != 0) {
        return GitResult(false, QVariant(),
                         QString("Commit not found: %1").arg(commitHash));
    }


    // Get HEAD commit (the "our_commit" parameter)
    git_commit* head_commit = nullptr;
    git_object* head_obj = nullptr;
    result = git_revparse_single(&head_obj, m_currentRepo->repo, "HEAD");
    if (result != 0 || !head_obj) {
        git_commit_free(commit_to_revert);
        return GitResult(false, QVariant(), "Cannot find HEAD commit");
    }
    head_commit = (git_commit*)head_obj;

    // Create revert index (does NOT commit yet)
    git_index* revert_index = nullptr;
    git_merge_options merge_opts = GIT_MERGE_OPTIONS_INIT;
    // For normal commits, mainline is 0. For merge commits, specify which parent.
    unsigned int mainline = 0;

    result = git_revert_commit(
        &revert_index,        // out: index with revert changes
        m_currentRepo->repo,  // repo
        commit_to_revert,     // commit to revert
        head_commit,          // our commit (HEAD)
        mainline,             // parent number for merge commits
        &merge_opts           // merge options
        );

    if (result != 0) {
        git_object_free(head_obj);
        git_commit_free(commit_to_revert);

        if (result == GIT_ECONFLICT) {
            return GitResult(false, QVariant(),
                             "Revert caused conflicts.\n\n"
                             "Please resolve conflicts manually and commit the result.");
        }
        return GitResult(false, QVariant(), "Failed to create revert index");
    }

    // 6. Apply the revert index to working directory
    git_checkout_options checkout_opts = GIT_CHECKOUT_OPTIONS_INIT;
    checkout_opts.checkout_strategy = GIT_CHECKOUT_SAFE;
    result = git_checkout_index(m_currentRepo->repo, revert_index, &checkout_opts);

    // 7. Clean up intermediate objects
    git_index_free(revert_index);
    git_object_free(head_obj);
    git_commit_free(commit_to_revert);

    if (result != 0) {
        return GitResult(false, QVariant(), "Failed to apply revert to working tree");
    }

    // Create the revert commit (using your existing commit() function)
    QString message = QString("Revert \"%1\"\n\nThis reverts commit %2.")
                          .arg(commitHash.left(7))
                          .arg(commitHash);

    return commit(message, false, false); // Don't amend, don't allow empty
}

void GitCommit::freeParentCommits(ParentCommits& parents)
{
    if (parents.commits) {
        for (size_t i = 0; i < parents.count; i++) {
            git_commit_free(parents.commits[i]);
        }
        delete[] parents.commits;
        parents.commits = nullptr;
    }
    parents.count = 0;

    // Free amended commit (if we were amending)
    if (parents.amendedCommit) {
        git_commit_free(parents.amendedCommit);
        parents.amendedCommit = nullptr;
    }
}

QStringList GitCommit::getAllParents(git_commit *gitCommit)
{
    QStringList parentHashes;
    unsigned int parentCount = git_commit_parentcount(gitCommit);
    for (unsigned int i = 0; i < parentCount; ++i) {
        const git_oid* parentOid = git_commit_parent_id(gitCommit, i);
        if (parentOid) {
            char hash[GIT_OID_HEXSZ + 1];
            git_oid_tostr(hash, sizeof(hash), parentOid);
            parentHashes.append(QString::fromUtf8(hash));
        }
    }

    return parentHashes;
}
