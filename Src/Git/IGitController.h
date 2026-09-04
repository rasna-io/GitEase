#pragma once

#include "Repository.h"
#include <QObject>
#include <QQmlEngine>
#include <QVariant>
#include <QVariantList>
#include <git2/deprecated.h>
#include <QMutexLocker>
#include <QMutex>
#include <QAtomicInteger>



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
     * @brief The lock a libgit2 access must hold, for one repository.
     *
     * A `git_repository*` is not safe for concurrent use, so work on the same repository is
     * serialised. Two *different* repositories carry independent locks and run side by side,
     * which is what lets a newly opened repository load while a fetch on the previous one is
     * still in flight.
     */
    static QRecursiveMutex *repoMutex(Repository *repo);

    /**
     * @brief The lock for a repository's transfer handle.
     *
     * Held by fetch and push instead of repoMutex(), which is what keeps reads on the same
     * repository responsive while a transfer is running.
     */
    static QRecursiveMutex *networkMutex(Repository *repo);

    /**
     * @brief The repository handle the code running right now should use.
     *
     * Every libgit2 call in the controllers goes through this rather than reaching for a
     * handle itself, so that which handle a method uses is decided in exactly one place -
     * GitAsyncRunner::accessForMethod() - instead of being hard-coded call site by call site.
     *
     * The runner binds this for the duration of each queued job. Synchronous calls made
     * straight from the GUI thread bind nothing, and fall back to the main handle.
     */
    git_repository *activeRepo() const;

    //! Called by GitAsyncRunner on the GUI thread. Not meant for anything else.
    void emitAsyncFinished(qint64 requestId, const QString &method, const QVariant &result, qint64 repoGeneration);
    void emitAsyncFailed(qint64 requestId, const QString &method, const QString &error, qint64 repoGeneration);

signals:
    void currentRepoChanged();
    void gitCommandGenerated(const QString &command);

    //! A queued call completed. \a result holds the result
    void asyncFinished(qint64 requestId, const QString &method, const QVariant &result, bool isRepoChanged);

    //! A queued call could not be delivered. \a error is "stale" when the repository changed
    //! underneath it, otherwise a resolution or invocation failure.
    void asyncFailed(qint64 requestId, const QString &method, const QString &error, bool isRepoChanged);

protected:
    void emitGitCommand(const QString &command);
    static QString quoteCommandArg(const QString &argument);

    Repository *m_currentRepo = nullptr;

private:
    //! Read from the worker threads while the GUI thread bumps it, so it is atomic.
    QAtomicInteger<qint64> m_repoGeneration = 0;
};
