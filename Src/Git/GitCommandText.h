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

};
