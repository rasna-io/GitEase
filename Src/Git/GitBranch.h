#pragma once

#include "GitResult.h"
#include "IGitController.h"
#include <QObject>

class GitBranch : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit GitBranch(QObject *parent = nullptr);

    /**
     * \brief Get list of branches
     * \return QVariantList of branch objects with name, isRemote, isCurrent properties
     */
    Q_INVOKABLE QVariantList getBranches();

    /**
    * \brief Creates a new branch pointing to the current HEAD.
    * \param branchName Name of the new branch.
    * \return True if creation was successful, false otherwise.
    */
    Q_INVOKABLE GitResult createBranch(const QString &branchName);

    /**
    * \brief Deletes an existing local branch from the repository.
    * \param branchName The name of the local branch to be removed.
    * \param repoPath Path to the repository. If empty, uses the current repository.
    * \return True if the branch was successfully deleted, false otherwise.
    */
    Q_INVOKABLE GitResult deleteBranch(const QString &branchName);

    /**
    * \brief Safely switches the current working directory to a target branch.
    * \param branchName The name of the local branch to checkout.
    * \param repoPath Path to the repository. If empty, uses the current repository.
    * \return True if the checkout was successful, false if there are conflicts or errors.
    */
    Q_INVOKABLE GitResult checkoutBranch(const QString &branchName);

    /**
    * \brief Renames an existing local branch.
    * \param oldName The current name of the branch.
    * \param newName The new desired name for the branch.
    * \return True if the rename was successful.
    */
    Q_INVOKABLE GitResult renameBranch(const QString &oldName, const QString &newName);

    /**
     * \brief Get current branch name
     * \param repo Git repository to check
     * \return Current branch name or empty string if detached HEAD
     */
    QString getCurrentBranchName();

};

