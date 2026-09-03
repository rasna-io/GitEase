#include "GitAsyncRunner.h"

GitAsyncRunner *GitAsyncRunner::s_instance = nullptr;

GitAsyncRunner::GitAsyncRunner()
    : QObject(nullptr)
    , m_nextRequestId(1)
{
    m_guiAnchor = new QObject();

    // The runner lives on the worker thread; its slots are executed there.
    moveToThread(m_thread);

    connect(this, &GitAsyncRunner::jobQueued, this, &GitAsyncRunner::executeJob, Qt::QueuedConnection);

    // Results travel back to the thread the runner was created on, the GUI thread.
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
    delete m_guiAnchor;
    m_guiAnchor = nullptr;

    if (m_thread)
    {
        m_thread->quit();
        m_thread->wait(10000);
        delete m_thread;
        m_thread = nullptr;
    }
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

    emit jobQueued(id, static_cast<void *>(controller), method, args, controller->repoGeneration());

    return id;
}

void GitAsyncRunner::executeJob(qint64 requestId, void *controller, const QString &method, const QVariantList &args, qint64 repoGeneration)
{
    auto *target = static_cast<IGitController *>(controller);

    // Serialise all libgit2 access.
    QMutexLocker<QRecursiveMutex> repoLocker(target->repoMutex());

    // The repository may have changed while the job was queued.
    if (target->repoGeneration() != repoGeneration)
    {
        emit jobFailed(requestId, controller, method, QStringLiteral("stale"), repoGeneration);
        return;
    }

    QVariant result;
    QString error;

    const bool ok = invokeByName(target, method, args, &result, &error);

    if (!ok)
    {
        emit jobFailed(requestId, controller, method, error, repoGeneration);
        return;
    }

    emit jobFinished(requestId, controller, method, result, repoGeneration);
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