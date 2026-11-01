#include "GitTree.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTimer>
#include <QUrl>
#include <QUuid>

#include <git2/diff.h>
#include <git2/index.h>

#include <utility>

namespace {

GitResult writeBlobToFile(git_blob *blob, const QString &targetPath)
{
    if (!blob)
        return GitResult(false, QVariant(), QStringLiteral("File has no content"));

    QFile file(targetPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return GitResult(false, QVariant(), QStringLiteral("Cannot write to ") + targetPath);

    const auto size = static_cast<qint64>(git_blob_rawsize(blob));
    const qint64 written = file.write(static_cast<const char *>(git_blob_rawcontent(blob)), size);
    file.close();

    if (written != size) {
        QFile::remove(targetPath);
        return GitResult(false, QVariant(), QStringLiteral("Cannot write to ") + targetPath);
    }

    return GitResult(true, targetPath);
}

QString normalizedGitPath(const QString &path)
{
    return QDir::fromNativeSeparators(path);
}

}

GitTree::GitTree(QObject *parent)
    : IGitController(parent)
{
}

GitTree::~GitTree()
{
    for (const QString &path : std::as_const(m_pendingTempFiles))
        QFile::remove(path);
}

GitResult GitTree::getFileTree(const QString &sha)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), "Repository not open");

    QString errorMessage;
    git_tree *rootTree = lookupCommitTree(sha, errorMessage);
    if (!rootTree)
        return GitResult(false, QVariant(), errorMessage);

    QVariantList entries;
    bool ok = appendTreeEntries(rootTree, "", 0, entries);
    git_tree_free(rootTree);

    if (!ok)
        return GitResult(false, QVariant(), "Failed to walk the commit tree");

    return GitResult(true, entries);
}

GitResult GitTree::getFileContent(const QString &sha, const QString &path)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), "Repository not open");

    QString errorMessage;
    git_blob *blob = lookupBlob(sha, path, errorMessage);
    if (!blob)
        return GitResult(false, QVariant(), errorMessage);

    bool isBinary = git_blob_is_binary(blob) != 0;
    git_object_size_t size = git_blob_rawsize(blob);

    QVariantMap fileMap;
    fileMap["path"]         = path;
    fileMap["isBinary"]     = isBinary;
    fileMap["size"]         = static_cast<qulonglong>(size);
    fileMap["content"]      = isBinary
            ? QString()
            : QString::fromUtf8(static_cast<const char*>(git_blob_rawcontent(blob)),
                                static_cast<int>(size));

    git_blob_free(blob);

    return GitResult(true, fileMap);
}

GitResult GitTree::saveFileContent(const QString &sha, const QString &path, const QString &targetPath)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), "Repository not open");

    if (targetPath.isEmpty())
        return GitResult(false, QVariant(), "Target path is empty");

    QString errorMessage;
    git_blob *blob = lookupBlob(sha, path, errorMessage);
    if (!blob)
        return GitResult(false, QVariant(), errorMessage);

    const GitResult result = writeBlobToFile(blob, targetPath);
    git_blob_free(blob);
    return result;
}

GitResult GitTree::saveIndexFileContent(const QString &path, const QString &targetPath)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), QStringLiteral("Repository not open"));

    if (targetPath.isEmpty())
        return GitResult(false, QVariant(), QStringLiteral("Target path is empty"));

    if (path.isEmpty())
        return GitResult(false, QVariant(), QStringLiteral("File path is empty"));

    git_index *index = nullptr;
    if (git_repository_index(&index, activeRepo()) != GIT_OK || !index)
        return GitResult(false, QVariant(), QStringLiteral("Failed to read the index"));

    const QByteArray pathUtf8 = path.toUtf8();
    const git_index_entry *entry = git_index_get_bypath(index, pathUtf8.constData(), 0);
    if (!entry) {
        git_index_free(index);
        return GitResult(false, QVariant(), QStringLiteral("File not found in the index: ") + path);
    }

    git_blob *blob = nullptr;
    const int error = git_blob_lookup(&blob, activeRepo(), &entry->id);
    git_index_free(index);
    if (error != GIT_OK || !blob)
        return GitResult(false, QVariant(), QStringLiteral("Failed to read the staged file: ") + path);

    const GitResult result = writeBlobToFile(blob, targetPath);
    git_blob_free(blob);
    return result;
}

