#include "IGitController.h"
#include "Async/GitAsyncRunner.h"

namespace
{
    thread_local git_repository *t_activeRepo = nullptr;
}

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

QRecursiveMutex *IGitController::repoMutex(Repository *repo)
{
    static QRecursiveMutex fallback;

    return repo ? &repo->mutex : &fallback;
}

QRecursiveMutex *IGitController::networkMutex(Repository *repo)
{
    static QRecursiveMutex fallback;

    return repo ? &repo->netMutex : &fallback;
}

qint64 IGitController::callAsync(const QString &method, const QVariantList &args)
{
    return GitAsyncRunner::instance()->submit(this, method, args);
}

void IGitController::emitAsyncFinished(qint64 requestId, const QString &method, const QVariant &result, Repository *jobRepo)
{
    emit asyncFinished(requestId, method, result, jobRepo != m_currentRepo);
}

void IGitController::emitAsyncFailed(qint64 requestId, const QString &method, const QString &error, Repository *jobRepo)
{
    emit asyncFailed(requestId, method, error, jobRepo != m_currentRepo);
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

IGitController::ActiveRepoScope::ActiveRepoScope(git_repository *repo)
    : m_previous(t_activeRepo)
{
    t_activeRepo = repo;
}

IGitController::ActiveRepoScope::~ActiveRepoScope()
{
    t_activeRepo = m_previous;
}

git_repository *IGitController::activeRepo() const
{
    if (t_activeRepo)
        return t_activeRepo;

    return m_currentRepo ? m_currentRepo->repo : nullptr;
}
