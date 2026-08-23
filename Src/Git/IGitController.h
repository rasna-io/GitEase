#pragma once

#include "Repository.h"
#include <QObject>
#include <QQmlEngine>
#include <QVariant>
#include <QVariantList>
#include <git2/deprecated.h>
#include <QMutexLocker>
#include <QMutex>

class IGitController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(Repository* currentRepo READ currentRepo WRITE setCurrentRepo NOTIFY currentRepoChanged FINAL)

public:
    explicit IGitController(QObject *parent = nullptr);

    Repository *currentRepo() const;
    void setCurrentRepo(Repository *newCurrentRepo);

    QString gitOidToString(const git_oid *oid);

    /**
     * @brief Queues a method for execution on the Git worker thread.
     * @param method Name of a Q_INVOKABLE declared on this controller.
     * @param args   Arguments, converted to the declared parameter types.
     * @return A process-unique request id, or 0 when the call could not be queued.
     */
    Q_INVOKABLE qint64 callAsync(const QString &method, const QVariantList &args = QVariantList());

    /**
     * @brief Bumped every time currentRepo changes.
     *
     * Results produced for an older generation are dropped rather than delivered against the
     * wrong repository — this is what stops a slow status() on the previous repository from
     * repainting the UI after the user has already switched away.
     */
    qint64 repoGeneration() const;

    /**
     * @brief The lock every libgit2 access must hold.
     *
     * A `git_repository*` is not safe for concurrent use, and libgit2's own caches are shared
     * process-wide, so one recursive lock guards all of it. Recursive because several
     * Q_INVOKABLEs legitimately call one another on the same thread.
     *
     * The async runner takes this around every queued job. Synchronous calls still made from
     * the GUI thread take it via QMutexLocker directly.
     */
    static QRecursiveMutex *repoMutex();

    //! Called by GitAsyncRunner on the GUI thread. Not meant for anything else.
    void emitAsyncFinished(qint64 requestId, const QString &method, const QVariant &result, qint64 repoGeneration);
    void emitAsyncFailed(qint64 requestId, const QString &method, const QString &error, qint64 repoGeneration);

signals:
    void currentRepoChanged();
    void gitCommandGenerated(const QString &command);

    //! A queued call completed. \a result holds the result
    void asyncFinished(qint64 requestId, const QString &method, const QVariant &result, qint64 repoGeneration);

    //! A queued call could not be delivered. \a error is "stale" when the repository changed
    //! underneath it, otherwise a resolution or invocation failure.
    void asyncFailed(qint64 requestId, const QString &method, const QString &error, qint64 repoGeneration);

protected:
    void emitGitCommand(const QString &command);
    static QString quoteCommandArg(const QString &argument);

    Repository *m_currentRepo = nullptr;

private:
    qint64 m_repoGeneration = 0;
};
