#include "GitAsyncRunner.h"

GitAsyncRunner *GitAsyncRunner::s_instance = nullptr;

GitAsyncRunner::GitAsyncRunner()
    : QObject(nullptr)
    , m_nextRequestId(1)
{
    m_guiAnchor = new QObject();

    // The runner itself stays on the GUI thread; the workers below call into it directly. The
    // result signals are queued, so they arrive back on the GUI thread where m_guiAnchor lives.
    connect(this, &GitAsyncRunner::jobFinished,
            m_guiAnchor, [this](qint64 id, void *controller, const QString &method, const QVariant &result, qint64 generation)
            {
                deliverFinished(id, controller, method, result, generation);
            },
            Qt::QueuedConnection);

    connect(this, &GitAsyncRunner::jobFailed,
            m_guiAnchor, [this](qint64 id, void *controller, const QString &method, const QString &error, qint64 generation)
            {
                deliverFailed(id, controller, method, error, generation);
            },
            Qt::QueuedConnection);

    startWorkers(&m_local, qBound(2, QThread::idealThreadCount() / 2, 8), QStringLiteral("GitLocal"));

    startWorkers(&m_network, 4, QStringLiteral("GitNetwork"));
}

void GitAsyncRunner::startWorkers(Pool *pool, int count, const QString &name)
{
    for (int i = 0; i < count; ++i)
    {
        QThread *thread = QThread::create([this, pool] { workerLoop(pool); });
        thread->setObjectName(QStringLiteral("%1-%2").arg(name).arg(i));

        pool->threads.append(thread);
        thread->start();
    }
}

bool GitAsyncRunner::isNetworkMethod(const QString &method)
{
    return method == QLatin1String("fetch")
        || method == QLatin1String("fetchWithToken")
        || method == QLatin1String("push")
        || method == QLatin1String("pull")
        || method == QLatin1String("clone")
        || method == QLatin1String("pushTag")
        || method == QLatin1String("pushDeleteTag");
}

bool GitAsyncRunner::usesNetworkHandle(const QString &method)
{
    return method == QLatin1String("fetch")
        || method == QLatin1String("fetchWithToken")
        || method == QLatin1String("push");
}

GitAsyncRunner::~GitAsyncRunner()
{
    {
        QMutexLocker locker(&m_mutex);
        m_stopping = true;
    }

    m_wake.wakeAll();

    const QList<QThread *> threads = m_local.threads + m_network.threads;

    for (QThread *thread : threads)
    {
        if (thread->wait(10000))
            delete thread;
    }

    m_local.threads.clear();
    m_network.threads.clear();

    delete m_guiAnchor;
    m_guiAnchor = nullptr;
}

GitAsyncRunner *GitAsyncRunner::instance()
{
    if (!s_instance)
        s_instance = new GitAsyncRunner();

    return s_instance;
}

GitAsyncRunner *GitAsyncRunner::existingInstance()
{
    return s_instance;
}

void GitAsyncRunner::shutdown()
{
    if (!s_instance)
        return;

    GitAsyncRunner *runner = s_instance;
    s_instance = nullptr;

    delete runner;
}

qint64 GitAsyncRunner::submit(IGitController *controller, const QString &method, const QVariantList &args)
{
    if (!controller || method.isEmpty())
        return 0;

    const qint64 id = m_nextRequestId.fetchAndAddOrdered(1);

    Job job;
    job.requestId      = id;
    job.controller     = controller;
    job.method         = method;
    job.args           = args;
    job.repoGeneration = controller->repoGeneration();

    Pool *pool = isNetworkMethod(method) ? &m_network : &m_local;

    {
        QMutexLocker locker(&m_mutex);
        pool->lanes[controller->currentRepo()].pending.enqueue(job);
    }

    m_wake.wakeAll();

    return id;
}

void GitAsyncRunner::workerLoop(Pool *pool)
{
    QMutexLocker locker(&m_mutex);

    for (;;)
    {
        Repository *lane = nullptr;
        Job         job;

        if (!takeReadyJob(pool, &lane, &job))
        {
            if (m_stopping)
                return;

            m_wake.wait(&m_mutex);
            continue;
        }

        locker.unlock();
        runJob(job, lane);
        locker.relock();

        auto it = pool->lanes.find(lane);

        if (it != pool->lanes.end())
        {
            it->running = false;

            if (it->pending.isEmpty())
                pool->lanes.erase(it);
        }

        m_wake.wakeAll();
    }
}

