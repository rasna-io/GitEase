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
    QMutexLocker<QRecursiveMutex> repoLocker(repoMutex());

    if (m_currentRepo == newCurrentRepo)
        return;
    m_currentRepo = newCurrentRepo;

    ++m_repoGeneration;

    emit currentRepoChanged();
}

QRecursiveMutex *IGitController::repoMutex()
{
    static QRecursiveMutex mutex;
    return &mutex;
}


void IGitController::emitAsyncFinished(qint64 requestId, const QString &method, const QVariant &result, qint64 repoGeneration)
{
    emit asyncFinished(requestId, method, result, repoGeneration);
}

void IGitController::emitAsyncFailed(qint64 requestId, const QString &method, const QString &error, qint64 repoGeneration)
{
    emit asyncFailed(requestId, method, error, repoGeneration);
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

void IGitController::emitGitCommand(const QString &command)
{
    const QString trimmedCommand = command.trimmed();
    if (!trimmedCommand.isEmpty()) {
        emit gitCommandGenerated(trimmedCommand);
    }
}

QString IGitController::quoteCommandArg(const QString &argument)
{
    QString escaped = argument;
    escaped.replace("\\", "\\\\");
    escaped.replace("\"", "\\\"");
    return "\"" + escaped + "\"";
}
