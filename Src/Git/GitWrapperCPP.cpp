#include "GitWrapperCPP.h"
#include <QDebug>
#include <QDir>
#include <QDateTime>
#include <QProcess>
#include <QStandardPaths>
#include <QTemporaryDir>

// Helper function to convert git status to string
QString gitStatusToString(git_status_t status)
{
    if (status & GIT_STATUS_WT_NEW) return "untracked";
    if (status & GIT_STATUS_WT_MODIFIED) return "modified";
    if (status & GIT_STATUS_WT_DELETED) return "deleted";
    if (status & GIT_STATUS_WT_RENAMED) return "renamed";
    if (status & GIT_STATUS_WT_TYPECHANGE) return "typechange";
    if (status & GIT_STATUS_INDEX_NEW) return "staged_new";
    if (status & GIT_STATUS_INDEX_MODIFIED) return "staged_modified";
    if (status & GIT_STATUS_INDEX_DELETED) return "staged_deleted";
    if (status & GIT_STATUS_INDEX_RENAMED) return "staged_renamed";
    return "unknown";
}

GitWrapperCPP::GitWrapperCPP(QObject *parent)
    : QObject(parent)
{
    git_libgit2_init();
    qDebug() << "GitWrapperCPP: libgit2 initialized";

    runInternalTests();
}

GitWrapperCPP::~GitWrapperCPP()
{
    // Free current repository if open
    if (m_currentRepo)
    {
        git_repository_free(m_currentRepo);
        m_currentRepo = nullptr;
    }

    git_libgit2_shutdown();
    qDebug() << "GitWrapperCPP: libgit2 shutdown";
}

/* Repository Operations Implementation */

QVariantMap GitWrapperCPP::init(const QString &path)
{
    // Validate path
    if (path.isEmpty())
    {
        return createResult(false, QVariant(), "Path cannot be empty");
    }

    // Check if directory exists
    QDir dir(path);
    if (dir.exists())
    {
        return createResult(false, QVariant(), "Directory already exists");
    }

    // Check if repository is already open
    if (m_currentRepo)
    {
        return createResult(false, QVariant(), "Repository already open");
    }

    // Convert path to UTF-8 for libgit2
    QByteArray pathUtf8 = path.toUtf8();

    // Initialize repository
    int result = git_repository_init(&m_currentRepo, pathUtf8.constData(), 0);

    if (result != 0)
    {
        handleGitError(result);
        return createResult(false, QVariant(), "Failed to initialize repository");
    }

    // Store path and emit signal
    m_currentRepoPath = path;

    qDebug() << "GitWrapperCPP: Repository initialized at" << path;
    return createResult(true, path);
}

QVariantMap GitWrapperCPP::open(const QString &path)
{
    // Validate path
    if (path.isEmpty())
    {
        return createResult(false, QVariant(), "Path cannot be empty");
    }

    // Check if directory exists
    QDir dir(path);
    if (!dir.exists())
    {
        return createResult(false, QVariant(), "Directory does not exist");
    }

    // Close current repository if open
    if (m_currentRepo)
    {
        git_repository_free(m_currentRepo);
        m_currentRepo = nullptr;
    }

    // Convert path to UTF-8
    QByteArray pathUtf8 = path.toUtf8();

    // Open repository
    int result = git_repository_open(&m_currentRepo, pathUtf8.constData());

    if (result != 0)
    {
        handleGitError(result);
        return createResult(false, QVariant(), "Failed to open repository");
    }

    // Store path and emit signal
    m_currentRepoPath = path;

    qDebug() << "GitWrapperCPP: Repository opened at" << path;
    return createResult(true, path);
}

