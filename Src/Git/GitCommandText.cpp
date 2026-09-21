#include "GitCommandText.h"

GitCommandText::GitCommandText(QObject *parent)
    : QObject{parent}
{}

QString GitCommandText::quote(const QString &argument)
{
    if (argument.isEmpty())
        return argument;

    QString escaped = argument;
    escaped.replace("\\", "\\\\");
    escaped.replace("\"", "\\\"");
    return "\"" + escaped + "\"";
}

QString GitCommandText::createBranch(const QString &branchName, const QString &startPoint)
{
    if (startPoint.isEmpty())
        return QString("git branch %1").arg(quote(branchName));

    return QString("git branch %1 %2").arg(quote(branchName), quote(startPoint));
}

QString GitCommandText::createBranchAndCheckout(const QString &branchName, const QString &startPoint)
{
    if (startPoint.isEmpty())
        return QString("git checkout -b %1").arg(quote(branchName));

    return QString("git checkout -b %1 %2").arg(quote(branchName), quote(startPoint));
}

QString GitCommandText::deleteBranch(const QString &branchName)
{
    return QString("git branch -d %1").arg(quote(branchName));
}

QString GitCommandText::renameBranch(const QString &oldName, const QString &newName)
{
    return QString("git branch -m %1 %2").arg(quote(oldName), quote(newName));
}

QString GitCommandText::checkoutBranch(const QString &branchName)
{
    return QString("git checkout %1").arg(quote(branchName));
}

QString GitCommandText::checkoutCommit(const QString &commitHash)
{
    return QString("git checkout --detach %1").arg(quote(commitHash));
}

QString GitCommandText::createTag(const QString &name, const QString &message, bool force)
{
    QString command = "git tag";

    if (force)
        command += " -f";

    if (!message.isEmpty())
        command += " -a -m " + quote(message);

    command += " " + quote(name);

    return command;
}

QString GitCommandText::deleteTag(const QString &name)
{
    return QString("git tag -d %1").arg(quote(name));
}

QString GitCommandText::pushTag(const QString &name)
{
    return QString("git push origin %1").arg(quote(name));
}

QString GitCommandText::pushDeleteTag(const QString &name)
{
    return QString("git push origin --delete %1").arg(quote(name));
}

QString GitCommandText::addRemote(const QString &name, const QString &url)
{
    return QString("git remote add %1 %2").arg(quote(name), quote(url));
}

QString GitCommandText::removeRemote(const QString &name)
{
    return QString("git remote remove %1").arg(quote(name));
}

QString GitCommandText::renameRemote(const QString &oldName, const QString &newName)
{
    return QString("git remote rename %1 %2").arg(quote(oldName), quote(newName));
}

QString GitCommandText::setRemoteUrl(const QString &name, const QString &url)
{
    return QString("git remote set-url %1 %2").arg(quote(name), quote(url));
}

QString GitCommandText::push(const QString &remoteName, const QString &branchName, bool force)
{
    return QString("git push %1%2 %3").arg(force ? "--force " : "",
                                           quote(remoteName),
                                           quote(branchName));
}

QString GitCommandText::stashPush(const QString &message, bool keepIndex)
{
    QString command = "git stash push";

    if (keepIndex)
        command += " --keep-index";

    if (!message.trimmed().isEmpty())
        command += " -m " + quote(message.trimmed());

    return command;
}

QString GitCommandText::stashApply(int index, bool reinstateIndex)
{
    QString command = QString("git stash apply stash@{%1}").arg(index);

    if (reinstateIndex)
        command += " --index";

    return command;
}

QString GitCommandText::stashPop(int index, bool reinstateIndex)
{
    QString command = QString("git stash pop stash@{%1}").arg(index);

    if (reinstateIndex)
        command += " --index";

    return command;
}

QString GitCommandText::stashDrop(int index)
{
    return QString("git stash drop stash@{%1}").arg(index);
}

QString GitCommandText::commit(const QString &message, bool amend, bool allowEmpty)
{
    QString command = "git commit";

    if (amend)
        command += " --amend";

    if (allowEmpty)
        command += " --allow-empty";

    command += " -m " + quote(message.trimmed());

    return command;
}

QString GitCommandText::merge(const QString &sourceBranch, bool noFF)
{
    return noFF ? QString("git merge --no-ff %1").arg(quote(sourceBranch))
                : QString("git merge %1").arg(quote(sourceBranch));
}

QString GitCommandText::mergeContinue()
{
    return "git merge --continue";
}

QString GitCommandText::mergeAbort()
{
    return "git merge --abort";
}

QString GitCommandText::rebaseOnto(const QString &upstream)
{
    return QString("git rebase %1").arg(quote(upstream));
}

QString GitCommandText::rebase(const QString &onto, const QString &upstream, const QString &branch,
                               bool interactive, int skippedCount)
{
    QString command = interactive ? "git rebase -i" : "git rebase";

    if (!onto.trimmed().isEmpty())
        command += " --onto " + quote(onto);

    command += " " + quote(upstream);

    if (!branch.isEmpty())
        command += " " + quote(branch);

    if (skippedCount > 0)
        command += QString("  # skipped %1 commit(s)").arg(skippedCount);

    return command;
}

QString GitCommandText::rebaseContinue()
{
    return "git rebase --continue";
}

QString GitCommandText::rebaseSkip()
{
    return "git rebase --skip";
}

QString GitCommandText::rebaseAbort()
{
    return "git rebase --abort";
}

QString GitCommandText::cherryPickContinue()
{
    return "git cherry-pick --continue";
}

QString GitCommandText::cherryPickSkip()
{
    return "git cherry-pick --skip";
}

QString GitCommandText::cherryPickAbort()
{
    return "git cherry-pick --abort";
}

QString GitCommandText::reset(const QString &commitHash, int mode)
{
    QString command = "git reset";

    switch (mode) {
    case 0:  command += " --soft";  break;
    case 1:  command += " --mixed"; break;
    case 2:  command += " --hard";  break;
    default: break;
    }

    // Refs and hashes never need quoting, and the unquoted form is what git users type
    return command + " " + commitHash;
}

QString GitCommandText::init(const QString &path)
{
    return QString("git init %1").arg(quote(path));
}

QString GitCommandText::clone(const QString &url, const QString &localPath)
{
    return QString("git clone %1 %2").arg(quote(url), quote(localPath));
}