bool GitAsyncRunner::takeReadyJob(Pool *pool, Repository **lane, Job *job)
{
    for (auto it = pool->lanes.begin(); it != pool->lanes.end(); ++it)
    {
        if (it->running || it->pending.isEmpty())
            continue;

        it->running = true;

        *job  = it->pending.dequeue();
        *lane = it.key();

        return true;
    }

    return false;
}

void GitAsyncRunner::runJob(const Job &job, Repository *lane)
{
    // Only this repository is locked, so calls against other repositories run alongside it.
    QRecursiveMutex *lock = usesNetworkHandle(job.method)
                                ? IGitController::networkMutex(lane)
                                : IGitController::repoMutex(lane);

    QMutexLocker<QRecursiveMutex> repoLocker(lock);

    IGitController *target  = job.controller;
    auto *controller        = static_cast<void *>(target);

    // The repository may have changed while the job was queued.
    if (target->repoGeneration() != job.repoGeneration)
    {
        emit jobFailed(job.requestId, controller, job.method, QStringLiteral("stale"), job.repoGeneration);
        return;
    }

    QVariant result;
    QString error;

    const bool ok = invokeByName(target, job.method, job.args, &result, &error);

    if (!ok)
    {
        emit jobFailed(job.requestId, controller, job.method, error, job.repoGeneration);
        return;
    }

    emit jobFinished(job.requestId, controller, job.method, result, job.repoGeneration);
}

bool GitAsyncRunner::invokeByName(QObject *target, const QString &methodName, const QVariantList &args, QVariant *result, QString *error)
{
    const QByteArray wanted = methodName.toUtf8();
    const QMetaObject *mo = target->metaObject();

    QMetaMethod chosen;
    bool found = false;

    // check type of function, name, and parameter count
    for (int i = 0; i < mo->methodCount(); ++i) {
        const QMetaMethod candidate = mo->method(i);

        if (candidate.methodType() != QMetaMethod::Method
            && candidate.methodType() != QMetaMethod::Slot)
            continue;

        if (candidate.name() != wanted)
            continue;

        if (candidate.parameterCount() != args.size())
            continue;

        chosen = candidate;
        found = true;
        break;
    }

    if (!found) {
        *error = QStringLiteral("no invokable '%1' taking %2 argument(s) on %3")
        .arg(methodName)
            .arg(args.size())
            .arg(QString::fromUtf8(mo->className()));
        return false;
    }

    // check parameter type
    QVariantList converted;
    converted.reserve(args.size());

    for (int i = 0; i < args.size(); ++i) {
        QVariant value = args.at(i);
        const QMetaType wantedType = chosen.parameterMetaType(i);

        if (value.metaType() != wantedType && !value.convert(wantedType)) {
            *error = QStringLiteral("argument %1 of '%2' cannot be converted to %3")
            .arg(i)
                .arg(methodName)
                .arg(QString::fromUtf8(wantedType.name()));
            return false;
        }

        converted.append(value);
    }

    std::vector<void *> argv(args.size() + 1, nullptr);

    for (size_t i = 0; i < converted.size(); ++i)
        argv[i + 1] = const_cast<void *>(converted.at(i).constData());

    const QMetaType returnType = chosen.returnMetaType();
    const bool hasReturn = returnType.isValid() && returnType.id() != QMetaType::Void;

    void *returnStorage = nullptr;
    if (hasReturn) {
        returnStorage = returnType.create();
        if (!returnStorage) {
            *error = QStringLiteral("cannot default-construct return type %1 of '%2'")
            .arg(QString::fromUtf8(returnType.name()))
                .arg(methodName);
            return false;
        }
        argv[0] = returnStorage;
    }

    const bool ok = QMetaObject::metacall(target,
                                          QMetaObject::InvokeMetaMethod,
                                          chosen.methodIndex(),
                                          argv.data()) < 0;

    if (!ok)
        *error = QStringLiteral("metacall('%1') was not handled").arg(methodName);
    else if (hasReturn)
        *result = QVariant(returnType, returnStorage);
    else
        *result = QVariant();

    if (returnStorage)
        returnType.destroy(returnStorage);

    return ok;
}

void GitAsyncRunner::deliverFinished(qint64 requestId,void *controller,const QString &method,const QVariant &result, qint64 repoGeneration)
{
    auto *target = static_cast<IGitController *>(controller);

    target->emitAsyncFinished(requestId, method, result, repoGeneration);
}

void GitAsyncRunner::deliverFailed(qint64 requestId, void *controller, const QString &method, const QString &error, qint64 repoGeneration)
{
    auto *target = static_cast<IGitController *>(controller);

    target->emitAsyncFailed(requestId, method, error, repoGeneration);
}