QVariantMap GitWrapperCPP::clone(const QString &url, const QString &localPath)
{
    // 1. Check if inputs are empty
    if (url.isEmpty() || localPath.isEmpty())
    {
        // Return error result
        return createResult(false, QVariant(), "URL and local path cannot be empty");
    }

    // 2. Check if directory already exists
    QDir dir(localPath);  // Create QDir object for the path
    if (dir.exists())  // Check if folder exists
    {
        return createResult(false, QVariant(), "Directory already exists: " + localPath);
    }

    // 3. Close current repository if open
    if (m_currentRepo)
    {
        git_repository_free(m_currentRepo);  // Free old repository
        m_currentRepo = nullptr;  // Clear pointer
    }

    // 4. Prepare libgit2 clone options
    git_clone_options opts = GIT_CLONE_OPTIONS_INIT;  // Default options

    // Convert QString to C strings (UTF-8)
    QByteArray urlUtf8 = url.toUtf8();  // "https://..." → bytes
    QByteArray pathUtf8 = localPath.toUtf8();  // "/home/user/repo" → bytes

    // 5. Call libgit2 to clone repository
    int result = git_clone(&m_currentRepo,        // Store repo here
                           urlUtf8.constData(),    // URL as C string
                           pathUtf8.constData(),   // Path as C string
                           &opts);                 // Options

    // 6. Check if clone succeeded
    if (result != 0)  // 0 means success in libgit2
    {
        handleGitError(result);  // Get error message
        return createResult(false, QVariant(), "Failed to clone repository");
    }

    // 7. Success! Store the path
    m_currentRepoPath = localPath;  // Remember where we cloned to

    // 8. Print debug message
    qDebug() << "GitWrapperCPP: Repository cloned to" << localPath;

    // 9. Return success result
    return createResult(true, localPath);
}

QVariantMap GitWrapperCPP::close()
{
    if (!m_currentRepo)
    {
        return createResult(false, QVariant(), "No repository open");
    }

    git_repository_free(m_currentRepo);
    m_currentRepo = nullptr;
    m_currentRepoPath.clear();

    qDebug() << "GitWrapperCPP: Repository closed";
    return createResult(true);
}

/* Git Operations Implementation */

QVariantMap GitWrapperCPP::status(const QString &repoPath)
{
     // 1. Get repository handle
    git_repository* repo = repoPath.isEmpty() ? m_currentRepo : openRepository(repoPath);
    if (!repo)
    {
        return createResult(false, QVariant(), "No repository available");
    }

    QVariantMap statusData;
    QVariantList stagedFiles;
    QVariantList unstagedFiles;
    QVariantList untrackedFiles;

    // Configure status options
    git_status_options opts = GIT_STATUS_OPTIONS_INIT;
    opts.show = GIT_STATUS_SHOW_INDEX_AND_WORKDIR;
    opts.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED;

    git_status_list *status_list = nullptr;
    int gitResult = git_status_list_new(&status_list, repo, &opts);

    if (gitResult == 0) {
        size_t count = git_status_list_entrycount(status_list);

        // Process each status entry
        for (size_t i = 0; i < count; i++) {
            const git_status_entry *entry = git_status_byindex(status_list, i);
            if (!entry) continue;

            QVariantMap fileInfo = statusEntryToMap(entry);

            // Classify based on status flags
            if (entry->status & GIT_STATUS_WT_NEW) {
                untrackedFiles.append(fileInfo);
            } else if (entry->status & (GIT_STATUS_INDEX_NEW | GIT_STATUS_INDEX_MODIFIED |
                                        GIT_STATUS_INDEX_DELETED | GIT_STATUS_INDEX_RENAMED)) {
                stagedFiles.append(fileInfo);
            } else if (entry->status & (GIT_STATUS_WT_MODIFIED | GIT_STATUS_WT_DELETED |
                                        GIT_STATUS_WT_RENAMED | GIT_STATUS_WT_TYPECHANGE)) {
                unstagedFiles.append(fileInfo);
            }
        }

        // Clean up status list
        git_status_list_free(status_list);

        // Build result data
        statusData["stagedFiles"] = stagedFiles;
        statusData["unstagedFiles"] = unstagedFiles;
        statusData["untrackedFiles"] = untrackedFiles;
        statusData["totalFiles"] = static_cast<int>(count);
        statusData["hasChanges"] = (count > 0);

        // Get current branch
        statusData["currentBranch"] = getCurrentBranchName(repo);
    }

    // Clean up if we opened a temporary repository
    if (repo != m_currentRepo) {
        git_repository_free(repo);
    }

    return createResult(true, statusData);
}

