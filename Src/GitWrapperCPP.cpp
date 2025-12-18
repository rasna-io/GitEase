#include "GitWrapperCPP.h"
#include <QDebug>
#include <QDir>

/* Constructor */
GitWrapperCPP::GitWrapperCPP(QObject *parent) : QObject(parent)
{
    git_libgit2_init();
    qDebug() << "GitWrapperCPP: Ready";
}

/* Destructor */
GitWrapperCPP::~GitWrapperCPP()
{
    closeRepo();
    git_libgit2_shutdown();
}

/* Open local repository */
bool GitWrapperCPP::openLocalRepo(const QString &path)
{
    closeRepo();

    QByteArray pathUtf8 = path.toUtf8();
    int result = git_repository_open(&m_repo, pathUtf8.constData());

    if (result != 0) {
        handleGitError(result);
        return false;
    }

    m_repoPath = path;
    updateBasicInfo();

    qDebug() << "Opened repo at:" << path;
    emit repoChanged();
    emit operationDone("Repository opened successfully");

    return true;
}

/* Clone remote repository */
bool GitWrapperCPP::cloneRemoteRepo(const QString &url, const QString &localPath)
{
    closeRepo();

    QDir dir(localPath);
    if (dir.exists()) {
        m_lastError = "Directory already exists";
        emit errorOccurred(m_lastError);
        return false;
    }

    qDebug() << "Cloning" << url << "to" << localPath;

    // Simple clone
    git_clone_options opts = GIT_CLONE_OPTIONS_INIT;
    QByteArray urlUtf8 = url.toUtf8();
    QByteArray pathUtf8 = localPath.toUtf8();

    int result = git_clone(&m_repo, urlUtf8.constData(), pathUtf8.constData(), &opts);

    if (result != 0) {
        handleGitError(result);
        return false;
    }

    m_repoPath = localPath;
    updateBasicInfo();

    qDebug() << "Clone successful";
    emit repoChanged();
    emit operationDone("Repository cloned successfully");

    return true;
}

/* Close repository */
void GitWrapperCPP::closeRepo()
{
    if (m_repo) {
        git_repository_free(m_repo);
        m_repo = nullptr;
        m_repoPath.clear();
        m_currentBranch.clear();

        qDebug() << "Repository closed";
        emit repoChanged();
    }
}

/* Get basic repository info */
QVariantList GitWrapperCPP::getBasicInfo()
{
    QVariantList info;

    if (!m_repo) {
        m_lastError = "No repository open";
        emit errorOccurred(m_lastError);
        return info;
    }

    updateBasicInfo();

    // Create simple info list
    info.append(QString("Repository: %1").arg(m_repoPath));
    info.append(QString("Current branch: %1").arg(m_currentBranch));

    // Get commit count
    git_revwalk *walker = nullptr;
    int result = git_revwalk_new(&walker, m_repo);

    if (result == 0) {
        git_revwalk_push_head(walker);
        git_oid oid;
        int commitCount = 0;

        while (git_revwalk_next(&oid, walker) == 0) {
            commitCount++;
            if (commitCount > 100) break; // Limit for speed
        }

        info.append(QString("Commits: %1").arg(commitCount));
        git_revwalk_free(walker);
    }

    // Get branch count
    git_branch_iterator *iter = nullptr;
    result = git_branch_iterator_new(&iter, m_repo, GIT_BRANCH_LOCAL);

    if (result == 0) {
        git_reference *ref = nullptr;
        git_branch_t type;
        int branchCount = 0;

        while (git_branch_next(&ref, &type, iter) == 0) {
            branchCount++;
            git_reference_free(ref);
        }

        info.append(QString("Local branches: %1").arg(branchCount));
        git_branch_iterator_free(iter);
    }

    // Get status
    git_status_options opts = GIT_STATUS_OPTIONS_INIT;
    opts.show = GIT_STATUS_SHOW_INDEX_AND_WORKDIR;

    git_status_list *status = nullptr;
    result = git_status_list_new(&status, m_repo, &opts);

    if (result == 0) {
        size_t count = git_status_list_entrycount(status);
        info.append(QString("Changed files: %1").arg(count));
        git_status_list_free(status);
    }

    qDebug() << "Basic info retrieved";
    return info;
}

