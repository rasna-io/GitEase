#include "GitWrapperCPP.h"
#include <QDebug>
#include <QDir>
#include <QFileInfo>

// Private implementation (PIMPL pattern)
struct GitWrapperCPP::GitRepo
{
    git_repository* repo = nullptr;

    ~GitRepo()
    {
        if (repo)
        {
            git_repository_free(repo);
            repo = nullptr;
        }
    }
};

// Constructor: Initialize libgit2 library
GitWrapperCPP::GitWrapperCPP(QObject *parent) : QObject(parent)
{
    git_libgit2_init();
    qDebug() << "GitWrapperCPP: libgit2 initialized";
}

// Destructor: Clean up
GitWrapperCPP::~GitWrapperCPP()
{
    closeRepo();
    git_libgit2_shutdown();
    qDebug() << "GitWrapperCPP: libgit2 shutdown";
}

// Initialize a new repository
bool GitWrapperCPP::initRepo(const QString& path)
{
    closeRepo(); // Close any open repository

    QDir dir(path);
    if (!dir.exists()) {
        if (!dir.mkpath(".")) {
            m_lastError = "Failed to create directory: " + path;
            qDebug() << m_lastError;
            return false;
        }
    }

    // Check if directory is empty
    if (dir.exists(".git")) {
        m_lastError = "Directory already contains a .git folder: " + path;
        qDebug() << m_lastError;
        return false;
    }

    m_repo = new GitRepo();

    // Convert QString to UTF-8 for libgit2
    QByteArray pathUtf8 = path.toUtf8();
    const char* cpath = pathUtf8.constData();

    int result = git_repository_init(&m_repo->repo, cpath, 0);

    if (result != 0) {
        const git_error* error = git_error_last();
        if (error) {
            m_lastError = QString("libgit2 error [%1]: %2").arg(result).arg(error->message);
        } else {
            m_lastError = QString("Unknown libgit2 error: %1").arg(result);
        }
        qDebug() << "initRepo failed:" << m_lastError;
        delete m_repo;
        m_repo = nullptr;
        return false;
    }

    qDebug() << "Repository successfully initialized at:" << path;
    return true;
}

// Open an existing repository
bool GitWrapperCPP::openRepo(const QString& path)
{
    closeRepo();

    QDir dir(path);
    if (!dir.exists()) {
        m_lastError = "Directory does not exist: " + path;
        qDebug() << m_lastError;
        return false;
    }

    m_repo = new GitRepo();

    // Check if it's a repository
    QString gitPath = path;
    if (!path.endsWith(".git") && QFileInfo(path + "/.git").exists()) {
        // It's a working directory with .git subdirectory
        gitPath = path;
    }

    // Convert QString to UTF-8 for libgit2
    QByteArray pathUtf8 = gitPath.toUtf8();
    const char* cpath = pathUtf8.constData();

    int result = git_repository_open(&m_repo->repo, cpath);

    if (result != 0) {
        const git_error* error = git_error_last();
        if (error) {
            m_lastError = QString("libgit2 error [%1]: %2").arg(result).arg(error->message);
        } else {
            m_lastError = QString("Not a git repository: %1").arg(path);
        }
        qDebug() << "openRepo failed:" << m_lastError;
        delete m_repo;
        m_repo = nullptr;
        return false;
    }

    qDebug() << "Repository successfully opened:" << repoPath();
    return true;
}

// Close the current repository
void GitWrapperCPP::closeRepo()
{
    if (m_repo) {
        delete m_repo;
        m_repo = nullptr;
        qDebug() << "Repository closed";
    }
}

// Check if a repository is open
bool GitWrapperCPP::isRepoOpen() const
{
    return m_repo && m_repo->repo;
}

// Get repository path (.git directory)
QString GitWrapperCPP::repoPath() const
{
    if (!isRepoOpen()) {
        return QString();
    }

    const char* path = git_repository_path(m_repo->repo);
    return path ? QString::fromUtf8(path) : QString();
}

// Get working directory
QString GitWrapperCPP::workDir() const
{
    if (!isRepoOpen()) {
        return QString();
    }

    const char* workdir = git_repository_workdir(m_repo->repo);
    return workdir ? QString::fromUtf8(workdir) : QString();
}

// Get last error message
QString GitWrapperCPP::lastError() const
{
    return m_lastError;
}

