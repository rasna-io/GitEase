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
