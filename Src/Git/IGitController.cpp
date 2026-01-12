#include "IGitController.h"

IGitController::IGitController(QObject *parent)
    : QObject{parent}
{
}

Repository *IGitController::currentRepo() const
{
    return m_currentRepo;
}

void IGitController::setCurrentRepo(Repository *newCurrentRepo)
{
    if (m_currentRepo == newCurrentRepo)
        return;
    m_currentRepo = newCurrentRepo;
    emit currentRepoChanged();
}

QString IGitController::gitOidToString(const git_oid *oid)
{
    if (!oid)
        return QString();

    char oidStr[GIT_OID_HEXSZ + 1];
    git_oid_fmt(oidStr, oid);
    oidStr[GIT_OID_HEXSZ] = '\0';

    return QString::fromUtf8(oidStr, GIT_OID_HEXSZ);
}