bool GitWrapperCPP::runTests()
{
    qDebug() << "===== Starting GitWrapperCPP Tests =====";

    GitWrapperCPP wrapper;

    bool allTestsPassed = true;

    // Test 1: Local repository operations
    qDebug() << "\n[Test 1] Testing local repository operations...";
    if (!wrapper.testLocalRepo()) {
        qDebug() << "❌ Local repo test FAILED";
        allTestsPassed = false;
    } else {
        qDebug() << "✅ Local repo test PASSED";
    }

    // Test 2: Clone repository (optional - requires network)
    qDebug() << "\n[Test 2] Testing clone repository (requires network)...";
    if (!wrapper.testCloneRepo()) {
        qDebug() << "⚠️ Clone test failed (might be network issue)";
        // Don't fail entire test for network issues
    } else {
        qDebug() << "✅ Clone test PASSED";
    }

    // Test 3: Open repository
    qDebug() << "\n[Test 3] Testing open repository...";
    QString tempPath = QDir::tempPath() + "/libgit2_test_repo";
    if (wrapper.openRepo(tempPath)) {
        qDebug() << "✅ Open existing repo PASSED";
        qDebug() << "   Repo path:" << wrapper.repoPath();
        qDebug() << "   Work dir:" << wrapper.workDir();
        wrapper.closeRepo();
    } else {
        qDebug() << "❌ Open existing repo FAILED:" << wrapper.lastError();
        allTestsPassed = false;
    }

    // Cleanup
    QDir tempDir(tempPath);
    if (tempDir.exists()) {
        tempDir.removeRecursively();
        qDebug() << "\nCleaned up test directory:" << tempPath;
    }

    qDebug() << "\n===== Test Results =====";
    if (allTestsPassed) {
        qDebug() << "✅ ALL TESTS PASSED!";
    } else {
        qDebug() << "❌ SOME TESTS FAILED";
    }
    qDebug() << "========================\n";

    return allTestsPassed;
}

bool GitWrapperCPP::testLocalRepo()
{
    QString tempPath = QDir::tempPath() + "/libgit2_test_repo";
    QDir tempDir(tempPath);

    // Clean up any existing test directory
    if (tempDir.exists()) {
        tempDir.removeRecursively();
    }

    // Test initRepo
    if (!initRepo(tempPath)) {
        qDebug() << "   Failed to init repo:" << lastError();
        return false;
    }

    qDebug() << "   Repository created at:" << tempPath;
    qDebug() << "   Repo path:" << repoPath();
    qDebug() << "   Work dir:" << workDir();

    // Verify the repository was created
    if (!isRepoOpen()) {
        qDebug() << "   Repository not open after init";
        return false;
    }

    // Check that .git directory exists
    QFileInfo gitDir(tempPath + "/.git");
    if (!gitDir.exists() || !gitDir.isDir()) {
        qDebug() << "   .git directory not found";
        return false;
    }

    qDebug() << "   .git directory exists: YES";

    // Test reopening the same repo
    closeRepo();
    if (!openRepo(tempPath)) {
        qDebug() << "   Failed to reopen repo:" << lastError();
        return false;
    }

    qDebug() << "   Reopen successful: YES";

    return true;
}

// Test clone repository
bool GitWrapperCPP::testCloneRepo()
{
    QString clonePath = QDir::tempPath() + "/libgit2_clone_test";
    QDir cloneDir(clonePath);

    // Clean up any existing clone directory
    if (cloneDir.exists()) {
        cloneDir.removeRecursively();
    }

    qDebug() << "   Attempting to clone: https://github.com/Roniasoft/NodeLink.git";
    qDebug() << "   Target directory:" << clonePath;

    // Use QMap for options (can be empty for now)
    QMap<QString, QString> options;

    // Note: You'll need to implement cloneRepo() first
    // For now, let's test the raw libgit2 clone like in your test code
    closeRepo(); // Close any open repo

    // Direct libgit2 test (temporary until cloneRepo is implemented)
    git_repository* clonedRepo = nullptr;
    QByteArray urlBytes = "https://github.com/Roniasoft/NodeLink.git";
    QByteArray pathBytes = clonePath.toUtf8();

    qDebug() << "   libgit2 features available:" << git_libgit2_features();

    // Try clone with basic options
    git_clone_options clone_opts = GIT_CLONE_OPTIONS_INIT;
    int result = git_clone(&clonedRepo,
                           urlBytes.constData(),
                           pathBytes.constData(),
                           &clone_opts);

    if (result == 0) {
        qDebug() << "   Clone SUCCESS!";

        // Open the cloned repo with our wrapper
        if (openRepo(clonePath)) {
            qDebug() << "   Successfully opened cloned repo";
            qDebug() << "   Cloned repo path:" << repoPath();

            // Get repository info
            const char* branch = nullptr;
            git_reference* head = nullptr;
            if (git_repository_head(&head, clonedRepo) == 0) {
                branch = git_reference_shorthand(head);
                qDebug() << "   Current branch:" << (branch ? branch : "unknown");
                git_reference_free(head);
            }

            // Get remote info
            git_remote* remote = nullptr;
            if (git_remote_lookup(&remote, clonedRepo, "origin") == 0) {
                const char* remote_url = git_remote_url(remote);
                qDebug() << "   Remote URL:" << (remote_url ? remote_url : "none");
                git_remote_free(remote);
            }

            closeRepo();
        }

        // Free the cloned repo
        git_repository_free(clonedRepo);

        return true;
    } else {
        const git_error* error = git_error_last();
        if (error) {
            qDebug() << "   Clone FAILED [" << result << "]:" << error->message;
        } else {
            qDebug() << "   Clone FAILED with code:" << result;
        }

        // Check for common issues
        qDebug() << "   Possible issues:";
        qDebug() << "   - Network connectivity";
        qDebug() << "   - SSL/TLS certificates";
        qDebug() << "   - Repository URL accessibility";

        return false;
    }
}
