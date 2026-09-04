#pragma once

#include <QAtomicInteger>
#include <QHash>
#include <QList>
#include <QMutex>
#include <QObject>
#include <QQueue>
#include <QSet>
#include <QString>
#include <QThread>
#include <QWaitCondition>
#include <QVariant>
#include <QVariantList>
#include <vector>
#include <QMetaMethod>
#include <QMetaObject>
#include <QMetaType>
#include <QMutexLocker>

#include "IGitController.h"

/**
 * @brief Owns the worker threads for all asynchronous libgit2 calls.
 *
 * The runner provides a generic submit() that accepts a controller, a method name,
 * and a list of arguments. It resolves the method through the meta‑object system
 * and invokes it on a worker thread. Results are delivered back to the GUI thread.
 *
 * Work is grouped into lanes, one per repository. Jobs in a lane run in submission order and
 * one at a time, which is what a `git_repository*` requires. Different lanes run on different
 * threads, so a long fetch on one repository no longer delays work on another: opening a
 * second repository loads its content straight away instead of waiting behind the fetch.
 *
 * Lanes are served by two separate pools. Anything that talks to a remote runs in the network
 * pool; everything else runs in the local pool. Keeping them apart is what makes opening a
 * repository work in *any* situation: however many fetches are hung on an unreachable host,
 * they can only ever fill the network pool, and reading a repository never needs it.
 */
class GitAsyncRunner : public QObject
{
    Q_OBJECT

private:
    //! One queued call, with everything about it captured at submit time.
    struct Job
    {
        qint64          requestId      = 0;
        IGitController *controller     = nullptr;
        QString         method;
        QVariantList    args;
        qint64          repoGeneration = 0;
    };

    //! Everything queued for one repository. At most one of its jobs runs at a time.
    struct Lane
    {
        QQueue<Job> pending;
        bool        running = false;
    };

    //! A set of lanes and the threads that serve them.
    struct Pool
    {
        QHash<Repository *, Lane> lanes;
        QList<QThread *>          threads;
    };

    static GitAsyncRunner *s_instance;

    QObject *m_guiAnchor = nullptr; // lives on GUI thread, used for result delivery

    QAtomicInteger<qint64> m_nextRequestId;

    Pool           m_local;      // reads, commits, stashes, tags, and pull
    Pool           m_network;    // fetch, push, clone - may block for a long time
    QMutex         m_mutex;      // guards both pools' lanes and m_stopping
    QWaitCondition m_wake;
    bool           m_stopping = false;

    explicit GitAsyncRunner();
    ~GitAsyncRunner() override;

    /**
     * @brief Worker body: takes one ready job from pool at a time until shutdown.
     */
    void workerLoop(Pool *pool);

    /**
     * @brief Everything a method needs from the repository it runs against.
     *
     * The three things that used to be worked out separately - which pool queues the job,
     * which lock guards it, and which handle it runs on - are decided together, so they cannot
     * drift apart as methods are added.
     *
     * A null lock means "take no lock", and a null handle means "bind nothing", which is what
     * clone wants: it builds a new repository and touches no existing one.
     */
    struct RepoAccessInfo
    {
        Pool            *pool   = nullptr;
        QRecursiveMutex *lock   = nullptr;
        git_repository  *handle = nullptr;
    };

    /**
     * @brief The pool, lock and handle for one method against one repository.
     *
     * The single table describing how every method is scheduled and guarded. Called once when
     * the job is queued, for the pool, and once when it runs, for the lock and the handle.
     */
    RepoAccessInfo accessFor(const QString &method, Repository *lane);

    /**
     * @brief Starts count threads serving pool.
     */
    void startWorkers(Pool *pool, int count, const QString &name);

    /**
     * @brief Takes the next job from a lane that is not already busy.
     *
     * Skipping busy lanes is what keeps a repository's jobs in order while still letting
     * other repositories run. Call with m_mutex held.
     *
     * @param pool The pool to take from.
     * @param lane Receives the repository the job belongs to.
     * @param job  Receives the job itself.
     * @return true when a job was taken.
     */
    bool takeReadyJob(Pool *pool, Repository **lane, Job *job);

    /**
     * @brief Runs one job and emits its result. Call without m_mutex held.
     */
    void runJob(const Job &job, Repository *lane);

    /**
     * @brief Resolves methodName on target by name and argument count, converts args to the
     *        declared parameter types and invokes it directly on the current thread.
     * @param target       The object on which the method will be invoked.
     * @param methodName   Name of the method to call.
     * @param args         Arguments to pass to the method.
     * @param result       Pointer to QVariant where the return value will be stored (if any).
     * @param error        Pointer to QString where an error message will be stored on failure.
     * @return true if the method was found and invoked successfully, false otherwise.
     */
    static bool invokeByName(QObject *target, const QString &methodName, const QVariantList &args, QVariant *result,  QString *error);

public:
    static GitAsyncRunner *instance();
    static GitAsyncRunner *existingInstance();
    static void shutdown();

    /**
     * @brief Queues a   method call on a controller for execution on the worker thread.
     * @param controller The controller that will execute the method.
     * @param method     Name of the Q_INVOKABLE method to call.
     * @param args       Arguments to pass to the method.
     * @return A unique request id, or 0 if the method could not be resolved.
     */
    qint64 submit(IGitController *controller, const QString &method, const QVariantList &args);

private slots:
    void deliverFinished(qint64 requestId, void *controller, const QString &method, const QVariant &result, qint64 repoGeneration);

    void deliverFailed(qint64 requestId, void *controller, const QString &method, const QString &error, qint64 repoGeneration);

signals:
    //! Internal. Emitted on the worker thread, delivered queued back to the GUI thread.
    void jobFinished(qint64 requestId, void *controller, const QString &method, const QVariant &result, qint64 repoGeneration);

    //! Internal. Emitted on the worker thread, delivered queued back to the GUI thread.
    void jobFailed(qint64 requestId, void *controller, const QString &method, const QString &error, qint64 repoGeneration);
};