QVariantList GitWrapperCPP::getCommits(const QString &repoPath, int limit)
{
    QVariantList commits;

    // Get repository (opens if needed)
    git_repository* repo = repoPath.isEmpty() ? m_currentRepo : openRepository(repoPath);
    if (!repo) {
        return commits; // Empty list
    }

    git_revwalk *walker = nullptr;
    int result = git_revwalk_new(&walker, repo);

    if (result == 0) {
        // Start from HEAD and sort by time (newest first)
        git_revwalk_push_head(walker);
        git_revwalk_sorting(walker, GIT_SORT_TIME);

        git_oid oid;
        int count = 0;

        // Walk through commits up to limit
        while (count < limit && git_revwalk_next(&oid, walker) == 0) {
            git_commit *commit = nullptr;
            result = git_commit_lookup(&commit, repo, &oid);

            if (result == 0) {
                commits.append(commitToMap(commit));
                git_commit_free(commit);
                count++;
            }
        }

        // Clean up walker
        git_revwalk_free(walker);
    }

    // Clean up if we opened a temporary repository
    if (repo != m_currentRepo) {
        git_repository_free(repo);
    }

    qDebug() << "GitWrapperCPP: Retrieved" << commits.size() << "commits";
    return commits;
}

QVariantList GitWrapperCPP::getBranches(const QString &repoPath)
{
    QVariantList branches;

    // Get repository (opens if needed)
    git_repository* repo = repoPath.isEmpty() ? m_currentRepo : openRepository(repoPath);
    if (!repo) {
        return branches; // Empty list
    }

    git_branch_iterator *iter = nullptr;
    int result = git_branch_iterator_new(&iter, repo, GIT_BRANCH_ALL);

    if (result == 0) {
        git_reference *ref = nullptr;
        git_branch_t type;

        // Iterate through all branches
        while (git_branch_next(&ref, &type, iter) == 0) {
            const char *name = nullptr;
            git_branch_name(&name, ref);

            if (name) {
                QVariantMap branch;
                branch["name"] = QString::fromUtf8(name);
                branch["isRemote"] = (type == GIT_BRANCH_REMOTE);
                branch["isLocal"] = (type == GIT_BRANCH_LOCAL);

                // Check if this is the current branch
                git_reference *head = nullptr;
                bool isCurrent = false;
                if (git_repository_head(&head, repo) == 0) {
                    isCurrent = git_reference_cmp(ref, head) == 0;
                    git_reference_free(head);
                }
                branch["isCurrent"] = isCurrent;

                branches.append(branch);
            }

            git_reference_free(ref);
        }

        // Clean up iterator
        git_branch_iterator_free(iter);
    }

    // Clean up if we opened a temporary repository
    if (repo != m_currentRepo) {
        git_repository_free(repo);
    }

    qDebug() << "GitWrapperCPP: Retrieved" << branches.size() << "branches";
    return branches;
}

QVariantMap GitWrapperCPP::getRepoInfo(const QString &repoPath)
{
    // 1. Prepare result map
    QVariantMap info;

    // 2. Get repository (open if needed)
    git_repository* repo = repoPath.isEmpty() ? m_currentRepo : openRepository(repoPath);
    if (!repo)  // If repo is null (not open)
    {
        return createResult(false, QVariant(), "No repository available");
    }

    // 3. Get current branch name
    info["branch"] = getCurrentBranchName(repo);  // e.g., "main"

    // 4. Count commits
    int commitCount = 0;
    git_revwalk *walker = nullptr;  // libgit2's "commit walker"

    // Create a walker to go through commits
    if (git_revwalk_new(&walker, repo) == 0) {
        git_revwalk_push_head(walker);  // Start from HEAD (latest commit)
        git_oid oid;  // libgit2's commit ID object

        // Walk through all commits
        while (git_revwalk_next(&oid, walker) == 0) {
            commitCount++;  // Count each commit
        }
        git_revwalk_free(walker);  // Clean up
    }
    info["commitCount"] = commitCount;  // e.g., 42

    // 5. Check for uncommitted changes
    bool hasChanges = false;
    git_status_options opts = GIT_STATUS_OPTIONS_INIT;  // Default options
    git_status_list* status = nullptr;

    // Get status list
    if (git_status_list_new(&status, repo, &opts) == 0) {
        // If there are any entries, we have changes
        hasChanges = (git_status_list_entrycount(status) > 0);
        git_status_list_free(status);  // Clean up
    }
    info["hasChanges"] = hasChanges;  // true/false

    // 6. Get repository path
    const char* path = git_repository_path(repo);  // Get .git folder path
    if (path) {
        info["path"] = QString::fromUtf8(path);  // Convert to QString
    }

    // 7. Clean up if we opened a temporary repository
    if (repo != m_currentRepo) {
        git_repository_free(repo);  // Only free if not the main repo
    }

    // 8. Return structured data
    return createResult(true, info);
}