/* Create a commit */
bool GitWrapperCPP::commit(const QString &message)
{
    if (!m_repo) {
        m_lastError = "No repository open";
        emit errorOccurred(m_lastError);
        return false;
    }

    if (message.isEmpty()) {
        m_lastError = "Commit message is empty";
        emit errorOccurred(m_lastError);
        return false;
    }

    // Stage all changes first (simplified)
    git_index *index = nullptr;
    int result = git_repository_index(&index, m_repo);

    if (result == 0) {
        git_index_add_all(index, nullptr, 0, nullptr, nullptr);
        git_index_write(index);

        // Create tree
        git_oid tree_id;
        git_index_write_tree(&tree_id, index);
        git_index_free(index);

        git_tree *tree = nullptr;
        git_tree_lookup(&tree, m_repo, &tree_id);

        // Get signature
        git_signature *sig = nullptr;
        git_signature_default(&sig, m_repo);

        // Get parent
        git_commit *parent = nullptr;
        git_reference *head = nullptr;
        if (git_repository_head(&head, m_repo) == 0) {
            git_reference_peel((git_object**)&parent, head, GIT_OBJECT_COMMIT);
            git_reference_free(head);
        }

        // Create commit
        git_oid commit_id;
        const git_commit *parents[] = { parent };

        QByteArray msg = message.toUtf8();
        result = git_commit_create(&commit_id, m_repo, "HEAD",
                                   sig, sig, nullptr,
                                   msg.constData(), tree,
                                   parent ? 1 : 0, parent ? parents : nullptr);

        if (tree) git_tree_free(tree);
        if (sig) git_signature_free(sig);
        if (parent) git_commit_free(parent);

        if (result != 0) {
            handleGitError(result);
            return false;
        }

        qDebug() << "Committed:" << message;
        emit operationDone("Commit created successfully");
        return true;
    }

    handleGitError(result);
    return false;
}

/* Push to remote */
bool GitWrapperCPP::push(const QString &remote)
{
    if (!m_repo) {
        m_lastError = "No repository open";
        emit errorOccurred(m_lastError);
        return false;
    }

    // Simple push implementation
    git_remote *rmt = nullptr;
    QByteArray remoteUtf8 = remote.toUtf8();
    int result = git_remote_lookup(&rmt, m_repo, remoteUtf8.constData());

    if (result == 0) {
        // Get current branch for push
        git_reference *head = nullptr;
        if (git_repository_head(&head, m_repo) == 0) {
            const char *branch = git_reference_shorthand(head);
            QString refspec = QString("refs/heads/%1:refs/heads/%1").arg(branch);

            const char *refspecs[] = { refspec.toUtf8().constData() };
            git_strarray refs = { (char**)refspecs, 1 };

            // Connect and push
            result = git_remote_connect(rmt, GIT_DIRECTION_PUSH, nullptr, nullptr, nullptr);
            if (result == 0) {
                result = git_remote_push(rmt, &refs, nullptr);
                git_remote_disconnect(rmt);
            }

            git_reference_free(head);
        }

        git_remote_free(rmt);
    }

    if (result != 0) {
        handleGitError(result);
        return false;
    }

    qDebug() << "Pushed to" << remote;
    emit operationDone("Push successful");
    return true;
}

/* Private helper to update basic info */
void GitWrapperCPP::updateBasicInfo()
{
    if (!m_repo) return;

    // Get current branch
    git_reference *head = nullptr;
    if (git_repository_head(&head, m_repo) == 0) {
        const char *branch = git_reference_shorthand(head);
        m_currentBranch = branch ? QString(branch) : "detached";
        git_reference_free(head);
    } else {
        m_currentBranch = "unknown";
    }
}

/* Handle Git errors */
void GitWrapperCPP::handleGitError(int errorCode)
{
    const git_error *error = git_error_last();
    if (error && error->message) {
        m_lastError = QString("Git error: %1").arg(error->message);
    } else {
        m_lastError = QString("Git error code: %1").arg(errorCode);
    }

    qDebug() << "Error:" << m_lastError;
    emit errorOccurred(m_lastError);
}