QString GitTree::previousPath(const QString &filePath, const QString &oldRevision,
                              const QString &mode, const QString &newRevision)
{
    const QString fallback = normalizedGitPath(filePath);
    if (!m_currentRepo || !activeRepo() || fallback.isEmpty())
        return fallback;

    const QString oldRev = oldRevision.isEmpty() ? QStringLiteral("HEAD") : oldRevision;
    QString errorMessage;
    git_tree *oldTree = lookupCommitTree(oldRev, errorMessage);
    if (!oldTree)
        return fallback;

    git_tree *newTree = nullptr;
    git_diff *diff = nullptr;
    git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
    int error = GIT_OK;

    if (mode == QLatin1String("commit")) {
        newTree = lookupCommitTree(newRevision, errorMessage);
        if (!newTree) {
            git_tree_free(oldTree);
            return fallback;
        }
        error = git_diff_tree_to_tree(&diff, activeRepo(), oldTree, newTree, &opts);
    } else if (mode == QLatin1String("index")) {
        error = git_diff_tree_to_index(&diff, activeRepo(), oldTree, nullptr, &opts);
    } else {
        opts.flags |= GIT_DIFF_INCLUDE_UNTRACKED | GIT_DIFF_RECURSE_UNTRACKED_DIRS;
        error = git_diff_tree_to_workdir(&diff, activeRepo(), oldTree, &opts);
    }

    git_tree_free(oldTree);
    if (newTree)
        git_tree_free(newTree);

    if (error != GIT_OK || !diff)
        return fallback;

    git_diff_find_options findOpts = GIT_DIFF_FIND_OPTIONS_INIT;
    findOpts.flags = GIT_DIFF_FIND_RENAMES;
    if (mode != QLatin1String("commit") && mode != QLatin1String("index"))
        findOpts.flags |= GIT_DIFF_FIND_FOR_UNTRACKED;
    git_diff_find_similar(diff, &findOpts);

    QString found = fallback;
    const size_t count = git_diff_num_deltas(diff);
    for (size_t i = 0; i < count; ++i) {
        const git_diff_delta *delta = git_diff_get_delta(diff, i);
        if (!delta || !delta->new_file.path)
            continue;

        const QString newPath = normalizedGitPath(QString::fromUtf8(delta->new_file.path));
        if (newPath != fallback)
            continue;

        if (delta->old_file.path) {
            const QString oldPath = normalizedGitPath(QString::fromUtf8(delta->old_file.path));
            if (!oldPath.isEmpty())
                found = oldPath;
        }
        break;
    }

    git_diff_free(diff);
    return found;
}

QString GitTree::absoluteWorkdirFile(const QString &repositoryPath, const QString &filePath) const
{
    return QDir(repositoryPath).filePath(filePath);
}

bool GitTree::localFileExists(const QString &path) const
{
    const QFileInfo info(path);
    return info.isFile() && info.exists();
}

QUrl GitTree::localFileUrl(const QString &path) const
{
    return QUrl::fromLocalFile(QFileInfo(path).absoluteFilePath());
}

QString GitTree::makeTempImagePath(const QString &extension) const
{
    QString ext;
    for (const QChar &ch : extension) {
        if (ch.isLetterOrNumber())
            ext.append(ch.toLower());
        if (ext.size() >= 8)
            break;
    }
    if (ext.isEmpty())
        ext = QStringLiteral("img");

    const QString name = QStringLiteral("gitease-imagediff-%1.%2")
                             .arg(QUuid::createUuid().toString(QUuid::Id128), ext);
    return QDir(QDir::tempPath()).filePath(name);
}

void GitTree::discardTempFiles(const QStringList &paths)
{
    const QString tempRoot = QDir(QDir::tempPath()).absolutePath();
    for (const QString &path : paths) {
        const QFileInfo info(path);
        if (!info.fileName().startsWith(QStringLiteral("gitease-imagediff-")))
            continue;
        const QString absolute = info.absoluteFilePath();
        if (!absolute.startsWith(tempRoot, Qt::CaseInsensitive))
            continue;
        if (!m_pendingTempFiles.contains(absolute))
            m_pendingTempFiles.append(absolute);
    }

    if (m_pendingTempFiles.isEmpty())
        return;

    if (!m_tempDiscardTimer) {
        m_tempDiscardTimer = new QTimer(this);
        m_tempDiscardTimer->setInterval(400);
        connect(m_tempDiscardTimer, &QTimer::timeout, this, &GitTree::flushTempFiles);
    }

    m_tempDiscardAttempts = 0;
    flushTempFiles();
    if (!m_pendingTempFiles.isEmpty() && !m_tempDiscardTimer->isActive())
        m_tempDiscardTimer->start();
}