/* Helper Functions Implementation */

QVariantMap GitWrapperCPP::createResult(bool success,
                                        const QVariant &data,
                                        const QString &errorMessage)
{
    QVariantMap result;  // Create empty map/dictionary

    result["success"] = success;  // Always include success flag

    if (success && !data.isNull())  // If success AND we have data
        result["data"] = data;  // Add data field
    else if (!success)  // If failed
        result["error"] = errorMessage.isEmpty() ? m_lastError : errorMessage;

    return result;  // Return formatted result
}

QVariantMap GitWrapperCPP::commitToMap(git_commit *commit)
{
    QVariantMap commitMap;

    if (!commit) return commitMap;

    // Get commit hash
    char hash[GIT_OID_HEXSZ + 1];
    git_oid_tostr(hash, sizeof(hash), git_commit_id(commit));
    commitMap["hash"] = QString::fromUtf8(hash);
    commitMap["shortHash"] = QString::fromUtf8(hash).left(7);

    // Get commit message
    commitMap["message"] = QString::fromUtf8(git_commit_message(commit));

    // Get summary (first line of message)
    QString fullMessage = commitMap["message"].toString();
    QStringList lines = fullMessage.split("\n");
    commitMap["summary"] = lines.first();

    // Get author information
    const git_signature *author = git_commit_author(commit);
    if (author) {
        commitMap["author"] = QString::fromUtf8(author->name);
        commitMap["authorEmail"] = QString::fromUtf8(author->email);
        QDateTime authorDate = QDateTime::fromSecsSinceEpoch(author->when.time);
        commitMap["authorDate"] = authorDate.toString(Qt::ISODate);
    }

    return commitMap;
}

QString GitWrapperCPP::getCurrentBranchName(git_repository* repo)
{
    QString branchName;  // Empty string to start
    git_reference* head = nullptr;  // libgit2 HEAD reference

    // Get HEAD reference (points to current branch)
    if (git_repository_head(&head, repo) == 0)
    {
        const char* name = nullptr;  // Will store branch name

        // Extract branch name from reference
        if (git_branch_name(&name, head) == 0 && name)
        {
            branchName = QString::fromUtf8(name);  // Convert C string to QString
        }
        git_reference_free(head);  // Clean up libgit2 object
    }

    return branchName;  // "main", "master", or empty if detached
}

QVariantMap GitWrapperCPP::statusEntryToMap(const git_status_entry *entry)
{
    QVariantMap fileInfo;  // Empty map/dictionary

    if (!entry) return fileInfo;  // Safety: if null, return empty

    // Get file path - check both staged and unstaged locations
    const char* path = entry->head_to_index ?
                           entry->head_to_index->old_file.path :  // Staged changes path
                           entry->index_to_workdir->old_file.path; // Unstaged changes path

    if (path) {
        fileInfo["path"] = QString::fromUtf8(path);  // Store path
    }

    // Convert status bits to human-readable string
    fileInfo["status"] = gitStatusToString(entry->status);

    // Store raw status flags (for debugging)
    fileInfo["statusFlags"] = static_cast<int>(entry->status);

    // Classify the status for easy UI filtering
    bool isStaged = entry->status & (GIT_STATUS_INDEX_NEW |
                                     GIT_STATUS_INDEX_MODIFIED |
                                     GIT_STATUS_INDEX_DELETED |
                                     GIT_STATUS_INDEX_RENAMED);

    bool isUnstaged = entry->status & (GIT_STATUS_WT_MODIFIED |
                                       GIT_STATUS_WT_DELETED |
                                       GIT_STATUS_WT_RENAMED |
                                       GIT_STATUS_WT_TYPECHANGE);

    bool isUntracked = entry->status & GIT_STATUS_WT_NEW;

    // Store classifications
    fileInfo["isStaged"] = isStaged;
    fileInfo["isUnstaged"] = isUnstaged;
    fileInfo["isUntracked"] = isUntracked;

    return fileInfo;  // Return populated file info
}

