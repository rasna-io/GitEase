#include "GitBranch.h"
#include "GitResult.h"

#include <QDebug>
#include <git2/branch.h>
#include <git2/deprecated.h>
#include <git2/object.h>
#include <git2/refs.h>
#include <git2/revparse.h>
#include <git2/types.h>

GitBranch::GitBranch(QObject *parent)
    : IGitController{parent}
{}

QVariantList GitBranch::getBranches()
{
    QVariantList branches;

    if (!m_currentRepo || m_currentRepo->repo)
        return branches;

    git_reference *head = nullptr;
    git_repository_head(&head, m_currentRepo->repo);

    git_branch_iterator *iter = nullptr;

    if (git_branch_iterator_new(&iter, m_currentRepo->repo, GIT_BRANCH_ALL) == 0) {
        git_reference *ref = nullptr;
        git_branch_t type;

        // Iterate through all branches
        while (git_branch_next(&ref, &type, iter) == 0) {
            const char *name = nullptr;

            if (git_branch_name(&name, ref) == GIT_OK && name) {

                //TODO we need Branch object class here
                QVariantMap branch;
                branch["name"] = QString::fromUtf8(name);
                branch["isRemote"] = (type == GIT_BRANCH_REMOTE);
                branch["isLocal"] = (type == GIT_BRANCH_LOCAL);

                // Branch tip commit hash (needed to map branches to commits in QML)
                QString targetHash;
                const git_oid* oid = git_reference_target(ref);
                if (!oid) {
                    git_object* target = nullptr;
                    if (git_reference_peel(&target, ref, GIT_OBJECT_COMMIT) == 0 && target) {
                        oid = git_object_id(target);
                        git_object_free(target);
                    }
                }
                if (oid) {
                    char hash[GIT_OID_HEXSZ + 1];
                    git_oid_tostr(hash, sizeof(hash), oid);
                    targetHash = QString::fromUtf8(hash);
                }
                branch["targetHash"] = targetHash;

                // Check if this is the current branch
                int isHead = git_branch_is_head(ref);
                bool isCurrent = (isHead == 1);
                branch["isCurrent"] = isCurrent;

                branches.append(branch);
            }

            git_reference_free(ref);
        }

        // Clean up iterator
        git_branch_iterator_free(iter);
    }

    if (head)
    {
        git_reference_free(head);
    }


    qDebug() << "GitWrapperCPP: Retrieved" << branches.size() << "branches";
    return branches;
}

GitResult GitBranch::createBranch(const QString &branchName)
{
    if (!m_currentRepo || m_currentRepo->repo)
        return GitResult(false, QVariant(), "Repository not found");

    git_reference* new_branch_ref = nullptr;
    git_object* target_object = nullptr;

    if (git_revparse_single(&target_object, m_currentRepo->repo, "HEAD") == 0)
    {
        int error = git_branch_create(&new_branch_ref, m_currentRepo->repo,
            branchName.toUtf8(), (const git_commit*)target_object, 0 );

        if (error != GIT_OK)
            return GitResult(false, QVariant(), "Failed to create branch");
    }

    if (target_object) {
        git_object_free(target_object);
    }
    if (new_branch_ref) {
        git_reference_free(new_branch_ref);
    }

    return GitResult(true, QVariant(), QString("Branch created successfully: %1").arg(branchName));
}

GitResult GitBranch::deleteBranch(const QString &branchName)
{
    if (!m_currentRepo || m_currentRepo->repo)
        return GitResult(false, QVariant(), "Repository not found for creating branch");

    git_reference* branchRef = nullptr;

    int error = git_branch_lookup(&branchRef, m_currentRepo->repo, branchName.toUtf8().constData(), GIT_BRANCH_LOCAL);

    if (error == GIT_OK) {
        error = git_branch_delete(branchRef);
        if (error != GIT_OK)
            return GitResult(false, QVariant(), "Failed to delete branch");

    } else {
        return GitResult(false, QVariant(), "Branch not found");
    }

    if (branchRef) {
        git_reference_free(branchRef);
    }

    return GitResult(true, QVariant(), QString("Successfully deleted branch: %1").arg(branchName));
}

GitResult GitBranch::checkoutBranch(const QString &branchName)
{
    if (!m_currentRepo || m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository is not open.");
    }

    git_reference* targetRef = nullptr;
    git_object* targetCommit = nullptr;

    // Attempt to find the branch reference
    int error = git_branch_lookup(&targetRef, m_currentRepo->repo, branchName.toUtf8().constData(), GIT_BRANCH_LOCAL);
    if (error != 0) {
        return GitResult(false, QVariant(), QString("Branch '%1' not found.").arg(branchName));
    }

    // Peel the reference to get the commit object
    error = git_reference_peel(&targetCommit, targetRef, GIT_OBJ_COMMIT);
    if (error != GIT_OK) {
        git_reference_free(targetRef);
        return GitResult(false, QVariant(), QString("Failed to peel the reference for branch '%1'.").arg(branchName));
    }

    // Checkout the tree of the commit
    git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
    opts.checkout_strategy = GIT_CHECKOUT_SAFE | GIT_CHECKOUT_RECREATE_MISSING;

    error = git_checkout_tree(m_currentRepo->repo, targetCommit, &opts);
    if (error != GIT_OK) {
        git_object_free(targetCommit);
        git_reference_free(targetRef);
        return GitResult(false, QVariant(), QString("Failed to checkout branch '%1' due to tree checkout error.").arg(branchName));
    }

    // Set HEAD to the target branch
    error = git_repository_set_head(m_currentRepo->repo, git_reference_name(targetRef));
    if (error != GIT_OK) {
        git_object_free(targetCommit);
        git_reference_free(targetRef);
        return GitResult(false, QVariant(), QString("Failed to set HEAD to '%1'.").arg(branchName));
    }

    // Cleanup resources
    git_object_free(targetCommit);
    git_reference_free(targetRef);

    return GitResult(true, QVariant(), QString("Successfully checked out branch '%1'.").arg(branchName));
}

GitResult GitBranch::renameBranch(const QString &oldName, const QString &newName)
{
    if (!m_currentRepo || m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository is not open.");
    }

    git_reference* branchRef = nullptr;
    git_reference* newRef = nullptr;

    // Attempt to find the old branch reference
    int error = git_branch_lookup(&branchRef, m_currentRepo->repo, oldName.toUtf8().constData(), GIT_BRANCH_LOCAL);
    if (error != GIT_OK) {
        return GitResult(false, QVariant(), QString("Branch '%1' not found.").arg(oldName));
    }

    // Attempt to rename the branch
    error = git_branch_move(&newRef, branchRef, newName.toUtf8().constData(), 0);
    if (error != GIT_OK) {
        git_reference_free(branchRef); // Clean up
        return GitResult(false, QVariant(), QString("Rename failed"));
    }


    // Clean up references
    git_reference_free(newRef);
    git_reference_free(branchRef);

    return GitResult(true, QVariant(), QString("Successfully renamed branch '%1' to '%2'.").arg(oldName).arg(newName));
}

QString GitBranch::getCurrentBranchName()
{
    if (!m_currentRepo || m_currentRepo->repo)
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
    } else if (error == GIT_ENOTFOUND)
    {
        branchName = "initial/no-commits";
    } else
    {
        branchName = "Detached HEAD";
    }

    return branchName;  // "main", "master", or Detached HEAD if detached
}
