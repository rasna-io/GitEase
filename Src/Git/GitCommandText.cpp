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

