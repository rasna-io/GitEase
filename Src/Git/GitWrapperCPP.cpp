#include "GitWrapperCPP.h"

#include <string.h>

#include <QDebug>
#include <QDir>
#include <QDateTime>
#include <QProcess>
#include <QStandardPaths>
#include <QTemporaryDir>
#include <QFuture>
#include <qtconcurrentrun.h>
#include <QFutureWatcher>
#include <QRegularExpression>

#include <git2/commit.h>
#include <git2/signature.h>
#include <git2/tree.h>
#include <git2/index.h>
#include <git2/revparse.h>
#include <git2/branch.h>
#include <git2/refs.h>
#include <git2/object.h>

// Helper function to convert git status to string
QString gitStatusToString(git_status_t status)
{
    if (status & GIT_STATUS_WT_NEW) return "untracked";                 //working directory
    if (status & GIT_STATUS_WT_MODIFIED) return "modified";             //Tracked file
    if (status & GIT_STATUS_WT_DELETED) return "deleted";               //File removed from disk but Still tracked in Git
    if (status & GIT_STATUS_WT_RENAMED) return "renamed";               //Rename detected in working tree
    if (status & GIT_STATUS_WT_TYPECHANGE) return "typechange";         //File type changed
    if (status & GIT_STATUS_INDEX_NEW) return "staged_new";             //File added to index
    if (status & GIT_STATUS_INDEX_MODIFIED) return "staged_modified";   //Tracked file - Changes are staged
    if (status & GIT_STATUS_INDEX_DELETED) return "staged_deleted";     //File deletion staged
    if (status & GIT_STATUS_INDEX_RENAMED) return "staged_renamed";
    return "unknown";
}

