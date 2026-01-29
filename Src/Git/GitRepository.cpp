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



GitResult GitRepository::clone(const QString& url,
                               const QString& localPath,
                               const QString& authType,
                               const QString& username,
                               const QString& password,
                               const QString& privateKeyPath)
{
    IGitAuth* auth = nullptr;

    if (authType.toLower() == "ssh")
        auth = new GitSshAuth(privateKeyPath, this);

    else if (authType.toLower() == "https")
        auth = new GitHttpsAuth(username, password, this);

    else
        return GitResult(false, {}, "Unknown auth type");

    git_clone_options opts = GIT_CLONE_OPTIONS_INIT;
    opts.fetch_opts = GIT_FETCH_OPTIONS_INIT;

    if (auth)
        auth->apply(opts.fetch_opts);

    git_repository* repo = nullptr;
    int rc = git_clone(&repo,
                       url.toUtf8().constData(),
                       localPath.toUtf8().constData(),
                       &opts);

    if (rc != 0) {
        const git_error* err = giterr_last();
        return GitResult(false, {}, err ? err->message : "Clone failed");
    }

    git_repository_free(repo);
    return GitResult(true, {}, "Clone success");
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
