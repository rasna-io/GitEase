#include "GitRepository.h"
#include "GitResult.h"

#include <QDir>
#include <QtConcurrent>

#include <git2.h>


GitRepository::GitRepository(QObject *parent)
    : IGitController{parent}
{
    m_currentRepo = new Repository();
}

GitResult GitRepository::init(const QString &path)
{
    // Validate path
    if (path.isEmpty())
    {
        return GitResult(false, QVariant(), "Path cannot be empty");
    }

    // Check if directory exists
    QDir dir(path);
    if (dir.exists())
    {
        return GitResult(false, QVariant(), "Directory already exists");
    }

    // Check if repository is already open
    if (m_currentRepo)
    {
        return GitResult(false, QVariant(), "Repository already open");
    }

    // Convert path to UTF-8 for libgit2
    QByteArray pathUtf8 = path.toUtf8();

    // Initialize repository
    int result = git_repository_init(&m_currentRepo->repo, pathUtf8.constData(), 0);

    if (result != 0)
        return GitResult(false, QVariant(), "Failed to initialize repository");

    // Store path and emit signal
    m_currentRepoPath = path;

    qDebug() << "GitWrapperCPP: Repository initialized at" << path;
    return GitResult(true, path);
}

GitResult GitRepository::open(const QString &path)
{
    // Validate path
    if (path.isEmpty())
    {
        return GitResult(false, QVariant(), "Path cannot be empty");
    }

    // Check if directory exists
    QDir dir(path);
    if (!dir.exists())
    {
        return GitResult(false, QVariant(), "Directory does not exist");
    }

    // Close current repository if open
    if (m_currentRepo)
    {
        git_repository_free(m_currentRepo->repo);
    }


    // Convert path to UTF-8
    QByteArray pathUtf8 = path.toUtf8();

    // Open repository
    int result = git_repository_open(&m_currentRepo->repo, pathUtf8.constData());

    if (result != 0)
        return GitResult(false, QVariant(), "Failed to open repository");

    // Store path and emit signal
    m_currentRepoPath = path;
    emit currentRepoChanged();

    return GitResult(true, path);
}



GitResult GitRepository::clone(const QString &url, const QString &localPath)
{
    qDebug() << "GitWrapperCPP: clone requested:" << localPath;

    if (url.isEmpty() || localPath.isEmpty())
        return GitResult(false, QVariant(), "URL and local path cannot be empty");

    QDir dir(localPath);
    if (dir.exists())
        return GitResult(false, QVariant(), "Directory already exists: " + localPath);

    const QString safeUrl = url;
    const QString safePath = localPath;

    auto future = QtConcurrent::run([=]() -> QVariantMap {

        struct Payload { GitRepository *self; } payload { this };

        auto progressCallback = [](const git_indexer_progress *stats, void *p) -> int {
            auto *data = static_cast<Payload*>(p);

            if (stats->total_objects > 0) {
                int percent = static_cast<int>(
                    (100.0 * stats->received_objects) / stats->total_objects
                    );

                QMetaObject::invokeMethod(
                    data->self,
                    "cloneProgress",
                    Qt::QueuedConnection,
                    Q_ARG(int, percent)
                    );
            }
            return 0;
        };

        git_repository *repo = nullptr;

        git_clone_options opts = GIT_CLONE_OPTIONS_INIT;
        opts.fetch_opts.callbacks.transfer_progress = progressCallback;
        opts.fetch_opts.callbacks.payload = &payload;

        QByteArray urlUtf8 = safeUrl.toUtf8();
        QByteArray pathUtf8 = safePath.toUtf8();

        int result = git_clone(&repo, urlUtf8.constData(), pathUtf8.constData(), &opts);

        if (result != 0) {
            const git_error *err = git_error_last();
            QString msg = err ? err->message : "Unknown git error";
            return QVariantMap { {"success", false}, {"error", msg} };
        }

        git_repository_free(repo);

        return QVariantMap { {"success", true}, {"data", safePath} };
    });

    auto *watcher = new QFutureWatcher<QVariantMap>(this);

    connect(watcher, &QFutureWatcher<QVariantMap>::finished, this, [=]() {
        QVariantMap result = watcher->result();

        if (result["success"].toBool())
            m_currentRepoPath = safePath;

        emit cloneFinished(result);
        watcher->deleteLater();
    });

    watcher->setFuture(future);

    return GitResult(true, QVariant(), "Clone started");
}

GitResult GitRepository::close()
{
    if (!m_currentRepo)
    {
        return GitResult(false, QVariant(), "No repository open");
    }

    git_repository_free(m_currentRepo->repo);
    m_currentRepo = nullptr;
    m_currentRepoPath.clear();

    qDebug() << "GitWrapperCPP: Repository closed";

    return GitResult(true);
}
