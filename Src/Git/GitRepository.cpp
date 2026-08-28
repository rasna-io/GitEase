#include "GitRepository.h"
#include "GitResult.h"

#include <QDir>

#include <git2.h>




GitRepository::GitRepository(QObject *parent)
    : IGitController{parent}
{
    m_currentRepo = new Repository(this);
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
    emitGitCommand(QString("git init %1").arg(quoteCommandArg(path)));

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

    Repository *newRepo = openDetached(path);

    if (!newRepo || !newRepo->repo)
    {
        return GitResult(false, QVariant(), "Failed to open repository");
    }

    newRepo->setParent(this);

    Repository *oldRepo = m_currentRepo;
    m_currentRepo = newRepo;
    
    // Store path and emit signal
    m_currentRepoPath = path;
    emit currentRepoChanged();
    emitGitCommand(QString("git -C %1 rev-parse --git-dir").arg(quoteCommandArg(path)));

    if (oldRepo)
    {
        oldRepo->deleteLater();
    }

    return GitResult(true, path);
}

Repository *GitRepository::openDetached(const QString &path)
{
    if (path.isEmpty())
    {
        return nullptr;
    }

    QDir dir(path);
    if (!dir.exists())
    {
        return nullptr;
    }

    Repository *repo = new Repository(this);
    QByteArray pathUtf8 = path.toUtf8();

    int result = git_repository_open(&repo->repo, pathUtf8.constData());

    if (result != 0)
    {
        delete repo;
        return nullptr;
    }

    return repo;
}

GitResult GitRepository::clone(const QString& url,
                               const QString& localPath)
{
    return cloneInternal(url, localPath, std::make_unique<GitSshAuth>());
}

GitResult GitRepository::clone(const QString& url,
                               const QString& localPath,
                               const QString& token)
{
    return cloneInternal(url, localPath, std::make_unique<GitHttpsAuth>(token));
}

GitResult GitRepository::cloneInternal(const QString& url,
                                       const QString& localPath,
                                       std::unique_ptr<IGitAuth> auth)
{
    if (url.isEmpty() || localPath.isEmpty())
        return GitResult(false, {}, "URL and local path cannot be empty");

    if (QDir(localPath).exists())
        return GitResult(false, {}, "Directory already exists");

#ifdef Q_OS_LINUX
    git_libgit2_opts(GIT_OPT_SET_SSL_CERT_LOCATIONS, "/etc/ssl/certs/ca-certificates.crt", "/etc/ssl/certs");
#endif

    // SSH agent pre check
    if (auto sshAuth = dynamic_cast<GitSshAuth*>(auth.get()))
    {
        QString setupError = sshAuth->getSetupError();
        if (!setupError.isEmpty())
        {
            return GitResult(
                false,
                QVariant(),
                setupError
                );
        }
    }

    GitPayload payload {
        this,
        auth.get()
    };

    auto progressCallback = [](const git_indexer_progress *stats, void *p) -> int {
        auto *data = static_cast<GitPayload*>(p);

        if (stats->total_objects > 0) {
            int percent = static_cast<int>(
                (100.0 * stats->received_objects) / stats->total_objects
                );

            QMetaObject::invokeMethod(
                data->parentThread,
                "cloneProgress",
                Qt::QueuedConnection,
                Q_ARG(int, percent)
                );
        }
        return 0;
    };

    git_clone_options opts = GIT_CLONE_OPTIONS_INIT;
    opts.fetch_opts = GIT_FETCH_OPTIONS_INIT;

    opts.fetch_opts.callbacks.transfer_progress = progressCallback;
    opts.fetch_opts.callbacks.payload = &payload;

    auth->apply(opts.fetch_opts);

    git_repository* repo = nullptr;
    int result = git_clone(
        &repo,
        url.toUtf8().constData(),
        localPath.toUtf8().constData(),
        &opts
        );

    emitGitCommand(QString("git clone %1 %2")
                       .arg(quoteCommandArg(url), quoteCommandArg(localPath)));

    if (result != 0) {
        const git_error *err = git_error_last();
        QString msg = err ? err->message : "Unknown git error";
        return GitResult(false, {}, msg);
    }

    git_repository_free(repo);
    m_currentRepoPath = localPath;

    return GitResult(true, localPath);
}

GitResult GitRepository::close()
{
    if (!m_currentRepo)
    {
        return GitResult(false, QVariant(), "No repository open");
    }

    m_currentRepo->deleteLater();
    m_currentRepo = nullptr;
    m_currentRepoPath.clear();

    return GitResult(true);
}

GitResult GitRepository::closeRepository(Repository *repository)
{
    if (!repository)
    {
        return GitResult(false, QVariant(), "Repository handle is null");
    }

    if (repository == m_currentRepo)
    {
        return close();
    }

    repository->deleteLater();
    return GitResult(true);
}

int GitRepository::detectGitProtocol(const QString& url) const
{
    return static_cast<int>(GitProtocolDetector::detectProtocol(url));
}