GitWrapperCPP::GitWrapperCPP(QObject *parent)
    : QObject(parent)
{
    git_libgit2_init();
    qDebug() << "GitWrapperCPP: libgit2 initialized";

    // unitTest();
    // unitTestForGitWorkflow();
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
    qDebug() << "GitWrapperCPP: clone requested:" << localPath;

    if (url.isEmpty() || localPath.isEmpty())
        return createResult(false, QVariant(), "URL and local path cannot be empty");

    QDir dir(localPath);
    if (dir.exists())
        return createResult(false, QVariant(), "Directory already exists: " + localPath);

    const QString safeUrl = url;
    const QString safePath = localPath;

    auto future = QtConcurrent::run([=]() -> QVariantMap {

        struct Payload { GitWrapperCPP *self; } payload { this };

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

    return createResult(true, QVariant(), "Clone started");
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
    getBranches();
    getRepoInfo();

    return createResult(true);
}

/* Git Operations Implementation */

QVariantMap GitWrapperCPP::status()
{
    // 1. Get repository handle - SIMPLIFIED
    if (!m_currentRepo)
        return createResult(false, QVariant(), "No repository available. Please open a repository first.");


    QVariantMap statusData;
    QVariantList stagedFiles;
    QVariantList unstagedFiles;
    QVariantList untrackedFiles;

    // Configure status options
    git_status_options opts = GIT_STATUS_OPTIONS_INIT;
    opts.show = GIT_STATUS_SHOW_INDEX_AND_WORKDIR;      //Index vs HEAD
    opts.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED;

    git_status_list *status_list = nullptr;
    int gitResult = git_status_list_new(&status_list, m_currentRepo, &opts);

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
        statusData["currentBranch"] = getCurrentBranchName(m_currentRepo);
    }

    return createResult(true, statusData);
}

QVariantList GitWrapperCPP::getCommits(const QString &repoPath, int limit, int offset)
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
        git_revwalk_sorting(walker, GIT_SORT_TOPOLOGICAL | GIT_SORT_TIME);

        // Push *all* branch tips so we get commits reachable from any branch.
        {
            git_branch_iterator* iter = nullptr;
            if (git_branch_iterator_new(&iter, repo, GIT_BRANCH_ALL) == 0) {
                git_reference* ref = nullptr;
                git_branch_t type;

                while (git_branch_next(&ref, &type, iter) == 0) {
                    const git_oid* oid = git_reference_target(ref);
                    if (oid) {
                        git_revwalk_push(walker, oid);
                    } else {
                        // Symbolic ref, peel to commit
                        git_object* target = nullptr;
                        if (git_reference_peel(&target, ref, GIT_OBJECT_COMMIT) == 0 && target) {
                            const git_oid* peeledOid = git_object_id(target);
                            if (peeledOid)
                                git_revwalk_push(walker, peeledOid);
                            git_object_free(target);
                        }
                    }

                    git_reference_free(ref);
                }

                git_branch_iterator_free(iter);
            }
        }

        // Also push HEAD as a fallback (detached HEAD or repos without branches)
        git_revwalk_push_head(walker);

        git_oid oid;
        int count = 0;

        // Skip `offset` commits (paging)
        int skipped = 0;
        while (skipped < offset && git_revwalk_next(&oid, walker) == 0) {
            skipped++;
        }

        // Walk through commits up to limit
        while (count < limit && git_revwalk_next(&oid, walker) == 0) {
            git_commit *commit = nullptr;
            result = git_commit_lookup(&commit, repo, &oid);

            if (result == 0 && commit) {
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
        return branches;
    }

    git_reference *head = nullptr;
    git_repository_head(&head, repo);

    git_branch_iterator *iter = nullptr;

    if (git_branch_iterator_new(&iter, repo, GIT_BRANCH_ALL) == 0) {
        git_reference *ref = nullptr;
        git_branch_t type;

        // Iterate through all branches
        while (git_branch_next(&ref, &type, iter) == 0) {
            const char *name = nullptr;

            if (git_branch_name(&name, ref) == GIT_OK && name) {
                QVariantMap branch;
                branch["name"] = QString::fromUtf8(name);
                branch["isRemote"] = (type == GIT_BRANCH_REMOTE);
                branch["isLocal"] = (type == GIT_BRANCH_LOCAL);

                // Branch tip commit hash (needed to map branches to commits in QML)
                QString targetHash;
                const git_oid* oid = git_reference_target(ref);
                if (!oid) {
                    git_object* target = nullptr;
                    if (git_reference_peel(&target, ref, GIT_OBJECT_COMMIT) == 0 && target) {
                        oid = git_object_id(target);
                        git_object_free(target);
                    }
                }
                if (oid) {
                    char hash[GIT_OID_HEXSZ + 1];
                    git_oid_tostr(hash, sizeof(hash), oid);
                    targetHash = QString::fromUtf8(hash);
                }
                branch["targetHash"] = targetHash;

                // Check if this is the current branch
                int isHead = git_branch_is_head(ref);
                bool isCurrent = (isHead == 1);
                branch["isCurrent"] = isCurrent;

                branches.append(branch);
            }

            git_reference_free(ref);
        }

        // Clean up iterator
        git_branch_iterator_free(iter);
    }

    if (head)
    {
        git_reference_free(head);
    }

    // Clean up if we opened a temporary repository
    if (repo != m_currentRepo) {
        git_repository_free(repo);
    }

    qDebug() << "GitWrapperCPP: Retrieved" << branches.size() << "branches";
    return branches;
}

bool GitWrapperCPP::createBranch(const QString &branchName, const QString &repoPath)
{
    git_repository* repo = repoPath.isEmpty() ? m_currentRepo : openRepository(repoPath);
    if (!repo) {
        qWarning() << "GitWrapperCPP: Repository not found for creating branch";
        return false;
    }

    bool success = false;
    git_reference* new_branch_ref = nullptr;
    git_object* target_object = nullptr;

    if (git_revparse_single(&target_object, repo, "HEAD") == 0)
    {
        int error = git_branch_create(
            &new_branch_ref,
            repo,
            branchName.toUtf8(),
            (const git_commit*)target_object,
            0
        );

        if (error == 0) {
            qDebug() << "GitWrapperCPP: Branch created successfully:" << branchName;
            success = true;
        } else {
            const git_error* e = git_error_last();
            qWarning() << "GitWrapperCPP: Failed to create branch. Error:" << (e ? e->message : "Unknown");
        }
    }

    if (target_object) {
        git_object_free(target_object);
    }
    if (new_branch_ref) {
        git_reference_free(new_branch_ref);
    }
    if (repo != m_currentRepo) {
        git_repository_free(repo);
    }

    return success;
}

bool GitWrapperCPP::deleteBranch(const QString &branchName, const QString &repoPath)
{
    git_repository* repo = repoPath.isEmpty() ? m_currentRepo : openRepository(repoPath);

    if (!repo) {
        qWarning() << "GitWrapperCPP: Cannot delete branch, repository not found.";
        return false;
    }

    git_reference* branchRef = nullptr;
    bool success = false;

    int error = git_branch_lookup(&branchRef, repo, branchName.toUtf8().constData(), GIT_BRANCH_LOCAL);

    if (error == 0) {
        error = git_branch_delete(branchRef);

        if (error == 0) {
            qDebug() << "GitWrapperCPP: Successfully deleted branch:" << branchName;
            success = true;
        } else {
            const git_error* e = git_error_last();
            qWarning() << "GitWrapperCPP: Failed to delete branch. Error:" << (e ? e->message : "Unknown");
        }
    } else {
        qWarning() << "GitWrapperCPP: Branch not found:" << branchName;
    }

    if (branchRef) {
        git_reference_free(branchRef);
    }

    if (repo != m_currentRepo) {
        git_repository_free(repo);
    }

    return success;
}

bool GitWrapperCPP::checkoutBranch(const QString &branchName, const QString &repoPath)
{
    git_repository* repo = repoPath.isEmpty() ? m_currentRepo : openRepository(repoPath);
    if (!repo) {
        qWarning() << "GitWrapperCPP: Repository not found for checkout.";
        return false;
    }

    git_reference* targetRef = nullptr;
    git_object* targetCommit = nullptr;
    bool success = false;

    int error = git_branch_lookup(&targetRef, repo, branchName.toUtf8().constData(), GIT_BRANCH_LOCAL);

    if (error == 0) {
        error = git_reference_peel(&targetCommit, targetRef, GIT_OBJ_COMMIT);

        if (error == 0) {
            git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
            opts.checkout_strategy = GIT_CHECKOUT_SAFE | GIT_CHECKOUT_RECREATE_MISSING;

            error = git_checkout_tree(repo, targetCommit, &opts);

            if (error == 0) {
                error = git_repository_set_head(repo, git_reference_name(targetRef));

                if (error == 0) {
                    qDebug() << "GitWrapperCPP: Successfully checked out to" << branchName;
                    success = true;
                }
            }
        }
    }

    if (!success) {
        const git_error* e = git_error_last();
        qWarning() << "GitWrapperCPP: Checkout failed." << (e ? e->message : "Unknown error");
    }

    if (targetCommit) git_object_free(targetCommit);
    if (targetRef) git_reference_free(targetRef);

    if (repo != m_currentRepo) {
        git_repository_free(repo);
    }

    return success;
}

bool GitWrapperCPP::renameBranch(const QString &oldName, const QString &newName)
{
    if (!m_currentRepo) return false;

    git_reference* branchRef = nullptr;
    git_reference* newRef = nullptr;
    bool success = false;

    int error = git_branch_lookup(&branchRef, m_currentRepo, oldName.toUtf8().constData(), GIT_BRANCH_LOCAL);

    if (error == 0) {
        error = git_branch_move(&newRef, branchRef, newName.toUtf8().constData(), 0);

        if (error == 0) {
            qDebug() << "GitWrapperCPP: Renamed" << oldName << "to" << newName;
            success = true;
        } else {
            const git_error* e = git_error_last();
            qWarning() << "GitWrapperCPP: Rename failed:" << (e ? e->message : "Unknown");
        }
    }

    if (newRef) git_reference_free(newRef);
    if (branchRef) git_reference_free(branchRef);

    return success;
}

QString GitWrapperCPP::getUpstreamName(const QString &localBranchName)
{
    if (!m_currentRepo) return "";

    git_reference* localRef = nullptr;
    git_reference* upstreamRef = nullptr;
    QString result = "";

    int error = git_branch_lookup(&localRef, m_currentRepo, localBranchName.toUtf8().constData(), GIT_BRANCH_LOCAL);

    if (error == 0) {
        if (git_branch_upstream(&upstreamRef, localRef) == 0) {
            const char* name = nullptr;
            if (git_branch_name(&name, upstreamRef) == 0 && name) {
                result = QString::fromUtf8(name);
            }
        }
    }

    if (upstreamRef) git_reference_free(upstreamRef);
    if (localRef) git_reference_free(localRef);

    return result;
}

QVariantMap GitWrapperCPP::getRepoInfo(const QString &repoPath)
{
    // Step 1: Check if repository is open
    if (!m_currentRepo) {
        return createResult(false, QVariant(), "No repository available. Please open a repository first.");
    }

    // Step 2: Prepare result map and use m_currentRepo
    QVariantMap info;

    // Get current branch name
    info["branch"] = getCurrentBranchName(m_currentRepo);  // e.g., "main"

    // Count commits
    int commitCount = 0;
    git_revwalk *walker = nullptr;

    if (git_revwalk_new(&walker, m_currentRepo) == 0) {
        git_revwalk_push_head(walker);
        git_oid oid;

        while (git_revwalk_next(&oid, walker) == 0) {
            commitCount++;
        }
        git_revwalk_free(walker);
    }
    info["commitCount"] = commitCount;

    // Check for uncommitted changes
    bool hasChanges = false;
    git_status_options opts = GIT_STATUS_OPTIONS_INIT;
    git_status_list* status = nullptr;

    if (git_status_list_new(&status, m_currentRepo, &opts) == 0) {
        hasChanges = (git_status_list_entrycount(status) > 0);
        git_status_list_free(status);
    }
    info["hasChanges"] = hasChanges;

    // Get repository path
    const char* path = git_repository_path(m_currentRepo);
    if (path) {
        info["path"] = QString::fromUtf8(path);
    }

    // Step 3: Return result
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
        result["data"] = data;
    else if (!success)  // If failed
        result["error"] = errorMessage.isEmpty() ? m_lastError : errorMessage;

    return result;
}

QVariantMap GitWrapperCPP::commitToMap(git_commit *commit)
{
    QVariantMap commitMap;

    if (!commit) return commitMap;

    // Get commit hash
    char hash[GIT_OID_HEXSZ + 1];   //e83c5163316f89bfbde7d9ab23ca2e25604af290\0
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
    if (!repo)
    {
        return "";
    }

    QString branchName;  // Empty string to start
    git_reference* head = nullptr;  // libgit2 HEAD reference

    int error = git_repository_head(&head, repo);

    // Get HEAD reference (points to current branch)
    if (error == GIT_OK)
    {
        const char* name = nullptr;  // Will store branch name

        // Extract branch name from reference
        if (git_branch_name(&name, head) == GIT_OK && name)
        {
            branchName = QString::fromUtf8(name);  // Convert C string to QString
        }
        git_reference_free(head);  // Clean up libgit2 object
    } else if (error == GIT_ENOTFOUND)
    {
        branchName = "initial/no-commits";
    } else
    {
        branchName = "Detached HEAD";
    }

    return branchName;  // "main", "master", or Detached HEAD if detached
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

// Add to the helper functions section
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

QString GitWrapperCPP::validateCommitMessage(const QString &message)
{
    if (message.trimmed().isEmpty())
        return "Commit message cannot be empty";

    // Check for common commit message issues
    QRegularExpression trailingWhitespace("\\s+$");
    if (trailingWhitespace.match(message).hasMatch())
        return "Commit message has trailing whitespace";

    return QString();
}

QVariantMap GitWrapperCPP::createSignatureMap(const git_signature *sig)
{
    QVariantMap signature;
    if (sig) {
        signature["name"] = QString::fromUtf8(sig->name);
        signature["email"] = QString::fromUtf8(sig->email);
        signature["timestamp"] = QDateTime::fromSecsSinceEpoch(sig->when.time);
        signature["offset"] = sig->when.offset;
    }
    return signature;
}

QVariantMap GitWrapperCPP::commit(const QString& message,
                                  bool amend,
                                  bool allowEmpty)
{
    QString validationError = validateCommitInputs(m_currentRepo, message, allowEmpty);
    if (!validationError.isEmpty()) {
        return createResult(false, QVariant(), validationError);
    }

    git_signature* author = getAuthorSignature(m_currentRepo);
    if (!author) {
        return createResult(false, QVariant(),
                            "Failed to create author signature. Check Git config.");
    }


    git_tree* tree = createTreeFromStagedChanges(m_currentRepo);
    if (!tree) {
        return createResult(false, QVariant(),
                            "Failed to create tree from staged changes.");
    }

    ParentCommits parents = resolveParentCommits(m_currentRepo, amend);

    git_oid newCommitOid;
    int result = createCommitObject(m_currentRepo, message, tree,
                                    author, author, parents, newCommitOid);

    if (result != 0) {
        // Cleanup on failure
        cleanupCommitResources(author, tree, parents);
        handleGitError(result);

        // Provide helpful error messages
        if (result == GIT_EAMBIGUOUS)
            return createResult(false, QVariant(),
                                "Ambiguous commit state. Repository may be mid-merge/rebase.");
        else if (result == GIT_EUNBORNBRANCH)
            return createResult(false, QVariant(),
                                "Cannot amend: no commits yet (unborn branch).");


        return createResult(false, QVariant(), "Failed to create commit object.");
    }

    QVariantMap commitDetails = getCommitDetails(m_currentRepo, newCommitOid);
    commitDetails["amend"] = amend;

    cleanupCommitResources(author, tree, parents);


    qDebug() << "GitWrapperCPP: Created commit"
             << (amend ? "(amend)" : "")
             << commitDetails["shortHash"].toString()
             << "-" << commitDetails["summary"].toString();

    return createResult(true, commitDetails);
}

QString GitWrapperCPP::validateCommitInputs(git_repository* repo,
                                            const QString& message,
                                            bool allowEmpty)
{
    if (!repo)
        return QString("No repository available. Please open a repository first.");

    QString msgError = validateCommitMessage(message);
    if (!msgError.isEmpty())
        return msgError;

    if (!allowEmpty && !hasStagedChanges())
        return QString("No staged changes to commit. Please stage files first.");

    return QString();
}

git_signature* GitWrapperCPP::getAuthorSignature(git_repository* repo)
{
    git_signature* signature = nullptr;

    // Try to get default signature from Git config
    int result = git_signature_default(&signature, repo);

    if (result != 0) {
        handleGitError(result);
        return nullptr;
    }

    return signature;
}

git_tree* GitWrapperCPP::createTreeFromStagedChanges(git_repository* repo)
{
    git_index* index = nullptr;

    int result = git_repository_index(&index, repo);
    if (result != 0) {
        handleGitError(result);
        return nullptr;
    }

    // creates a tree object in .git/objects/
    git_oid treeOid;
    result = git_index_write_tree(&treeOid, index);

    git_index_free(index);

    if (result != 0) {
        handleGitError(result);
        return nullptr;
    }

    // Look up the tree object we just created
    git_tree* tree = nullptr;
    result = git_tree_lookup(&tree, repo, &treeOid);
    if (result != 0) {
        handleGitError(result);
        return nullptr;
    }

    return tree;
}

ParentCommits GitWrapperCPP::resolveParentCommits(git_repository* repo, bool amend)
{
    ParentCommits parents {};

    if (amend) {
        // Get current HEAD reference
        git_reference* headRef = nullptr;
        int result = git_repository_head(&headRef, repo);

        if (result == 0 && headRef) {
            // Get the commit being amended
            result = git_reference_peel((git_object**)&parents.amendedCommit,
                                        headRef, GIT_OBJECT_COMMIT);
            git_reference_free(headRef);

            if (result == 0 && parents.amendedCommit) {
                // Copy parent commits from the commit being amended
                parents.count = git_commit_parentcount(parents.amendedCommit);

                if (parents.count > 0) {
                    parents.commits = new git_commit*[parents.count];

                    for (size_t i = 0; i < parents.count; ++i) {
                        // Note: git_commit_parent INCREMENTS refcount
                        if (git_commit_parent(&parents.commits[i],
                                              parents.amendedCommit, i) != 0) {
                            // Error handling: free what we got so far
                            for (size_t j = 0; j < i; ++j) {
                                git_commit_free(parents.commits[j]);
                            }
                            delete[] parents.commits;
                            parents.commits = nullptr;
                            parents.count = 0;
                            break;
                        }
                    }
                }
            }
        }
    } else {
        // REGULAR COMMIT CASE: Use HEAD as parent

        git_commit* headCommit = nullptr;
        int result = git_revparse_single((git_object**)&headCommit, repo, "HEAD");

        if (result == 0 && headCommit) {
            // Normal commit: HEAD is the parent
            parents.count = 1;
            parents.commits = new git_commit*[1];
            parents.commits[0] = headCommit;
        } else {
            // No HEAD = initial commit (0 parents)
            parents.count = 0;
        }
    }

    return parents;
}

int GitWrapperCPP::createCommitObject(git_repository* repo,
                                      const QString& message,
                                      git_tree* tree,
                                      git_signature* author,
                                      git_signature* committer,
                                      const ParentCommits& parents,
                                      git_oid& commitOid)
{
    // Convert message to UTF-8 (Git's internal format)
    QByteArray messageUtf8 = message.trimmed().toUtf8();

    // Create the commit object
    return git_commit_create(
        &commitOid,                         // Output: new commit's SHA-1
        repo,                               // Repository to create in
        "HEAD",                             // Update HEAD reference
        author,                             // Who wrote the changes
        committer,                          // Who committed them
        nullptr,                            // Default encoding (UTF-8)
        messageUtf8.constData(),            // Commit message
        tree,                               // Tree snapshot
        parents.count,                      // Number of parents
        (const git_commit**)parents.commits // Parent commits
        );
}

QVariantMap GitWrapperCPP::getCommitDetails(git_repository* repo, const git_oid& commitOid)
{
    QVariantMap details;

    // Look up the commit we just created
    git_commit* newCommit = nullptr;
    int result = git_commit_lookup(&newCommit, repo, &commitOid);

    if (result == 0 && newCommit) { //0 means success
        details = commitToMap(newCommit);

        // Add extra metadata
        details["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);

        git_commit_free(newCommit);
    }

    return details;
}

void GitWrapperCPP::cleanupCommitResources(git_signature* signature,
                                           git_tree* tree,
                                           ParentCommits& parents)
{
    if (signature)
        git_signature_free(signature);

    if (tree)
        git_tree_free(tree);

    freeParentCommits(parents);
}

void GitWrapperCPP::freeParentCommits(ParentCommits& parents)
{
    if (parents.commits) {
        for (size_t i = 0; i < parents.count; i++) {
            git_commit_free(parents.commits[i]);
        }
        delete[] parents.commits;
        parents.commits = nullptr;
    }
    parents.count = 0;

    // Free amended commit (if we were amending)
    if (parents.amendedCommit) {
        git_commit_free(parents.amendedCommit);
        parents.amendedCommit = nullptr;
    }
}

QVariantMap GitWrapperCPP::stageFile(const QString &filePath)
{
    if (!m_currentRepo) {
        return createResult(false, QVariant(), "No repository open");
    }

    if (filePath.isEmpty()) {
        return createResult(false, QVariant(), "File path cannot be empty");
    }

    git_index *index = nullptr;
    int result = git_repository_index(&index, m_currentRepo);
    if (result != 0) {
        handleGitError(result);
        return createResult(false, QVariant(), "Failed to get repository index");
    }

    QByteArray filePathUtf8 = filePath.toUtf8();
    result = git_index_add_bypath(index, filePathUtf8.constData());

    if (result != 0) {
        git_index_free(index);
        handleGitError(result);

        // Provide specific error messages
        if (result == GIT_ENOTFOUND) {
            return createResult(false, QVariant(),
                                QString("File not found: %1\n\nPlease check the file path exists in the working directory.").arg(filePath));
        }

        return createResult(false, QVariant(),
                            QString("Failed to stage file: %1").arg(filePath));
    }

    // Write the index to disk
    result = git_index_write(index);
    git_index_free(index);

    if (result != 0) {
        handleGitError(result);
        return createResult(false, QVariant(), "Failed to write staged changes to disk");
    }

    qDebug() << "GitWrapperCPP: Staged file:" << filePath;
    return createResult(true, filePath);
}

QVariantMap GitWrapperCPP::unstageFile(const QString &filePath)
{
    if (!m_currentRepo) {
        return createResult(false, QVariant(), "No repository open");
    }

    if (filePath.isEmpty()) {
        return createResult(false, QVariant(), "File path cannot be empty");
    }

    git_index *index = nullptr;
    int result = git_repository_index(&index, m_currentRepo);
    if (result != 0) {
        handleGitError(result);
        return createResult(false, QVariant(), "Failed to get repository index");
    }

    QByteArray filePathUtf8 = filePath.toUtf8();

    // First, check if the file is actually in the index
    const git_index_entry *entry = git_index_get_bypath(index, filePathUtf8.constData(), 0);
    if (!entry) {
        git_index_free(index);
        return createResult(false, QVariant(),
                            QString("File is not staged: %1\n\nUse status() to see staged files.").arg(filePath));
    }

    // Remove from index (unstage)
    result = git_index_remove_bypath(index, filePathUtf8.constData());

    if (result != 0) {
        git_index_free(index);
        handleGitError(result);
        return createResult(false, QVariant(),
                            QString("Failed to unstage file: %1").arg(filePath));
    }

    // Write the index to disk
    result = git_index_write(index);
    git_index_free(index);

    if (result != 0) {
        handleGitError(result);
        return createResult(false, QVariant(), "Failed to write unstaged changes to disk");
    }

    qDebug() << "GitWrapperCPP: Unstaged file:" << filePath;
    return createResult(true, filePath);
}

QVariantMap GitWrapperCPP::stageAll()
{
    if (!m_currentRepo) {
        return createResult(false, QVariant(), "No repository open");
    }

    // Get current status to find unstaged files
    QVariantMap statusResult = status();
    if (!statusResult["success"].toBool()) {
        return statusResult;
    }

    QVariantMap statusData = statusResult["data"].toMap();
    QVariantList unstagedFiles = statusData["unstagedFiles"].toList();
    QVariantList untrackedFiles = statusData["untrackedFiles"].toList();

    if (unstagedFiles.isEmpty() && untrackedFiles.isEmpty()) {
        return createResult(false, QVariant(),
                            "No unstaged changes found.\n\nUse status() to see current changes.");
    }

    git_index *index = nullptr;
    int result = git_repository_index(&index, m_currentRepo);
    if (result != 0) {
        handleGitError(result);
        return createResult(false, QVariant(), "Failed to get repository index");
    }

    int stagedCount = 0;
    QStringList stagedFiles;

    // Stage all unstaged modified/deleted files
    for (const QVariant &fileVar : unstagedFiles) {
        QVariantMap fileInfo = fileVar.toMap();
        QString filePath = fileInfo["path"].toString();

        // Don't stage untracked files through this loop
        if (fileInfo["status"].toString() == "untracked") {
            continue;
        }

        QByteArray filePathUtf8 = filePath.toUtf8();

        if (fileInfo["status"].toString() == "deleted") {
            result = git_index_remove_bypath(index, filePathUtf8.constData());
        } else {
            result = git_index_add_bypath(index, filePathUtf8.constData());
        }

        if (result == 0) {
            stagedCount++;
            stagedFiles.append(filePath);
        }
    }

    // Stage all untracked files
    for (const QVariant &fileVar : untrackedFiles) {
        QVariantMap fileInfo = fileVar.toMap();
        QString filePath = fileInfo["path"].toString();

        QByteArray filePathUtf8 = filePath.toUtf8();
        result = git_index_add_bypath(index, filePathUtf8.constData());

        if (result == 0) {
            stagedCount++;
            stagedFiles.append(filePath);
        }
    }

    // Write the index to disk
    result = git_index_write(index);
    git_index_free(index);

    if (result != 0) {
        handleGitError(result);
        return createResult(false, QVariant(), "Failed to write staged changes to disk");
    }

    QVariantMap resultData;
    resultData["count"] = stagedCount;
    resultData["files"] = stagedFiles;

    qDebug() << "GitWrapperCPP: Staged all files:" << stagedCount << "files staged";
    return createResult(true, resultData);
}

QVariantMap GitWrapperCPP::unstageAll()
{
    if (!m_currentRepo) {
        return createResult(false, QVariant(), "No repository open");
    }

    // Get current status to find staged files
    QVariantMap statusResult = status();
    if (!statusResult["success"].toBool()) {
        return statusResult;
    }

    QVariantMap statusData = statusResult["data"].toMap();
    QVariantList stagedFiles = statusData["stagedFiles"].toList();

    if (stagedFiles.isEmpty()) {
        return createResult(false, QVariant(),
                            "No staged changes found.\n\nUse status() to see current changes.");
    }

    git_index *index = nullptr;
    int result = git_repository_index(&index, m_currentRepo);
    if (result != 0) {
        handleGitError(result);
        return createResult(false, QVariant(), "Failed to get repository index");
    }

    int unstagedCount = 0;
    QStringList unstagedFiles;

    for (const QVariant &fileVar : stagedFiles) {
        QVariantMap fileInfo = fileVar.toMap();
        QString filePath = fileInfo["path"].toString();

        QByteArray filePathUtf8 = filePath.toUtf8();
        result = git_index_remove_bypath(index, filePathUtf8.constData());

        if (result == 0) {
            unstagedCount++;
            unstagedFiles.append(filePath);
        }
    }

    // Write the index to disk
    result = git_index_write(index);
    git_index_free(index);

    if (result != 0) {
        handleGitError(result);
        return createResult(false, QVariant(), "Failed to write unstaged changes to disk");
    }

    QVariantMap resultData;
    resultData["count"] = unstagedCount;
    resultData["files"] = unstagedFiles;

    qDebug() << "GitWrapperCPP: Unstaged all files:" << unstagedCount << "files unstaged";
    return createResult(true, resultData);
}

QVariantMap GitWrapperCPP::getStagedFiles()
{
    if (!m_currentRepo) {
        return createResult(false, QVariant(), "No repository open");
    }

    QVariantMap statusResult = status();
    if (!statusResult["success"].toBool()) {
        return statusResult;
    }

    QVariantMap statusData = statusResult["data"].toMap();
    QVariantList stagedFiles = statusData["stagedFiles"].toList();

    QVariantMap resultData;
    resultData["files"] = stagedFiles;
    resultData["count"] = stagedFiles.size();

    return createResult(true, resultData);
}

bool GitWrapperCPP::hasStagedChanges()
{
    if (!m_currentRepo) {
        return false;
    }

    QVariantMap statusResult = status();
    if (!statusResult["success"].toBool()) {
        return false;
    }

    QVariantMap statusData = statusResult["data"].toMap();
    QVariantList stagedFiles = statusData["stagedFiles"].toList();

    return !stagedFiles.isEmpty();
}

QVariantMap GitWrapperCPP::getCommit(const QString &commitHash)
{
    // Step 1: Validate inputs and check repository
    if (commitHash.isEmpty()) {
        return createResult(false, QVariant(), "Commit hash cannot be empty");
    }

    if (!m_currentRepo) {
        return createResult(false, QVariant(), "No repository available");
    }

    // Step 2: Use m_currentRepo directly
    git_oid oid;
    int result = git_oid_fromstr(&oid, commitHash.toUtf8().constData());

    if (result != 0) {
        // Try with short hash
        git_object *obj = nullptr;
        result = git_revparse_single(&obj, m_currentRepo, commitHash.toUtf8().constData());

        if (result == 0) {
            git_oid_cpy(&oid, git_object_id(obj));
            git_object_free(obj);
        } else {
            return createResult(false, QVariant(),
                                QString("Invalid commit hash: %1").arg(commitHash));
        }
    }

    git_commit *commit = nullptr;
    result = git_commit_lookup(&commit, m_currentRepo, &oid);

    if (result != 0) {
        handleGitError(result);
        return createResult(false, QVariant(),
                            QString("Commit not found: %1").arg(commitHash));
    }

    QVariantMap commitDetails = commitToMap(commit);

    // Add additional details
    commitDetails["parentCount"] = (int)git_commit_parentcount(commit);

    // Get parent hashes
    QVariantList parentHashes;
    unsigned int parentCount = git_commit_parentcount(commit);
    for (unsigned int i = 0; i < parentCount; ++i) {
        const git_oid* parentOid = git_commit_parent_id(commit, i);
        if (parentOid) {
            char hash[GIT_OID_HEXSZ + 1];
            git_oid_tostr(hash, sizeof(hash), parentOid);
            parentHashes.append(QString::fromUtf8(hash));
        }
    }
    commitDetails["parentHashes"] = parentHashes;

    // Get committer signature
    const git_signature *committer = git_commit_committer(commit);
    if (committer) {
        commitDetails["committer"] = createSignatureMap(committer);
    }

    // Get tree hash
    const git_oid *tree_oid = git_commit_tree_id(commit);
    if (tree_oid) {
        char tree_hash[GIT_OID_HEXSZ + 1];
        git_oid_tostr(tree_hash, sizeof(tree_hash), tree_oid);
        commitDetails["treeHash"] = QString::fromUtf8(tree_hash);
    }

    git_commit_free(commit);

    // Step 3: Return result
    return createResult(true, commitDetails);
}

QVariantMap GitWrapperCPP::amendLastCommit(const QString &newMessage)
{
    // This is a convenience wrapper around commit() with amend=true
    if (newMessage.isEmpty()) {
        return createResult(false, QVariant(),
                            "Cannot amend commit with empty message.\n\n"
                            "Tip: Use commit() with amend flag to keep the same message.");
    }

    return commit(newMessage, true);
}

QVariantMap GitWrapperCPP::revertCommit(const QString &commitHash)
{
    if (!m_currentRepo) {
        return createResult(false, QVariant(), "No repository open");
    }

    if (commitHash.isEmpty()) {
        return createResult(false, QVariant(), "Commit hash cannot be empty");
    }

    // 1. Convert commit hash to OID
    git_oid oid;
    int result = git_oid_fromstr(&oid, commitHash.toUtf8().constData());
    if (result != 0) {
        return createResult(false, QVariant(),
                            QString("Invalid commit hash: %1").arg(commitHash));
    }

    // 2. Look up the commit to revert
    git_commit *commit_to_revert = nullptr;  // DECLARED HERE - FIXED!
    result = git_commit_lookup(&commit_to_revert, m_currentRepo, &oid);
    if (result != 0) {
        handleGitError(result);
        return createResult(false, QVariant(),
                            QString("Commit not found: %1").arg(commitHash));
    }

    // 3. Check if there are uncommitted changes
    if (hasStagedChanges()) {
        git_commit_free(commit_to_revert);
        return createResult(false, QVariant(),
                            "Cannot revert with staged changes.\n\n"
                            "Please commit or stash your changes before reverting.");
    }

    // 4. Get HEAD commit (the "our_commit" parameter)
    git_commit* head_commit = nullptr;
    git_object* head_obj = nullptr;
    result = git_revparse_single(&head_obj, m_currentRepo, "HEAD");
    if (result != 0 || !head_obj) {
        git_commit_free(commit_to_revert);
        return createResult(false, QVariant(), "Cannot find HEAD commit");
    }
    head_commit = (git_commit*)head_obj;

    // 5. Create revert index (does NOT commit yet)
    git_index* revert_index = nullptr;
    git_merge_options merge_opts = GIT_MERGE_OPTIONS_INIT;
    // For normal commits, mainline is 0. For merge commits, specify which parent.
    unsigned int mainline = 0;

    result = git_revert_commit(
        &revert_index,        // out: index with revert changes
        m_currentRepo,        // repo
        commit_to_revert,     // commit to revert
        head_commit,          // our commit (HEAD)
        mainline,             // parent number for merge commits
        &merge_opts           // merge options
        );

    if (result != 0) {
        git_object_free(head_obj);
        git_commit_free(commit_to_revert);
        handleGitError(result);

        if (result == GIT_ECONFLICT) {
            return createResult(false, QVariant(),
                                "Revert caused conflicts.\n\n"
                                "Please resolve conflicts manually and commit the result.");
        }
        return createResult(false, QVariant(), "Failed to create revert index");
    }

    // 6. Apply the revert index to working directory
    git_checkout_options checkout_opts = GIT_CHECKOUT_OPTIONS_INIT;
    checkout_opts.checkout_strategy = GIT_CHECKOUT_SAFE;
    result = git_checkout_index(m_currentRepo, revert_index, &checkout_opts);

    // 7. Clean up intermediate objects
    git_index_free(revert_index);
    git_object_free(head_obj);
    git_commit_free(commit_to_revert);

    if (result != 0) {
        handleGitError(result);
        return createResult(false, QVariant(), "Failed to apply revert to working tree");
    }

    // 8. Create the revert commit (using your existing commit() function)
    QString message = QString("Revert \"%1\"\n\nThis reverts commit %2.")
                          .arg(commitHash.left(7))
                          .arg(commitHash);

    return commit(message, false, false); // Don't amend, don't allow empty
}

QVariantList GitWrapperCPP::getRemotes()
{
    QVariantList remotes;

    // Step 1: Check if repository is open
    if (!m_currentRepo) {
        qWarning() << "GitWrapperCPP: No repository open for getRemotes";
        return remotes;
    }

    // Step 2: Use m_currentRepo directly
    git_strarray remote_list = {0};
    int result = git_remote_list(&remote_list, m_currentRepo);

    if (result == 0) {
        for (size_t i = 0; i < remote_list.count; i++) {
            git_remote* remote = nullptr;
            result = git_remote_lookup(&remote, m_currentRepo, remote_list.strings[i]);

            if (result == 0 && remote) {
                QVariantMap remoteInfo;
                remoteInfo["name"] = QString::fromUtf8(remote_list.strings[i]);
                remoteInfo["url"] = QString::fromUtf8(git_remote_url(remote));

                // Check if this is the default remote (origin)
                remoteInfo["isOrigin"] = QString::fromUtf8(remote_list.strings[i]) == "origin";

                // Get fetch and push URLs
                const char* fetch_url = git_remote_url(remote);
                const char* push_url = git_remote_pushurl(remote);
                if (fetch_url) remoteInfo["fetchUrl"] = QString::fromUtf8(fetch_url);
                if (push_url) remoteInfo["pushUrl"] = QString::fromUtf8(push_url);

                remotes.append(remoteInfo);
                git_remote_free(remote);
            }
        }
        git_strarray_free(&remote_list);
    }

    // Step 3: No cleanup needed
    qDebug() << "GitWrapperCPP: Retrieved" << remotes.size() << "remotes";
    return remotes;
}

QVariantMap GitWrapperCPP::addRemote(const QString &name, const QString &url)
{
    // Step 1: Validate inputs and check repository
    if (name.isEmpty() || url.isEmpty()) {
        return createResult(false, QVariant(), "Remote name and URL cannot be empty");
    }

    if (!m_currentRepo) {
        return createResult(false, QVariant(), "No repository available");
    }

    // Step 2: Use m_currentRepo directly
    // Check if remote already exists
    git_remote* existing = nullptr;
    if (git_remote_lookup(&existing, m_currentRepo, name.toUtf8().constData()) == 0) {
        git_remote_free(existing);
        return createResult(false, QVariant(),
                            QString("Remote '%1' already exists").arg(name));
    }

    git_remote* remote = nullptr;
    int result = git_remote_create(&remote, m_currentRepo, name.toUtf8().constData(), url.toUtf8().constData());

    if (result != 0) {
        handleGitError(result);
        return createResult(false, QVariant(),
                            QString("Failed to add remote '%1'").arg(name));
    }

    QVariantMap remoteInfo;
    remoteInfo["name"] = name;
    remoteInfo["url"] = url;

    git_remote_free(remote);

    // Step 3: Return success
    qDebug() << "GitWrapperCPP: Added remote" << name << "with URL" << url;
    return createResult(true, remoteInfo);
}

QVariantMap GitWrapperCPP::removeRemote(const QString &name)
{
    // Step 1: Validate inputs and check repository
    if (name.isEmpty()) {
        return createResult(false, QVariant(), "Remote name cannot be empty");
    }

    if (!m_currentRepo) {
        return createResult(false, QVariant(), "No repository available");
    }

    // Step 2: Use m_currentRepo directly
    int result = git_remote_delete(m_currentRepo, name.toUtf8().constData());

    if (result != 0) {
        handleGitError(result);

        if (result == GIT_ENOTFOUND) {
            return createResult(false, QVariant(),
                                QString("Remote '%1' not found").arg(name));
        }

        return createResult(false, QVariant(),
                            QString("Failed to remove remote '%1'").arg(name));
    }

    // Step 3: Return success
    qDebug() << "GitWrapperCPP: Removed remote" << name;
    return createResult(true, name);
}

QVariantMap GitWrapperCPP::push(const QString &remoteName,
                                const QString &branchName,
                                const QString &username,
                                const QString &password,
                                bool force)
{
    // Step 1: Validate inputs and check repository
    if (remoteName.isEmpty()) {
        return createResult(false, QVariant(), "Remote name cannot be empty");
    }

    if (!m_currentRepo) {
        return createResult(false, QVariant(), "No repository available");
    }

    // Step 2: Use m_currentRepo directly
    // Determine which branch to push
    QString targetBranch = branchName;
    if (targetBranch.isEmpty()) {
        targetBranch = getCurrentBranchName(m_currentRepo);
        if (targetBranch.isEmpty()) {
            return createResult(false, QVariant(),
                                "No branch specified and repository is in detached HEAD state");
        }
    }

    // Look up the remote
    git_remote* remote = nullptr;
    int result = git_remote_lookup(&remote, m_currentRepo, remoteName.toUtf8().constData());

    if (result != 0) {
        handleGitError(result);

        if (result == GIT_ENOTFOUND) {
            return createResult(false, QVariant(),
                                QString("Remote '%1' not found. Use addRemote() to add it first.").arg(remoteName));
        }

        return createResult(false, QVariant(), "Failed to lookup remote");
    }

    // Prepare push options
    git_push_options push_opts;
    result = git_push_options_init(&push_opts, GIT_PUSH_OPTIONS_VERSION);
    if (result != 0) {
        git_remote_free(remote);
        handleGitError(result);
        return createResult(false, QVariant(), "Failed to initialize push options");
    }

    // Define a struct to hold credentials
    struct CredentialsPayload {
        QString username;
        QString password;
    };

    // Create payload on heap (will be freed later)
    CredentialsPayload* credentialsPayload = new CredentialsPayload{username, password};

    // Set the callback as a static function
    push_opts.callbacks.credentials = [](git_credential **out,
                                         const char *url,
                                         const char *username_from_url,
                                         unsigned int allowed_types,
                                         void *payload) -> int {

        CredentialsPayload* creds = static_cast<CredentialsPayload*>(payload);

        qDebug() << "GitWrapperCPP: Attempting authentication for" << url;

        // Check if credentials are provided
        if (creds->username.isEmpty() || creds->password.isEmpty()) {
            qDebug() << "GitWrapperCPP: No credentials provided in payload";
            return GIT_EUSER;
        }

        // Convert QString to C strings for libgit2
        QByteArray usernameBytes = creds->username.toUtf8();
        QByteArray passwordBytes = creds->password.toUtf8();
        const char* usernameCStr = usernameBytes.constData();
        const char* passwordCStr = passwordBytes.constData();

        // HTTPS authentication
        if (allowed_types & GIT_CREDENTIAL_USERPASS_PLAINTEXT) {
            int result = git_credential_userpass_plaintext_new(out, usernameCStr, passwordCStr);
            if (result == 0) {
                qDebug() << "GitWrapperCPP: HTTPS credentials provided successfully";
                return 0; // Success
            }
        }

        // SSH authentication
        if (allowed_types & GIT_CREDENTIAL_SSH_KEY) {
            qDebug() << "GitWrapperCPP: SSH authentication requested (not implemented)";
            return GIT_EUSER;
        }

        qDebug() << "GitWrapperCPP: No suitable authentication method";
        return GIT_EUSER;
    };

    // ✅ IMPORTANT: Pass payload pointer
    push_opts.callbacks.payload = credentialsPayload;

    // Prepare refspecs
    git_strarray refspecs = {0};
    QString refspec = force ?
                          QString("+refs/heads/%1:refs/heads/%1").arg(targetBranch) :
                          QString("refs/heads/%1:refs/heads/%1").arg(targetBranch);

    char* refspec_cstr = new char[refspec.length() + 1];
    strcpy(refspec_cstr, refspec.toUtf8().constData());
    refspecs.strings = &refspec_cstr;
    refspecs.count = 1;

    // Perform the push
    qDebug() << "GitWrapperCPP: Pushing" << targetBranch << "to" << remoteName
             << (force ? "(force)" : "");

    result = git_remote_push(remote, &refspecs, &push_opts);


    // ✅ Clean up payload
    delete credentialsPayload;
    delete[] refspec_cstr;
    git_remote_free(remote);

    // Clean up
    delete[] refspec_cstr;
    git_remote_free(remote);

    // Step 3: Handle result and return
    if (result != 0) {
        handleGitError(result);

        if (result == GIT_EUSER) {
            return createResult(false, QVariant(),
                                "Authentication required but not provided.\n\n"
                                "Please configure your credentials.");
        } else if (result == GIT_EEXISTS) {
            return createResult(false, QVariant(),
                                QString("Push rejected: remote already has changes you don't have.\n\n"
                                        "Try pulling first with:\n"
                                        "git pull %1 %2").arg(remoteName).arg(targetBranch));
        } else if (result == GIT_ENONFASTFORWARD && !force) {
            return createResult(false, QVariant(),
                                QString("Push rejected: non-fast-forward update.\n\n"
                                        "To force push, set force=true (not recommended on shared branches)"));
        }

        return createResult(false, QVariant(), "Push failed");
    }

    QVariantMap pushResult;
    pushResult["remote"] = remoteName;
    pushResult["branch"] = targetBranch;
    pushResult["force"] = force;
    pushResult["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);

    qDebug() << "GitWrapperCPP: Successfully pushed to" << remoteName;
    return createResult(true, pushResult);
}


void GitWrapperCPP::unitTest()
{
    qDebug() << "\n" << QString(60, '=');
    qDebug() << "  GitWrapperCPP - INTERNAL FUNCTIONAL TESTS";
    qDebug() << QString(60, '=') << "\n";

    int testsPassed = 0;
    int testsTotal = 0;

    // Create temporary directory for testing
    QTemporaryDir tempDir;
    if (!tempDir.isValid()) {
        qWarning() << "Failed to create temporary directory for testing";
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
        qDebug() << " init() passed - Repository created at:" << initResult["data"].toString();
        testsPassed++;
    } else {
        qWarning() << " init() failed:" << initResult["error"].toString();
    }

    // --------------------------------------------------------------------
    // TEST 2: Get Repository Info (on empty repo)
    // --------------------------------------------------------------------
    qDebug() << "\n[TEST 2/6] Testing getRepoInfo() on empty repo...";
    QVariantMap infoResult = getRepoInfo();
    testsTotal++;

    if (infoResult["success"].toBool()) {
        QVariantMap infoData = infoResult["data"].toMap();
        qDebug() << "  getRepoInfo() passed";
        qDebug() << "    - Branch:" << (infoData["branch"].toString().isEmpty() ? "detached HEAD" : infoData["branch"].toString());
        qDebug() << "    - Commit count:" << infoData["commitCount"].toInt();
        qDebug() << "    - Has changes:" << infoData["hasChanges"].toBool();
        testsPassed++;
    } else {
        qWarning() << "getRepoInfo() failed:" << infoResult["error"].toString();
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
                qDebug() << " status() passed - Detected" << untrackedCount << "untracked file(s)";
                testsPassed++;
            } else {
                qWarning() << " status() failed - No untracked files detected";
            }
        } else {
            qWarning() << " status() failed:" << statusResult["error"].toString();
        }
    } else {
        qWarning() << " Failed to create test file";
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
        qDebug() << " getBranches() - No branches found (empty repo)";
        testsPassed++; // This is acceptable for a new repo
    }

    // --------------------------------------------------------------------
    // TEST 5: Get commits (should be empty in new repo)
    // --------------------------------------------------------------------
    qDebug() << "\n[TEST 5/6] Testing getCommits()...";
    QVariantList commits = getCommits("",10);
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
        qDebug() << "close() passed - Repository closed successfully";
        testsPassed++;

        // Verify repository is actually closed
        if (m_currentRepo == nullptr && m_currentRepoPath.isEmpty()) {
            qDebug() << " Repository state cleared correctly";
        } else {
            qWarning() << "Repository state not fully cleared";
        }
    } else {
        qWarning() << "close() failed:" << closeResult["error"].toString();
    }

    // --------------------------------------------------------------------
    // TEST SUMMARY
    // --------------------------------------------------------------------
    qDebug() << "\n" << QString(60, '=');
    qDebug() << "  TEST SUMMARY";
    qDebug() << QString(60, '=');

    QString summary = QString("  Tests: %1/%2 passed").arg(testsPassed).arg(testsTotal);

    if (testsPassed == testsTotal) {
        qDebug() << summary << "ALL TESTS PASSED!";
    } else if (testsPassed > testsTotal * 0.7) {
        qDebug() << summary << "MOST TESTS PASSED";
    } else {
        qDebug() << summary << "MANY TESTS FAILED";
    }

    qDebug() << "\nNote: Clone test skipped (requires network connection)";
    qDebug() << "To test clone(), use: gitWrapper.clone(\"https://github.com/...\", \"/path/to/clone\")";
    qDebug() << QString(60, '=') << "\n";
}

void GitWrapperCPP::unitTestForGitWorkflow()
{
    qDebug() << "\nGitWrapperCPP - Git Workflow Test\n";

    int testsPassed = 0;
    int testsTotal = 0;

    // Test repository
    QString repoUrl = "https://github.com/git/GitTetser.git";
    QString localPath = QDir::homePath() + "/GitTetser_Test";
    QDir testDir(localPath);

    // --------------------------------------------------------------------
    // STEP 1: Setup - Clone or open existing
    // --------------------------------------------------------------------
    qDebug() << "STEP 1: Setup repository";

    if (testDir.exists()) {
        qDebug() << "Opening existing repository at:" << localPath;
        QVariantMap openResult = open(localPath);
        if (!openResult["success"].toBool()) {
            qWarning() << "Failed to open existing repo:" << openResult["error"].toString();
        }
    } else {
        qDebug() << "Cloning repository to:" << localPath;
        QVariantMap cloneResult = clone(repoUrl, localPath);
        if (!cloneResult["success"].toBool()) {
            qWarning() << "Clone failed:" << cloneResult["error"].toString();
            return;
        }
    }

    testsTotal++;
    testsPassed++;
    qDebug() << "Repository ready\n";

    // --------------------------------------------------------------------
    // STEP 2: Test status() function
    // --------------------------------------------------------------------
    qDebug() << "STEP 2: Testing status()";
    QVariantMap statusResult = status();
    testsTotal++;

    if (statusResult["success"].toBool()) {
        QVariantMap data = statusResult["data"].toMap();
        qDebug() << "status() - Current branch:" << data["currentBranch"].toString();
        qDebug() << "  Files staged:" << data["stagedFiles"].toList().size();
        qDebug() << "  Files unstaged:" << data["unstagedFiles"].toList().size();
        testsPassed++;
    } else {
        qWarning() << "status() failed:" << statusResult["error"].toString();
    }

    // --------------------------------------------------------------------
    // STEP 3: Create test files
    // --------------------------------------------------------------------
    qDebug() << "\nSTEP 3: Creating test files";

    QString file1 = localPath + "/test1.txt";
    QString file2 = localPath + "/test2.txt";
    QString file3 = localPath + "/test3.txt";

    // Create files
    QFile f1(file1);
    if (f1.open(QIODevice::WriteOnly)) {
        f1.write("Test file 1 content");
        f1.close();
        qDebug() << "Created: test1.txt";
    }

    QFile f2(file2);
    if (f2.open(QIODevice::WriteOnly)) {
        f2.write("Test file 2 content");
        f2.close();
        qDebug() << "Created: test2.txt";
    }

    QFile f3(file3);
    if (f3.open(QIODevice::WriteOnly)) {
        f3.write("Test file 3 content");
        f3.close();
        qDebug() << "Created: test3.txt";
    }

    // --------------------------------------------------------------------
    // STEP 4: Test stageFile() and unstageFile()
    // --------------------------------------------------------------------
    qDebug() << "\nSTEP 4: Testing stageFile() and unstageFile()";

    // Stage one file
    qDebug() << "Staging test1.txt";
    QVariantMap stageResult1 = stageFile("test1.txt");
    testsTotal++;

    if (stageResult1["success"].toBool()) {
        qDebug() << "stageFile() passed";
        testsPassed++;
    } else {
        qWarning() << "stageFile() failed:" << stageResult1["error"].toString();
    }

    // Unstage the file
    qDebug() << "Unstaging test1.txt";
    QVariantMap unstageResult = unstageFile("test1.txt");
    testsTotal++;

    if (unstageResult["success"].toBool()) {
        qDebug() << "unstageFile() passed";
        testsPassed++;
    } else {
        qWarning() << "unstageFile() failed:" << unstageResult["error"].toString();
    }

    // --------------------------------------------------------------------
    // STEP 5: Test stageAll()
    // --------------------------------------------------------------------
    qDebug() << "\nSTEP 5: Testing stageAll()";
    QVariantMap stageAllResult = stageAll();
    testsTotal++;

    if (stageAllResult["success"].toBool()) {
        QVariantMap data = stageAllResult["data"].toMap();
        qDebug() << "stageAll() - Staged" << data["count"].toInt() << "files";
        testsPassed++;
    } else {
        qWarning() << "stageAll() failed:" << stageAllResult["error"].toString();
    }

    // --------------------------------------------------------------------
    // STEP 6: Test getStagedFiles()
    // --------------------------------------------------------------------
    qDebug() << "\nSTEP 6: Testing getStagedFiles()";
    QVariantMap stagedFilesResult = getStagedFiles();
    testsTotal++;

    if (stagedFilesResult["success"].toBool()) {
        QVariantMap data = stagedFilesResult["data"].toMap();
        int stagedCount = data["count"].toInt();
        qDebug() << "getStagedFiles() - Found" << stagedCount << "staged files";

        if (stagedCount > 0) {
            qDebug() << "Staged files:";
            QVariantList files = data["files"].toList();
            for (const QVariant &file : files) {
                QVariantMap fileInfo = file.toMap();
                qDebug() << "  -" << fileInfo["path"].toString() << "[" << fileInfo["status"].toString() << "]";
            }
        }
        testsPassed++;
    } else {
        qWarning() << "getStagedFiles() failed:" << stagedFilesResult["error"].toString();
    }

    // --------------------------------------------------------------------
    // STEP 7: Test commit()
    // --------------------------------------------------------------------
    qDebug() << "\nSTEP 7: Testing commit()";
    QString commitMsg1 = "Test commit: Adding initial files";
    QVariantMap commitResult1 = commit(commitMsg1, false, false);
    testsTotal++;

    if (commitResult1["success"].toBool()) {
        QVariantMap data = commitResult1["data"].toMap();
        qDebug() << "commit() - Created commit:" << data["shortHash"].toString();
        qDebug() << "  Message:" << data["summary"].toString();
        testsPassed++;
    } else {
        qWarning() << "commit() failed:" << commitResult1["error"].toString();
    }

    // --------------------------------------------------------------------
    // STEP 8: Test getCommit()
    // --------------------------------------------------------------------
    qDebug() << "\nSTEP 8: Testing getCommit()";
    // Get the latest commit from history
    QVariantList commits = getCommits("",1);
    if (!commits.isEmpty()) {
        QVariantMap latestCommit = commits.first().toMap();
        QString commitHash = latestCommit["hash"].toString();

        QVariantMap getCommitResult = getCommit(commitHash);
        testsTotal++;

        if (getCommitResult["success"].toBool()) {
            QVariantMap data = getCommitResult["data"].toMap();
            qDebug() << "getCommit() - Retrieved commit:" << data["shortHash"].toString();
            qDebug() << "  Author:" << data["author"].toString();
            qDebug() << "  Message:" << data["summary"].toString();
            testsPassed++;
        } else {
            qWarning() << "getCommit() failed:" << getCommitResult["error"].toString();
        }
    }

    // // --------------------------------------------------------------------
    // // STEP 9: Test amendLastCommit()
    // // --------------------------------------------------------------------
    qDebug() << "\nSTEP 9: Testing amendLastCommit()";

    // Create another file to amend with
    QString amendFile = localPath + "/amend_test.txt";
    QFile f4(amendFile);
    if (f4.open(QIODevice::WriteOnly)) {
        f4.write("File for amend test");
        f4.close();
        stageFile("amend_test.txt");

        QString amendedMsg = "Amended: Added amend_test.txt file";
        QVariantMap amendResult = amendLastCommit(amendedMsg);
        testsTotal++;

        if (amendResult["success"].toBool()) {
            QVariantMap data = amendResult["data"].toMap();
            qDebug() << "amendLastCommit() - Created amended commit:" << data["shortHash"].toString();
            testsPassed++;
        } else {
            qWarning() << "amendLastCommit() failed:" << amendResult["error"].toString();
        }
    }

    // --------------------------------------------------------------------
    // STEP 10: Test revertCommit()
    // --------------------------------------------------------------------
    qDebug() << "\nSTEP 10: Testing revertCommit()";

    // Get commit to revert (the amended commit)
    commits = getCommits("",1);
    if (!commits.isEmpty()) {
        QVariantMap commitToRevert = commits.first().toMap();
        QString revertHash = commitToRevert["hash"].toString();

        qDebug() << "Attempting to revert commit:" << commitToRevert["shortHash"].toString();
        QVariantMap revertResult = revertCommit(revertHash);
        testsTotal++;

        if (revertResult["success"].toBool()) {
            qDebug() << "revertCommit() - Success";

            // Commit the revert
            QString revertMsg = "Revert: " + commitToRevert["summary"].toString();
            QVariantMap revertCommitResult = commit(revertMsg, false, false);
            if (revertCommitResult["success"].toBool()) {
                qDebug() << "Revert committed successfully";
            }
            testsPassed++;
        } else {
            qDebug() << "Note: revertCommit() result:" << revertResult["error"].toString();
        }
    }

    // --------------------------------------------------------------------
    // STEP 11: Test unstageAll()
    // --------------------------------------------------------------------
    qDebug() << "\nSTEP 11: Testing unstageAll()";

    // Create some files and stage them
    QString file4 = localPath + "/test4.txt";
    QFile f5(file4);
    if (f5.open(QIODevice::WriteOnly)) {
        f5.write("Test for unstageAll");
        f5.close();
        stageFile("test4.txt");
    }

    QVariantMap unstageAllResult = unstageAll();
    testsTotal++;

    if (unstageAllResult["success"].toBool()) {
        QVariantMap data = unstageAllResult["data"].toMap();
        qDebug() << "unstageAll() - Unstaged" << data["count"].toInt() << "files";
        testsPassed++;
    } else {
        qWarning() << "unstageAll() failed:" << unstageAllResult["error"].toString();
    }

    // --------------------------------------------------------------------
    // STEP 12: Test push() function
    // --------------------------------------------------------------------
    qDebug() << "\nSTEP 12: Testing push()";
    // Stage and commit some changes first
    stageAll();
    QVariantMap finalCommit = commit("Final test commit before push", false, false);

    if (finalCommit["success"].toBool()) {
        QVariantMap pushResult = push("origin", "", "your_User_Name", "GITHUB_TOKEN",false);
        testsTotal++;

        if (pushResult["success"].toBool()) {
            qDebug() << "push() - Successfully pushed to origin";
            qDebug() << "  Branch:" << pushResult["data"].toMap()["branch"].toString();
            testsPassed++;
        } else {
            qDebug() << "push() result:" << pushResult["error"].toString();
            qDebug() << "Note: This may be expected if you don't have push permissions";
        }
    }
    // --------------------------------------------------------------------
    // FINAL SUMMARY
    // --------------------------------------------------------------------
    qDebug() << "\nTEST COMPLETE";
    qDebug() << "============";
    qDebug() << "Tests passed:" << testsPassed << "/" << testsTotal;

    // Clean up - close repository
    close();

    qDebug() << "\nRepository path for manual inspection:" << localPath;
    qDebug() << "You can check the git history with: git log --oneline";
}
