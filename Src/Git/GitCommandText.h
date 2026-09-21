#pragma once

#include <QObject>
#include <QQmlEngine>

/*!
 * @brief Builds the git command strings shown to the user.
 *
 * Both sides of the app go through here: the controllers pass the result to emitGitCommand()
 * after an operation succeeds, and the forms call the same function to preview the command
 * before the user commits to it. Keeping one implementation is what stops a preview from
 * promising something other than what the controller runs.
 */
class GitCommandText : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit GitCommandText(QObject *parent = nullptr);

    //! Quotes an argument the way the command strings expect. Empty arguments stay empty.
    Q_INVOKABLE static QString quote(const QString &argument);

    /* Branch
     * ****************************************************************************************/
    Q_INVOKABLE static QString createBranch(const QString &branchName, const QString &startPoint = QString());
    Q_INVOKABLE static QString createBranchAndCheckout(const QString &branchName, const QString &startPoint = QString());
    Q_INVOKABLE static QString deleteBranch(const QString &branchName);
    Q_INVOKABLE static QString renameBranch(const QString &oldName, const QString &newName);
    Q_INVOKABLE static QString checkoutBranch(const QString &branchName);
    Q_INVOKABLE static QString checkoutCommit(const QString &commitHash);

    /* Tag
     * ****************************************************************************************/
    Q_INVOKABLE static QString createTag(const QString &name, const QString &message, bool force = false);
    Q_INVOKABLE static QString deleteTag(const QString &name);
    Q_INVOKABLE static QString pushTag(const QString &name);
    Q_INVOKABLE static QString pushDeleteTag(const QString &name);

    /* Remote
     * ****************************************************************************************/
    Q_INVOKABLE static QString addRemote(const QString &name, const QString &url);
    Q_INVOKABLE static QString removeRemote(const QString &name);
    Q_INVOKABLE static QString renameRemote(const QString &oldName, const QString &newName);
    Q_INVOKABLE static QString setRemoteUrl(const QString &name, const QString &url);
    Q_INVOKABLE static QString push(const QString &remoteName, const QString &branchName, bool force = false);

    /* Stash
     * ****************************************************************************************/
    Q_INVOKABLE static QString stashPush(const QString &message, bool keepIndex);
    Q_INVOKABLE static QString stashApply(int index, bool reinstateIndex);
    Q_INVOKABLE static QString stashPop(int index, bool reinstateIndex);
    Q_INVOKABLE static QString stashDrop(int index);

    /* Commit
     * ****************************************************************************************/
    Q_INVOKABLE static QString commit(const QString &message, bool amend = false, bool allowEmpty = false);

    /* Merge / rebase / reset
     * ****************************************************************************************/
    Q_INVOKABLE static QString merge(const QString &sourceBranch, bool noFF);
    Q_INVOKABLE static QString mergeContinue();
    Q_INVOKABLE static QString mergeAbort();
    Q_INVOKABLE static QString rebaseOnto(const QString &upstream);
    Q_INVOKABLE static QString rebase(const QString &onto, const QString &upstream, const QString &branch,
                                      bool interactive, int skippedCount = 0);
    Q_INVOKABLE static QString rebaseContinue();
    Q_INVOKABLE static QString rebaseSkip();
    Q_INVOKABLE static QString rebaseAbort();
    Q_INVOKABLE static QString cherryPickContinue();
    Q_INVOKABLE static QString cherryPickSkip();
    Q_INVOKABLE static QString cherryPickAbort();

    //! \a mode matches ResetController.ResetMode: 0 soft, 1 mixed, 2 hard.
    Q_INVOKABLE static QString reset(const QString &commitHash, int mode);

    /* Repository
     * ****************************************************************************************/
    Q_INVOKABLE static QString init(const QString &path);
    Q_INVOKABLE static QString clone(const QString &url, const QString &localPath);

    /* Bundle
     * ****************************************************************************************/
    Q_INVOKABLE static QString bundleCreate(const QString &bundlePath, const QString &targetRef,
                                            const QString &baseRef = QString());
    Q_INVOKABLE static QString bundleUnbundle(const QString &bundlePath);

};
