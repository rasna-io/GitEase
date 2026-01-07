#pragma once

#include "IGitController.h"
#include "Repository.h"
#include <QObject>

class GitResult;
class GitRemote : public IGitController
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit GitRemote(QObject *parent = nullptr);

    /**
     * \brief Push commits to a remote repository
     * \param remoteName Name of the remote (default: "origin")
     * \param branchName Branch to push (default: current branch)
     * \param username GitHub username (required for HTTPS)
     * \param password GitHub Personal Access Token (required for HTTPS)
     * \param force Whether to force push (default: false)
     * \return GitResult with operation result
     */
    Q_INVOKABLE GitResult push(const QString &remoteName = "origin",
                                 const QString &branchName = "",
                                 const QString &username = "",
                                 const QString &password = "",
                                 bool force = false);

    /**
     * \brief Get list of remotes for the repository
     * \return QVariantList with remote information
     */
    Q_INVOKABLE GitResult getRemotes();

    /**
     * \brief Add a new remote
     * \param name Remote name
     * \param url Remote URL
     * \return QVariantMap with operation result
     */
    Q_INVOKABLE GitResult addRemote(const QString &name,
                                      const QString &url);

    /**
     * \brief Remove a remote
     * \param name Remote name
     * \return QVariantMap with operation result
     */
    Q_INVOKABLE GitResult removeRemote(const QString &name);

    /**
    * \brief Retrieves the name of the tracked upstream branch.
    * \param localBranchName The name of the local branch to check.
    * \return The upstream branch name (e.g., "origin/main") or an empty QString if no upstream is set.
    */
    Q_INVOKABLE GitResult getUpstreamName(const QString &localBranchName);
};