void GitTree::flushTempFiles()
{
    QStringList stillLocked;
    for (const QString &path : std::as_const(m_pendingTempFiles)) {
        if (!QFileInfo::exists(path))
            continue;
        if (!QFile::remove(path))
            stillLocked.append(path);
    }

    m_pendingTempFiles = stillLocked;
    ++m_tempDiscardAttempts;

    if (m_pendingTempFiles.isEmpty() || m_tempDiscardAttempts >= 20) {
        m_pendingTempFiles.clear();
        if (m_tempDiscardTimer)
            m_tempDiscardTimer->stop();
        return;
    }

    if (m_tempDiscardTimer && !m_tempDiscardTimer->isActive())
        m_tempDiscardTimer->start();
}

git_tree* GitTree::lookupCommitTree(const QString &sha, QString &errorMessage)
{
    QString revision = sha + "^{commit}";

    git_object *commitObj = nullptr;
    if (git_revparse_single(&commitObj, activeRepo(), revision.toUtf8().constData()) < 0) {
        errorMessage = "Commit not found: " + sha;
        return nullptr;
    }

    git_tree *tree = nullptr;
    int error = git_commit_tree(&tree, reinterpret_cast<git_commit*>(commitObj));
    git_object_free(commitObj);

    if (error < 0) {
        errorMessage = "Failed to read tree of commit " + sha;
        return nullptr;
    }

    return tree;
}

git_blob* GitTree::lookupBlob(const QString &sha, const QString &path, QString &errorMessage)
{
    git_tree *rootTree = lookupCommitTree(sha, errorMessage);
    if (!rootTree)
        return nullptr;

    git_tree_entry *entry = nullptr;
    int error = git_tree_entry_bypath(&entry, rootTree, path.toUtf8().constData());
    git_tree_free(rootTree);

    if (error < 0) {
        errorMessage = "File not found at this commit: " + path;
        return nullptr;
    }

    if (git_tree_entry_type(entry) != GIT_OBJECT_BLOB) {
        git_tree_entry_free(entry);
        errorMessage = "Path is not a file: " + path;
        return nullptr;
    }

    git_blob *blob = nullptr;
    error = git_blob_lookup(&blob, activeRepo(), git_tree_entry_id(entry));
    git_tree_entry_free(entry);

    if (error < 0) {
        errorMessage = "Failed to read file content: " + path;
        return nullptr;
    }

    return blob;
}

bool GitTree::appendTreeEntries(git_tree *tree, const QString &basePath, int depth, QVariantList &entries)
{
    struct ChildEntry {
        QString name;
        const git_tree_entry *entry;
    };

    QList<ChildEntry> folders;
    QList<ChildEntry> files;

    size_t count = git_tree_entrycount(tree);
    for (size_t i = 0; i < count; ++i) {
        const git_tree_entry *entry = git_tree_entry_byindex(tree, i);
        if (!entry)
            continue;

        QString name = QString::fromUtf8(git_tree_entry_name(entry));

        if (git_tree_entry_type(entry) == GIT_OBJECT_TREE)
            folders.append({name, entry});
        else if (git_tree_entry_type(entry) == GIT_OBJECT_BLOB)
            files.append({name, entry});
    }

    auto byName = [](const ChildEntry &a, const ChildEntry &b) {
        return a.name.compare(b.name, Qt::CaseInsensitive) < 0;
    };
    std::sort(folders.begin(), folders.end(), byName);
    std::sort(files.begin(), files.end(), byName);

    for (const ChildEntry &folder : folders) {
        QString fullPath = basePath.isEmpty() ? folder.name : basePath + "/" + folder.name;

        QVariantMap entryMap;
        entryMap["name"]        = folder.name;
        entryMap["path"]        = fullPath;
        entryMap["type"]        = "tree";
        entryMap["depth"]       = depth;
        entryMap["parentPath"]  = basePath;
        entries.append(entryMap);

        git_tree *subTree = nullptr;
        if (git_tree_lookup(&subTree, activeRepo(), git_tree_entry_id(folder.entry)) < 0)
            return false;

        bool ok = appendTreeEntries(subTree, fullPath, depth + 1, entries);
        git_tree_free(subTree);

        if (!ok)
            return false;
    }

    for (const ChildEntry &file : files) {
        QString fullPath = basePath.isEmpty() ? file.name : basePath + "/" + file.name;

        QVariantMap entryMap;
        entryMap["name"]        = file.name;
        entryMap["path"]        = fullPath;
        entryMap["type"]        = "blob";
        entryMap["depth"]       = depth;
        entryMap["parentPath"]  = basePath;
        entries.append(entryMap);
    }

    return true;
}
