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
 * @brief Owns the single worker thread for all asynchronous libgit2 calls.
 *
 * The runner provides a generic submit() that accepts a controller, a method name,
 * and a list of arguments. It resolves the method through the meta‑object system
 * and invokes it on the worker thread. Results are delivered back to the GUI thread.
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

    Pool           m_local;      // reads, commits, stashes, tags - never touches a remote
    Pool           m_network;    // fetch, push, pull, clone - may block for a long time
    QMutex         m_mutex;      // guards both pools' lanes and m_stopping
    QWaitCondition m_wake;
    bool           m_stopping = false;

    explicit GitAsyncRunner();
    ~GitAsyncRunner() override;

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
    void executeJob(qint64 requestId, void *controller, const QString &method, const QVariantList &args, qint64 repoGeneration);

    void deliverFinished(qint64 requestId, void *controller, const QString &method, const QVariant &result, qint64 repoGeneration);

    void deliverFailed(qint64 requestId, void *controller, const QString &method, const QString &error, qint64 repoGeneration);

signals:
    //! Internal. Emitted on the caller's thread, delivered queued to the worker thread.
    void jobQueued(qint64 requestId, void *controller, const QString &method, const QVariantList &args, qint64 repoGeneration);

    //! Internal. Emitted on the worker thread, delivered queued back to the GUI thread.
    void jobFinished(qint64 requestId, void *controller, const QString &method, const QVariant &result, qint64 repoGeneration);

    //! Internal. Emitted on the worker thread, delivered queued back to the GUI thread.
    void jobFailed(qint64 requestId, void *controller, const QString &method, const QString &error, qint64 repoGeneration);
};