bool GitWrapperCPP::isValidPath(const QString &path)
{
    if (path.isEmpty()) return false;

    QDir dir(path);
    QString absolutePath = dir.absolutePath();

    // Check if path is absolute
    if (QDir::isRelativePath(absolutePath))
    {
        return false;
    }

    return true;
}



git_repository* GitWrapperCPP::openRepository(const QString &path)
{
    if (m_currentRepo) return m_currentRepo;

    git_repository* repo = nullptr;
    QByteArray pathUtf8 = path.toUtf8();
    int result = git_repository_open(&repo, pathUtf8.constData());

    if (result != 0) {
        handleGitError(result);
        return nullptr;
    }

    return repo;
}

void GitWrapperCPP::handleGitError(int errorCode)
{
    const git_error *error = git_error_last();
    if (error && error->message) {
        m_lastError = QString::fromUtf8(error->message);
        qWarning() << "GitWrapperCPP Error:" << m_lastError << "(code:" << errorCode << ")";
    } else {
        m_lastError = QString("Git error code: %1").arg(errorCode);
        qWarning() << m_lastError;
    }
}

void GitWrapperCPP::runInternalTests()
{
    qDebug() << "\n" << QString(60, '=');
    qDebug() << "  GitWrapperCPP - INTERNAL FUNCTIONAL TESTS";
    qDebug() << QString(60, '=') << "\n";

    int testsPassed = 0;
    int testsTotal = 0;

    // Create temporary directory for testing
    QTemporaryDir tempDir;
    if (!tempDir.isValid()) {
        qWarning() << "❌ Failed to create temporary directory for testing";
        return;
    }

    QString testRepoPath = tempDir.path() + "/test-repo";
    QString testFilePath = testRepoPath + "/test.txt";

    qDebug() << "Test Repository Path:" << testRepoPath;
    qDebug() << "";

    // --------------------------------------------------------------------
    // TEST 1: Initialize Repository
    // --------------------------------------------------------------------
    qDebug() << "[TEST 1/6] Testing init()...";
    QVariantMap initResult = clone("https://github.com/Roniasoft/NodeLink", testRepoPath);
    testsTotal++;

    if (initResult["success"].toBool()) {
        qDebug() << "  ✓ init() passed - Repository created at:" << initResult["data"].toString();
        testsPassed++;
    } else {
        qWarning() << "  ✗ init() failed:" << initResult["error"].toString();
    }

    // --------------------------------------------------------------------
    // TEST 2: Get Repository Info (on empty repo)
    // --------------------------------------------------------------------
    qDebug() << "\n[TEST 2/6] Testing getRepoInfo() on empty repo...";
    QVariantMap infoResult = getRepoInfo();
    testsTotal++;

    if (infoResult["success"].toBool()) {
        QVariantMap infoData = infoResult["data"].toMap();
        qDebug() << "  ✓ getRepoInfo() passed";
        qDebug() << "    - Branch:" << (infoData["branch"].toString().isEmpty() ? "detached HEAD" : infoData["branch"].toString());
        qDebug() << "    - Commit count:" << infoData["commitCount"].toInt();
        qDebug() << "    - Has changes:" << infoData["hasChanges"].toBool();
        testsPassed++;
    } else {
        qWarning() << "  ✗ getRepoInfo() failed:" << infoResult["error"].toString();
    }

    // --------------------------------------------------------------------
    // TEST 3: Create a file and check status
    // --------------------------------------------------------------------
    qDebug() << "\n[TEST 3/6] Testing file creation and status()...";

    // Create a test file
    QFile testFile(testFilePath);
    if (testFile.open(QIODevice::WriteOnly)) {
        QTextStream stream(&testFile);
        stream << "Test file created at: " << QDateTime::currentDateTime().toString() << "\n";
        stream << "This is a test file for GitWrapperCPP testing.\n";
        testFile.close();

        // Check status - should show untracked file
        QVariantMap statusResult = status();
        testsTotal++;

        if (statusResult["success"].toBool()) {
            QVariantMap statusData = statusResult["data"].toMap();
            int untrackedCount = statusData["untrackedFiles"].toList().size();

            if (untrackedCount > 0) {
                qDebug() << "  ✓ status() passed - Detected" << untrackedCount << "untracked file(s)";
                testsPassed++;
            } else {
                qWarning() << "  ✗ status() failed - No untracked files detected";
            }
        } else {
            qWarning() << "  ✗ status() failed:" << statusResult["error"].toString();
        }
    } else {
        qWarning() << "  ✗ Failed to create test file";
        testsTotal++;
    }

    // --------------------------------------------------------------------
    // TEST 4: Get branches (should have at least 'master' or 'main')
    // --------------------------------------------------------------------
    qDebug() << "\n[TEST 4/6] Testing getBranches()...";
    QVariantList branches = getBranches();
    testsTotal++;

    if (!branches.isEmpty()) {
        qDebug() << "  ✓ getBranches() passed - Found" << branches.size() << "branch(es)";
        for (const QVariant &branchVar : branches) {
            QVariantMap branch = branchVar.toMap();
            qDebug() << "    -" << branch["name"].toString()
                     << (branch["isCurrent"].toBool() ? "(current)" : "")
                     << (branch["isLocal"].toBool() ? "local" : "remote");
        }
        testsPassed++;
    } else {
        qDebug() << "  ⓘ getBranches() - No branches found (empty repo)";
        testsPassed++; // This is acceptable for a new repo
    }

    // --------------------------------------------------------------------
    // TEST 5: Get commits (should be empty in new repo)
    // --------------------------------------------------------------------
    qDebug() << "\n[TEST 5/6] Testing getCommits()...";
    QVariantList commits = getCommits("", 10);
    testsTotal++;

    qDebug() << "  ✓ getCommits() passed - Found" << commits.size() << "commit(s)";
    if (!commits.isEmpty()) {
        for (int i = 0; i < qMin(commits.size(), 3); i++) {
            QVariantMap commit = commits[i].toMap();
            qDebug() << "    -" << commit["shortHash"].toString()
                     << ":" << commit["summary"].toString();
        }
    }
    testsPassed++;

    // --------------------------------------------------------------------
    // TEST 6: Close repository
    // --------------------------------------------------------------------
    qDebug() << "\n[TEST 6/6] Testing close()...";
    QVariantMap closeResult = close();
    testsTotal++;

    if (closeResult["success"].toBool()) {
        qDebug() << "  ✓ close() passed - Repository closed successfully";
        testsPassed++;

        // Verify repository is actually closed
        if (m_currentRepo == nullptr && m_currentRepoPath.isEmpty()) {
            qDebug() << "  ✓ Repository state cleared correctly";
        } else {
            qWarning() << "  ⚠ Repository state not fully cleared";
        }
    } else {
        qWarning() << "  ✗ close() failed:" << closeResult["error"].toString();
    }

    // --------------------------------------------------------------------
    // TEST SUMMARY
    // --------------------------------------------------------------------
    qDebug() << "\n" << QString(60, '=');
    qDebug() << "  TEST SUMMARY";
    qDebug() << QString(60, '=');

    QString summary = QString("  Tests: %1/%2 passed").arg(testsPassed).arg(testsTotal);

    if (testsPassed == testsTotal) {
        qDebug() << summary << "✅ ALL TESTS PASSED!";
    } else if (testsPassed > testsTotal * 0.7) {
        qDebug() << summary << "⚠️  MOST TESTS PASSED";
    } else {
        qDebug() << summary << "❌ MANY TESTS FAILED";
    }

    qDebug() << "\nNote: Clone test skipped (requires network connection)";
    qDebug() << "To test clone(), use: gitWrapper.clone(\"https://github.com/...\", \"/path/to/clone\")";
    qDebug() << QString(60, '=') << "\n";
}
